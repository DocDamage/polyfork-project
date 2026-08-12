extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const WorldRuntime = preload("res://src/runtime/play_runtime_state.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const RuntimeGameplay = preload("res://src/gameplay/runtime_gameplay_state.gd")
const Interaction = preload("res://src/gameplay/runtime_interaction_service.gd")
const NpcAi = preload("res://src/gameplay/runtime_npc_ai_service.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new(); project.initialize_new("Phase 10 NPC", &"small", "blank_sandbox")
    var cell_id := StableId.generate(); var cells: Array[String] = [cell_id]; project.cell_ids = cells
    var npc = WorldEntity.new(); npc.initialize_new("NPC", cell_id); npc.transform["position"] = [0.0, 0.0, 0.0]
    var target = WorldEntity.new(); target.initialize_new("Target", cell_id); target.transform["position"] = [4.0, 0.0, 0.0]
    var instances: Array[Dictionary] = []
    _attach(npc, instances, "character_controller", {"move_speed": 4.0})
    _attach(npc, instances, "npc_brain", {"enabled": true, "profile": "basic"})
    _attach(target, instances, "interactable", {"prompt": "Talk"})
    var records: Array[Dictionary] = [npc.to_dictionary(), target.to_dictionary()]; project.entity_records = records
    var authored := project.to_dictionary()

    var gameplay = RuntimeGameplay.new()
    var gameplay_result := gameplay.initialize(authored, {"definitions": Components.definitions(), "instances": instances, "sockets": [], "attachments": []})
    if not gameplay_result.get("ok", false): return ["Phase 10 NPC gameplay fixture failed: %s" % str(gameplay_result.get("errors", []))]
    var world = WorldRuntime.new()
    var world_result := world.load_authored_project(authored)
    if not world_result.get("ok", false): return ["Phase 10 NPC world runtime fixture failed."]
    var interaction = Interaction.new(); interaction.bind_runtime(gameplay)
    var ai = NpcAi.new()
    if not ai.bind_runtime(gameplay, world, interaction).get("ok", false): return ["NPC AI service must bind to Play runtime services."]

    var destination := ai.set_destination(npc.entity_id, Vector3(4.0, 0.0, 0.0), 0.1)
    if not destination.get("ok", false): errors.append("Enabled NPCs must accept reusable destination goals.")
    var first := ai.advance(0.5)
    var first_position := _position(world.get_entity(npc.entity_id))
    if not first.get("ok", false) or not is_equal_approx(first_position.x, 2.0): errors.append("NPC destination advance must use Character Controller movement speed.")
    ai.advance(0.5)
    var final_position := _position(world.get_entity(npc.entity_id))
    if not is_equal_approx(final_position.x, 4.0) or not ai.get_goal(npc.entity_id).is_empty(): errors.append("NPC destination goals must complete deterministically at arrival.")
    if _position_from_project(authored, npc.entity_id) != Vector3.ZERO: errors.append("NPC Play movement must never mutate authored Build transforms.")

    ai.wait(npc.entity_id, 1.0)
    ai.advance(0.4)
    if ai.get_goal(npc.entity_id).is_empty(): errors.append("NPC wait goals must remain active until their duration expires.")
    ai.advance(0.6)
    if not ai.get_goal(npc.entity_id).is_empty(): errors.append("NPC wait goals must complete after deterministic accumulated delta.")

    var follow := ai.follow_entity(npc.entity_id, target.entity_id, 0.25, true)
    if not follow.get("ok", false): errors.append("NPCs must follow stable target entity IDs.")
    ai.advance(0.1)
    var kinds: Dictionary = {}
    for event in gameplay.events_after(0): kinds[str(event.get("kind", ""))] = true
    if not kinds.has("interaction.performed"): errors.append("NPC goals may route a generic interaction when arriving at an interactable target.")
    if ai.follow_entity(npc.entity_id, StableId.generate()).get("ok", false): errors.append("NPC follow goals must fail closed for missing stable target references.")
    return errors


static func _attach(entity, instances: Array[Dictionary], key: String, patch: Dictionary) -> void:
    var definition := _definition(key); var values: Dictionary = Contracts.defaults_for(definition)
    for field in patch.keys(): values[field] = patch[field]
    var record := {"document_type": Contracts.COMPONENT_INSTANCE, "schema_version": Contracts.SCHEMA_VERSION, "instance_id": StableId.generate(), "definition_id": str(definition.get("definition_id", "")), "owner_entity_id": entity.entity_id, "values": values}
    instances.append(record); entity.component_instance_ids.append(str(record["instance_id"]))

static func _definition(key: String) -> Dictionary:
    for definition in Components.definitions():
        if str(definition.get("key", "")) == key: return definition.duplicate(true)
    return {}

static func _position(record: Dictionary) -> Vector3:
    var value: Array = record.get("transform", {}).get("position", [])
    return Vector3(float(value[0]), float(value[1]), float(value[2])) if value.size() == 3 else Vector3.ZERO

static func _position_from_project(project_data: Dictionary, entity_id: String) -> Vector3:
    for record in project_data.get("entities", []):
        if record is Dictionary and str(record.get("entity_id", "")) == entity_id: return _position(record)
    return Vector3.ZERO
