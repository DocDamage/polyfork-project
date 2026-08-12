class_name PlayWorldProceduralRepository
extends RefCounted

const SafeJsonWriter = preload("res://src/world/safe_json_writer.gd")
const Contracts = preload("res://src/procedural/procedural_contracts.gd")
const ProceduralState = preload("res://src/procedural/procedural_state.gd")

var project_directory: String
var root_directory: String
var writer


func _init(project_dir: String, safe_writer = null) -> void:
    project_directory = project_dir.trim_suffix("/")
    root_directory = project_directory.path_join("procedural")
    writer = safe_writer if safe_writer != null else SafeJsonWriter.new()


func open_or_create(project) -> Dictionary:
    if project == null:
        return _failure("Procedural repository requires a world project.")
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_directory))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS:
        return _failure("Unable to create procedural storage directory.")
    var state = ProceduralState.new()
    var path: String = get_path()
    var created: bool = false
    if FileAccess.file_exists(path):
        var read: Dictionary = writer.read_dictionary(path)
        if not read.get("ok", false):
            return _failure("Procedural registry is corrupt or unreadable.")
        var data: Dictionary = read.get("data", {})
        if str(data.get("project_id", "")) != str(project.project_id):
            return _failure("Procedural registry belongs to a different project.")
        var load_errors: Array[String] = state.load_document(data)
        if not load_errors.is_empty():
            return {"ok": false, "errors": load_errors}
    else:
        var empty: Dictionary = Contracts.empty_document(str(project.project_id))
        var load_errors: Array[String] = state.load_document(empty)
        if not load_errors.is_empty():
            return {"ok": false, "errors": load_errors}
        var write_result: Dictionary = _write_state(state)
        if not write_result.get("ok", false):
            return write_result
        created = true
    var registry_changed: bool = _sync_project_registries(project, state)
    return {
        "ok": true,
        "errors": [],
        "state": state,
        "created": created,
        "registry_changed": registry_changed,
        "path": path,
    }


func flush(state, project) -> Dictionary:
    if state == null or project == null:
        return _failure("Procedural persistence requires state and project.")
    var errors: Array[String] = state.validate()
    if not errors.is_empty():
        return {"ok": false, "errors": errors}
    if state.project_id != str(project.project_id):
        return _failure("Procedural state project identity does not match the active project.")
    _sync_project_registries(project, state)
    return _write_state(state)


func get_path() -> String:
    return root_directory.path_join("procedural.json")


func _write_state(state) -> Dictionary:
    var data: Dictionary = state.to_document()
    var validator := func(value: Dictionary) -> Array[String]:
        return Contracts.validate_document(value)
    return writer.write_validated_dictionary(get_path(), data, validator)


func _sync_project_registries(project, state) -> bool:
    var registries: Dictionary = project.registries.duplicate(true)
    var changed: bool = false
    changed = _sync_id_list(registries, "procedural_foliage_set_ids", state.foliage_set_ids()) or changed
    changed = _sync_id_list(registries, "procedural_scatter_layer_ids", state.scatter_layer_ids()) or changed
    changed = _sync_id_list(registries, "procedural_spline_ids", state.spline_ids()) or changed
    if changed:
        project.registries = registries
    return changed


static func _sync_id_list(registries: Dictionary, key: String, expected: Array[String]) -> bool:
    var current: Array[String] = []
    for value in registries.get(key, []):
        current.append(str(value))
    current.sort()
    if current == expected:
        return false
    registries[key] = expected.duplicate()
    return true


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
