class_name PlayWorldCheckpointStore
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const CheckpointRecord = preload("res://src/world/checkpoint_record.gd")
const SafeJsonWriter = preload("res://src/world/safe_json_writer.gd")

const CHECKPOINT_DIRECTORY := "checkpoints"
const CHECKPOINT_SUFFIX := ".json"
const DEFAULT_RETENTION_LIMIT := 5

var root_path: String
var retention_limit: int
var _writer
var _last_created_msec := 0


func _init(
    storage_root: String = "user://projects",
    checkpoint_retention: int = DEFAULT_RETENTION_LIMIT,
    safe_writer = null
) -> void:
    root_path = storage_root.trim_suffix("/")
    retention_limit = max(1, checkpoint_retention)
    _writer = safe_writer if safe_writer != null else SafeJsonWriter.new()


func create_checkpoint(project) -> Dictionary:
    if project == null:
        return _failure("Project is required for checkpoint creation.")
    var project_errors: Array[String] = project.validate()
    if not project_errors.is_empty():
        return {"ok": false, "errors": project_errors, "checkpoint": null, "path": ""}

    var checkpoint_dir := get_checkpoint_directory(project.project_id)
    var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(checkpoint_dir))
    if make_error != OK:
        return _failure("Unable to create checkpoint directory: %s" % make_error)

    var record = CheckpointRecord.new()
    record.initialize_from_project(project, _next_created_msec(project.updated_at_msec + 1))
    var path := get_checkpoint_path(project.project_id, record.checkpoint_id)
    var write_result: Dictionary = _writer.write_validated_dictionary(
        path,
        record.to_dictionary(),
        Callable(CheckpointRecord, "validate_dictionary")
    )
    if not write_result.get("ok", false):
        return {
            "ok": false,
            "errors": write_result.get("errors", ["Checkpoint write failed."]),
            "checkpoint": null,
            "path": path
        }

    var retention_errors := _prune_retention(project.project_id)
    return {
        "ok": true,
        "errors": [],
        "warnings": retention_errors,
        "checkpoint": record,
        "path": path
    }


func list_checkpoints(project_id: String) -> Array:
    var entries: Array = []
    if not StableId.is_valid(project_id):
        return entries
    var directory := DirAccess.open(get_checkpoint_directory(project_id))
    if directory == null:
        return entries

    directory.list_dir_begin()
    var name := directory.get_next()
    while not name.is_empty():
        if not directory.current_is_dir() and name.ends_with(CHECKPOINT_SUFFIX) and not name.contains(".tmp-"):
            var path := "%s/%s" % [get_checkpoint_directory(project_id), name]
            var load_result := load_checkpoint(path, project_id)
            if load_result.get("ok", false):
                entries.append({"record": load_result["checkpoint"], "path": path})
        name = directory.get_next()
    directory.list_dir_end()
    entries.sort_custom(_checkpoint_entry_newer)
    return entries


func inspect_recovery(project_id: String, canonical_updated_at_msec: int) -> Dictionary:
    if not StableId.is_valid(project_id):
        return _failure("Project ID is invalid for recovery inspection.")

    var valid_entries: Array = []
    var invalid_count := 0
    var unsupported_count := 0
    var temporary_count := 0
    var directory := DirAccess.open(get_checkpoint_directory(project_id))
    if directory != null:
        directory.list_dir_begin()
        var name := directory.get_next()
        while not name.is_empty():
            if not directory.current_is_dir():
                if name.contains(".tmp-"):
                    temporary_count += 1
                elif name.ends_with(CHECKPOINT_SUFFIX):
                    var path := "%s/%s" % [get_checkpoint_directory(project_id), name]
                    var read_result: Dictionary = _writer.read_dictionary(path)
                    if not read_result.get("ok", false):
                        invalid_count += 1
                    else:
                        var data: Dictionary = read_result["data"]
                        if data.get("document_type") == CheckpointRecord.DOCUMENT_TYPE \
                                and int(data.get("schema_version", 0)) > CheckpointRecord.SCHEMA_VERSION:
                            unsupported_count += 1
                        else:
                            var load_result := load_checkpoint(path, project_id)
                            if load_result.get("ok", false):
                                valid_entries.append({"record": load_result["checkpoint"], "path": path})
                            else:
                                invalid_count += 1
            name = directory.get_next()
        directory.list_dir_end()

    valid_entries.sort_custom(_checkpoint_entry_newer)
    for entry in valid_entries:
        var record = entry["record"]
        if record.created_at_msec > canonical_updated_at_msec:
            return _status(
                "available",
                true,
                record.checkpoint_id,
                entry["path"],
                invalid_count,
                unsupported_count,
                temporary_count
            )

    var status := "missing"
    if unsupported_count > 0:
        status = "unsupported_schema"
    elif invalid_count > 0:
        status = "invalid_checkpoint"
    elif temporary_count > 0:
        status = "incomplete_temporary_write"
    elif not valid_entries.is_empty():
        status = "not_newer"
    return _status(status, false, "", "", invalid_count, unsupported_count, temporary_count)


func load_checkpoint(path: String, expected_project_id: String = "") -> Dictionary:
    var read_result: Dictionary = _writer.read_dictionary(path)
    if not read_result.get("ok", false):
        return {"ok": false, "errors": read_result.get("errors", []), "checkpoint": null}

    var record = CheckpointRecord.new()
    var errors: Array[String] = record.load_dictionary(read_result["data"])
    if not errors.is_empty():
        return {"ok": false, "errors": errors, "checkpoint": null}
    if not expected_project_id.is_empty() and record.project_id != expected_project_id:
        return _failure("Checkpoint project association does not match the requested project.")
    return {"ok": true, "errors": [], "checkpoint": record}


func get_checkpoint_directory(project_id: String) -> String:
    return "%s/%s/%s" % [root_path, project_id, CHECKPOINT_DIRECTORY]


func get_checkpoint_path(project_id: String, checkpoint_id: String) -> String:
    return "%s/%s%s" % [get_checkpoint_directory(project_id), checkpoint_id, CHECKPOINT_SUFFIX]


func _prune_retention(project_id: String) -> Array[String]:
    var errors: Array[String] = []
    var checkpoints := list_checkpoints(project_id)
    while checkpoints.size() > retention_limit:
        var oldest: Dictionary = checkpoints.pop_back()
        var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(str(oldest["path"])))
        if remove_error != OK:
            errors.append("Unable to remove expired checkpoint: %s" % remove_error)
    return errors


func _next_created_msec(minimum_msec: int = 0) -> int:
    var now := int(Time.get_unix_time_from_system() * 1000.0)
    _last_created_msec = max(now, max(_last_created_msec + 1, minimum_msec))
    return _last_created_msec


func _checkpoint_entry_newer(a: Dictionary, b: Dictionary) -> bool:
    var a_record = a["record"]
    var b_record = b["record"]
    if a_record.created_at_msec != b_record.created_at_msec:
        return a_record.created_at_msec > b_record.created_at_msec
    return a_record.checkpoint_id > b_record.checkpoint_id


func _status(
    status: String,
    recoverable: bool,
    checkpoint_id: String,
    checkpoint_path: String,
    invalid_count: int,
    unsupported_count: int,
    temporary_count: int
) -> Dictionary:
    return {
        "ok": true,
        "status": status,
        "recoverable": recoverable,
        "checkpoint_id": checkpoint_id,
        "checkpoint_path": checkpoint_path,
        "invalid_count": invalid_count,
        "unsupported_count": unsupported_count,
        "temporary_count": temporary_count
    }


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message], "checkpoint": null}
