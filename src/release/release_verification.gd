extends Node

const ProjectRepository = preload("res://src/world/project_repository.gd")
const UserPreferences = preload("res://src/scale/user_preferences.gd")
const ExportPipeline = preload("res://src/export/export_pipeline.gd")
const PerformanceProfiles = preload("res://src/scale/performance_profiles.gd")
const ProductIdentity = preload("res://src/release/product_identity.gd")

const STATE_PATH := "user://phase17-release-state.json"
const ASSET_ROOT := "user://phase17-release-assets"
const EXPORTED_GAME_NAME := "Phase17CreatorExport"

var _mode := ""

func _ready() -> void:
    _mode = _argument_value("--phase17-release-smoke=")
    if not _mode.is_empty(): call_deferred("_run")

func _run() -> void:
    for _frame in range(4): await get_tree().process_frame
    var errors: Array[String] = []
    match _mode:
        "first": errors = await _run_first_launch()
        "reopen": errors = await _run_reopen(false)
        "readonly": errors = await _run_reopen(true)
        "visual": errors = await _capture_visual_evidence()
        _: errors.append("Unknown Phase 17 release verification mode.")
    if errors.is_empty():
        print(_pass_marker(_mode))
        get_tree().quit(0)
        return
    for error in errors: push_error(error)
    get_tree().quit(1)

