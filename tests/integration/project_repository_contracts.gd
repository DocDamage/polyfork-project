extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const Repository = preload("res://src/world/project_repository.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var root := "user://tests/project_repository_%s" % StableId.generate()
    var repository := Repository.new(root)

    var create_result := repository.create_project("Repository Test", &"small", "blank_sandbox")
    if not create_result.get("ok", false):
        errors.append("Project repository must create a valid project: %s" % create_result.get("errors", []))
        return errors

    var project = create_result["project"]
    var manifest_path := str(create_result["manifest_path"])
    if not FileAccess.file_exists(manifest_path):
        errors.append("Creating a project must persist project.json.")
        return errors

    var first_text := FileAccess.get_file_as_string(manifest_path)
    var first_parsed = JSON.parse_string(first_text)
    if not first_parsed is Dictionary:
        errors.append("Persisted project manifest must be valid JSON.")

    var open_result := repository.open_project(project.project_id)
    if not open_result.get("ok", false):
        errors.append("Persisted project must reopen successfully: %s" % open_result.get("errors", []))
    elif open_result["project"].title != "Repository Test":
        errors.append("Reopened project must preserve its title.")

    project.title = "Repository Test Renamed"
    var save_result := repository.save_project(project)
    if not save_result.get("ok", false):
        errors.append("Valid project update must save successfully: %s" % save_result.get("errors", []))
    else:
        var reopened := repository.open_project(project.project_id)
        if not reopened.get("ok", false) or reopened["project"].title != "Repository Test Renamed":
            errors.append("Atomic replacement must persist the latest valid project data.")

    var saved_text := FileAccess.get_file_as_string(manifest_path)
    project.title = ""
    var invalid_save := repository.save_project(project)
    if invalid_save.get("ok", false):
        errors.append("Invalid project data must be rejected before replacing the live manifest.")
    if FileAccess.get_file_as_string(manifest_path) != saved_text:
        errors.append("Rejected save must leave the existing live manifest unchanged.")

    var invalid_open := repository.open_project("not-a-project-id")
    if invalid_open.get("ok", false):
        errors.append("Repository must reject malformed project IDs before filesystem access.")

    var temp_dir := repository.get_project_directory(create_result["project"].project_id)
    var dir := DirAccess.open(temp_dir)
    if dir != null:
        dir.list_dir_begin()
        var entry := dir.get_next()
        while not entry.is_empty():
            if not dir.current_is_dir() and entry.contains(".tmp-"):
                errors.append("Successful atomic save must not leave temporary manifest files behind.")
            entry = dir.get_next()
        dir.list_dir_end()

    _check_invalid_manifest_rejection(repository, errors)
    return errors


static func _check_invalid_manifest_rejection(repository, errors: Array[String]) -> void:
    var invalid_id := StableId.generate()
    var invalid_dir := repository.get_project_directory(invalid_id)
    var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(invalid_dir))
    if make_error != OK:
        errors.append("Integration test could not create invalid-manifest fixture directory.")
        return

    var file := FileAccess.open(repository.get_manifest_path(invalid_id), FileAccess.WRITE)
    if file == null:
        errors.append("Integration test could not write invalid-manifest fixture.")
        return
    file.store_string("{ not valid json")
    file.close()

    var open_result := repository.open_project(invalid_id)
    if open_result.get("ok", false):
        errors.append("Repository must reject a malformed project manifest.")
