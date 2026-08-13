extends Node

const ProductIdentity = preload("res://src/release/product_identity.gd")
const ProjectRepository = preload("res://src/world/project_repository.gd")
const UserPreferences = preload("res://src/scale/user_preferences.gd")
const ExportPipeline = preload("res://src/export/export_pipeline.gd")
const PerformanceProfiles = preload("res://src/scale/performance_profiles.gd")

const STATE_PATH := "user://phase18-release-state.json"
const ACCEPTANCE_STATE_PATH := "user://phase17-release-state.json"
const ASSET_ROOT := "user://phase18-release-assets"
const EXPORTED_GAME_NAME := "Phase18CreatorExport"
const VISUAL_ROOT := "user://phase18-visual"

var _mode := ""

func _ready() -> void:
    _mode = _argument_value("--phase18-release-smoke=")
    if not _mode.is_empty(): call_deferred("_run")

func _run() -> void:
    for _frame in range(5): await get_tree().process_frame
    var errors: Array[String] = []
    match _mode:
        "first": errors = await _run_first()
        "reopen": errors = await _run_reopen(false)
        "readonly": errors = await _run_reopen(true)
        "upgrade": errors = await _run_upgrade()
        "visual": errors = await _capture_visuals()
        _: errors.append("Unknown Phase 18 stable release verification mode.")
    if errors.is_empty():
        print(_pass_marker(_mode)); get_tree().quit(0); return
    for error in errors: push_error(error)
    get_tree().quit(1)

func _run_first() -> Array[String]:
    var errors: Array[String] = []
    if ProductIdentity.version() != "0.1.0" or ProductIdentity.CHANNEL != "stable": errors.append("Packaged creator does not report stable 0.1.0 identity.")
    errors.append_array(_verify_user_paths())
    var maintenance := get_node_or_null("/root/ReleaseMaintenance")
    if maintenance == null: return errors + ["Stable release maintenance service is unavailable."]
    var migration: Dictionary = maintenance.call("run_startup_migration")
    if not migration.get("ok", false): errors.append("Stable migration failed: %s" % str(migration.get("errors", [])))
    var preferences := UserPreferences.defaults(); preferences["density"] = "compact"; preferences["ui_scale"] = 1.1; preferences["reduced_motion"] = true
    var pref_saved: Dictionary = UserPreferences.new().save_preferences(preferences)
    if not pref_saved.get("ok", false): errors.append("Stable preferences could not be persisted.")
    if not errors.is_empty(): return errors
    var main := get_tree().current_scene
    if main == null or main.name != "Main": return ["Stable packaged creator did not reach Main."]
    main.call("_on_new_world_create_requested", {"title": "Phase 18 Stable Gate", "world_profile": "medium", "template_id": "third_person_adventure", "biome_preset": "meadow"})
    for _frame in range(5): await get_tree().process_frame
    var project = main.get("_active_project")
    if project == null: return ["Stable packaged creator failed to create a project."]
    var workspace := main.get_node_or_null("WorkspaceScreen")
    if workspace == null: return ["Stable packaged creator is missing the workspace."]
    var begin: Dictionary = workspace.call("begin_proxy_placement", "Stable Release Entity")
    if not begin.get("ok", false): errors.append("Stable placement could not begin.")
    workspace.call("update_placement_preview", Vector3(2.0, 1.0, 3.0))
    var placed: Dictionary = workspace.call("commit_placement")
    var entity_id := str(placed.get("entity_id", ""))
    if not placed.get("ok", false) or entity_id.is_empty(): errors.append("Stable placement could not commit an entity.")
    var source_result: Dictionary = workspace.call("register_asset_source", ProjectSettings.globalize_path(ASSET_ROOT), "Phase 18 Release Assets") if _prepare_asset_fixture().is_empty() else {"ok": false}
    if not source_result.get("ok", false): errors.append("Stable Asset Library source registration failed.")
    var library = workspace.call("get_asset_library")
    if library == null: errors.append("Stable Asset Library is unavailable.")
    else:
        var scan: Dictionary = library.scan_all()
        if not scan.get("ok", false): errors.append("Stable Asset Library scan failed.")
    var repository = main.get("_project_repository")
    var saved: Dictionary = repository.save_project(project)
    if not saved.get("ok", false): errors.append("Stable authored project could not be saved.")
    if not errors.is_empty(): return errors
    var project_directory: String = repository.get_project_directory(str(project.project_id))
    var export_result: Dictionary = ExportPipeline.new().export_windows(project, project_directory, library, "user://phase18-release-exports", EXPORTED_GAME_NAME, PerformanceProfiles.get_profile("balanced"))
    if not export_result.get("ok", false): return ["Stable packaged creator could not export a standalone Windows game: %s" % str(export_result.get("errors", []))]
    var executable := str(export_result.get("executable_path", ""))
    if not FileAccess.file_exists(executable): return ["Stable creator export did not produce a Windows executable."]
    OS.set_environment("POLYFORK_EXPORT_SMOKE", "1")
    var output: Array = []; var exit_code := OS.execute(ProjectSettings.globalize_path(executable), PackedStringArray(["--headless"]), output, true, false)
    OS.set_environment("POLYFORK_EXPORT_SMOKE", "")
    var game_log := "\n".join(PackedStringArray(output.map(func(value): return str(value))))
    if exit_code != 0 or not game_log.contains("PASS: Phase 13 standalone export runtime smoke completed."): errors.append("Stable creator-to-game export launch did not complete.")
    if game_log.contains("SCRIPT ERROR:") or game_log.contains("ERROR:"): errors.append("Stable exported game emitted strict runtime errors.")
    var support: Dictionary = maintenance.call("create_support_bundle")
    if not support.get("ok", false): errors.append("Stable support bundle generation failed.")
    var state := {"version": ProductIdentity.version(), "project_id": str(project.project_id), "entity_id": entity_id, "asset_relative_path": "release_gate.gltf", "exported_game": ProjectSettings.globalize_path(executable)}
    errors.append_array(_write_state(STATE_PATH, state)); errors.append_array(_write_state(ACCEPTANCE_STATE_PATH, state))
    return errors

