class_name PlayWorldUpdateService
extends Node

const ProductIdentity = preload("res://src/release/product_identity.gd")
const UpdateManifest = preload("res://src/release/update_manifest.gd")
const UpdatePreferences = preload("res://src/release/update_preferences.gd")
const UpdateJournal = preload("res://src/release/update_journal.gd")
const ReleasePaths = preload("res://src/release/release_paths.gd")

const TRUST_REGISTRY_PATH := "res://config/release/update_keys.json"
const STAGING_ROOT := "user://updates/staging"
const REQUEST_ROOT := "user://updates/requests"
const CACHE_ROOT := "user://updates/cache"
const MAX_MANIFEST_BYTES := 1024 * 1024
const CHECK_TIMEOUT_SECONDS := 12.0
const DOWNLOAD_TIMEOUT_SECONDS := 1800.0
const STATES := ["idle", "checking", "current", "available", "downloading", "verifying", "ready", "handoff", "failed", "cancelled", "offline", "recovery"]

signal state_changed(state: StringName, snapshot: Dictionary)
signal progress_changed(downloaded: int, total: int, ratio: float)
signal update_available(payload: Dictionary, artifact: Dictionary)
signal channel_changed(channel: String)
signal operation_failed(message: String, recoverable: bool)

var _preferences := UpdatePreferences.new()
var _journal := UpdateJournal.new()
var _manifest_request: HTTPRequest
var _download_request: HTTPRequest
var _state: StringName = &"idle"
var _manual_check := false
var _busy := false
var _cancel_requested := false
var _available_payload: Dictionary = {}
var _selected_artifact: Dictionary = {}
var _staged_path := ""
var _last_message := "Updates have not been checked yet."
var _downloaded := 0
var _download_total := 0
var _last_manifest_text := ""
var _progress_poll_elapsed := 0.0

func _ready() -> void:
    ReleasePaths.ensure_directory(STAGING_ROOT)
    ReleasePaths.ensure_directory(REQUEST_ROOT)
    ReleasePaths.ensure_directory(CACHE_ROOT)
    _cleanup_abandoned_partials()
    _manifest_request = HTTPRequest.new()
    _manifest_request.name = "ManifestRequest"
    _manifest_request.timeout = float(ProjectSettings.get_setting("playworld/release/check_timeout_seconds", CHECK_TIMEOUT_SECONDS))
    add_child(_manifest_request)
    _manifest_request.request_completed.connect(_on_manifest_request_completed)
    _download_request = HTTPRequest.new()
    _download_request.name = "ArtifactRequest"
    _download_request.timeout = float(ProjectSettings.get_setting("playworld/release/download_timeout_seconds", DOWNLOAD_TIMEOUT_SECONDS))
    add_child(_download_request)
    _download_request.request_completed.connect(_on_download_request_completed)
    if _download_request.has_signal("request_progress"):
        _download_request.connect("request_progress", Callable(self, "_on_download_progress"))
    var recovery := _journal.recovery_snapshot()
    if bool(recovery.get("available", false)):
        _set_state(&"recovery", "An interrupted update requires repair or rollback.")
    else:
        _set_state(&"idle", "Updates are optional and never block offline creator use.")
    call_deferred("_background_check")


func _process(delta: float) -> void:
    if _state != &"downloading" or _staged_path.is_empty(): return
    _progress_poll_elapsed += delta
    if _progress_poll_elapsed < 0.10: return
    _progress_poll_elapsed = 0.0
    var absolute := ProjectSettings.globalize_path(_staged_path)
    if not FileAccess.file_exists(absolute): return
    var handle := FileAccess.open(absolute, FileAccess.READ)
    if handle == null: return
    var length := maxi(0, handle.get_length())
    handle.close()
    if length == _downloaded: return
    _on_download_progress(length, _download_total)

