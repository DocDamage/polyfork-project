extends Node

const ProductIdentity = preload("res://src/release/product_identity.gd")
const ProjectRepository = preload("res://src/world/project_repository.gd")
const UserPreferences = preload("res://src/scale/user_preferences.gd")
const ExportPipeline = preload("res://src/export/export_pipeline.gd")
const PerformanceProfiles = preload("res://src/scale/performance_profiles.gd")

const STATE_PATH := "user://phase19-release-state.json"
const PHASE18_STATE_PATH := "user://phase18-release-state.json"
const EXPORT_ROOT := "user://phase19-release-exports"
const VISUAL_ROOT := "user://phase19-visual"
const EXPORTED_GAME_NAME := "Phase19CreatorExport"

var _mode := ""

func _ready() -> void:
    _mode = _argument_value("--phase19-release-smoke=")
    if not _mode.is_empty(): call_deferred("_run")

func _run() -> void:
    for _frame in range(6): await get_tree().process_frame
    var errors: Array[String] = []
    match _mode:
        "first": errors = await _run_first()
        "reopen": errors = await _run_reopen()
        "upgrade": errors = await _run_upgrade()
        "offline": errors = await _run_offline()
        "visual": errors = await _capture_visuals()
        _: errors.append("Unknown Phase 19 release verification mode.")
    var session := get_node_or_null("/root/SessionRecovery")
    if session != null and session.has_method("mark_clean_shutdown"): session.call("mark_clean_shutdown")
    if errors.is_empty():
        print(_pass_marker(_mode)); get_tree().quit(0); return
    for error in errors: push_error(error)
    get_tree().quit(1)

func _run_first() -> Array[String]:
    var errors := _identity_and_boundary_errors()
    var main := get_tree().current_scene
    if main == null or main.name != "Main": return errors + ["Phase 19 packaged creator did not reach Main."]
    main.call("_on_new_world_create_requested", {"title": "Phase 19 Update Gate", "world_profile": "medium", "template_id": "third_person_adventure", "biome_preset": "meadow"})
    for _frame in range(5): await get_tree().process_frame
    var project = main.get("_active_project")
    var workspace := main.get_node_or_null("WorkspaceScreen")
    if project == null or workspace == null: return errors + ["Phase 19 packaged creator could not create and enter a real project."]
    var begin: Dictionary = workspace.call("begin_proxy_placement", "Phase 19 Entity")
    if not begin.get("ok", false): errors.append("Phase 19 placement could not begin.")
    workspace.call("update_placement_preview", Vector3(4.0, 1.0, 2.0))
    var placed: Dictionary = workspace.call("commit_placement")
    if not placed.get("ok", false): errors.append("Phase 19 placement could not commit.")
    errors.append_array(await _exercise_build_play(workspace))
    var repository = main.get("_project_repository")
    var saved: Dictionary = repository.save_project(project)
    if not saved.get("ok", false): errors.append("Phase 19 project could not be saved.")
    var checkpoint: Dictionary = repository.create_checkpoint(project)
    if not checkpoint.get("ok", false): errors.append("Phase 19 project checkpoint could not be created.")
    var library = workspace.call("get_asset_library")
    errors.append_array(_export_and_launch(project, repository.get_project_directory(str(project.project_id)), library))
    if not errors.is_empty(): return errors
    return _write_state({"version": ProductIdentity.version(), "project_id": str(project.project_id), "entity_id": str(placed.get("entity_id", "")), "created_at_unix": int(Time.get_unix_time_from_system())})