func _run_first_launch() -> Array[String]:
    var errors: Array[String] = []
    var main := get_tree().current_scene
    if main == null or main.name != "Main": return ["Packaged creator did not reach Main."]
    var home := main.get_node_or_null("HomeScreen")
    var new_world := main.get_node_or_null("NewWorldScreen")
    var workspace := main.get_node_or_null("WorkspaceScreen")
    if home == null or not home.visible: errors.append("Packaged creator did not reach Home.")
    if new_world == null or workspace == null: return errors + ["Packaged creator is missing required creator screens."]
    if ProductIdentity.version() != "0.1.0-rc.1": errors.append("Runtime product version does not match the release candidate.")
    errors.append_array(_verify_user_paths())
    errors.append_array(_verify_preferences())
    errors.append_array(_prepare_asset_fixture())
    if not errors.is_empty(): return errors

    main.call("_show_new_world")
    await get_tree().process_frame
    if not new_world.visible: errors.append("New World did not become visible from the packaged creator.")
    main.call("_on_new_world_create_requested", {
        "title": "Phase 17 Release Gate",
        "world_profile": "medium",
        "template_id": "third_person_adventure",
        "biome_preset": "meadow",
    })
    for _frame in range(4): await get_tree().process_frame
    var project = main.get("_active_project")
    if project == null: return errors + ["Packaged creator failed to create and activate a project."]
    if str(project.template_id) != "third_person_adventure": errors.append("Created project did not retain the selected real template.")
    if str(project.runtime_config.get("biome_preset", "")) != "meadow": errors.append("Created project did not retain the selected biome.")
    if not workspace.visible: errors.append("Packaged creator did not enter the workspace.")

    var begin: Dictionary = workspace.call("begin_proxy_placement", "Release Gate Entity")
    if not begin.get("ok", false): errors.append("Packaged creator could not begin real editor placement: %s" % str(begin.get("errors", [])))
    var preview: Dictionary = workspace.call("update_placement_preview", Vector3(2.0, 1.0, 3.0))
    if not preview.get("ok", false): errors.append("Packaged creator could not update placement preview.")
    var placed: Dictionary = workspace.call("commit_placement")
    var entity_id := str(placed.get("entity_id", ""))
    if not placed.get("ok", false) or entity_id.is_empty(): errors.append("Packaged creator could not commit a real editor entity.")
    var moved: Dictionary = workspace.call("nudge_selection", &"move", Vector3(1.0, 0.0, 0.0))
    if not moved.get("ok", false): errors.append("Packaged creator could not edit the placed entity transform.")

    var source_result: Dictionary = workspace.call("register_asset_source", ProjectSettings.globalize_path(ASSET_ROOT), "Phase 17 Release Assets")
    if not source_result.get("ok", false): errors.append("Packaged creator could not register a real shared Asset Library source: %s" % str(source_result.get("errors", [])))
    var library = workspace.call("get_asset_library")
    if library == null: errors.append("Workspace Asset Library is unavailable.")
    else:
        var scan: Dictionary = library.scan_all()
        if not scan.get("ok", false): errors.append("Packaged creator Asset Library scan failed: %s" % str(scan.get("errors", [])))
        var found := false
        for record in library.get_records(true):
            if str(record.get("relative_path", "")) == "release_gate.gltf": found = true; break
        if not found: errors.append("Packaged creator did not index the real GLTF source fixture.")

    var mode_switch := workspace.get_node_or_null("TopBar/TopMargin/TopRow/ModeSlot/ModeSwitch")
    if mode_switch == null: errors.append("Workspace Build/Play mode switch is unavailable.")
    else:
        mode_switch.call("set_mode", &"play")
        for _frame in range(3): await get_tree().process_frame
        if workspace.call("get_mode") != &"play": errors.append("Packaged creator failed to enter Instant Play.")
        mode_switch.call("set_mode", &"build")
        for _frame in range(2): await get_tree().process_frame
        if workspace.call("get_mode") != &"build": errors.append("Packaged creator failed to return from Instant Play.")

    var repository = main.get("_project_repository")
    var saved: Dictionary = repository.save_project(project)
    if not saved.get("ok", false): errors.append("Packaged creator could not save the authored project.")
    if not errors.is_empty(): return errors

    var project_directory: String = repository.get_project_directory(str(project.project_id))
    var export_result: Dictionary = ExportPipeline.new().export_windows(project, project_directory, library, "user://phase17-release-exports", EXPORTED_GAME_NAME, PerformanceProfiles.get_profile("balanced"))
    if not export_result.get("ok", false): return ["Packaged creator could not export a standalone Windows game: %s" % str(export_result.get("errors", []))]
    var executable := str(export_result.get("executable_path", ""))
    if not FileAccess.file_exists(executable): return ["Packaged creator export did not produce its Windows executable."]
    OS.set_environment("POLYFORK_EXPORT_SMOKE", "1")
    var output: Array = []
    var exit_code := OS.execute(ProjectSettings.globalize_path(executable), PackedStringArray(["--headless"]), output, true, false)
    OS.set_environment("POLYFORK_EXPORT_SMOKE", "")
    var game_log := "\n".join(PackedStringArray(output.map(func(value): return str(value))))
    if exit_code != 0: errors.append("Game exported by packaged creator exited %d." % exit_code)
    if not game_log.contains("PASS: Phase 13 standalone export runtime smoke completed."): errors.append("Game exported by packaged creator did not reach the standalone runtime marker.")
    if game_log.contains("SCRIPT ERROR:") or game_log.contains("ERROR:"): errors.append("Game exported by packaged creator emitted strict runtime errors.")
    if not errors.is_empty(): return errors

    var expected_position: Array = []
    for record in project.entity_records:
        if str(record.get("entity_id", "")) == entity_id:
            expected_position = record.get("transform", {}).get("position", []).duplicate()
            break
    return _write_state({
        "version": ProductIdentity.version(),
        "project_id": str(project.project_id),
        "entity_id": entity_id,
        "expected_position": expected_position,
        "asset_relative_path": "release_gate.gltf",
        "exported_game": ProjectSettings.globalize_path(executable),
    })

