class_name PlayWorldProjectRepository
extends RefCounted

const WorldProject = preload("res://src/world/world_project.gd")
const StableId = preload("res://src/world/stable_id.gd")
const SafeJsonWriter = preload("res://src/world/safe_json_writer.gd")
const CheckpointStore = preload("res://src/world/checkpoint_store.gd")
const TemplateRegistry = preload("res://src/templates/template_registry.gd")
const TemplateApplicationService = preload("res://src/templates/template_application_service.gd")

const MANIFEST_FILE := "project.json"

var root_path: String
var _writer
var _checkpoint_store


func _init(
    storage_root: String = "user://projects",
    safe_writer = null,
    checkpoint_retention: int = CheckpointStore.DEFAULT_RETENTION_LIMIT
) -> void:
    root_path = storage_root.trim_suffix("/")
    _writer = safe_writer if safe_writer != null else SafeJsonWriter.new()
    _checkpoint_store = CheckpointStore.new(root_path, checkpoint_retention, _writer)


func create_project(title: String, profile_id: StringName, template_id: String) -> Dictionary:
    var registry = TemplateRegistry.new()
    var registry_result: Dictionary = registry.load_builtin()
    if not registry_result.get("ok", false):
        return _failure("Unable to load template registry: %s" % str(registry_result.get("errors", [])))
    var manifest_result: Dictionary = registry.require_manifest(template_id)
    if not manifest_result.get("ok", false):
        return _failure(str(manifest_result.get("errors", ["Unknown template."])[0]))

    var project = WorldProject.new()
    project.initialize_new(title, profile_id, template_id)
    var application = TemplateApplicationService.new()
    var apply_result: Dictionary = application.apply_to_project(project, manifest_result["manifest"])
    if not apply_result.get("ok", false):
        return {"ok": false, "errors": apply_result.get("errors", ["Template application failed."]), "project": null, "manifest_path": ""}

    var errors: Array[String] = project.validate()
    if not errors.is_empty():
        return {"ok": false, "errors": errors, "project": null, "manifest_path": ""}

    var project_dir: String = get_project_directory(project.project_id)
    var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(project_dir))
    if make_error != OK:
        return _failure("Unable to create project directory: %s" % make_error)

    var save_result: Dictionary = save_project(project)
    if not save_result.get("ok", false):
        return save_result
    save_result["project"] = project
    save_result["template_application"] = apply_result
    return save_result


func save_project(project) -> Dictionary:
    if project == null:
        return _failure("Project is required.")

    var errors: Array[String] = project.validate()
    if not errors.is_empty():
        return {"ok": false, "errors": errors, "project": project, "manifest_path": ""}

    var project_dir: String = get_project_directory(project.project_id)
    var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(project_dir))
    if make_error != OK:
        return _failure("Unable to create project directory: %s" % make_error)

    var original_updated_at_unix: int = project.updated_at_unix
    var original_updated_at_msec: int = project.updated_at_msec
    project.touch_updated()
    var final_path: String = get_manifest_path(project.project_id)
    var write_result: Dictionary = _writer.write_validated_dictionary(
        final_path,
        project.to_dictionary(),
        Callable(WorldProject, "validate_dictionary")
    )
    if not write_result.get("ok", false):
        project.updated_at_unix = original_updated_at_unix
        project.updated_at_msec = original_updated_at_msec
        return {
            "ok": false,
            "errors": write_result.get("errors", ["Project save failed."]),
            "project": project,
            "manifest_path": final_path
        }

    return {"ok": true, "errors": [], "project": project, "manifest_path": final_path}


func open_project(project_id: String) -> Dictionary:
    var load_result := _load_project_manifest(project_id)
    if not load_result.get("ok", false):
        return load_result

    var project = load_result["project"]
    var recovery: Dictionary = _checkpoint_store.inspect_recovery(project_id, project.updated_at_msec)
    if not recovery.get("ok", false):
        return {
            "ok": false,
            "errors": recovery.get("errors", ["Recovery inspection failed."]),
            "project": null,
            "manifest_path": load_result["manifest_path"]
        }

    load_result["recovery"] = recovery
    return load_result


func create_checkpoint(project) -> Dictionary:
    return _checkpoint_store.create_checkpoint(project)


func list_checkpoints(project_id: String) -> Array:
    return _checkpoint_store.list_checkpoints(project_id)


