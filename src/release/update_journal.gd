class_name PlayWorldUpdateJournal
extends RefCounted

const ReleasePaths = preload("res://src/release/release_paths.gd")
const JOURNAL_PATH := "user://updates/update_journal.json"
const HISTORY_ROOT := "user://updates/history"
const TERMINAL_STAGES := ["completed", "rolled_back", "failed", "cancelled"]
const VALID_STAGES := [
    "created", "checking", "available", "downloading", "downloaded", "verifying",
    "verified", "handoff", "waiting_for_shutdown", "backing_up", "replacing",
    "installer_running", "restart_pending", "completed", "failed", "rollback_pending",
    "rolled_back", "cancelled"
]

var _path: String

func _init(path: String = JOURNAL_PATH) -> void:
    _path = path

func begin(operation: String, metadata: Dictionary = {}) -> Dictionary:
    if operation not in ["portable_update", "installed_update", "repair", "rollback"]:
        return ReleasePaths.failure("Update operation is invalid.")
    var existing := load_state()
    if not existing.get("ok", false): return existing
    if existing.get("exists", false):
        var recovery := recovery_snapshot()
        if bool(recovery.get("available", false)):
            return ReleasePaths.failure("An interrupted update journal must be repaired, rolled back, or explicitly archived before another operation begins.")
        var archived := archive_current("superseded_by_%s" % operation)
        if not archived.get("ok", false): return archived
    var now := int(Time.get_unix_time_from_system())
    var state := {
        "schema_version": 1,
        "operation_id": "%d-%d" % [now, Time.get_ticks_usec()],
        "operation": operation,
        "stage": "created",
        "created_at_unix": now,
        "updated_at_unix": now,
        "outcome": "in_progress",
        "artifact": {},
        "application_root": "",
        "backup_root": "",
        "previous_inventory": [],
        "replacement_inventory": [],
        "completed_paths": [],
        "errors": [],
        "metadata": metadata.duplicate(true),
    }
    var saved := ReleasePaths.atomic_write_json(_path, state)
    if not saved.get("ok", false): return saved
    return {"ok": true, "errors": [], "state": state}

func load_state() -> Dictionary:
    if not FileAccess.file_exists(_path):
        return {"ok": true, "errors": [], "exists": false, "state": {}}
    var result := ReleasePaths.read_json(_path)
    if not result.get("ok", false): return result
    var state: Dictionary = result.get("value", {})
    var validation := validate(state)
    if not validation.get("ok", false): return validation
    return {"ok": true, "errors": [], "exists": true, "state": state}

func transition(stage: String, patch: Dictionary = {}) -> Dictionary:
    if not VALID_STAGES.has(stage): return ReleasePaths.failure("Update journal stage is invalid.")
    var loaded := load_state()
    if not loaded.get("ok", false) or not loaded.get("exists", false):
        return ReleasePaths.failure("No update operation is available to transition.")
    var state: Dictionary = loaded.get("state", {})
    var current_stage := str(state.get("stage", ""))
    if TERMINAL_STAGES.has(current_stage) and not (stage == "rollback_pending" and current_stage in ["completed", "failed"]):
        return ReleasePaths.failure("A completed update journal cannot be transitioned.")
    state["stage"] = stage
    state["updated_at_unix"] = int(Time.get_unix_time_from_system())
    for key in patch.keys(): state[key] = patch[key]
    if stage == "failed": state["outcome"] = "failed"
    elif stage == "cancelled": state["outcome"] = "cancelled"
    elif stage == "rolled_back": state["outcome"] = "rolled_back"
    elif stage == "completed": state["outcome"] = "success"
    var validation := validate(state)
    if not validation.get("ok", false): return validation
    var saved := ReleasePaths.atomic_write_json(_path, state)
    if not saved.get("ok", false): return saved
    return {"ok": true, "errors": [], "state": state}

func append_completed_path(relative_path: String) -> Dictionary:
    if not _safe_relative_path(relative_path):
        return ReleasePaths.failure("Update journal replacement path is unsafe.")
    var loaded := load_state()
    if not loaded.get("ok", false) or not loaded.get("exists", false):
        return ReleasePaths.failure("No update operation is available.")
    var state: Dictionary = loaded.get("state", {})
    var paths: Array = state.get("completed_paths", [])
    if not paths.has(relative_path): paths.append(relative_path)
    return transition(str(state.get("stage", "replacing")), {"completed_paths": paths})

func fail(message: String, recoverable: bool = true) -> Dictionary:
    var loaded := load_state()
    if not loaded.get("ok", false) or not loaded.get("exists", false):
        return ReleasePaths.failure(message)
    var state: Dictionary = loaded.get("state", {})
    var errors: Array = state.get("errors", [])
    errors.append({"at_unix": int(Time.get_unix_time_from_system()), "message": message.left(1024)})
    return transition("failed", {"errors": errors, "recoverable": recoverable})

