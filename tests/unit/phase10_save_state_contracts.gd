extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const WorldRuntime = preload("res://src/runtime/play_runtime_state.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const RuntimeGameplay = preload("res://src/gameplay/runtime_gameplay_state.gd")
const SaveState = preload("res://src/gameplay/runtime_save_state_service.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new()
    project.initialize_new("Phase 10 Save State", &"small", "blank_sandbox")
    var cell_id: String = StableId.generate()
    var cell_ids: Array[String] = [cell_id]
    project.cell_ids = cell_ids

    var persistent = WorldEntity.new()
    persistent.initialize_new("Persistent", cell_id)
    var transient = WorldEntity.new()
    transient.initialize_new("Transient", cell_id)
    var instances: Array[Dictionary] = []
    _attach(persistent, instances, "health", {"max_health": 100.0, "current_health": 100.0})
    _attach(persistent, instances, "save_state", {"persist": true, "scope": "world"})
    _attach(transient, instances, "health", {"max_health": 100.0, "current_health": 100.0})
    _attach(transient, instances, "save_state", {"persist": true, "scope": "session"})
    var entity_records: Array[Dictionary] = [persistent.to_dictionary(), transient.to_dictionary()]
    project.entity_records = entity_records
    var authored: Dictionary = project.to_dictionary()

    var gameplay = RuntimeGameplay.new()
    var snapshot: Dictionary = {
        "definitions": Components.definitions(),
        "instances": instances,
        "sockets": [],
        "attachments": [],
        "dialogues": [],
        "quests": [],
    }
    var gameplay_result: Dictionary = gameplay.initialize(authored, snapshot)
    if not gameplay_result.get("ok", false):
        return ["Phase 10 save-state gameplay fixture failed: %s" % str(gameplay_result.get("errors", []))]
    var world = WorldRuntime.new()
    if not world.load_authored_project(authored).get("ok", false):
        return ["Phase 10 save-state world fixture failed."]

    var project_directory := "user://phase10-save-%s" % project.project_id
    var service = SaveState.new()
    var bind_result: Dictionary = service.bind_runtime(project_directory, project.project_id, gameplay, world)
    if not bind_result.get("ok", false):
        return ["Save-state service must bind to project-managed storage and disposable Play state."]

    gameplay.set_component_value(persistent.entity_id, "health", "current_health", 40.0)
    world.set_entity_position(persistent.entity_id, Vector3(3.0, 0.0, 1.0))
    gameplay.set_component_value(transient.entity_id, "health", "current_health", 20.0)
    world.set_entity_position(transient.entity_id, Vector3(5.0, 0.0, 0.0))
    var save_result: Dictionary = service.save_slot("checkpoint")
    if not save_result.get("ok", false) or int(save_result.get("entity_count", -1)) != 1:
        errors.append("Save-state snapshots must persist only entities explicitly opted into world scope.")
    if not service.slot_exists("checkpoint"):
        errors.append("Crash-safe save-state writes must produce a readable project-managed slot.")

    gameplay.set_component_value(persistent.entity_id, "health", "current_health", 5.0)
    world.set_entity_position(persistent.entity_id, Vector3(9.0, 0.0, 0.0))
    gameplay.set_component_value(transient.entity_id, "health", "current_health", 1.0)
    world.set_entity_position(transient.entity_id, Vector3(8.0, 0.0, 0.0))
    var load_result: Dictionary = service.load_slot("checkpoint")
    if not load_result.get("ok", false):
        errors.append("A valid gameplay save-state slot must restore opted-in runtime values.")
    else:
        var restored_health := float(gameplay.get_component_values(persistent.entity_id, "health").get("current_health", -1.0))
        if restored_health != 40.0 or _position(world.get_entity(persistent.entity_id)) != Vector3(3.0, 0.0, 1.0):
            errors.append("Save-state restore must recover opted-in runtime component values and position.")
        var transient_health := float(gameplay.get_component_values(transient.entity_id, "health").get("current_health", -1.0))
        if transient_health != 1.0 or _position(world.get_entity(transient.entity_id)) != Vector3(8.0, 0.0, 0.0):
            errors.append("Session-scope entities must remain untouched by world save-state restore.")
    if authored != project.to_dictionary():
        errors.append("Gameplay save-state operations must never mutate authored Build project data.")

    var corrupt_save: Dictionary = service.save_slot("corrupt")
    if not corrupt_save.get("ok", false):
        errors.append("Save-state corruption fixture could not create its baseline slot.")
    else:
        var corrupt_path := project_directory.path_join("gameplay/save_states/corrupt.json")
        var file := FileAccess.open(corrupt_path, FileAccess.WRITE)
        if file == null:
            errors.append("Save-state corruption fixture could not open its slot.")
        else:
            file.store_string("{not-valid-json")
            file.close()
            if service.load_slot("corrupt").get("ok", false):
                errors.append("Corrupt gameplay save-state files must fail closed without partial restore.")
    if service.save_slot("../escape").get("ok", false):
        errors.append("Save-state slot names must reject path traversal and unsupported characters.")
    return errors


static func _attach(entity, instances: Array[Dictionary], component_key: String, patch: Dictionary) -> void:
    var definition: Dictionary = _definition(component_key)
    var values: Dictionary = Contracts.defaults_for(definition)
    for key in patch.keys():
        values[key] = patch[key]
    var record: Dictionary = {
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
        if str(definition.get("key", "")) == key:
            return definition.duplicate(true)
    return {}


static func _position(record: Dictionary) -> Vector3:
    var value: Variant = record.get("transform", {}).get("position", [])
    if value is Array and value.size() == 3:
        return Vector3(float(value[0]), float(value[1]), float(value[2]))
    return Vector3.ZERO
