extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const RuntimeGameplay = preload("res://src/gameplay/runtime_gameplay_state.gd")

const ENTITY_COUNT := 256
const MAX_INIT_MSEC := 10000


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new()
    project.initialize_new("Phase 10 Scale", &"large", "blank_sandbox")
    var cell_id: String = StableId.generate()
    project.cell_ids.append(cell_id)

    var definitions: Array[Dictionary] = Components.definitions()
    var health_definition := _definition(definitions, "health")
    var inventory_definition := _definition(definitions, "inventory_container")
    var save_definition := _definition(definitions, "save_state")
    if health_definition.is_empty() or inventory_definition.is_empty() or save_definition.is_empty():
        return ["Phase 10 scale suite could not resolve required built-in gameplay definitions."]

    var instances: Array[Dictionary] = []
    var expected_ids: Array[String] = []
    for index in range(ENTITY_COUNT):
        var entity = WorldEntity.new()
        entity.initialize_new("Scale Actor %03d" % index, cell_id)
        var entity_id: String = entity.entity_id
        expected_ids.append(entity_id)
        for component in [
            _instance(entity_id, health_definition, {"max_health": 100.0, "current_health": 100.0}),
            _instance(entity_id, inventory_definition, {"capacity": 16, "locked": false}),
            _instance(entity_id, save_definition, {"persist": true, "scope": "world"}),
        ]:
            instances.append(component)
            entity.component_instance_ids.append(str(component["instance_id"]))
        project.entity_records.append(entity.to_dictionary())

    var authored_snapshot: Dictionary = {
        "definitions": definitions,
        "instances": instances,
        "sockets": [],
        "attachments": [],
        "dialogues": [],
        "quests": [],
    }
    var authored_before := authored_snapshot.duplicate(true)
    var runtime = RuntimeGameplay.new()
    var started := Time.get_ticks_msec()
    var load_result: Dictionary = runtime.initialize(project.to_dictionary(), authored_snapshot)
    var elapsed := Time.get_ticks_msec() - started
    if not load_result.get("ok", false):
        return ["Phase 10 scale runtime must initialize a representative large gameplay snapshot: %s" % str(load_result.get("errors", []))]
    if elapsed > MAX_INIT_MSEC:
        errors.append("Phase 10 gameplay runtime initialization exceeded the %d ms representative-scale budget: %d ms." % [MAX_INIT_MSEC, elapsed])

    for entity_id in expected_ids:
        var keys: Array[String] = runtime.component_keys_for_entity(entity_id)
        if keys != ["health", "inventory_container", "save_state"]:
            errors.append("Phase 10 scale lookup lost deterministic component ordering for entity %s." % entity_id)
            break
        var mutate: Dictionary = runtime.set_component_value(entity_id, "health", "current_health", 75.0)
        if not mutate.get("ok", false):
            errors.append("Phase 10 scale mutation failed for entity %s." % entity_id)
            break

    if authored_snapshot != authored_before:
        errors.append("Representative-scale Play mutations must not mutate authored Build gameplay data.")
    if runtime.events_after(0).size() != 0:
        errors.append("Representative-scale initialization/mutation must not invent gameplay events.")

    var missing_result: Dictionary = runtime.set_component_value(StableId.generate(), "health", "current_health", 1.0)
    if missing_result.get("ok", false):
        errors.append("Representative-scale runtime must still fail safely for missing stable entity references.")

    runtime.clear()
    if runtime.is_loaded():
        errors.append("Representative-scale gameplay state must remain disposable after Play exit.")
    return errors


static func _definition(definitions: Array[Dictionary], key: String) -> Dictionary:
    for definition in definitions:
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
