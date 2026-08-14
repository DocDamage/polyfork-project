extends SceneTree

const SemanticVersion = preload("res://src/release/semantic_version.gd")
const UpdateManifest = preload("res://src/release/update_manifest.gd")
const UpdatePreferences = preload("res://src/release/update_preferences.gd")
const UpdateJournal = preload("res://src/release/update_journal.gd")
const UpdateServiceScript = preload("res://src/release/update_service.gd")
const SessionRecoveryScript = preload("res://src/release/session_recovery_service.gd")
const MigrationRegistry = preload("res://src/release/data_migration_registry.gd")
const ReleasePaths = preload("res://src/release/release_paths.gd")
const ProductIdentity = preload("res://src/release/product_identity.gd")
const ProjectRepository = preload("res://src/world/project_repository.gd")

const FIXTURE_ROOT := "res://tests/fixtures/phase19"
const FIXTURE_NOW := 1786665600

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var errors: Array[String] = []
    errors.append_array(_semantic_version_contracts())
    errors.append_array(_signed_manifest_contracts())
    errors.append_array(_preference_and_channel_contracts())
    errors.append_array(_journal_contracts())
    errors.append_array(_migration_contracts())
    errors.append_array(await _update_service_contracts())
    errors.append_array(await _ui_and_recovery_contracts())
    errors.append_array(_diagnostic_privacy_contracts())
    _cleanup_runtime_nodes()
    await process_frame
    if errors.is_empty():
        print("PASS: Phase 19 update, signature, channel, migration, recovery, diagnostics, and UI contracts completed.")
        quit(0)
        return
    for error in errors: push_error(error)
    quit(1)

func _cleanup_runtime_nodes() -> void:
    for node in root.get_children():
        node.queue_free()

func _semantic_version_contracts() -> Array[String]:
    var errors: Array[String] = []
    for value in ["0.1.0", "0.2.0", "1.0.0-rc.1", "1.2.3+build.9"]:
        if not SemanticVersion.parse(value).get("ok", false): errors.append("Valid semantic version was rejected: %s" % value)
    for value in ["", "01.0.0", "1.0", "1.0.0-01", "1.0.0+"]:
        if SemanticVersion.parse(value).get("ok", false): errors.append("Invalid semantic version was accepted: %s" % value)
    if SemanticVersion.compare("0.2.0", "0.1.0") <= 0: errors.append("Semantic version upgrade comparison failed.")
    if SemanticVersion.compare("1.0.0-rc.1", "1.0.0") >= 0: errors.append("Prerelease precedence is invalid.")
    if SemanticVersion.compare("1.0.0+one", "1.0.0+two") != 0: errors.append("Build metadata incorrectly changes precedence.")
    return errors

func _signed_manifest_contracts() -> Array[String]:
    var errors: Array[String] = []
    var registry_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_ROOT.path_join("test_keys.json")))
    if not registry_value is Dictionary: return ["Phase 19 test key registry is malformed."]
    var registry: Dictionary = registry_value
    var accepted := _validate_fixture("accepted-update.json", registry, "0.1.0", "development", "portable")
    if not accepted.get("ok", false) or not accepted.get("is_update", false): errors.append("Real RSA/SHA-256 signed update fixture was not accepted: %s" % str(accepted.get("errors", [])))
    var installed := _validate_fixture("accepted-update.json", registry, "0.1.0", "development", "installed")
    if not installed.get("ok", false) or str(installed.get("artifact", {}).get("kind", "")) != "installer": errors.append("Installed mode did not select the signed installer artifact.")
    var current := _validate_fixture("accepted-update.json", registry, "0.2.0", "development", "portable")
    if not current.get("ok", false) or current.get("is_update", true): errors.append("Same-version signed metadata was not recognized as current.")
    for fixture in ["wrong-product.json", "wrong-channel.json", "wrong-platform.json", "unsafe-filename.json", "future-publication.json", "minimum-updater.json", "duplicate-artifacts.json", "unknown-field.json"]:
        if _validate_fixture(fixture, registry, "0.1.0", "development", "portable").get("ok", false): errors.append("Invalid signed manifest fixture was accepted: %s" % fixture)
    if _validate_fixture("stable-prerelease.json", registry, "0.2.0", "stable", "portable").get("ok", false): errors.append("Stable channel accepted a prerelease build.")
    if _validate_fixture("downgrade.json", registry, "0.2.0", "development", "portable").get("ok", false): errors.append("Unauthorized downgrade was accepted.")
    var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_ROOT.path_join("accepted-update.json")))
    var altered_signature := envelope.duplicate(true)
    var signature := str(altered_signature.get("signature", "")); altered_signature["signature"] = ("A" if not signature.begins_with("A") else "B") + signature.substr(1)
    if UpdateManifest.validate_envelope(altered_signature, registry, "0.1.0", "development", "portable", false, FIXTURE_NOW).get("ok", false): errors.append("Altered manifest signature was accepted.")
    var altered_payload := envelope.duplicate(true)
    var payload := str(altered_payload.get("payload", "")); altered_payload["payload"] = ("A" if not payload.begins_with("A") else "B") + payload.substr(1)
    if UpdateManifest.validate_envelope(altered_payload, registry, "0.1.0", "development", "portable", false, FIXTURE_NOW).get("ok", false): errors.append("Altered signed payload was accepted.")
    var revoked := registry.duplicate(true); revoked["keys"][0]["revoked"] = true
    if _validate_fixture("accepted-update.json", revoked, "0.1.0", "development", "portable").get("ok", false): errors.append("Revoked signing key was accepted.")
    if UpdateManifest.validate_text(FileAccess.get_file_as_string(FIXTURE_ROOT.path_join("accepted-update.json")), registry, "0.1.0", "development", "portable", false, 1900000000).get("ok", false): errors.append("Expired signing key was accepted.")
    var wrong_channel_key := registry.duplicate(true); wrong_channel_key["keys"][0]["channels"] = ["stable"]
    if _validate_fixture("accepted-update.json", wrong_channel_key, "0.1.0", "development", "portable").get("ok", false): errors.append("Wrong-channel signing key was accepted.")
    return errors