func complete(result: Dictionary = {}) -> Dictionary:
    return transition("completed", {"result": result.duplicate(true), "recoverable": false})

func mark_rollback_pending(reason: String) -> Dictionary:
    return transition("rollback_pending", {"rollback_reason": reason.left(1024), "recoverable": true})

func archive_current(reason: String) -> Dictionary:
    var loaded := load_state()
    if not loaded.get("ok", false): return loaded
    if not loaded.get("exists", false): return {"ok": true, "errors": [], "archived": false}
    var state: Dictionary = (loaded.get("state", {}) as Dictionary).duplicate(true)
    state["archived_at_unix"] = int(Time.get_unix_time_from_system())
    state["archive_reason"] = reason.left(256)
    var operation_id := str(state.get("operation_id", ""))
    var operation_id_pattern := RegEx.new()
    operation_id_pattern.compile("^[0-9-]+$")
    var safe_id := operation_id if operation_id_pattern.search(operation_id) != null else str(Time.get_unix_time_from_system())
    var archive_path := HISTORY_ROOT.path_join("update_journal-%s-%d.json" % [safe_id, Time.get_unix_time_from_system()])
    var saved := ReleasePaths.atomic_write_json(archive_path, state)
    if not saved.get("ok", false): return saved
    var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(_path))
    if remove_error not in [OK, ERR_DOES_NOT_EXIST]:
        return ReleasePaths.failure("Update journal was archived but the active journal could not be removed.")
    return {"ok": true, "errors": [], "archived": true, "path": archive_path}

func clear_if_terminal() -> Dictionary:
    var loaded := load_state()
    if not loaded.get("ok", false): return loaded
    if not loaded.get("exists", false): return {"ok": true, "errors": [], "cleared": false}
    var stage := str((loaded.get("state", {}) as Dictionary).get("stage", ""))
    if not TERMINAL_STAGES.has(stage):
        return ReleasePaths.failure("Active update journal cannot be cleared.")
    var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(_path))
    if error not in [OK, ERR_DOES_NOT_EXIST]: return ReleasePaths.failure("Completed update journal could not be removed.")
    return {"ok": true, "errors": [], "cleared": true}

func recovery_snapshot() -> Dictionary:
    var loaded := load_state()
    if not loaded.get("ok", false):
        return {"available": false, "corrupt": true, "errors": loaded.get("errors", [])}
    if not loaded.get("exists", false):
        return {"available": false, "corrupt": false, "stage": "none"}
    var state: Dictionary = loaded.get("state", {})
    var stage := str(state.get("stage", ""))
    var backup_root := str(state.get("backup_root", ""))
    var backup_available := not backup_root.is_empty() and DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(backup_root))
    return {
        "available": stage not in ["completed", "rolled_back", "cancelled"],
        "corrupt": false,
        "operation": str(state.get("operation", "")),
        "operation_id": str(state.get("operation_id", "")),
        "stage": stage,
        "outcome": str(state.get("outcome", "")),
        "backup_available": backup_available,
        "recoverable": bool(state.get("recoverable", stage in ["failed", "rollback_pending", "backing_up", "replacing", "restart_pending"])),
        "updated_at_unix": int(state.get("updated_at_unix", 0)),
    }

func validate(state: Dictionary) -> Dictionary:
    var required := ["schema_version", "operation_id", "operation", "stage", "created_at_unix", "updated_at_unix", "outcome", "artifact", "previous_inventory", "replacement_inventory", "completed_paths", "errors", "metadata"]
    for key in required:
        if not state.has(key): return ReleasePaths.failure("Update journal field is missing: %s" % key)
    if int(state.get("schema_version", -1)) != 1: return ReleasePaths.failure("Update journal schema is unsupported.")
    if str(state.get("operation", "")) not in ["portable_update", "installed_update", "repair", "rollback"]:
        return ReleasePaths.failure("Update journal operation is invalid.")
    if not VALID_STAGES.has(str(state.get("stage", ""))): return ReleasePaths.failure("Update journal stage is invalid.")
    for key in ["previous_inventory", "replacement_inventory", "completed_paths", "errors"]:
        if not state.get(key, []) is Array: return ReleasePaths.failure("Update journal collection is invalid: %s" % key)
    for path_value in state.get("completed_paths", []):
        if not _safe_relative_path(str(path_value)): return ReleasePaths.failure("Update journal contains an unsafe replacement path.")
    return {"ok": true, "errors": []}

func _safe_relative_path(value: String) -> bool:
    var normalized := value.replace("\\", "/")
    if normalized.is_empty() or normalized.begins_with("/") or normalized.contains(":"):
        return false
    for part in normalized.split("/", false):
        if part in ["", ".", ".."]: return false
    return true
