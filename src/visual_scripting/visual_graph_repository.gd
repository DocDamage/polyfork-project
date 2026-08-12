class_name PlayWorldVisualGraphRepository
extends RefCounted

const SafeJsonWriter = preload("res://src/world/safe_json_writer.gd")
const Contracts = preload("res://src/visual_scripting/visual_graph_contracts.gd")
const NodeLibrary = preload("res://src/visual_scripting/builtin_visual_node_library.gd")
const GraphState = preload("res://src/visual_scripting/visual_graph_state.gd")

var project_directory: String
var root_directory: String
var writer

func _init(project_dir: String, safe_writer = null) -> void:
    project_directory = project_dir.trim_suffix("/")
    root_directory = project_directory.path_join("visual_scripting")
    writer = safe_writer if safe_writer != null else SafeJsonWriter.new()

func open_or_create(project) -> Dictionary:
    if project == null: return _failure("Visual graph repository requires a world project.")
    var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_directory))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS: return _failure("Unable to create visual scripting storage directory.")
    var path := get_path(); var state = GraphState.new(); var created := false
    if FileAccess.file_exists(path):
        var read: Dictionary = writer.read_dictionary(path)
        if not read.get("ok", false): return _failure("Visual graph registry is corrupt or unreadable.")
        var errors: Array[String] = Contracts.validate_registry_document(read.get("data", {}), NodeLibrary.keys())
        if not errors.is_empty(): return {"ok":false,"errors":errors}
        errors = state.load_records(read["data"].get("graphs", []))
        if not errors.is_empty(): return {"ok":false,"errors":errors}
    else:
        var write: Dictionary = _write_state(state)
        if not write.get("ok", false): return write
        created = true
    var registry_changed := _sync_project_registry(project, state.graph_ids())
    return {"ok":true,"errors":[],"state":state,"created":created,"registry_changed":registry_changed,"path":path}

func flush(state, project) -> Dictionary:
    if state == null or project == null: return _failure("Visual graph persistence requires state and project.")
    var errors: Array[String] = state.validate()
    if not errors.is_empty(): return {"ok":false,"errors":errors}
    _sync_project_registry(project, state.graph_ids())
    return _write_state(state)

func get_path() -> String: return root_directory.path_join("graphs.json")

func _write_state(state) -> Dictionary:
    var data: Dictionary = state.to_document()
    var validator := func(value: Dictionary) -> Array[String]: return Contracts.validate_registry_document(value, NodeLibrary.keys())
    return writer.write_validated_dictionary(get_path(), data, validator)

func _sync_project_registry(project, ids: Array[String]) -> bool:
    var registries: Dictionary = project.registries.duplicate(true)
    var current: Array[String] = []
    for value in registries.get("visual_graph_ids", []): current.append(str(value))
    current.sort()
    if current == ids: return false
    registries["visual_graph_ids"] = ids.duplicate()
    project.registries = registries
    return true

static func _failure(message: String) -> Dictionary: return {"ok":false,"errors":[message]}