func _validate_fixture(filename: String, registry: Dictionary, current: String, channel: String, mode: String) -> Dictionary:
    return UpdateManifest.validate_text(FileAccess.get_file_as_string(FIXTURE_ROOT.path_join(filename)), registry, current, channel, mode, false, FIXTURE_NOW)

func _preference_and_channel_contracts() -> Array[String]:
    var errors: Array[String] = []
    var path := "user://phase19-tests/update-preferences.cfg"
    ProjectSettings.set_setting("playworld/release/allow_development_channel", true)
    var preferences := UpdatePreferences.new(path)
    var initial := preferences.load_preferences()
    if not initial.get("ok", false) or str(initial.get("settings", {}).get("channel", "")) != "stable": errors.append("Stable is not the default update channel.")
    if not preferences.set_channel("beta").get("ok", false) or preferences.selected_channel() != "beta": errors.append("Beta channel preference did not persist.")
    if not preferences.set_channel("development").get("ok", false) or preferences.selected_channel() != "development": errors.append("Development channel opt-in did not persist.")
    if preferences.set_channel("nightly").get("ok", false): errors.append("Unknown update channel was accepted.")
    if not preferences.is_url_allowed("https://raw.githubusercontent.com/DocDamage/polyfork-project/master/update.json", "development"): errors.append("Authorized development host was rejected.")
    if preferences.is_url_allowed("https://example.invalid/update.json", "development"): errors.append("Unauthorized channel host was accepted.")
    preferences.record_check(false, "offline", "offline fixture")
    var after_failure: Dictionary = preferences.load_preferences().get("settings", {})
    if int(after_failure.get("consecutive_failures", 0)) != 1 or int(after_failure.get("next_allowed_check_unix", 0)) <= int(after_failure.get("last_check_unix", 0)): errors.append("Update-check backoff was not recorded.")
    ProjectSettings.set_setting("playworld/release/allow_development_channel", false)
    return errors

func _journal_contracts() -> Array[String]:
    var errors: Array[String] = []
    var journal := UpdateJournal.new("user://phase19-tests/update-journal.json")
    if not journal.begin("portable_update", {"fixture": true}).get("ok", false): return ["Update journal could not begin."]
    if journal.begin("installed_update", {"fixture": true}).get("ok", false): errors.append("Active update journal was silently overwritten.")
    for stage in ["downloading", "downloaded", "verifying", "verified", "handoff", "backing_up", "replacing", "restart_pending"]:
        if not journal.transition(stage).get("ok", false): errors.append("Update journal could not transition to %s." % stage)
    if not journal.append_completed_path("PlayWorld Studio.exe").get("ok", false): errors.append("Safe replacement path was rejected by update journal.")
    if journal.append_completed_path("../project.json").get("ok", false): errors.append("Unsafe replacement path entered update journal.")
    if not journal.complete({"version": "0.2.0"}).get("ok", false): errors.append("Update journal could not complete.")
    var snapshot := journal.recovery_snapshot()
    if snapshot.get("available", true) or not snapshot.get("backup_available", false) and str(snapshot.get("stage", "")) != "completed": errors.append("Completed update journal recovery state is invalid.")
    if not journal.mark_rollback_pending("fixture rollback").get("ok", false): errors.append("Completed update journal could not enter explicit rollback.")
    var archived := journal.archive_current("fixture_archive")
    if not archived.get("ok", false) or not archived.get("archived", false) or not FileAccess.file_exists(str(archived.get("path", ""))): errors.append("Update journal could not preserve recovery evidence before a replacement operation.")
    if not journal.begin("repair", {"fixture": true}).get("ok", false): errors.append("Archived journal did not allow a new repair operation.")
    journal.complete({"fixture": true})
    return errors