func check_for_updates(manual: bool = true, manifest_text: String = "") -> Dictionary:
    if manifest_text.is_empty() and OS.get_environment("PLAYWORLD_DISABLE_UPDATE_NETWORK") == "1":
        _set_state(&"offline", "Update networking is disabled for this session. Offline creator use remains fully functional.")
        return {"ok": false, "errors": ["Update networking is disabled for this session."], "offline": true}
    var recovery := _journal.recovery_snapshot()
    if bool(recovery.get("available", false)):
        return ReleasePaths.failure("Repair or rollback the interrupted update before checking for another update.")
    if _busy: return ReleasePaths.failure("Another update operation is already active.")
    if not _preferences.check_allowed_now(manual):
        return {"ok": true, "errors": [], "deferred": true, "state": str(_state)}
    _manual_check = manual
    _cancel_requested = false
    _busy = true
    _available_payload.clear()
    _selected_artifact.clear()
    _staged_path = ""
    _set_state(&"checking", "Checking the selected release channel…")
    if not manifest_text.is_empty():
        var result := _accept_manifest_text(manifest_text)
        _busy = false
        return result
    var channel := _preferences.selected_channel()
    var url := _preferences.manifest_url(channel)
    if url.is_empty():
        return _check_failure("No update endpoint is configured for the %s channel." % channel, false)
    if not _preferences.is_url_allowed(url, channel):
        return _check_failure("The configured update endpoint is not authorized for this channel.", false)
    var error := _manifest_request.request(url, ["Accept: application/json", "Cache-Control: no-cache"], HTTPClient.METHOD_GET)
    if error != OK:
        return _check_failure("The update request could not start.", true)
    return {"ok": true, "errors": [], "started": true, "state": "checking"}

func set_channel(channel: String) -> Dictionary:
    if _busy: return ReleasePaths.failure("Release channel cannot change during an active update operation.")
    var result := _preferences.set_channel(channel)
    if result.get("ok", false):
        _available_payload.clear()
        _selected_artifact.clear()
        _staged_path = ""
        _set_state(&"idle", "%s channel selected. No project data was changed." % channel.capitalize())
        channel_changed.emit(channel)
    return result

func set_auto_check(enabled: bool) -> Dictionary:
    return _preferences.set_auto_check(enabled)

func start_download() -> Dictionary:
    var recovery := _journal.recovery_snapshot()
    if bool(recovery.get("available", false)):
        return ReleasePaths.failure("Repair or rollback the interrupted update before starting another download.")
    if _busy: return ReleasePaths.failure("Another update operation is already active.")
    if _state != &"available" or _selected_artifact.is_empty():
        return ReleasePaths.failure("No verified update is available to download.")
    var filename := str(_selected_artifact.get("filename", ""))
    if not ReleasePaths.is_safe_filename(filename): return ReleasePaths.failure("Update filename is unsafe.")
    var version := str(_available_payload.get("version", "unknown"))
    var staging_directory := STAGING_ROOT.path_join(version)
    var directory := ReleasePaths.ensure_directory(staging_directory)
    if not directory.get("ok", false): return directory
    _staged_path = staging_directory.path_join(filename + ".part")
    if FileAccess.file_exists(_staged_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(_staged_path))
    _download_request.download_file = ProjectSettings.globalize_path(_staged_path)
    _downloaded = 0
    _download_total = int(_selected_artifact.get("size", 0))
    _cancel_requested = false
    _busy = true
    var operation := "portable_update" if ReleasePaths.install_mode() == "portable" else "installed_update"
    var started := _journal.begin(operation, {
        "version": version,
        "channel": _preferences.selected_channel(),
        "source_commit": str(_available_payload.get("source_commit", "")),
    })
    if not started.get("ok", false):
        _busy = false
        return started
    _journal.transition("downloading", {
        "artifact": _selected_artifact.duplicate(true),
        "application_root": ReleasePaths.application_root(),
    })
    _set_state(&"downloading", "Downloading %s…" % filename)
    var artifact_url := str(_selected_artifact.get("url", ""))
    if not _preferences.is_url_allowed(artifact_url):
        _busy = false
        _journal.fail("Signed artifact URL is not authorized for this channel.")
        return _operation_failure("Signed artifact URL is not authorized for this channel.", true)
    var error := _download_request.request(artifact_url, ["Accept: application/octet-stream"], HTTPClient.METHOD_GET)
    if error != OK:
        _busy = false
        _journal.fail("Artifact download could not start.")
        return _operation_failure("Artifact download could not start.", true)
    return {"ok": true, "errors": [], "started": true, "path": _staged_path}

