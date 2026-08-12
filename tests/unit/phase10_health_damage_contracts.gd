extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const RuntimeGameplay = preload("res://src/gameplay/runtime_gameplay_state.gd")
const Health = preload("res://src/gameplay/runtime_health_service.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new()
    project.initialize_new("Phase 10 Health", &"small", "blank_sandbox")
    var cell_id := StableId.generate()
    var cells: Array[String] = [cell_id]
    project.cell_ids = cells
    var source = WorldEntity.new(); source.initialize_new("Source", cell_id)
    var target = WorldEntity.new(); target.initialize_new("Target", cell_id)
    var invulnerable = WorldEntity.new(); invulnerable.initialize_new("Invulnerable", cell_id)
    var instances: Array[Dictionary] = []
    _attach(target, instances, "health", {"max_health": 100.0, "current_health": 100.0})
    _attach(target, instances, "damageable", {"armor": 5.0})
    _attach(invulnerable, instances, "health", {"max_health": 50.0, "current_health": 50.0})
    _attach(invulnerable, instances, "damageable", {"invulnerable": true})
    var records: Array[Dictionary] = [source.to_dictionary(), target.to_dictionary(), invulnerable.to_dictionary()]
    project.entity_records = records

    var runtime = RuntimeGameplay.new()
    var load_result := runtime.initialize(project.to_dictionary(), {
        "definitions": Components.definitions(),
        "instances": instances,
        "sockets": [],
        "attachments": [],
    })
    if not load_result.get("ok", false): return ["Phase 10 health fixture must initialize: %s" % str(load_result.get("errors", []))]
    var health = Health.new()
    if not health.bind_runtime(runtime).get("ok", false): return ["Health service must bind to loaded runtime state."]

    var damage := health.apply_damage(target.entity_id, 25.0, source.entity_id)
    if not damage.get("ok", false) or float(damage.get("applied", -1.0)) != 20.0 or float(damage.get("current_health", -1.0)) != 80.0:
        errors.append("Damage must apply reusable armor reduction and update runtime Health state.")
    var heal := health.heal(target.entity_id, 50.0, source.entity_id)
    if not heal.get("ok", false) or float(heal.get("current_health", -1.0)) != 100.0 or float(heal.get("applied", -1.0)) != 20.0:
        errors.append("Healing must clamp to authored max_health.")
    var blocked := health.apply_damage(invulnerable.entity_id, 20.0, source.entity_id)
    if not blocked.get("ok", false) or not bool(blocked.get("blocked", false)) or float(blocked.get("applied", -1.0)) != 0.0:
        errors.append("Invulnerable damageable entities must fail damage safely without health loss.")

    var lethal := health.apply_damage(target.entity_id, 200.0, source.entity_id)
    if not lethal.get("ok", false) or not bool(lethal.get("died", false)) or not health.is_dead(target.entity_id):
        errors.append("Lethal damage must generate reusable dead runtime state.")
    if float(runtime.get_component_values(target.entity_id, "health").get("current_health", -1.0)) != 0.0:
        errors.append("Lethal damage must clamp runtime health at zero.")
    var revive := health.heal(target.entity_id, 10.0, source.entity_id)
    if not revive.get("ok", false) or health.is_dead(target.entity_id):
        errors.append("Generic healing above zero must clear derived dead runtime state.")

    if health.apply_damage(target.entity_id, 10.0, StableId.generate()).get("ok", false):
        errors.append("Damage events with missing stable source references must fail closed.")
    var kinds: Dictionary = {}
    for event in runtime.events_after(0): kinds[str(event.get("kind", ""))] = true
    for expected in ["health.damaged", "health.healed", "health.damage_blocked", "entity.died"]:
        if not kinds.has(expected): errors.append("Health runtime event bus is missing event: %s" % expected)
    return errors


static func _attach(entity, instances: Array[Dictionary], component_key: String, patch: Dictionary) -> void:
    var definition := _definition(component_key)
    var values: Dictionary = Contracts.defaults_for(definition)
    for key in patch.keys(): values[key] = patch[key]
    var record := {
        "document_type": Contracts.COMPONENT_INSTANCE,
        "schema_version": Contracts.SCHEMA_VERSION,
        "instance_id": StableId.generate(),
        "definition_id": str(definition.get("definition_id", "")),
        "owner_entity_id": entity.entity_id,
        "values": values,
    }
    instances.append(record)
    entity.component_instance_ids.append(str(record["instance_id"]))


static func _definition(key: String) -> Dictionary:
    for definition in Components.definitions():
        if str(definition.get("key", "")) == key: return definition.duplicate(true)
    return {}