func inspect_recovery(project_id: String) -> Dictionary:
    var canonical := _load_project_manifest(project_id)
    if not canonical.get("ok", false):
        return canonical
    return _checkpoint_store.inspect_recovery(project_id, canonical["project"].updated_at_msec)


func recover_latest_checkpoint(project_id: String) -> Dictionary:
    var canonical := _load_project_manifest(project_id)
    if not canonical.get("ok", false):
        return canonical

    var recovery: Dictionary = _checkpoint_store.inspect_recovery(
        project_id,
        canonical["project"].updated_at_msec
    )
    if not recovery.get("ok", false):
        return recovery
    if not recovery.get("recoverable", false):
        return {
            "ok": false,
            "errors": ["No recoverable checkpoint is available: %s" % recovery.get("status", "missing")],
            "project": canonical["project"],
            "manifest_path": canonical["manifest_path"],
            "recovery": recovery
        }

    var checkpoint_result: Dictionary = _checkpoint_store.load_checkpoint(
        str(recovery["checkpoint_path"]),
        project_id
    )
    if not checkpoint_result.get("ok", false):
        return {
            "ok": false,
            "errors": checkpoint_result.get("errors", ["Unable to load recovery checkpoint."]),
            "project": canonical["project"],
            "manifest_path": canonical["manifest_path"],
            "recovery": recovery
        }

    var recovered_project = WorldProject.new()
    var load_errors: Array[String] = recovered_project.load_dictionary(
        checkpoint_result["checkpoint"].project_state
    )
    if not load_errors.is_empty() or recovered_project.project_id != project_id:
        if load_errors.is_empty():
            load_errors.append("Recovery checkpoint project ID does not match canonical project.")
        return {
            "ok": false,
            "errors": load_errors,
            "project": canonical["project"],
            "manifest_path": canonical["manifest_path"],
            "recovery": recovery
        }

    var save_result: Dictionary = save_project(recovered_project)
    if not save_result.get("ok", false):
        return {
            "ok": false,
            "errors": save_result.get("errors", ["Recovery promotion failed."]),
            "project": canonical["project"],
            "manifest_path": canonical["manifest_path"],
            "recovery": recovery
        }

    save_result["recovery"] = recovery
    return save_result


func list_projects() -> Array:
    var projects: Array = []
    var directory := DirAccess.open(root_path)
    if directory == null:
        return projects

    directory.list_dir_begin()
    var entry := directory.get_next()
    while not entry.is_empty():
        if directory.current_is_dir() and StableId.is_valid(entry):
            var open_result := open_project(entry)
            if open_result.get("ok", false):
                projects.append(open_result["project"])
        entry = directory.get_next()
    directory.list_dir_end()

    projects.sort_custom(func(a, b): return a.updated_at_msec > b.updated_at_msec)
    return projects


func get_recent_project() -> Dictionary:
    var projects := list_projects()
    if projects.is_empty():
        return {
            "ok": true,
            "errors": [],
            "project": null,
            "manifest_path": "",
            "recovery": {"ok": true, "status": "missing", "recoverable": false}
        }
    return open_project(projects[0].project_id)


func get_project_directory(project_id: String) -> String:
    return "%s/%s" % [root_path, project_id]


func get_manifest_path(project_id: String) -> String:
    return "%s/%s" % [get_project_directory(project_id), MANIFEST_FILE]


func get_checkpoint_directory(project_id: String) -> String:
    return _checkpoint_store.get_checkpoint_directory(project_id)


func _load_project_manifest(project_id: String) -> Dictionary:
    if not StableId.is_valid(project_id):
        return _failure("Project ID is invalid.")

    var manifest_path: String = get_manifest_path(project_id)
    if not FileAccess.file_exists(manifest_path):
        return _failure("Project manifest does not exist.")

    var read_result: Dictionary = _writer.read_dictionary(manifest_path)
    if not read_result.get("ok", false):
        return {
            "ok": false,
            "errors": read_result.get("errors", ["Project manifest is not valid JSON."]),
            "project": null,
            "manifest_path": manifest_path
        }

    var project = WorldProject.new()
    var load_errors: Array[String] = project.load_dictionary(read_result["data"])
    if not load_errors.is_empty():
        return {
            "ok": false,
            "errors": load_errors,
            "project": null,
            "manifest_path": manifest_path
        }
    if project.project_id != project_id:
        return _failure("Project manifest ID does not match its directory.")

    return {"ok": true, "errors": [], "project": project, "manifest_path": manifest_path}


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message], "project": null, "manifest_path": ""}