func cancel_current() -> Dictionary:
    if not _busy: return {"ok": true, "errors": [], "cancelled": false}
    _cancel_requested = true
    if _state == &"checking": _manifest_request.cancel_request()
    if _state == &"downloading": _download_request.cancel_request()
    _busy = false
    _journal.transition("cancelled", {"recoverable": false})
    if not _staged_path.is_empty() and FileAccess.file_exists(_staged_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(_staged_path))
    _set_state(&"cancelled", "Update operation cancelled. The installed application was not changed.")
    return {"ok": true, "errors": [], "cancelled": true}

func verify_staged_artifact(path: String = "") -> Dictionary:
    var candidate := _staged_path if path.is_empty() else path
    if candidate.is_empty() or not FileAccess.file_exists(candidate):
        return ReleasePaths.failure("Staged update artifact is missing.")
    if _selected_artifact.is_empty(): return ReleasePaths.failure("Verified artifact metadata is unavailable.")
    _set_state(&"verifying", "Verifying exact size and SHA-256…")
    _journal.transition("verifying")
    var digest := ReleasePaths.sha256_file(candidate)
    if not digest.get("ok", false): return _verification_failure(str(digest.get("errors", [])))
    var expected_size := int(_selected_artifact.get("size", 0))
    var expected_hash := str(_selected_artifact.get("sha256", ""))
    if int(digest.get("size", -1)) != expected_size:
        return _verification_failure("Downloaded byte count does not match the signed manifest.")
    if str(digest.get("sha256", "")).to_lower() != expected_hash:
        return _verification_failure("Downloaded SHA-256 does not match the signed manifest.")
    var final_path := candidate.trim_suffix(".part")
    if final_path != candidate:
        if FileAccess.file_exists(final_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(final_path))
        var rename := DirAccess.rename_absolute(ProjectSettings.globalize_path(candidate), ProjectSettings.globalize_path(final_path))
        if rename != OK: return _verification_failure("Verified artifact could not be promoted from staging.")
        _staged_path = final_path
    _preferences.record_verified_artifact(_staged_path, {
        "sha256": expected_hash,
        "size": expected_size,
        "version": str(_available_payload.get("version", "")),
        "kind": str(_selected_artifact.get("kind", "")),
    })
    _journal.transition("verified", {"staged_artifact": ProjectSettings.globalize_path(_staged_path), "verified_sha256": expected_hash, "verified_size": expected_size})
    _busy = false
    _set_state(&"ready", "Update verified and ready to install. Your projects remain outside the application directory.")
    return {"ok": true, "errors": [], "path": _staged_path, "sha256": expected_hash, "size": expected_size}

func install_ready_update(restart: bool = true) -> Dictionary:
    if _busy: return ReleasePaths.failure("Another update operation is already active.")
    if _state != &"ready" or _staged_path.is_empty() or not FileAccess.file_exists(_staged_path):
        return ReleasePaths.failure("No verified update is ready to install.")
    var mode := ReleasePaths.install_mode()
    if mode == "development" and bool(ProjectSettings.get_setting("playworld/release/dry_run_updates", false)):
        mode = str(ProjectSettings.get_setting("playworld/release/development_install_mode", "portable"))
    if mode not in ["portable", "installed"]:
        return ReleasePaths.failure("Updates can be installed only from a packaged portable or installed application.")
    var operation := "apply-portable" if mode == "portable" else "apply-installer"
    var request := _build_helper_request(operation, _staged_path, restart)
    var request_write := _write_helper_request(request)
    if not request_write.get("ok", false): return request_write
    _journal.transition("handoff", {"helper_request": request_write.get("path", ""), "backup_root": request.get("backup_root", "")})
    return _launch_helper(str(request_write.get("path", "")), true)

