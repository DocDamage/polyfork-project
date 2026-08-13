extends SceneTree

const ProjectRepository = preload("res://src/world/project_repository.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var errors: Array[String] = []
    var original_root := str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects"))
    var fixture_root := "user://phase18-recovery-projects-%d" % Time.get_ticks_usec()
    ProjectSettings.set_setting("playworld/storage/projects_root", fixture_root)
    var repository = ProjectRepository.new(fixture_root)
    var created: Dictionary = repository.create_project("Phase 18 Recovery Gate", &"small", "third_person_adventure")
    var project = created.get("project")
    if not created.get("ok", false) or project == null:
        errors.append("Could not create recovery fixture project: %s" % str(created.get("errors", [])))
    else:
        var checkpoint: Dictionary = repository.create_checkpoint(project)
        if not checkpoint.get("ok", false):
            errors.append("Could not create recovery fixture checkpoint: %s" % str(checkpoint.get("errors", [])))
        else:
            var manifest := repository.get_manifest_path(str(project.project_id))
            var handle := FileAccess.open(manifest, FileAccess.WRITE)
            if handle == null:
                errors.append("Could not corrupt canonical project metadata for recovery QA.")
            else:
                handle.store_string("{broken-phase18-project")
                handle.close()
                var broken: Dictionary = repository.open_project(str(project.project_id))
                if broken.get("ok", false): errors.append("Corrupted canonical project metadata did not fail before recovery.")
                var maintenance := root.get_node_or_null("ReleaseMaintenance")
                if maintenance == null:
                    errors.append("ReleaseMaintenance is unavailable for damaged-project recovery QA.")
                else:
                    var recovered: Dictionary = maintenance.call("recover_project", str(project.project_id))
                    if not recovered.get("ok", false):
                        errors.append("Damaged project recovery failed: %s" % str(recovered.get("errors", [])))
                    else:
                        var backup := str(recovered.get("backup_path", ""))
                        if backup.is_empty() or not FileAccess.file_exists(backup): errors.append("Recovery did not preserve the damaged canonical metadata backup.")
                        var reopened: Dictionary = repository.open_project(str(project.project_id))
                        if not reopened.get("ok", false): errors.append("Recovered project cannot be reopened.")
                        elif str(reopened.get("project").title) != "Phase 18 Recovery Gate": errors.append("Recovered project content does not match the checkpoint fixture.")
                        if str(recovered.get("recovered_from", "")).is_empty(): errors.append("Recovery did not report the checkpoint source.")
    ProjectSettings.set_setting("playworld/storage/projects_root", original_root)
    if errors.is_empty():
        print("PASS: Phase 18 damaged project checkpoint recovery and backup preservation completed.")
        quit(0)
        return
    for error in errors: push_error(error)
    quit(1)
