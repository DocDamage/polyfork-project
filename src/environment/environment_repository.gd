class_name PlayWorldEnvironmentRepository
extends RefCounted

const SafeJsonWriter = preload("res://src/world/safe_json_writer.gd")
const Contracts = preload("res://src/environment/environment_contracts.gd")
const EnvironmentState = preload("res://src/environment/environment_state.gd")

var project_directory: String
var root_directory: String
var writer

func _init(project_dir: String, safe_writer = null) -> void:
    project_directory = project_dir.trim_suffix("/")
    root_directory = project_directory.path_join("environment")
    writer = safe_writer if safe_writer != null else SafeJsonWriter.new()

func open_or_create(project) -> Dictionary:
    if project == null:
        return _failure("Environment repository requires a world project.")
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_directory))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS:
        return _failure("Unable to create environment storage directory.")
    var state = EnvironmentState.new()
    var created := false
    if FileAccess.file_exists(get_path()):
        var read: Dictionary = writer.read_dictionary(get_path())
        if not read.get("ok", false):
            return _failure("Environment registry is corrupt or unreadable.")
        var data: Dictionary = read.get("data", {})
        if str(data.get("project_id", "")) != str(project.project_id):
            return _failure("Environment registry belongs to a different project.")
        var load_errors: Array[String] = state.load_document(data)
        if not load_errors.is_empty():
            return {"ok": false, "errors": load_errors}
    else:
        var data: Dictionary = Contracts.empty_document(str(project.project_id))
        var load_errors: Array[String] = state.load_document(data)
        if not load_errors.is_empty():
            return {"ok": false, "errors": load_errors}
        var write_result: Dictionary = _write_state(state)
        if not write_result.get("ok", false):
            return write_result
        created = true
    var registry_changed: bool = _sync_project_registries(project, state)
    return {"ok": true, "errors": [], "state": state, "created": created, "registry_changed": registry_changed, "path": get_path()}

func flush(state, project) -> Dictionary:
    if state == null or project == null:
        return _failure("Environment persistence requires state and project.")
    var errors: Array[String] = state.validate()
    if not errors.is_empty():
        return {"ok": false, "errors": errors}
    if state.project_id != str(project.project_id):
        return _failure("Environment state project identity does not match the active project.")
    _sync_project_registries(project, state)
    return _write_state(state)

func get_path() -> String:
    return root_directory.path_join("environment.json")

func _write_state(state) -> Dictionary:
    var validator := func(value: Dictionary) -> Array[String]:
        return Contracts.validate_document(value)
    return writer.write_validated_dictionary(get_path(), state.to_document(), validator)

func _sync_project_registries(project, state) -> bool:
    var registries: Dictionary = project.registries.duplicate(true)
    var changed := false
    changed = _sync_ids(registries, "environment_weather_profile_ids", state.weather_profile_ids()) or changed
    changed = _sync_ids(registries, "environment_biome_override_ids", state.biome_override_ids()) or changed
    changed = _sync_ids(registries, "environment_water_hook_ids", state.water_hook_ids()) or changed
    if changed:
        project.registries = registries
    return changed

static func _sync_ids(registries: Dictionary, key: String, expected: Array[String]) -> bool:
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