func repair_application() -> Dictionary:
    if _busy: return ReleasePaths.failure("Another update operation is already active.")
    var settings := _preferences.load_preferences().get("settings", _preferences.defaults()) as Dictionary
    var verified := str(settings.get("last_verified_artifact", ""))
    if verified.is_empty() or not FileAccess.file_exists(verified):
        return ReleasePaths.failure("Repair requires the last verified update package.")
    var recovery := _journal.recovery_snapshot()
    if bool(recovery.get("available", false)):
        var archived := _journal.archive_current("repair_requested")
        if not archived.get("ok", false): return archived
    var started := _journal.begin("repair", {"requested_by_user": true})
    if not started.get("ok", false): return started
    _selected_artifact = {
        "sha256": str(settings.get("last_verified_sha256", "")),
        "size": int(settings.get("last_verified_size", 0)),
        "kind": str(settings.get("last_verified_kind", "")),
    }
    _available_payload = {"version": str(settings.get("last_verified_version", ProductIdentity.version()))}
    var request := _build_helper_request("repair", verified, true)
    var written := _write_helper_request(request)
    if not written.get("ok", false): return written
    _journal.transition("handoff", {"helper_request": written.get("path", "")})
    return _launch_helper(str(written.get("path", "")), true)

func rollback_application() -> Dictionary:
    if _busy: return ReleasePaths.failure("Another update operation is already active.")
    var recovery := _journal.recovery_snapshot()
    if not bool(recovery.get("backup_available", false)):
        return ReleasePaths.failure("No verified application-binary backup is available for rollback.")
    var request := _build_helper_request("rollback", "", true)
    var loaded := _journal.load_state()
    if loaded.get("ok", false) and loaded.get("exists", false):
        request["backup_root"] = str((loaded.get("state", {}) as Dictionary).get("backup_root", request.get("backup_root", "")))
    var written := _write_helper_request(request)
    if not written.get("ok", false): return written
    _journal.mark_rollback_pending("User requested binary rollback.")
    return _launch_helper(str(written.get("path", "")), true)

func snapshot() -> Dictionary:
    var settings := _preferences.load_preferences().get("settings", _preferences.defaults()) as Dictionary
    return {
        "state": str(_state),
        "busy": _busy,
        "message": _last_message,
        "current_version": ProductIdentity.version(),
        "available_version": str(_available_payload.get("version", "")),
        "channel": str(settings.get("channel", "stable")),
        "auto_check": bool(settings.get("auto_check", true)),
        "last_check_unix": int(settings.get("last_check_unix", 0)),
        "last_result": str(settings.get("last_result", "never")),
        "last_error": str(settings.get("last_error", "")),
        "downloaded": _downloaded,
        "download_total": _download_total,
        "release_notes": str(_available_payload.get("release_notes", "")),
        "artifact": _selected_artifact.duplicate(true),
        "staged_path": ReleasePaths.redact_path(_staged_path) if not _staged_path.is_empty() else "",
        "install_mode": ReleasePaths.install_mode(),
        "journal": _journal.recovery_snapshot(),
    }

func prepare_staged_artifact_for_validation(path: String, payload: Dictionary, artifact: Dictionary) -> Dictionary:
    if _busy: return ReleasePaths.failure("Another update operation is already active.")
    if not FileAccess.file_exists(path): return ReleasePaths.failure("Staged artifact fixture is missing.")
    if not ReleasePaths.is_safe_filename(str(artifact.get("filename", ""))): return ReleasePaths.failure("Staged artifact filename is unsafe.")
    _available_payload = payload.duplicate(true)
    _selected_artifact = artifact.duplicate(true)
    _staged_path = path
    var started := _journal.begin("portable_update" if str(artifact.get("kind", "portable")) == "portable" else "installed_update", {"prepared_for_validation": true})
    if not started.get("ok", false): return started
    var transitioned := _journal.transition("downloaded", {"artifact": _selected_artifact.duplicate(true)})
    if not transitioned.get("ok", false): return transitioned
    return {"ok": true, "errors": [], "path": path}

