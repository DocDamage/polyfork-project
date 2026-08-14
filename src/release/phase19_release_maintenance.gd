extends "res://src/release/release_maintenance.gd"

const ReleasePaths = preload("res://src/release/release_paths.gd")
const ProductIdentityV2 = preload("res://src/release/product_identity.gd")
const SUPPORT_PATH_V2 := "user://support/PlayWorld-Support.json"
const ERROR_PATH := "user://release/recent_errors.json"
const MAX_RECENT_ERRORS := 20

func run_startup_migration() -> Dictionary:
    var service := get_node_or_null("/root/DataMigration")
    if service != null:
        var result: Variant = service.get("startup_result")
        if result is Dictionary and not result.is_empty(): return result
        if service.has_method("run_startup_migrations"): return service.call("run_startup_migrations")
    var registry_script = load("res://src/release/data_migration_registry.gd")
    if registry_script == null: return {"ok": false, "errors": ["Phase 19 migration registry is unavailable."]}
    var registry = registry_script.new()
    registry.call("_register_builtin_steps")
    return registry.call("run_startup_migrations")

func diagnostic_report() -> Dictionary:
    var base: Dictionary = super.diagnostic_report()
    base["schema_version"] = 2
    base["product"] = ProductIdentityV2.summary()
    base["build_source_commit"] = ProductIdentityV2.source_commit()
    base["directories"] = {
        "application": "application://",
        "user_data": "user://",
        "projects": "user://projects",
        "asset_library": "user://asset_library",
        "updates": "user://updates",
    }
    base["recent_application_errors"] = _recent_errors()
    var update_service := get_node_or_null("/root/UpdateService")
    base["update"] = update_service.call("snapshot") if update_service != null and update_service.has_method("snapshot") else {"state": "unavailable"}
    var migration_service := get_node_or_null("/root/DataMigration")
    var migration_snapshot: Dictionary = migration_service.call("snapshot") if migration_service != null and migration_service.has_method("snapshot") else {"state": startup_result.duplicate(true)}
    var migration_state: Dictionary = migration_snapshot.get("state", {})
    var completed_steps: Variant = migration_state.get("completed_steps", [])
    var backups: Variant = migration_state.get("backups", [])
    base["migration"] = {
        "target_application_version": str(migration_snapshot.get("target_application_version", ProductIdentityV2.version())),
        "application_version": str(migration_state.get("application_version", migration_state.get("target_version", ProductIdentityV2.version()))),
        "completed_steps": completed_steps.duplicate() if completed_steps is Array else [],
        "backup_count": backups.size() if backups is Array else 0,
        "journal_status": str(migration_snapshot.get("journal_status", "none")),
        "journal_step": str(migration_snapshot.get("journal_step", "")),
    }
    var session_service := get_node_or_null("/root/SessionRecovery")
    base["session_recovery"] = session_service.call("recovery_snapshot") if session_service != null and session_service.has_method("recovery_snapshot") else {"available": false}
    base["privacy"] = {
        "authored_project_content_included": false,
        "credentials_included": false,
        "absolute_user_paths_included": false,
        "local_only_until_user_shares": true,
    }
    return _sanitize_value(base)

func create_support_bundle() -> Dictionary:
    var report := diagnostic_report()
    var text := JSON.stringify(report, "  ", true)
    if _contains_secret_material(text):
        return {"ok": false, "errors": ["Support bundle was blocked because credential-like material was detected."]}
    for forbidden in ["project.json\"", "BEGIN PRIVATE KEY", "OPENAI_API_KEY", ".polyforkAPI"]:
        if text.contains(forbidden):
            return {"ok": false, "errors": ["Support bundle contains prohibited private material."]}
    var result := ReleasePaths.atomic_write_json(SUPPORT_PATH_V2, report)
    if not result.get("ok", false): return result
    result["path"] = "user://support/PlayWorld-Support.json"
    result["redacted_path"] = "user://support/PlayWorld-Support.json"
    result["privacy_checked"] = true
    return result

func report_recent_error(category: String, message: String, context: Dictionary = {}) -> Dictionary:
    var errors := _recent_errors()
    errors.append({
        "at_unix": int(Time.get_unix_time_from_system()),
        "category": category.left(64),
        "message": _sanitize_text(message).left(1024),
        "context": _sanitize_value(context),
    })
    while errors.size() > MAX_RECENT_ERRORS: errors.pop_front()
    return ReleasePaths.atomic_write_json(ERROR_PATH, {"schema_version": 1, "errors": errors})

func _recent_errors() -> Array:
    if not FileAccess.file_exists(ERROR_PATH): return []
    var read := ReleasePaths.read_json(ERROR_PATH)
    if not read.get("ok", false): return []
    var values: Variant = (read.get("value", {}) as Dictionary).get("errors", [])
    var result: Array = []
    if values is Array:
        for value in values:
            if value is Dictionary: result.append(_sanitize_value(value))
    return result

func _sanitize_value(value: Variant) -> Variant:
    if value is Dictionary:
        var result := {}
        for key in value.keys():
            var key_text := str(key)
            if key_text.to_lower() in ["api_key", "token", "authorization", "password", "secret", "private_key"]: continue
            result[key_text] = _sanitize_value(value[key])
        return result
    if value is Array:
        var result: Array = []
        for item in value: result.append(_sanitize_value(item))
        return result
    if value is String: return _sanitize_text(value)
    return value

func _sanitize_text(value: String) -> String:
    var text := value
    var user_root := ProjectSettings.globalize_path("user://").replace("\\", "/").trim_suffix("/")
    var app_root := ReleasePaths.application_root().replace("\\", "/").trim_suffix("/")
    text = text.replace("\\", "/")
    if not user_root.is_empty(): text = text.replace(user_root, "user://")
    if not app_root.is_empty(): text = text.replace(app_root, "application://")
    var secret_regex := RegEx.new()
    secret_regex.compile("(?i)sk-(?:proj-)?[a-z0-9_-]{16,}")
    text = secret_regex.sub(text, "<redacted-credential>", true)
    var windows_path_regex := RegEx.new()
    windows_path_regex.compile("(?i)[a-z]:/[^\r\n\t\"']+")
    text = windows_path_regex.sub(text, "<external-path>", true)
    var home_path_regex := RegEx.new()
    home_path_regex.compile("/(?:home|Users)/[^/\\s]+/[^\r\n\t\"']+")
    text = home_path_regex.sub(text, "<external-path>", true)
    return text