func _migration_contracts() -> Array[String]:
    var errors: Array[String] = []
    var project_root := "user://phase19-tests/projects"
    ProjectSettings.set_setting("playworld/storage/projects_root", project_root)
    var repository = ProjectRepository.new(project_root)
    var created: Dictionary = repository.create_project("Phase 19 Migration Fixture", &"small", "third_person_adventure")
    var project = created.get("project")
    if not created.get("ok", false) or project == null: return ["Migration project fixture could not be created."]
    var path := repository.get_manifest_path(str(project.project_id))
    var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
    document["schema_version"] = 0
    document.erase("runtime")
    var write := ReleasePaths.atomic_write_json(path, document)
    if not write.get("ok", false): return ["Migration project fixture could not be downgraded."]
    var registry := MigrationRegistry.new()
    registry.call("_register_builtin_steps")
    var migrated: Dictionary = registry.migrate_project_file(path)
    if not migrated.get("ok", false) or not migrated.get("migrated", false) or str(migrated.get("backup_path", "")).is_empty(): errors.append("Sequential project migration did not create a backup and reach schema 1.")
    var idempotent: Dictionary = registry.migrate_project_file(path)
    if not idempotent.get("ok", false) or idempotent.get("migrated", true): errors.append("Project migration is not idempotent.")
    var future: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path)); future["schema_version"] = 99; ReleasePaths.atomic_write_json(path, future)
    if not registry.migrate_project_file(path).get("unsupported_future", false): errors.append("Unsupported future project schema was not refused.")
    return errors

func _update_service_contracts() -> Array[String]:
    var errors: Array[String] = []
    var previous_version := str(ProjectSettings.get_setting("application/config/version", "0.2.0"))
    # Exercise the 0.1.0 -> 0.2.0 update path while the project remains a
    # 0.2.0 release candidate for the rest of the contract suite.
    ProjectSettings.set_setting("application/config/version", "0.1.0")
    ProjectSettings.set_setting("playworld/release/allow_development_channel", true)
    ProjectSettings.set_setting("playworld/release/trust_registry_path", FIXTURE_ROOT.path_join("test_keys.json"))
    ProjectSettings.set_setting("playworld/release/dry_run_updates", true)
    ProjectSettings.set_setting("playworld/release/development_install_mode", "portable")
    UpdatePreferences.new().set_auto_check(false)
    var service := UpdateServiceScript.new()
    root.add_child(service)
    await process_frame
    var channel: Dictionary = service.set_channel("development")
    if not channel.get("ok", false): errors.append("Update service could not opt into Development for the signed fixture.")
    var accepted: Dictionary = service.check_for_updates(true, FileAccess.get_file_as_string(FIXTURE_ROOT.path_join("accepted-update.json")))
    if not accepted.get("ok", false) or service.state() != &"available": errors.append("Nonblocking update service did not accept verified signed metadata.")
    var staged := "user://phase19-tests/PlayWorld-Studio-0.2.0-Windows-x64.zip"
    var handle := FileAccess.open(staged, FileAccess.WRITE)
    if handle == null: errors.append("Could not create staged artifact fixture.")
    else:
        handle.store_buffer("phase19-artifact".to_utf8_buffer()); handle.close()
        var digest: Dictionary = ReleasePaths.sha256_file(staged)
        var artifact := {"kind": "portable", "filename": staged.get_file(), "size": int(digest.get("size", 0)), "sha256": str(digest.get("sha256", ""))}
        var prepared: Dictionary = service.prepare_staged_artifact_for_validation(staged, {"version": "0.2.0", "source_commit": "0123456789abcdef0123456789abcdef01234567"}, artifact)
        if not prepared.get("ok", false): errors.append("Staged artifact could not enter validation: %s" % str(prepared.get("errors", [])))
        var verified: Dictionary = service.verify_staged_artifact(staged)
        if not verified.get("ok", false) or service.state() != &"ready": errors.append("Exact byte-count/SHA-256 staging verification failed.")
        var handoff: Dictionary = service.install_ready_update(true)
        if not handoff.get("ok", false) or not handoff.get("dry_run", false): errors.append("Verified update did not reach safe external-helper handoff dry run.")
    service.queue_free()
    await process_frame
    ProjectSettings.set_setting("application/config/version", previous_version)
    ProjectSettings.set_setting("playworld/release/allow_development_channel", false)
    ProjectSettings.set_setting("playworld/release/trust_registry_path", "res://config/release/update_keys.json")
    return errors