func available_payload() -> Dictionary: return _available_payload.duplicate(true)
func selected_artifact() -> Dictionary: return _selected_artifact.duplicate(true)
func state() -> StringName: return _state

func _background_check() -> void:
    if OS.get_environment("PLAYWORLD_DISABLE_UPDATE_NETWORK") == "1": return
    var settings := _preferences.load_preferences().get("settings", _preferences.defaults()) as Dictionary
    if not bool(settings.get("auto_check", true)) or not _preferences.check_allowed_now(false): return
    check_for_updates(false)

func _on_manifest_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if _cancel_requested: return
    _busy = false
    if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
        _check_failure("Update endpoint is unavailable. Offline creator use remains fully functional.", true)
        return
    if body.size() <= 0 or body.size() > MAX_MANIFEST_BYTES:
        _check_failure("Update endpoint returned an invalid manifest size.", true)
        return
    var text := body.get_string_from_utf8()
    if text.to_utf8_buffer() != body:
        _check_failure("Update manifest is not valid UTF-8.", true)
        return
    _accept_manifest_text(text)

func _accept_manifest_text(text: String) -> Dictionary:
    _last_manifest_text = text
    var trust_path := str(ProjectSettings.get_setting("playworld/release/trust_registry_path", TRUST_REGISTRY_PATH))
    var registry_result := UpdateManifest.load_registry(trust_path)
    if not registry_result.get("ok", false): return _check_failure(str(registry_result.get("errors", [])), true)
    var mode := ReleasePaths.install_mode()
    if mode == "development": mode = str(ProjectSettings.get_setting("playworld/release/development_install_mode", "portable"))
    var validation := UpdateManifest.validate_text(text, registry_result.get("registry", {}), ProductIdentity.version(), _preferences.selected_channel(), mode, false)
    if not validation.get("ok", false):
        return _check_failure("Signed update metadata was rejected: %s" % str(validation.get("errors", [])), true)
    var cache_path := CACHE_ROOT.path_join("%s-manifest.json" % _preferences.selected_channel())
    var cache_handle := FileAccess.open(cache_path, FileAccess.WRITE)
    if cache_handle != null:
        cache_handle.store_string(text)
        cache_handle.close()
    _available_payload = (validation.get("payload", {}) as Dictionary).duplicate(true)
    _selected_artifact = (validation.get("artifact", {}) as Dictionary).duplicate(true)
    var is_update := bool(validation.get("is_update", true))
    _preferences.record_check(true, "available" if is_update else "current", "", cache_path)
    if not is_update:
        _set_state(&"current", "PlayWorld Studio is current on the %s channel." % _preferences.selected_channel().capitalize())
        return {"ok": true, "errors": [], "is_update": false, "payload": _available_payload}
    _set_state(&"available", "PlayWorld Studio %s is available." % str(_available_payload.get("version", "")))
    update_available.emit(_available_payload.duplicate(true), _selected_artifact.duplicate(true))
    return {"ok": true, "errors": [], "is_update": true, "payload": _available_payload, "artifact": _selected_artifact}

func _on_download_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
    if _cancel_requested: return
    if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
        _busy = false
        _journal.fail("Artifact download failed or was interrupted.")
        if not _staged_path.is_empty() and FileAccess.file_exists(_staged_path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(_staged_path))
        _operation_failure("Artifact download failed. The installed application was not changed.", true)
        return
    _journal.transition("downloaded")
    verify_staged_artifact()

func _on_download_progress(downloaded: int, total: int) -> void:
    _downloaded = maxi(0, downloaded)
    _download_total = total if total > 0 else int(_selected_artifact.get("size", 0))
    var ratio := 0.0 if _download_total <= 0 else clampf(float(_downloaded) / float(_download_total), 0.0, 1.0)
    progress_changed.emit(_downloaded, _download_total, ratio)

