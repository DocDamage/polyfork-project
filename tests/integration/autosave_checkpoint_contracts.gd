extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const SafeJsonWriter = preload("res://src/world/safe_json_writer.gd")
const CheckpointRecord = preload("res://src/world/checkpoint_record.gd")
const Repository = preload("res://src/world/project_repository.gd")
const AutosaveService = preload("res://src/world/autosave_service.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    _check_autosave_and_recovery(errors)
    _check_failed_writes_preserve_known_good_state(errors)
    _check_invalid_recovery_states(errors)
    _check_retention_policy(errors)
    return errors


static func _check_autosave_and_recovery(errors: Array[String]) -> void:
    var root := "user://tests/autosave_recovery_%s" % StableId.generate()
    var repository = Repository.new(root)
    var create_result: Dictionary = repository.create_project("Autosave Test", &"medium", "blank_sandbox")
    if not create_result.get("ok", false):
        errors.append("Autosave test project must be created: %s" % create_result.get("errors", []))
        return

    var project = create_result["project"]
    var original_id: String = project.project_id
    var service = AutosaveService.new(repository, 1.0)
    var attach_result: Dictionary = service.attach_project(project)
    if not attach_result.get("ok", false):
        errors.append("Autosave service must attach a valid project.")
        return

    var clean_tick: Dictionary = service.advance(5.0)
    if clean_tick.get("attempted", false) or not repository.list_checkpoints(original_id).is_empty():
        errors.append("Clean projects must not create timer-driven checkpoints.")

    project.title = "Autosaved Title"
    service.mark_dirty()
    var pending_tick: Dictionary = service.advance(0.5)
    if pending_tick.get("attempted", false):
        errors.append("Autosave must wait for its configured interval before checkpointing.")
    var checkpoint_result: Dictionary = service.advance(0.5)
    if not checkpoint_result.get("ok", false) or not checkpoint_result.get("attempted", false):
        errors.append("Dirty project must create a checkpoint at the autosave interval: %s" % checkpoint_result.get("errors", []))
        return
    if service.is_dirty():
        errors.append("Successful checkpoint creation must clear autosave dirty state.")

    var record = checkpoint_result["checkpoint"]
    if not StableId.is_valid(record.checkpoint_id):
        errors.append("Checkpoint must receive a stable UUID identity.")
    if record.project_id != original_id or str(record.project_state.get("project_id", "")) != original_id:
        errors.append("Checkpoint ownership and snapshot project identity must remain stable.")
    if str(record.project_state.get("title", "")) != "Autosaved Title":
        errors.append("Checkpoint must contain the authored dirty state.")
    var checkpoint_text := JSON.stringify(record.to_dictionary())
    for forbidden in ["scene_tree_path", "node_path", "parent_path"]:
        if checkpoint_text.contains(forbidden):
            errors.append("Checkpoint persistence must not introduce scene-tree path relationships.")

    var post_save_clean_tick: Dictionary = service.advance(10.0)
    if post_save_clean_tick.get("attempted", false) or repository.list_checkpoints(original_id).size() != 1:
        errors.append("Unchanged state after autosave must not create redundant checkpoints.")

    var reloaded_repository = Repository.new(root)
    var persisted_checkpoints := reloaded_repository.list_checkpoints(original_id)
    if persisted_checkpoints.size() != 1:
        errors.append("Checkpoint data must survive repository reload.")
        return
    var open_result: Dictionary = reloaded_repository.open_project(original_id)
    if not open_result.get("ok", false):
        errors.append("Canonical project must remain loadable while a checkpoint exists.")
        return
    if open_result["project"].title != "Autosave Test":
        errors.append("Autosave checkpoint must not silently overwrite canonical project state.")
    var recovery: Dictionary = open_result.get("recovery", {})
    if not recovery.get("recoverable", false) or recovery.get("status") != "available":
        errors.append("Opening a project must detect a valid newer recoverable checkpoint.")

    var recover_result: Dictionary = reloaded_repository.recover_latest_checkpoint(original_id)
    if not recover_result.get("ok", false):
        errors.append("Valid recovery must promote the checkpoint safely: %s" % recover_result.get("errors", []))
        return
    if recover_result["project"].title != "Autosaved Title" or recover_result["project"].project_id != original_id:
        errors.append("Recovery must restore checkpoint state without changing project identity.")

    var reopened: Dictionary = reloaded_repository.open_project(original_id)
    if not reopened.get("ok", false) or reopened["project"].title != "Autosaved Title":
        errors.append("Recovered state must persist through a fresh reopen.")
    elif reopened.get("recovery", {}).get("recoverable", false):
        errors.append("A successfully recovered checkpoint must not remain newer than canonical state.")


static func _check_failed_writes_preserve_known_good_state(errors: Array[String]) -> void:
    var root := "user://tests/autosave_failures_%s" % StableId.generate()
    var writer = SafeJsonWriter.new()
    var repository = Repository.new(root, writer)
    var create_result: Dictionary = repository.create_project("Known Good", &"small", "blank_sandbox")
    if not create_result.get("ok", false):
        errors.append("Failure-path project must be created.")
        return

    var project = create_result["project"]
    var manifest_path: String = create_result["manifest_path"]
    var known_good_text := FileAccess.get_file_as_string(manifest_path)
    var known_good_msec: int = project.updated_at_msec

    project.title = "Should Not Replace"
    writer.fault_injector = func(stage: StringName) -> bool: return stage == &"before_promote"
    var failed_save: Dictionary = repository.save_project(project)
    if failed_save.get("ok", false):
        errors.append("Injected pre-promotion save failure must be reported.")
    if FileAccess.get_file_as_string(manifest_path) != known_good_text:
        errors.append("Failed project write must preserve the previous canonical manifest.")
    if project.updated_at_msec != known_good_msec:
        errors.append("Failed project write must restore in-memory persistence timestamp metadata.")

    writer.fault_injector = Callable()
    project.title = "Checkpoint One"
    var good_checkpoint: Dictionary = repository.create_checkpoint(project)
    if not good_checkpoint.get("ok", false):
        errors.append("Baseline checkpoint must be created before failure simulation.")
        return
    var known_checkpoint_id: String = good_checkpoint["checkpoint"].checkpoint_id

    project.title = "Checkpoint Two"
    writer.fault_injector = func(stage: StringName) -> bool: return stage == &"before_promote"
    var failed_checkpoint: Dictionary = repository.create_checkpoint(project)
    if failed_checkpoint.get("ok", false):
        errors.append("Injected checkpoint promotion failure must be reported.")
    var checkpoints := repository.list_checkpoints(project.project_id)
    if checkpoints.size() != 1 or checkpoints[0]["record"].checkpoint_id != known_checkpoint_id:
        errors.append("Failed checkpoint write must preserve the previous known-good checkpoint set.")

    writer.fault_injector = Callable()
    var canonical_before_recovery := FileAccess.get_file_as_string(manifest_path)
    writer.fault_injector = func(stage: StringName) -> bool: return stage == &"before_promote"
    var failed_recovery: Dictionary = repository.recover_latest_checkpoint(project.project_id)
    if failed_recovery.get("ok", false):
        errors.append("Injected recovery promotion failure must be reported.")
    if FileAccess.get_file_as_string(manifest_path) != canonical_before_recovery:
        errors.append("Failed recovery must not destroy or replace canonical project state.")
    writer.fault_injector = Callable()


static func _check_invalid_recovery_states(errors: Array[String]) -> void:
    _check_corrupted_checkpoint(errors)
    _check_unsupported_checkpoint(errors)
    _check_incomplete_temporary_checkpoint(errors)


static func _check_corrupted_checkpoint(errors: Array[String]) -> void:
    var root := "user://tests/corrupt_checkpoint_%s" % StableId.generate()
    var repository = Repository.new(root)
    var created: Dictionary = repository.create_project("Corrupt Test", &"small", "blank_sandbox")
    if not created.get("ok", false):
        errors.append("Corrupt-checkpoint fixture project must be created.")
        return
    var project = created["project"]
    if not _ensure_checkpoint_directory(repository, project.project_id, errors):
        return
    _write_text("%s/corrupt.json" % repository.get_checkpoint_directory(project.project_id), "{ broken", errors)
    var opened: Dictionary = repository.open_project(project.project_id)
    if not opened.get("ok", false) or opened.get("recovery", {}).get("status") != "invalid_checkpoint":
        errors.append("Corrupted checkpoint data must be rejected without invalidating canonical state.")


static func _check_unsupported_checkpoint(errors: Array[String]) -> void:
    var root := "user://tests/unsupported_checkpoint_%s" % StableId.generate()
    var repository = Repository.new(root)
    var created: Dictionary = repository.create_project("Schema Test", &"small", "blank_sandbox")
    if not created.get("ok", false):
        errors.append("Unsupported-schema fixture project must be created.")
        return
    var project = created["project"]
    if not _ensure_checkpoint_directory(repository, project.project_id, errors):
        return
    var data := {
        "document_type": CheckpointRecord.DOCUMENT_TYPE,
        "schema_version": CheckpointRecord.SCHEMA_VERSION + 1,
        "id": StableId.generate(),
        "project_id": project.project_id,
        "created_at_msec": project.updated_at_msec + 10,
        "project_state": project.to_dictionary()
    }
    _write_text(
        "%s/future.json" % repository.get_checkpoint_directory(project.project_id),
        JSON.stringify(data),
        errors
    )
    var opened: Dictionary = repository.open_project(project.project_id)
    if not opened.get("ok", false) or opened.get("recovery", {}).get("status") != "unsupported_schema":
        errors.append("Future unsupported checkpoint schemas must fail safely and explicitly.")


static func _check_incomplete_temporary_checkpoint(errors: Array[String]) -> void:
    var root := "user://tests/temp_checkpoint_%s" % StableId.generate()
    var repository = Repository.new(root)
    var created: Dictionary = repository.create_project("Temp Test", &"small", "blank_sandbox")
    if not created.get("ok", false):
        errors.append("Temporary-write fixture project must be created.")
        return
    var project = created["project"]
    if not _ensure_checkpoint_directory(repository, project.project_id, errors):
        return
    var temp_path := "%s/checkpoint.json.tmp-%s" % [
        repository.get_checkpoint_directory(project.project_id),
        StableId.generate()
    ]
    _write_text(temp_path, "{ incomplete", errors)
    var canonical_text := FileAccess.get_file_as_string(repository.get_manifest_path(project.project_id))
    var opened: Dictionary = repository.open_project(project.project_id)
    if not opened.get("ok", false) or opened.get("recovery", {}).get("status") != "incomplete_temporary_write":
        errors.append("Incomplete temporary checkpoint writes must be detected separately.")
    if FileAccess.get_file_as_string(repository.get_manifest_path(project.project_id)) != canonical_text:
        errors.append("Incomplete temporary writes must never replace canonical project data.")


static func _check_retention_policy(errors: Array[String]) -> void:
    var root := "user://tests/checkpoint_retention_%s" % StableId.generate()
    var repository = Repository.new(root, null, 2)
    var created: Dictionary = repository.create_project("Retention Test", &"small", "blank_sandbox")
    if not created.get("ok", false):
        errors.append("Retention fixture project must be created.")
        return
    var project = created["project"]
    for title in ["Checkpoint A", "Checkpoint B", "Checkpoint C"]:
        project.title = title
        var result: Dictionary = repository.create_checkpoint(project)
        if not result.get("ok", false):
            errors.append("Retention fixture checkpoint must be created: %s" % result.get("errors", []))
            return
    var checkpoints := repository.list_checkpoints(project.project_id)
    if checkpoints.size() != 2:
        errors.append("Checkpoint retention must deterministically cap persisted valid checkpoints.")
        return
    if checkpoints[0]["record"].project_state.get("title") != "Checkpoint C" \
            or checkpoints[1]["record"].project_state.get("title") != "Checkpoint B":
        errors.append("Retention must keep the two newest valid checkpoints and prune the oldest.")


static func _ensure_checkpoint_directory(repository, project_id: String, errors: Array[String]) -> bool:
    var make_error := DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(repository.get_checkpoint_directory(project_id))
    )
    if make_error != OK:
        errors.append("Test fixture could not create checkpoint directory: %s" % make_error)
        return false
    return true


static func _write_text(path: String, text: String, errors: Array[String]) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        errors.append("Test fixture could not write %s" % path)
        return
    file.store_string(text)
    file.flush()
    file.close()