func _run_reopen(read_only_install: bool) -> Array[String]:
    var state_result := _read_state()
    if not state_result.get("ok", false): return state_result.get("errors", [])
    var state: Dictionary = state_result.get("state", {})
    var errors: Array[String] = _verify_user_paths()
    var repository = ProjectRepository.new(str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects")))
    var opened: Dictionary = repository.open_project(str(state.get("project_id", "")))
    var project = opened.get("project")
    if not opened.get("ok", false) or project == null: return errors + ["Packaged creator could not reopen the persisted project after restart."]
    var entity_id := str(state.get("entity_id", "")); var found := false
    for record in project.entity_records:
        if str(record.get("entity_id", "")) == entity_id:
            found = true
            if record.get("transform", {}).get("position", []) != state.get("expected_position", []): errors.append("Reopened authored entity transform does not match saved state.")
            break
    if not found: errors.append("Reopened project lost the authored entity.")
    var preferences := UserPreferences.new().load_preferences()
    if not preferences.get("ok", false) or str(preferences.get("settings", {}).get("density", "")) != "compact": errors.append("User settings did not persist across packaged creator restart.")

    var main := get_tree().current_scene
    if main == null or main.name != "Main": return errors + ["Reopened packaged creator did not reach Main."]
    if not bool(main.call("_activate_project", project)): return errors + ["Reopened packaged creator could not activate the persisted project."]
    main.call("_show_workspace", project.to_dictionary())
    for _frame in range(3): await get_tree().process_frame
    var workspace := main.get_node_or_null("WorkspaceScreen")
    if workspace == null or not workspace.visible: errors.append("Reopened packaged creator did not return to the workspace.")
    else:
        var library = workspace.call("get_asset_library")
        var asset_found := false
        if library != null:
            for record in library.get_records(true):
                if str(record.get("relative_path", "")) == str(state.get("asset_relative_path", "")): asset_found = true; break
        if not asset_found: errors.append("Shared Asset Library catalog did not persist across restart.")
    var save_result: Dictionary = repository.save_project(project)
    if not save_result.get("ok", false): errors.append("Reopened project could not be saved from per-user storage.")
    if read_only_install:
        var probe := FileAccess.open("user://phase17-readonly-install-probe.txt", FileAccess.WRITE)
        if probe == null: errors.append("Creator could not write user data while installed in a read-only-style location.")
        else: probe.store_string("user-data-only"); probe.close()
    return errors

func _verify_user_paths() -> Array[String]:
    var errors: Array[String] = []
    var install_root := OS.get_executable_path().get_base_dir().replace("\\", "/").simplify_path().trim_suffix("/")
    for user_path in ["user://projects", "user://asset_library", "user://scale_polish.cfg"]:
        var resolved := ProjectSettings.globalize_path(user_path).replace("\\", "/").simplify_path()
        if resolved == install_root or resolved.begins_with(install_root + "/"): errors.append("Persistent user data resolves inside the creator installation directory: %s" % user_path)
    return errors

func _verify_preferences() -> Array[String]:
    var settings := UserPreferences.defaults(); settings["density"] = "compact"; settings["ui_scale"] = 1.1; settings["reduced_motion"] = true
    var saved: Dictionary = UserPreferences.new().save_preferences(settings)
    if not saved.get("ok", false): return ["Could not persist creator preferences on clean first run."]
    var loaded: Dictionary = UserPreferences.new().load_preferences()
    if not loaded.get("ok", false) or str(loaded.get("settings", {}).get("density", "")) != "compact": return ["Creator preferences did not round-trip on clean first run."]
    var malformed_path := "user://phase17-malformed-preferences.cfg"
    var file := FileAccess.open(malformed_path, FileAccess.WRITE)
    if file == null: return ["Could not create malformed preference fixture."]
    file.store_string("[preferences\ninvalid"); file.close()
    var malformed: Dictionary = UserPreferences.new(malformed_path).load_preferences()
    if malformed.get("ok", false): return ["Malformed preference file did not fail explicitly."]
    if malformed.get("settings", {}) != UserPreferences.defaults(): return ["Malformed preference handling did not retain safe defaults."]
    return []

func _prepare_asset_fixture() -> Array[String]:
    var absolute_root := ProjectSettings.globalize_path(ASSET_ROOT)
    var make_error := DirAccess.make_dir_recursive_absolute(absolute_root)
    if make_error not in [OK, ERR_ALREADY_EXISTS]: return ["Could not create release Asset Library fixture directory."]
    var handle := FileAccess.open(ASSET_ROOT.path_join("release_gate.gltf"), FileAccess.WRITE)
    if handle == null: return ["Could not create release GLTF source fixture."]
    handle.store_string('{"asset":{"version":"2.0","generator":"Phase17ReleaseGate"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"name":"ReleaseGate"}]}')
    handle.close()
    return []

func _write_state(state: Dictionary) -> Array[String]:
    var handle := FileAccess.open(STATE_PATH, FileAccess.WRITE)
    if handle == null: return ["Could not persist Phase 17 restart verification state."]
    handle.store_string(JSON.stringify(state, "  ")); handle.close(); return []

func _read_state() -> Dictionary:
    if not FileAccess.file_exists(STATE_PATH): return {"ok": false, "errors": ["Phase 17 restart verification state is missing."], "state": {}}
    var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(STATE_PATH))
    if not value is Dictionary: return {"ok": false, "errors": ["Phase 17 restart verification state is malformed."], "state": {}}
    return {"ok": true, "errors": [], "state": value}

