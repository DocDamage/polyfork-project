extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const RuntimeGameplay = preload("res://src/gameplay/runtime_gameplay_state.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new()
    project.initialize_new("Phase 10 Runtime", &"small", "blank_sandbox")
    var cell_id: String = StableId.generate()
    var cell_ids: Array[String] = [cell_id]
    project.cell_ids = cell_ids

    var entity = WorldEntity.new()
    entity.initialize_new("Runtime Actor", cell_id)
    var entity_id: String = entity.entity_id
    var health_definition: Dictionary = _definition("health")
    var health_instance: Dictionary = _instance(entity_id, health_definition, {"max_health": 100.0, "current_health": 100.0})
    var component_ids: Array[String] = [str(health_instance["instance_id"])]
    entity.component_instance_ids = component_ids
    var entity_records: Array[Dictionary] = [entity.to_dictionary()]
    project.entity_records = entity_records

    var authored_snapshot: Dictionary = {
        "definitions": Components.definitions(),
        "instances": [health_instance.duplicate(true)],
        "sockets": [],
        "attachments": [],
        "dialogues": [],
        "quests": [],
    }
    var authored_before: Dictionary = authored_snapshot.duplicate(true)
    var runtime = RuntimeGameplay.new()
    var load_result: Dictionary = runtime.initialize(project.to_dictionary(), authored_snapshot)
    if not load_result.get("ok", false):
        return ["Phase 10 runtime gameplay state must initialize from valid authored state: %s" % str(load_result.get("errors", []))]
    if not runtime.has_component(entity_id, "health"):
        errors.append("Runtime gameplay state must resolve components by reusable component key.")
    var component_keys: Array[String] = runtime.component_keys_for_entity(entity_id)
    if component_keys != ["health"]:
        errors.append("Runtime gameplay component lookup must be deterministic.")

    var damage_result: Dictionary = runtime.set_component_value(entity_id, "health", "current_health", 65.0)
    if not damage_result.get("ok", false):
        errors.append("Runtime gameplay component values must be mutable inside Play state.")
    elif float(runtime.get_component_values(entity_id, "health").get("current_health", -1.0)) != 65.0:
        errors.append("Runtime gameplay component mutation did not persist in disposable runtime state.")
    if authored_snapshot != authored_before:
        errors.append("Runtime gameplay mutation must never mutate the authored gameplay snapshot.")

    var invalid_result: Dictionary = runtime.set_component_value(entity_id, "health", "current_health", 1000001.0)
    if invalid_result.get("ok", false):
        errors.append("Runtime gameplay mutations must preserve authored component property validation.")

    var event_result: Dictionary = runtime.emit_event("health.changed", entity_id, entity_id, {"amount": -35.0})
    if not event_result.get("ok", false):
        errors.append("Runtime gameplay events must accept valid stable entity references.")
    else:
        var event: Dictionary = event_result.get("event", {})
        if not StableId.is_valid(str(event.get("event_id", ""))) or int(event.get("sequence", 0)) != 1:
            errors.append("Runtime gameplay events require stable IDs and deterministic sequence numbers.")
    if runtime.events_after(0).size() != 1:
        errors.append("Runtime gameplay event history must be queryable for downstream systems.")

    var missing_owner: Dictionary = health_instance.duplicate(true)
    missing_owner["instance_id"] = StableId.generate()
    missing_owner["owner_entity_id"] = StableId.generate()
    var bad_snapshot: Dictionary = {
        "definitions": Components.definitions(),
        "instances": [missing_owner],
        "sockets": [],
        "attachments": [],
        "dialogues": [],
        "quests": [],
    }
    var bad_runtime = RuntimeGameplay.new()
    var bad_result: Dictionary = bad_runtime.initialize(project.to_dictionary(), bad_snapshot)
    if bad_result.get("ok", false):
        errors.append("Runtime gameplay state must fail closed when stable entity references do not resolve.")

    runtime.clear()
    if runtime.is_loaded() or runtime.has_component(entity_id, "health"):
        errors.append("Runtime gameplay state must be fully disposable on Play exit/rollback.")
    return errors


static func _definition(key: String) -> Dictionary:
    for definition in Components.definitions():
        if str(definition.get("key", "")) == key:
            return definition.duplicate(true)
    return {}


static func _instance(entity_id: String, definition: Dictionary, values: Dictionary) -> Dictionary:
    return {
        "document_type": Contracts.COMPONENT_INSTANCE,
        "schema_version": Contracts.SCHEMA_VERSION,
        "instance_id": StableId.generate(),
        "definition_id": str(definition.get("definition_id", "")),
        "owner_entity_id": entity_id,
        "values": values.duplicate(true),
    }
