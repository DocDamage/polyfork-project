class_name PlayWorldRuntimeSaveStateService
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const SafeJsonWriter = preload("res://src/world/safe_json_writer.gd")

const DOCUMENT_TYPE := "gameplay_save_snapshot"
const SCHEMA_VERSION := 1
const ALLOWED_SLOT_CHARS := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"

var _project_id := ""
var _root_directory := ""
var _gameplay
var _world_runtime
var _writer


func bind_runtime(project_directory: String, project_id: String, gameplay_runtime, world_runtime, writer = null) -> Dictionary:
    clear()
    if gameplay_runtime == null or not gameplay_runtime.has_method("is_loaded") or not gameplay_runtime.is_loaded():
        return _failure("Save-state runtime requires loaded gameplay state.")
    if world_runtime == null or not world_runtime.has_method("is_loaded") or not world_runtime.is_loaded():
        return _failure("Save-state runtime requires loaded world state.")
    if project_directory.strip_edges().is_empty():
        return {"ok": true, "errors": [], "enabled": false, "root": ""}
    if not StableId.is_valid(project_id):
        return _failure("Save-state runtime requires a stable project ID.")
    _project_id = project_id
    _root_directory = project_directory.trim_suffix("/").path_join("gameplay/save_states")
    _gameplay = gameplay_runtime
    _world_runtime = world_runtime
    _writer = writer if writer != null else SafeJsonWriter.new()
    var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_root_directory))
    if error != OK and error != ERR_ALREADY_EXISTS:
        clear()
        return _failure("Unable to create gameplay save-state directory.")
    return {"ok": true, "errors": [], "enabled": true, "root": _root_directory}


func clear() -> void:
    _project_id = ""
    _root_directory = ""
    _gameplay = null
    _world_runtime = null
    _writer = null


func save_slot(slot: String) -> Dictionary:
    var slot_error := _validate_slot(slot)
    if not slot_error.is_empty():
        return _failure(slot_error)
    if _gameplay == null or _world_runtime == null or _writer == null:
        return _failure("Save-state service is not bound.")
    var entities: Dictionary = {}
    var project_copy: Dictionary = _gameplay.get_authored_project_copy()
    for entity_value in project_copy.get("entities", []):
        if not entity_value is Dictionary:
            continue
        var entity_id := str(entity_value.get("entity_id", ""))
        if not _is_world_persistent(entity_id):
            continue
        var runtime_record: Dictionary = _world_runtime.get_entity(entity_id)
        if runtime_record.is_empty():
            return _failure("Persistent save-state entity is missing from the Play world runtime.")
        var components: Dictionary = {}
        var component_keys: Array[String] = _gameplay.component_keys_for_entity(entity_id)
        for component_key in component_keys:
            components[component_key] = _gameplay.get_component_values(entity_id, component_key)
        var position_value: Variant = runtime_record.get("transform", {}).get("position", [])
        if not position_value is Array or position_value.size() != 3:
            return _failure("Persistent save-state entity has an invalid runtime position.")
        entities[entity_id] = {
            "position": position_value.duplicate(),
            "components": components,
        }
    var document: Dictionary = {
        "document_type": DOCUMENT_TYPE,
        "schema_version": SCHEMA_VERSION,
        "snapshot_id": StableId.generate(),
        "project_id": _project_id,
        "slot": slot,
        "entities": entities,
    }
    var result: Dictionary = _writer.write_validated_dictionary(_slot_path(slot), document, Callable(self, "validate_document"))
    if not result.get("ok", false):
        return result
    result["snapshot_id"] = document["snapshot_id"]
    result["entity_count"] = entities.size()
    return result


func load_slot(slot: String) -> Dictionary:
    var slot_error := _validate_slot(slot)
    if not slot_error.is_empty():
        return _failure(slot_error)
    if _gameplay == null or _world_runtime == null or _writer == null:
        return _failure("Save-state service is not bound.")
    var read: Dictionary = _writer.read_dictionary(_slot_path(slot))
    if not read.get("ok", false):
        return _failure("Gameplay save-state is missing, corrupt, or unreadable.")
    var document: Dictionary = read.get("data", {})
    var validation_errors: Array[String] = validate_document(document)
    if not validation_errors.is_empty():
        return {"ok": false, "errors": validation_errors}
    if str(document.get("project_id", "")) != _project_id:
        return _failure("Gameplay save-state belongs to a different project.")
    if str(document.get("slot", "")) != slot:
        return _failure("Gameplay save-state slot metadata does not match its requested slot.")

    var entities: Dictionary = document.get("entities", {})
    var preflight: Array[String] = _preflight_entities(entities)
    if not preflight.is_empty():
        return {"ok": false, "errors": preflight}
    var backups: Dictionary = {}
    var applied: Array[String] = []
    var entity_ids: Array[String] = []
    for entity_id_value in entities.keys():
        entity_ids.append(str(entity_id_value))
    entity_ids.sort()
    for entity_id in entity_ids:
        var saved: Dictionary = entities[entity_id]
        backups[entity_id] = _capture_entity_runtime(entity_id)
        var apply_result: Dictionary = _apply_entity_runtime(entity_id, saved)
        if not apply_result.get("ok", false):
            _rollback_entities(applied, backups)
            return apply_result
        applied.append(entity_id)
    return {"ok": true, "errors": [], "snapshot_id": document.get("snapshot_id"), "entity_count": applied.size()}