func _build_helper_request(operation: String, artifact_path: String, restart: bool) -> Dictionary:
    var version := str(_available_payload.get("version", ProductIdentity.version()))
    var backup_root := ProjectSettings.globalize_path("user://updates/backups/%s-%d" % [version, Time.get_unix_time_from_system()])
    return {
        "schema_version": 1,
        "operation": operation,
        "application_root": ReleasePaths.application_root(),
        "artifact_path": ProjectSettings.globalize_path(artifact_path) if not artifact_path.is_empty() else "",
        "backup_root": backup_root,
        "journal_path": ProjectSettings.globalize_path(UpdateJournal.JOURNAL_PATH),
        "restart_executable": OS.get_executable_path() if restart else "",
        "expected_sha256": str(_selected_artifact.get("sha256", "")),
        "expected_size": int(_selected_artifact.get("size", 0)),
        "expected_version": version,
        "expected_product": ProductIdentity.PRODUCT_NAME,
        "parent_process_id": OS.get_process_id(),
        "install_mode": ReleasePaths.install_mode(),
        "created_at_unix": int(Time.get_unix_time_from_system()),
    }

func _write_helper_request(request: Dictionary) -> Dictionary:
    var path := REQUEST_ROOT.path_join("update-%d-%d.json" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()])
    var written := ReleasePaths.atomic_write_json(path, request)
    if not written.get("ok", false): return written
    return {"ok": true, "errors": [], "path": ProjectSettings.globalize_path(path)}

func _launch_helper(request_path: String, quit_after_handoff: bool) -> Dictionary:
    var helper := ReleasePaths.application_root().path_join("tools/updater/PlayWorldUpdater.exe")
    var dry_run := bool(ProjectSettings.get_setting("playworld/release/dry_run_updates", false))
    if dry_run:
        _set_state(&"handoff", "Updater handoff validated in dry-run mode.")
        return {"ok": true, "errors": [], "dry_run": true, "helper": helper, "request": request_path}
    if OS.get_name() != "Windows" or not FileAccess.file_exists(helper):
        return _operation_failure("The external Windows updater helper is unavailable.", true)
    var session := get_node_or_null("/root/SessionRecovery")
    if session != null and session.has_method("mark_update_handoff"): session.call("mark_update_handoff")
    var pid := OS.create_process(helper, ["--request", request_path], false)
    if pid <= 0: return _operation_failure("The external updater helper could not start.", true)
    _busy = true
    _set_state(&"handoff", "Verified update handed to the external updater. PlayWorld Studio will close safely.")
    if quit_after_handoff: get_tree().call_deferred("quit", 0)
    return {"ok": true, "errors": [], "pid": pid, "request": request_path}


func _cleanup_abandoned_partials() -> void:
    var absolute_root := ProjectSettings.globalize_path(STAGING_ROOT)
    if not DirAccess.dir_exists_absolute(absolute_root): return
    _remove_partials_recursive(absolute_root)

func _remove_partials_recursive(absolute_root: String) -> void:
    var directory := DirAccess.open(absolute_root)
    if directory == null: return
    directory.list_dir_begin()
    var entry := directory.get_next()
    while not entry.is_empty():
        var child := absolute_root.path_join(entry)
        if directory.current_is_dir():
            _remove_partials_recursive(child)
        elif entry.ends_with(".part"):
            DirAccess.remove_absolute(child)
        entry = directory.get_next()
    directory.list_dir_end()

func _check_failure(message: String, offline: bool) -> Dictionary:
    _busy = false
    _preferences.record_check(false, "offline" if offline else "failed", message)
    _set_state(&"offline" if offline else &"failed", message)
    operation_failed.emit(message, true)
    return {"ok": false, "errors": [message], "offline": offline}

func _verification_failure(message: String) -> Dictionary:
    _busy = false
    if not _staged_path.is_empty() and FileAccess.file_exists(_staged_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(_staged_path))
    _journal.fail(message, true)
    return _operation_failure(message, true)

func _operation_failure(message: String, recoverable: bool) -> Dictionary:
    _busy = false
    _set_state(&"failed", message)
    operation_failed.emit(message, recoverable)
    return {"ok": false, "errors": [message], "recoverable": recoverable}

func _set_state(value: StringName, message: String) -> void:
    if not STATES.has(str(value)): value = &"failed"
    _state = value
    _last_message = message
    state_changed.emit(_state, snapshot())
