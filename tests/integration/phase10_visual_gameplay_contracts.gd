extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const WorldRuntime = preload("res://src/runtime/play_runtime_state.gd")
const GameplayContracts = preload("res://src/gameplay/gameplay_contracts.gd")
const NarrativeContracts = preload("res://src/gameplay/gameplay_narrative_contracts.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const RuntimeGameplay = preload("res://src/gameplay/runtime_gameplay_state.gd")
const Health = preload("res://src/gameplay/runtime_health_service.gd")
const Quest = preload("res://src/gameplay/runtime_quest_service.gd")
const VisualContracts = preload("res://src/visual_scripting/visual_graph_contracts.gd")
const NodeLibrary = preload("res://src/visual_scripting/builtin_visual_node_library.gd")
const VisualRuntime = preload("res://src/visual_scripting/visual_graph_runtime_session.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var expected_nodes: Array[String] = [
        "gameplay.get_component_value",
        "gameplay.set_component_value",
        "gameplay.emit_event",
        "gameplay.interact",
        "gameplay.damage",
        "gameplay.heal",
        "gameplay.start_dialogue",
        "gameplay.start_quest",
        "gameplay.enter_vehicle",
        "gameplay.save_slot",
        "gameplay.load_slot",
    ]
    for node_key in expected_nodes:
        if not NodeLibrary.has_key(node_key):
            errors.append("Phase 10 Visual Scripting node library is missing: %s" % node_key)

    var project = WorldProject.new()
    project.initialize_new("Phase 10 Visual Gameplay", &"small", "blank_sandbox")
    var cell_id: String = StableId.generate()
    var cell_ids: Array[String] = [cell_id]
    project.cell_ids = cell_ids
    var source = WorldEntity.new()
    source.initialize_new("Source", cell_id)
    var target = WorldEntity.new()
    target.initialize_new("Target", cell_id)
    var instances: Array[Dictionary] = []
    _attach(target, instances, "health", {"max_health": 100.0, "current_health": 100.0})
    var entity_records: Array[Dictionary] = [source.to_dictionary(), target.to_dictionary()]
    project.entity_records = entity_records
    var authored: Dictionary = project.to_dictionary()

    var quest_id: String = StableId.generate()
    var objective_id: String = StableId.generate()
    var quest: Dictionary = {
        "document_type": NarrativeContracts.QUEST,
        "schema_version": NarrativeContracts.SCHEMA_VERSION,
        "quest_id": quest_id,
        "display_name": "Visual Event Quest",
        "description": "Advance through a gameplay graph event.",
        "participant_entity_ids": [],
        "prerequisite_quest_ids": [],
        "objectives": [{
            "objective_id": objective_id,
            "display_name": "Receive graph event",
            "kind": "custom",
            "event_key": "visual.gameplay.tick",
            "target_entity_id": target.entity_id,
            "required_count": 1,
            "optional": false,
        }],
    }
    var gameplay = RuntimeGameplay.new()
    var gameplay_snapshot: Dictionary = {
        "definitions": Components.definitions(),
        "instances": instances,
        "sockets": [],
        "attachments": [],
        "dialogues": [],
        "quests": [quest],
    }
    var gameplay_result: Dictionary = gameplay.initialize(authored, gameplay_snapshot)
    if not gameplay_result.get("ok", false):
        return ["Phase 10 Visual gameplay fixture failed: %s" % str(gameplay_result.get("errors", []))]
    var world = WorldRuntime.new()
    var world_result: Dictionary = world.load_authored_project(authored)
    if not world_result.get("ok", false):
        return ["Phase 10 Visual world fixture failed."]
    var health = Health.new()
    if not health.bind_runtime(gameplay).get("ok", false):
        return ["Phase 10 Visual health runtime could not bind."]
    var quest_runtime = Quest.new()
    if not quest_runtime.bind_runtime(gameplay).get("ok", false):
        return ["Phase 10 Visual quest runtime could not bind."]
    if not quest_runtime.start_quest(quest_id).get("ok", false):
        return ["Phase 10 Visual quest fixture could not start."]

    var graph: Dictionary = _gameplay_graph(source.entity_id, target.entity_id)
    var runtime = VisualRuntime.new()
    var context: Dictionary = {
        "gameplay_damage": Callable(health, "apply_damage"),
        "gameplay_emit_event": Callable(gameplay, "emit_event"),
    }
    var result: Dictionary = runtime.execute_start([graph], world, context)
    if not result.get("ok", false):
        errors.append("Phase 10 gameplay nodes must execute through the existing Phase 8 runtime: %s" % str(result.get("errors", [])))
    else:
        if int(result.get("executed_graphs", 0)) != 1:
            errors.append("Phase 10 Visual runtime must execute the event graph exactly once.")
        var health_values: Dictionary = gameplay.get_component_values(target.entity_id, "health")
        if float(health_values.get("current_health", -1.0)) != 75.0:
            errors.append("Visual gameplay.damage must invoke the shared Phase 10 health runtime.")
        var quest_state: Dictionary = quest_runtime.get_quest_state(quest_id).get("state", {})
        if str(quest_state.get("status", "")) != "completed":
            errors.append("Visual gameplay.emit_event must feed the shared Phase 10 quest event bus.")
    if authored != project.to_dictionary():
        errors.append("Visual gameplay execution must not mutate authored Build project data.")

    health.clear()
    quest_runtime.clear()
    gameplay.clear()
    world.clear()
    var replay_gameplay = RuntimeGameplay.new()
    var replay_result: Dictionary = replay_gameplay.initialize(authored, gameplay_snapshot)
    if not replay_result.get("ok", false):
        errors.append("Phase 10 runtime gameplay must reinitialize cleanly after disposable Play teardown.")
    elif float(replay_gameplay.get_component_values(target.entity_id, "health").get("current_health", -1.0)) != 100.0:
        errors.append("Repeated Play initialization must restore authored component state rather than prior runtime damage.")
    return errors


static func _gameplay_graph(source_entity_id: String, target_entity_id: String) -> Dictionary:
    var start_id: String = StableId.generate()
    var target_literal_id: String = StableId.generate()
    var amount_literal_id: String = StableId.generate()
    var damage_id: String = StableId.generate()
    var emit_id: String = StableId.generate()
    return {
        "document_type": VisualContracts.GRAPH_DOCUMENT_TYPE,
        "schema_version": VisualContracts.SCHEMA_VERSION,
        "graph_id": StableId.generate(),
        "display_name": "Phase 10 Gameplay Graph",
        "kind": "event",
        "owner_entity_id": null,
        "enabled": true,
        "nodes": [
            _node(start_id, "event.start"),
            _node(target_literal_id, "value.literal", {"value": target_entity_id}),
            _node(amount_literal_id, "value.literal", {"value": 25.0}),
            _node(damage_id, "gameplay.damage", {"source_entity_id": source_entity_id}),
            _node(emit_id, "gameplay.emit_event", {
                "event_key": "visual.gameplay.tick",
                "source_entity_id": source_entity_id,
                "target_entity_id": target_entity_id,
                "payload": {},
            }),
        ],
        "connections": [
            _connection(start_id, "next", damage_id, "in", "exec"),
            _connection(damage_id, "next", emit_id, "in", "exec"),
            _connection(target_literal_id, "value", damage_id, "target_entity_id", "data"),
            _connection(amount_literal_id, "value", damage_id, "amount", "data"),
        ],
        "variables": [],
        "interface": {"inputs": [], "outputs": []},
        "editor": {},
    }


static func _attach(entity, instances: Array[Dictionary], component_key: String, patch: Dictionary) -> void:
    var definition: Dictionary = _definition(component_key)
    var values: Dictionary = GameplayContracts.defaults_for(definition)
    for key in patch.keys():
        values[key] = patch[key]
    var record: Dictionary = {
        "document_type": GameplayContracts.COMPONENT_INSTANCE,
        "schema_version": GameplayContracts.SCHEMA_VERSION,
        "instance_id": StableId.generate(),
        "definition_id": str(definition.get("definition_id", "")),
        "owner_entity_id": entity.entity_id,
        "values": values,
    }
    instances.append(record)
    entity.component_instance_ids.append(str(record["instance_id"]))


static func _definition(key: String) -> Dictionary:
    for definition in Components.definitions():
        if str(definition.get("key", "")) == key:
            return definition.duplicate(true)
    return {}


static func _node(node_id: String, type_key: String, properties: Dictionary = {}) -> Dictionary:
    return {"node_id": node_id, "type_key": type_key, "position": [0.0, 0.0], "properties": properties}


static func _connection(from_id: String, from_port: String, to_id: String, to_port: String, kind: String) -> Dictionary:
    return {
        "connection_id": StableId.generate(),
        "from_node_id": from_id,
        "from_port": from_port,
        "to_node_id": to_id,
        "to_port": to_port,
        "kind": kind,
    }