func _run_reopen(readonly: bool) -> Array[String]:
    var state_result := _read_state(STATE_PATH)
    if not state_result.get("ok", false): return state_result.get("errors", [])
    var state: Dictionary = state_result.get("state", {})
    var repository = ProjectRepository.new(str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects")))
    var opened: Dictionary = repository.open_project(str(state.get("project_id", "")))
    if not opened.get("ok", false): return ["Stable creator could not reopen persisted authored project: %s" % str(opened.get("errors", []))]
    var preferences: Dictionary = UserPreferences.new().load_preferences()
    var errors: Array[String] = []
    if not preferences.get("ok", false) or str(preferences.get("settings", {}).get("density", "")) != "compact": errors.append("Stable preferences did not persist across restart/reinstall.")
    if ProductIdentity.version() != "0.1.0": errors.append("Reopened creator lost stable identity.")
    if readonly:
        var probe := FileAccess.open("user://phase18-readonly-install-probe.txt", FileAccess.WRITE)
        if probe == null: errors.append("Stable creator could not write user data outside a read-only-style install.")
        else: probe.store_string("user-data-only"); probe.close()
    return errors

func _run_upgrade() -> Array[String]:
    var legacy := _read_state(ACCEPTANCE_STATE_PATH)
    if not legacy.get("ok", false): return ["Real RC upgrade state is missing."]
    var state: Dictionary = legacy.get("state", {})
    if str(state.get("version", "")) != "0.1.0-rc.1": return ["Upgrade fixture was not authored by PlayWorld Studio 0.1.0-rc.1."]
    var repository = ProjectRepository.new(str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects")))
    var opened: Dictionary = repository.open_project(str(state.get("project_id", "")))
    if not opened.get("ok", false): return ["Stable release could not open the RC-authored world."]
    var prefs := UserPreferences.new().load_preferences()
    if not prefs.get("ok", false) or str(prefs.get("settings", {}).get("density", "")) != "compact": return ["RC user preferences were not preserved into stable."]
    var maintenance := get_node_or_null("/root/ReleaseMaintenance")
    var migration: Dictionary = maintenance.call("run_startup_migration") if maintenance != null else {"ok": false}
    if not migration.get("ok", false): return ["RC to stable migration did not complete safely."]
    if ProductIdentity.version() != "0.1.0": return ["RC upgrade did not land on stable 0.1.0 identity."]
    return []

func _capture_visuals() -> Array[String]:
    var errors: Array[String] = []
    var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(VISUAL_ROOT))
    if make_error not in [OK, ERR_ALREADY_EXISTS]: return ["Could not create stable visual evidence directory."]
    var main := get_tree().current_scene
    if main == null: return ["Stable visual gate did not reach Main."]
    get_window().size = Vector2i(1280, 720)
    main.call("_show_home")
    for _frame in range(3): await get_tree().process_frame
    var home := main.get_node_or_null("HomeScreen")
    if home == null: return ["Stable visual gate cannot find Home."]
    var about_button := home.get_node_or_null("SafeArea/Content/Header/HeaderActions/AboutButton")
    if about_button == null:
        errors.append("Stable visual gate cannot find the real About action.")
    else:
        about_button.emit_signal("pressed")
        for _frame in range(3): await get_tree().process_frame
        var overlay := home.get_node_or_null("HomeCreatorOverlay")
        errors.append_array(_verify_about_overlay(overlay, true))
        errors.append_array(_capture("09-about-version-1280x720.png"))
        home.call("_close_creator_overlay")
    home.call("_open_settings")
    for _frame in range(3): await get_tree().process_frame
    errors.append_array(_capture("10-settings-1280x720.png"))
    home.call("_close_settings")
    var maintenance := get_node_or_null("/root/ReleaseMaintenance")
    if maintenance == null: errors.append("Stable support/recovery surface is unavailable.")
    else:
        maintenance.call("show_support_panel")
        for _frame in range(3): await get_tree().process_frame
        errors.append_array(_capture("11-support-recovery-1280x720.png"))
    return errors

func _verify_about_overlay(overlay, require_renderable: bool) -> Array[String]:
    if overlay == null: return ["About/version action did not create the Home overlay."]
    if not overlay.has_method("presentation_state"): return ["Home overlay does not expose verifiable presentation state."]
    var state: Dictionary = overlay.call("presentation_state")
    var errors: Array[String] = []
    if not bool(state.get("visible", false)): errors.append("About/version overlay is not visible after the real About action.")
    if str(state.get("title", "")) != "About PlayWorld Studio": errors.append("About/version overlay title is incorrect.")
    var expected_subtitle := "%s  •  stable  •  Windows x64" % ProductIdentity.version()
    if str(state.get("subtitle", "")) != expected_subtitle: errors.append("About/version overlay does not expose the exact stable version/channel/platform identity.")
    var status := str(state.get("status", ""))
    if not status.contains("Godot %s" % ProductIdentity.GODOT_VERSION): errors.append("About/version overlay does not expose the Godot runtime identity.")
    if not status.contains("source %s" % ProductIdentity.short_commit()): errors.append("About/version overlay does not expose the source identity.")
    if not bool(state.get("topmost", false)): errors.append("About/version overlay is not the topmost Home surface.")
    if require_renderable:
        for key in ["title_renderable", "subtitle_renderable", "status_renderable", "covers_parent"]:
            if not bool(state.get(key, false)): errors.append("About/version overlay failed renderability assertion: %s" % key)
    return errors

func _verify_user_paths() -> Array[String]:
    var errors: Array[String] = []; var install_root := OS.get_executable_path().get_base_dir().replace("\\", "/").simplify_path().trim_suffix("/")
    for user_path in ["user://projects", "user://asset_library", "user://scale_polish.cfg", "user://release", "user://support"]:
        var resolved := ProjectSettings.globalize_path(user_path).replace("\\", "/").simplify_path()
        if resolved == install_root or resolved.begins_with(install_root + "/"): errors.append("Persistent user data resolves inside the installation directory: %s" % user_path)
    return errors

func _prepare_asset_fixture() -> Array[String]:
    var absolute_root := ProjectSettings.globalize_path(ASSET_ROOT)
    if DirAccess.make_dir_recursive_absolute(absolute_root) not in [OK, ERR_ALREADY_EXISTS]: return ["Could not create stable Asset Library fixture."]
    var handle := FileAccess.open(ASSET_ROOT.path_join("release_gate.gltf"), FileAccess.WRITE)
    if handle == null: return ["Could not create stable GLTF fixture."]
    handle.store_string('{"asset":{"version":"2.0","generator":"Phase18StableGate"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"name":"StableGate"}]}'); handle.close(); return []

func _capture(name: String) -> Array[String]:
    var save_error := get_viewport().get_texture().get_image().save_png(VISUAL_ROOT.path_join(name))
    return [] if save_error == OK else ["Could not save stable visual evidence: %s" % name]

func _write_state(path: String, state: Dictionary) -> Array[String]:
    var handle := FileAccess.open(path, FileAccess.WRITE)
    if handle == null: return ["Could not persist stable restart verification state."]
    handle.store_string(JSON.stringify(state, "  ")); handle.close(); return []

func _read_state(path: String) -> Dictionary:
    if not FileAccess.file_exists(path): return {"ok": false, "errors": ["Release verification state is missing."], "state": {}}
    var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not value is Dictionary: return {"ok": false, "errors": ["Release verification state is malformed."], "state": {}}
    return {"ok": true, "errors": [], "state": value}

func _argument_value(prefix: String) -> String:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with(prefix): return argument.substr(prefix.length())
    return ""

func _pass_marker(mode: String) -> String:
    match mode:
        "first": return "PASS: Phase 18 stable packaged creator first-run authoring and creator-to-game export completed."
        "reopen": return "PASS: Phase 18 stable packaged creator restart/reopen persistence completed."
        "readonly": return "PASS: Phase 18 stable packaged creator read-only-install user-data separation completed."
        "upgrade": return "PASS: Phase 18 real 0.1.0-rc.1 to 0.1.0 upgrade preservation completed."
        "visual": return "PASS: Phase 18 stable About, Settings, Support, and Recovery visual evidence captured."
    return "PASS: Phase 18 stable release verification completed."