func slot_exists(slot: String) -> bool:
    return _validate_slot(slot).is_empty() and not _root_directory.is_empty() and FileAccess.file_exists(_slot_path(slot))


func validate_document(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if data.get("document_type") != DOCUMENT_TYPE:
        errors.append("Gameplay save-state document_type is invalid.")
    if int(data.get("schema_version", 0)) != SCHEMA_VERSION:
        errors.append("Gameplay save-state schema_version is unsupported.")
    if not StableId.is_valid(str(data.get("snapshot_id", ""))):
        errors.append("Gameplay save-state snapshot_id must be a stable UUID.")
    if not StableId.is_valid(str(data.get("project_id", ""))):
        errors.append("Gameplay save-state project_id must be a stable UUID.")
    var slot := str(data.get("slot", ""))
    var slot_error := _validate_slot(slot)
    if not slot_error.is_empty():
        errors.append(slot_error)
    var entities = data.get("entities", {})
    if not entities is Dictionary:
        errors.append("Gameplay save-state entities must be a dictionary.")
        return errors
    for entity_id_value in entities.keys():
        var entity_id := str(entity_id_value)
        if not StableId.is_valid(entity_id):
            errors.append("Gameplay save-state entity key must be a stable UUID.")
            continue
        var value = entities[entity_id_value]
        if not value is Dictionary:
            errors.append("Gameplay save-state entity record must be a dictionary.")
            continue
        var record: Dictionary = value
        var position = record.get("position", [])
        if not position is Array or position.size() != 3:
            errors.append("Gameplay save-state entity position must contain three values.")
        var components = record.get("components", {})
        if not components is Dictionary:
            errors.append("Gameplay save-state entity components must be a dictionary.")
    return errors


func _preflight_entities(entities: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    for entity_id_value in entities.keys():
        var entity_id := str(entity_id_value)
        if not _gameplay.has_entity(entity_id):
            errors.append("Gameplay save-state entity reference no longer resolves.")
            continue
        if not _is_world_persistent(entity_id):
            errors.append("Gameplay save-state entity is no longer opted into world persistence.")
            continue
        var record: Dictionary = entities[entity_id_value]
        var components: Dictionary = record.get("components", {})
        for component_key_value in components.keys():
            var component_key := str(component_key_value)
            if not _gameplay.has_component(entity_id, component_key):
                errors.append("Gameplay save-state component reference no longer resolves: %s/%s" % [entity_id, component_key])
    return errors


func _capture_entity_runtime(entity_id: String) -> Dictionary:
    var world_record: Dictionary = _world_runtime.get_entity(entity_id)
    var components: Dictionary = {}
    var component_keys: Array[String] = _gameplay.component_keys_for_entity(entity_id)
    for component_key in component_keys:
        components[component_key] = _gameplay.get_component_values(entity_id, component_key)
    return {"position": world_record.get("transform", {}).get("position", []).duplicate(), "components": components}


func _apply_entity_runtime(entity_id: String, saved: Dictionary) -> Dictionary:
    var position: Array = saved.get("position", [])
    var position_result: Dictionary = _world_runtime.set_entity_position(entity_id, Vector3(float(position[0]), float(position[1]), float(position[2])))
    if not position_result.get("ok", false):
        return position_result
    var components: Dictionary = saved.get("components", {})
    var keys: Array[String] = []
    for key_value in components.keys():
        keys.append(str(key_value))
    keys.sort()
    for component_key in keys:
        var values: Dictionary = components[component_key]
        var component_result: Dictionary = _gameplay.patch_component_values(entity_id, component_key, values)
        if not component_result.get("ok", false):
            return component_result
    return {"ok": true, "errors": []}


func _rollback_entities(applied: Array[String], backups: Dictionary) -> void:
    for index in range(applied.size() - 1, -1, -1):
        var entity_id := applied[index]
        var backup: Dictionary = backups.get(entity_id, {})
        if not backup.is_empty():
            _apply_entity_runtime(entity_id, backup)


func _is_world_persistent(entity_id: String) -> bool:
    var values: Dictionary = _gameplay.get_component_values(entity_id, "save_state")
    return not values.is_empty() and bool(values.get("persist", true)) and str(values.get("scope", "world")) == "world"


func _slot_path(slot: String) -> String:
    return _root_directory.path_join("%s.json" % slot)


static func _validate_slot(slot: String) -> String:
    if slot.is_empty() or slot.length() > 64:
        return "Gameplay save-state slot must contain 1-64 safe characters."
    for index in range(slot.length()):
        if not ALLOWED_SLOT_CHARS.contains(slot.substr(index, 1)):
            return "Gameplay save-state slot contains unsupported characters."
    return ""


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