func _run_reopen() -> Array[String]:
    var state := _read_state(STATE_PATH)
    if not state.get("ok", false): return state.get("errors", [])
    var repository = ProjectRepository.new(str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects")))
    var opened: Dictionary = repository.open_project(str(state.get("state", {}).get("project_id", "")))
    if not opened.get("ok", false): return ["Phase 19 packaged creator could not reopen its persisted project."]
    var project = opened.get("project")
    var errors := _identity_and_boundary_errors()
    if project == null: errors.append("Reopened project object is missing.")
    else:
        var saved: Dictionary = repository.save_project(project)
        if not saved.get("ok", false): errors.append("Reopened Phase 19 project could not be saved again.")
    var preferences := UserPreferences.new().load_preferences()
    if not preferences.get("ok", false): errors.append("User preferences did not reopen after Phase 19 restart.")
    return errors

func _run_upgrade() -> Array[String]:
    var legacy := _read_state(PHASE18_STATE_PATH)
    if not legacy.get("ok", false): return ["Exact PlayWorld Studio 0.1.0 upgrade state is missing."]
    var legacy_state: Dictionary = legacy.get("state", {})
    if str(legacy_state.get("version", "")) != "0.1.0": return ["Upgrade source state was not authored by exact PlayWorld Studio 0.1.0."]
    var errors := _identity_and_boundary_errors()
    var migration := get_node_or_null("/root/DataMigration")
    if migration == null: return errors + ["Sequential migration registry is unavailable after upgrade."]
    var migration_result: Dictionary = migration.get("startup_result")
    if not migration_result.get("ok", false): errors.append("0.1.0 to 0.2.0 migration failed: %s" % str(migration_result.get("errors", [])))
    if str(migration_result.get("target_version", "")) != "0.2.0": errors.append("Migration did not reach application data version 0.2.0.")
    var repository = ProjectRepository.new(str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects")))
    var opened: Dictionary = repository.open_project(str(legacy_state.get("project_id", "")))
    var project = opened.get("project")
    if not opened.get("ok", false) or project == null: return errors + ["0.2.0 could not open the exact 0.1.0-authored world."]
    var preferences := UserPreferences.new().load_preferences()
    if not preferences.get("ok", false) or str(preferences.get("settings", {}).get("density", "")) != "compact": errors.append("0.1.0 preferences were not preserved into 0.2.0.")
    var main := get_tree().current_scene
    if main == null: return errors + ["Upgraded creator did not reach Main."]
    if not bool(main.call("_activate_project", project)): errors.append("Upgraded project could not be activated.")
    main.call("_show_workspace", project.to_dictionary())
    for _frame in range(4): await get_tree().process_frame
    var workspace := main.get_node_or_null("WorkspaceScreen")
    if workspace == null: return errors + ["Upgraded creator workspace is missing."]
    var placement: Dictionary = workspace.call("begin_proxy_placement", "Post-upgrade Entity")
    if placement.get("ok", false):
        workspace.call("update_placement_preview", Vector3(1.0, 1.0, 1.0))
        placement = workspace.call("commit_placement")
    if not placement.get("ok", false): errors.append("Continued authoring failed after 0.1.0 to 0.2.0 upgrade.")
    errors.append_array(await _exercise_build_play(workspace))
    var saved: Dictionary = repository.save_project(project)
    if not saved.get("ok", false): errors.append("Upgraded project could not be saved.")
    var project_directory := repository.get_project_directory(str(project.project_id))
    var project_backup_preserved := false
    for value in migration_result.get("backups", []):
        if not value is Dictionary: continue
        var record: Dictionary = value
        var source := str(record.get("source", "")).replace("\\", "/")
        var backup := str(record.get("backup", ""))
        if source.ends_with("/%s/project.json" % str(project.project_id)) and FileAccess.file_exists(backup):
            project_backup_preserved = true
            break
    if not project_backup_preserved: errors.append("The exact 0.1.0 project migration backup was not preserved through upgrade.")
    var checkpoint: Dictionary = repository.create_checkpoint(project)
    if not checkpoint.get("ok", false): errors.append("Upgraded project checkpoint/recovery data could not be established.")
    var checkpoint_root := repository.get_checkpoint_directory(str(project.project_id))
    if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(checkpoint_root)): errors.append("Upgraded project checkpoint/recovery directory is missing.")
    var library = workspace.call("get_asset_library")
    errors.append_array(_export_and_launch(project, project_directory, library))
    var maintenance := get_node_or_null("/root/ReleaseMaintenance")
    if maintenance == null: errors.append("Release diagnostics are unavailable after upgrade.")
    else:
        var bundle: Dictionary = maintenance.call("create_support_bundle")
        if not bundle.get("ok", false): errors.append("Support bundle generation failed after upgrade.")
    if errors.is_empty():
        _write_state({"version": "0.2.0", "project_id": str(project.project_id), "upgraded_from": "0.1.0", "upgrade_completed_at_unix": int(Time.get_unix_time_from_system())})
    return errors

func _run_offline() -> Array[String]:
    var errors := await _run_reopen()
    var service := get_node_or_null("/root/UpdateService")
    if service == null: return errors + ["Update service is unavailable for offline-failure proof."]
    var result: Dictionary = service.call("check_for_updates", true)
    if result.get("ok", false): errors.append("Network-disabled update check was accepted.")
    var snapshot: Dictionary = service.call("snapshot")
    if str(snapshot.get("state", "")) not in ["offline", "failed"]: errors.append("Update failure did not reach a bounded offline/failure state.")
    var state := _read_state(STATE_PATH)
    if state.get("ok", false):
        var repository = ProjectRepository.new(str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects")))
        var opened: Dictionary = repository.open_project(str(state.get("state", {}).get("project_id", "")))
        var project = opened.get("project")
        if not opened.get("ok", false) or project == null:
            errors.append("Ordinary project use failed after update endpoint failure.")
        else:
            var main := get_tree().current_scene
            if main != null and bool(main.call("_activate_project", project)):
                main.call("_show_workspace", project.to_dictionary())
                for _frame in range(3): await get_tree().process_frame
                var workspace := main.get_node_or_null("WorkspaceScreen")
                if workspace != null:
                    errors.append_array(await _exercise_build_play(workspace))
                    errors.append_array(_export_and_launch(project, repository.get_project_directory(str(project.project_id)), workspace.call("get_asset_library")))
                else: errors.append("Offline workspace could not be reached.")
            else: errors.append("Offline project could not be activated.")
    return errors

func _capture_visuals() -> Array[String]:
    var errors: Array[String] = []
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(VISUAL_ROOT)) not in [OK, ERR_ALREADY_EXISTS]: return ["Could not create Phase 19 visual evidence directory."]
    var main := get_tree().current_scene
    if main == null: return ["Phase 19 visual gate did not reach Main."]
    var home := main.get_node_or_null("HomeScreen")
    if home == null: return ["Phase 19 visual gate cannot find Home."]
    home.call("_open_settings")
    for _frame in range(5): await get_tree().process_frame
    var settings := home.find_child("SettingsScreen", true, false)
    if settings == null: settings = main.find_child("SettingsScreen", true, false)
    if settings == null: return ["Real Settings action did not open the Settings/Update Center surface."]
    var update_center := settings.find_child("UpdateCenter", true, false)
    if update_center == null or not update_center.visible: return ["Update Center is not active and renderable after opening Settings."]
    var states := [
        {"name": "01-updates-idle", "state": "idle", "details": {"message": "Updates are optional and never block offline creator use."}},
        {"name": "02-channel-selection", "state": "idle", "details": {"channel": "beta", "message": "Beta channel selected. Stable remains the default."}},
        {"name": "03-update-available", "state": "available", "details": {"available_version": "0.2.1", "message": "PlayWorld Studio 0.2.1 is available."}},
        {"name": "04-release-notes", "state": "available", "details": {"available_version": "0.2.1", "release_notes": "Safer updates, improved recovery, and creator workflow fixes."}},
        {"name": "05-downloading", "state": "downloading", "details": {"available_version": "0.2.1", "downloaded": 73400320, "download_total": 146800640, "message": "Downloading verified portable package…"}},
        {"name": "06-verifying", "state": "verifying", "details": {"available_version": "0.2.1", "downloaded": 146800640, "download_total": 146800640, "message": "Verifying exact size and SHA-256…"}},
        {"name": "07-ready-install", "state": "ready", "details": {"available_version": "0.2.1", "message": "Update verified and ready to install."}},
        {"name": "08-update-failure", "state": "failed", "details": {"message": "The downloaded package failed verification. The installed application was not changed."}},
        {"name": "09-repair", "state": "recovery", "details": {"message": "Repair is available from the last verified package."}},
        {"name": "10-rollback", "state": "recovery", "details": {"message": "Previous verified application binaries are available for rollback.", "journal": {"stage": "rollback_pending", "backup_available": true}}},
    ]
    get_window().size = Vector2i(1280, 720)
    for record in states:
        update_center.call("present_evidence_state", str(record["state"]), record["details"])
        for _frame in range(3): await get_tree().process_frame
        errors.append_array(_verify_update_center_state(update_center, str(record["state"])))
        errors.append_array(_capture_png("%s-1280x720.png" % str(record["name"])))
    update_center.call("_show_diagnostics")
    for _frame in range(2): await get_tree().process_frame
    errors.append_array(_capture_png("11-diagnostics-1280x720.png"))
    update_center.call("_create_support_bundle")
    for _frame in range(2): await get_tree().process_frame
    errors.append_array(_capture_png("12-support-bundle-1280x720.png"))
    var session := get_node_or_null("/root/SessionRecovery")
    if session != null:
        session.call("show_recovery_screen_for_evidence")
        for _frame in range(5): await get_tree().process_frame
        var overlay := main.find_child("Phase19RecoveryOverlay", true, false)
        if overlay == null or not overlay.visible: errors.append("Abnormal-shutdown recovery screen is not active for visual capture.")
        errors.append_array(_capture_png("13-abnormal-shutdown-recovery-1280x720.png"))
        session.call("set_safe_mode", true)
        errors.append_array(_capture_png("14-safe-mode-1280x720.png"))
        if overlay != null: overlay.hide()
    get_window().size = Vector2i(960, 600)
    update_center.call("apply_compact_layout", true)
    update_center.call("present_evidence_state", "available", {"available_version": "0.2.1", "release_notes": "Compact layout remains readable and controller navigable."})
    for _frame in range(4): await get_tree().process_frame
    errors.append_array(_capture_png("15-updates-compact-960x600.png"))
    get_window().size = Vector2i(1600, 900)
    update_center.call("apply_compact_layout", false)
    for _frame in range(4): await get_tree().process_frame
    errors.append_array(_capture_png("16-updates-normal-1600x900.png"))
    var evidence := {"schema_version": 1, "screenshots": states.size() + 6, "surface": "Settings/UpdateCenter", "active_control_count": int((update_center.call("focus_controls") as Array).size()), "captured_at_unix": int(Time.get_unix_time_from_system())}
    var handle := FileAccess.open(VISUAL_ROOT.path_join("evidence.json"), FileAccess.WRITE)
    if handle == null: errors.append("Could not write Phase 19 visual evidence metadata.")
    else: handle.store_string(JSON.stringify(evidence, "  ", true)); handle.close()
    return errors

func _verify_update_center_state(center: Node, expected: String) -> Array[String]:
    var errors: Array[String] = []
    var status := center.find_child("UpdateStatusLabel", true, false) as Label
    var check := center.find_child("CheckButton", true, false) as Button
    var progress := center.find_child("DownloadProgress", true, false) as ProgressBar
    if status == null or status.text.strip_edges().is_empty(): errors.append("Update Center state has no readable status: %s" % expected)
    if check == null or not check.visible: errors.append("Update Center Check action is not renderable: %s" % expected)
    if expected == "downloading" and (progress == null or progress.value <= 0.0): errors.append("Downloading state has no visible progress.")
    return errors

func _identity_and_boundary_errors() -> Array[String]:
    var errors: Array[String] = []
    if ProductIdentity.version() != "0.2.0" or ProductIdentity.CHANNEL != "stable": errors.append("Packaged creator does not report stable 0.2.0 identity.")
    var install_root := OS.get_executable_path().get_base_dir().replace("\\", "/").simplify_path().trim_suffix("/")
    for user_path in ["user://projects", "user://asset_library", "user://release", "user://updates", "user://support"]:
        var resolved := ProjectSettings.globalize_path(user_path).replace("\\", "/").simplify_path()
        if resolved == install_root or resolved.begins_with(install_root + "/"): errors.append("Persistent user data resolves inside application binaries: %s" % user_path)
    return errors

func _exercise_build_play(workspace: Node) -> Array[String]:
    var errors: Array[String] = []
    var switch := workspace.get_node_or_null("TopBar/TopMargin/TopRow/ModeSlot/ModeSwitch")
    if switch == null: return ["Build/Play switch is unavailable."]
    switch.call("set_mode", &"play")
    for _frame in range(3): await get_tree().process_frame
    if workspace.call("get_mode") != &"play": errors.append("Instant Play failed.")
    switch.call("set_mode", &"build")
    for _frame in range(2): await get_tree().process_frame
    if workspace.call("get_mode") != &"build": errors.append("Return to Build failed.")
    return errors

func _export_and_launch(project, project_directory: String, library) -> Array[String]:
    var result: Dictionary = ExportPipeline.new().export_windows(project, project_directory, library, EXPORT_ROOT, EXPORTED_GAME_NAME, PerformanceProfiles.get_profile("balanced"))
    if not result.get("ok", false): return ["Creator-to-game Windows export failed: %s" % str(result.get("errors", []))]
    var executable := str(result.get("executable_path", ""))
    if not FileAccess.file_exists(executable): return ["Creator-to-game export did not produce an executable."]
    OS.set_environment("POLYFORK_EXPORT_SMOKE", "1")
    var output: Array = []
    var exit_code := OS.execute(ProjectSettings.globalize_path(executable), PackedStringArray(["--headless"]), output, true, false)
    OS.set_environment("POLYFORK_EXPORT_SMOKE", "")
    var text := "\n".join(PackedStringArray(output.map(func(value): return str(value))))
    if exit_code != 0 or not text.contains("PASS: Phase 13 standalone export runtime smoke completed."): return ["Exported game did not pass its runtime smoke."]
    if text.contains("SCRIPT ERROR:") or text.contains("ERROR:"): return ["Exported game emitted strict runtime errors."]
    return []

func _capture_png(filename: String) -> Array[String]:
    var error := get_viewport().get_texture().get_image().save_png(VISUAL_ROOT.path_join(filename))
    return [] if error == OK else ["Could not save Phase 19 visual evidence: %s" % filename]

func _write_state(state: Dictionary) -> Array[String]:
    var handle := FileAccess.open(STATE_PATH, FileAccess.WRITE)
    if handle == null: return ["Could not persist Phase 19 release state."]
    handle.store_string(JSON.stringify(state, "  ", true)); handle.close(); return []

func _read_state(path: String) -> Dictionary:
    if not FileAccess.file_exists(path): return {"ok": false, "errors": ["Release state is missing: %s" % path], "state": {}}
    var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not value is Dictionary: return {"ok": false, "errors": ["Release state is malformed: %s" % path], "state": {}}
    return {"ok": true, "errors": [], "state": value}

func _argument_value(prefix: String) -> String:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with(prefix): return argument.substr(prefix.length())
    return ""

func _pass_marker(mode: String) -> String:
    match mode:
        "first": return "PASS: Phase 19 packaged 0.2.0 first-run authoring, Play, save, checkpoint, and export completed."
        "reopen": return "PASS: Phase 19 packaged 0.2.0 restart and reopen preservation completed."
        "upgrade": return "PASS: Phase 19 real 0.1.0 to 0.2.0 project, preference, recovery, authoring, Play, and export upgrade completed."
        "offline": return "PASS: Phase 19 offline startup, project use, and update-endpoint failure isolation completed."
        "visual": return "PASS: Phase 19 update, recovery, diagnostics, support, normal, and compact visual evidence captured."
    return "PASS: Phase 19 release verification completed."