func _capture_visual_evidence() -> Array[String]:
    var main := get_tree().current_scene
    if main == null or main.name != "Main": return ["Packaged creator visual gate did not reach Main."]
    var output_root := "user://phase17-visual"
    var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_root))
    if make_error not in [OK, ERR_ALREADY_EXISTS]: return ["Could not create packaged creator visual evidence directory."]
    var captures := [
        {"size": Vector2i(1600, 900), "name": "01-home-1600x900.png"},
        {"size": Vector2i(1280, 720), "name": "02-home-1280x720.png"},
        {"size": Vector2i(960, 600), "name": "03-home-compact.png"},
    ]
    for item in captures:
        get_window().size = item["size"]
        main.call("_show_home")
        for _frame in range(4): await get_tree().process_frame
        var image := get_viewport().get_texture().get_image()
        var save_error := image.save_png(output_root.path_join(str(item["name"])))
        if save_error != OK: return ["Could not save packaged Home visual evidence."]
    get_window().size = Vector2i(1280, 720)
    main.call("_show_new_world")
    for _frame in range(4): await get_tree().process_frame
    if get_viewport().get_texture().get_image().save_png(output_root.path_join("04-new-world-1280x720.png")) != OK: return ["Could not save packaged New World visual evidence."]
    var state := _read_state()
    if state.get("ok", false):
        var repository = ProjectRepository.new(str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects")))
        var opened: Dictionary = repository.open_project(str(state.get("state", {}).get("project_id", "")))
        var project = opened.get("project")
        if opened.get("ok", false) and project != null:
            if bool(main.call("_activate_project", project)):
                main.call("_show_workspace", project.to_dictionary())
                for _frame in range(4): await get_tree().process_frame
                if get_viewport().get_texture().get_image().save_png(output_root.path_join("05-workspace-1280x720.png")) != OK: return ["Could not save packaged Workspace visual evidence."]
    return []

func _argument_value(prefix: String) -> String:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with(prefix): return arg.trim_prefix(prefix)
    return ""

func _pass_marker(mode: String) -> String:
    match mode:
        "first": return "PASS: Phase 17 packaged creator first-run authoring and creator-to-game export completed."
        "reopen": return "PASS: Phase 17 packaged creator restart/reopen verification completed."
        "readonly": return "PASS: Phase 17 packaged creator read-only-style install verification completed."
        "visual": return "PASS: Phase 17 packaged creator visual evidence captured."
        _: return "PASS: Phase 17 release verification completed."