func _ui_and_recovery_contracts() -> Array[String]:
    var errors: Array[String] = []
    var scene_resource := load("res://src/app/screens/settings/SettingsScreen.tscn") as PackedScene
    if scene_resource == null: return ["Phase 19 Settings/Update Center scene cannot load."]
    var screen := scene_resource.instantiate()
    root.add_child(screen)
    await process_frame
    var update_center := screen.get_node_or_null("SafeArea/Content/Scroll/Stack/UpdateCenter")
    if update_center == null: errors.append("Production Update Center is missing from Settings.")
    else:
        for name in ["CheckButton", "DownloadButton", "InstallButton", "RepairButton", "RollbackButton", "SafeModeButton", "DiagnosticsButton", "SupportButton"]:
            var control := update_center.find_child(name, true, false) as Control
            if control == null or not control.visible: errors.append("Update Center control is missing or hidden: %s" % name)
        update_center.call("present_evidence_state", "downloading", {"downloaded": 5242880, "download_total": 10485760, "available_version": "0.2.1", "release_notes": "Evidence state"})
        var progress := update_center.find_child("DownloadProgress", true, false) as ProgressBar
        if progress == null or progress.value < 49.0: errors.append("Update Center did not render active download progress.")
    var accept_event := InputEventJoypadButton.new(); accept_event.button_index = JOY_BUTTON_A; accept_event.pressed = true
    if not accept_event.is_action("ui_accept"): errors.append("Gamepad A no longer maps to semantic ui_accept.")
    screen.queue_free(); await process_frame
    var session := root.get_node_or_null("SessionRecovery")
    if session == null: errors.append("Session recovery autoload is missing.")
    else:
        if not session.call("set_safe_mode", true).get("ok", false) or not session.call("is_safe_mode"): errors.append("Safe mode did not persist.")
        if OS.get_environment("PLAYWORLD_DISABLE_UPDATE_NETWORK") != "1" or OS.get_environment("PLAYWORLD_DISABLE_MULTIPLAYER") != "1": errors.append("Safe mode did not suppress optional network activity.")
        var reset: Dictionary = session.call("reset_preferences_non_destructive")
        if not reset.get("ok", false) or not reset.get("projects_preserved", false): errors.append("Non-destructive preference reset did not preserve the project boundary.")
        session.call("set_safe_mode", false)
        if OS.get_environment("PLAYWORLD_DISABLE_UPDATE_NETWORK") == "1" or OS.get_environment("PLAYWORLD_DISABLE_MULTIPLAYER") == "1": errors.append("Safe-mode network suppression did not clear when safe mode ended.")
        session.call("acknowledge_recovery")
    return errors

func _diagnostic_privacy_contracts() -> Array[String]:
    var errors: Array[String] = []
    if ProductIdentity.version() != "0.2.0" or ProductIdentity.package_name() != "PlayWorld-Studio-0.2.0-Windows-x64": errors.append("Product/package identity is not PlayWorld Studio 0.2.0.")
    var maintenance := root.get_node_or_null("ReleaseMaintenance")
    if maintenance == null: return errors + ["Phase 19 ReleaseMaintenance autoload is missing."]
    var report: Dictionary = maintenance.call("diagnostic_report")
    for key in ["product", "update", "migration", "session_recovery", "privacy", "recent_application_errors", "exporter", "project_schema_version"]:
        if not report.has(key): errors.append("Bounded diagnostics are missing field: %s" % key)
    var text := JSON.stringify(report)
    if text.contains(ProjectSettings.globalize_path("user://")) or text.contains("BEGIN PRIVATE KEY") or text.to_lower().contains("openai_api_key"): errors.append("Diagnostic report leaks absolute paths or credential material.")
    var bundle: Dictionary = maintenance.call("create_support_bundle")
    if not bundle.get("ok", false) or not bundle.get("privacy_checked", false): errors.append("Privacy-checked support bundle was not generated.")
    return errors
