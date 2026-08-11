class_name PlayWorldProjectRepository
extends RefCounted

const WorldProject = preload("res://src/world/world_project.gd")
const StableId = preload("res://src/world/stable_id.gd")

const MANIFEST_FILE := "project.json"

var root_path: String


func _init(storage_root: String = "user://projects") -> void:
    root_path = storage_root.trim_suffix("/")


func create_project(title: String, profile_id: StringName, template_id: String) -> Dictionary:
    var project := WorldProject.create_new(title, profile_id, template_id)
    var errors := project.validate()
    if not errors.is_empty():
        return {"ok": false, "errors": errors, "project": null, "manifest_path": ""}

    var project_dir := get_project_directory(project.project_id)
    var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(project_dir))
    if make_error != OK:
        return _failure("Unable to create project directory: %s" % make_error)

    var save_result := save_project(project)
    if not save_result.get("ok", false):
        return save_result
    save_result["project"] = project
    return save_result


func save_project(project: PlayWorldProject) -> Dictionary:
    if project == null:
        return _failure("Project is required.")

    var errors := project.validate()
    if not errors.is_empty():
        return {"ok": false, "errors": errors, "project": project, "manifest_path": ""}

    var project_dir := get_project_directory(project.project_id)
    var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(project_dir))
    if make_error != OK:
        return _failure("Unable to create project directory: %s" % make_error)

    project.touch_updated()
    var final_path := get_manifest_path(project.project_id)
    var temp_path := "%s.tmp-%s" % [final_path, StableId.generate()]
    var json_text := JSON.stringify(project.to_dictionary(), "  ") + "\n"

    var file := FileAccess.open(temp_path, FileAccess.WRITE)
    if file == null:
        return _failure("Unable to open temporary project manifest for writing: %s" % FileAccess.get_open_error())

    if not file.store_string(json_text):
        file.close()
        DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
        return _failure("Unable to write temporary project manifest.")
    file.flush()
    file.close()

    var parsed = JSON.parse_string(FileAccess.get_file_as_string(temp_path))
    if not parsed is Dictionary:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
        return _failure("Temporary project manifest failed JSON verification.")

    var verify_errors := WorldProject.validate_dictionary(parsed)
    if not verify_errors.is_empty():
        DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
        return {"ok": false, "errors": verify_errors, "project": project, "manifest_path": final_path}

    var rename_error := DirAccess.rename_absolute(
        ProjectSettings.globalize_path(temp_path),
        ProjectSettings.globalize_path(final_path)
    )
    if rename_error != OK:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
        return _failure("Unable to replace project manifest: %s" % rename_error)

    return {"ok": true, "errors": [], "project": project, "manifest_path": final_path}


func open_project(project_id: String) -> Dictionary:
    if not StableId.is_valid(project_id):
        return _failure("Project ID is invalid.")

    var manifest_path := get_manifest_path(project_id)
    if not FileAccess.file_exists(manifest_path):
        return _failure("Project manifest does not exist.")

    var text := FileAccess.get_file_as_string(manifest_path)
    var parsed = JSON.parse_string(text)
    if not parsed is Dictionary:
        return _failure("Project manifest is not valid JSON.")

    var decoded := WorldProject.from_dictionary(parsed)
    if not decoded.get("ok", false):
        return {
            "ok": false,
            "errors": decoded.get("errors", []),
            "project": null,
            "manifest_path": manifest_path
        }

    var project: PlayWorldProject = decoded["project"]
    if project.project_id != project_id:
        return _failure("Project manifest ID does not match its directory.")

    return {"ok": true, "errors": [], "project": project, "manifest_path": manifest_path}


func get_project_directory(project_id: String) -> String:
    return "%s/%s" % [root_path, project_id]


func get_manifest_path(project_id: String) -> String:
    return "%s/%s" % [get_project_directory(project_id), MANIFEST_FILE]


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message], "project": null, "manifest_path": ""}
