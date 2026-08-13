extends Node

const ProjectRepository = preload("res://src/world/project_repository.gd")
const UserPreferences = preload("res://src/scale/user_preferences.gd")

const STATE_PATH := "user://phase17-release-state.json"
const OUTPUT_ROOT := "user://phase17-acceptance"

func _ready() -> void:
    if OS.get_cmdline_user_args().has("--phase17-acceptance"):
        call_deferred("_run")

func _run() -> void:
    var errors: Array[String] = []
    for _frame in range(4): await get_tree().process_frame
    var main := get_tree().current_scene
    if main == null or main.name != "Main":
        _finish(["Packaged acceptance did not reach Main."])
        return
    var home := main.get_node_or_null("HomeScreen")
    var new_world := main.get_node_or_null("NewWorldScreen")
    var workspace := main.get_node_or_null("WorkspaceScreen")
    if home == null or new_world == null or workspace == null:
        _finish(["Packaged acceptance is missing required creator screens."])
        return
    var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_ROOT))
    if make_error not in [OK, ERR_ALREADY_EXISTS]:
        _finish(["Could not create packaged acceptance evidence directory."])
        return

    var preferences: Dictionary = UserPreferences.new().load_preferences()
    var settings: Dictionary = preferences.get("settings", {})
    if not preferences.get("ok", false): errors.append("Packaged creator could not reload persisted accessibility/preferences state.")
    if str(settings.get("density", "")) != "compact" or not bool(settings.get("reduced_motion", false)):
        errors.append("Packaged creator lost persisted density/reduced-motion preferences.")
    var missing_preferences := "user://phase17-intentionally-missing-preferences.cfg"
    if FileAccess.file_exists(missing_preferences): DirAccess.remove_absolute(ProjectSettings.globalize_path(missing_preferences))
    var missing_loaded: Dictionary = UserPreferences.new(missing_preferences).load_preferences()
    if not missing_loaded.get("ok", false) or missing_loaded.get("settings", {}) != UserPreferences.defaults():
        errors.append("Missing preference files do not resolve to safe defaults.")

    get_window().size = Vector2i(1600, 900)
    main.call("_show_home")
    for _frame in range(3): await get_tree().process_frame
    home.call("focus_primary")
    await get_tree().process_frame
    errors.append_array(_expect_focus("CreateButton", "Home primary focus"))
    errors.append_array(await _joy_focus(JOY_BUTTON_DPAD_RIGHT, "ui_right", "ContinueButton", "Home gamepad right navigation"))
    errors.append_array(_capture("01-home-1600x900.png"))

    get_window().size = Vector2i(1280, 720)
    for _frame in range(3): await get_tree().process_frame
    errors.append_array(_capture("02-home-1280x720.png"))
    get_window().size = Vector2i(960, 600)
    for _frame in range(3): await get_tree().process_frame
    errors.append_array(_capture("03-home-compact.png"))
    get_window().size = Vector2i(1280, 720)

    home.call("_open_asset_library_overlay")
    for _frame in range(3): await get_tree().process_frame
    var overlay = home.get("_creator_overlay")
    if overlay == null or not overlay.visible: errors.append("Packaged Home Asset Library surface did not open.")
    errors.append_array(_capture("04-asset-library-1280x720.png"))
    home.call("_close_creator_overlay")

    main.call("_show_new_world")
    for _frame in range(3): await get_tree().process_frame
    new_world.call("focus_primary")
    await get_tree().process_frame
    errors.append_array(_expect_focus("WorldNameEdit", "New World primary focus"))
    errors.append_array(await _joy_focus(JOY_BUTTON_DPAD_DOWN, "ui_down", "MediumButton", "New World gamepad down navigation"))
    errors.append_array(_capture("05-new-world-1280x720.png"))

    var state_result := _read_state()
    if not state_result.get("ok", false):
        errors.append_array(state_result.get("errors", []))
        _finish(errors)
        return
    var state: Dictionary = state_result.get("state", {})
    var repository = ProjectRepository.new(str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects")))
    var project_id := str(state.get("project_id", ""))
    var discovered := false
    for candidate in repository.list_projects():
        if str(candidate.project_id) == project_id:
            discovered = true
            break
    if not discovered: errors.append("Packaged creator project discovery did not find the persisted world.")
    var opened: Dictionary = repository.open_project(project_id)
    var project = opened.get("project")
    if not opened.get("ok", false) or project == null:
        errors.append("Packaged acceptance could not reopen the persisted project.")
        _finish(errors)
        return
    if not bool(main.call("_activate_project", project)):
        errors.append("Packaged acceptance could not activate the persisted project.")
        _finish(errors)
        return
    main.call("_show_workspace", project.to_dictionary())
    for _frame in range(4): await get_tree().process_frame
    workspace.call("focus_primary")
    await get_tree().process_frame
    errors.append_array(_expect_focus("BuildButton", "Workspace primary focus"))
    errors.append_array(await _joy_focus(JOY_BUTTON_DPAD_RIGHT, "ui_right", "PlayButton", "Workspace gamepad Build-to-Play navigation"))
    errors.append_array(_capture("06-workspace-1280x720.png"))

    var mode_switch := workspace.get_node_or_null("TopBar/TopMargin/TopRow/ModeSlot/ModeSwitch")
    if mode_switch == null:
        errors.append("Packaged acceptance could not find the Build/Play mode switch.")
    else:
        var accept_event := InputEventJoypadButton.new()
        accept_event.button_index = JOY_BUTTON_A
        accept_event.pressed = true
        if not accept_event.is_action("ui_accept"): errors.append("Gamepad A is not mapped to the semantic UI accept action.")
        mode_switch.call("set_mode", &"play")
        for _frame in range(4): await get_tree().process_frame
        if workspace.call("get_mode") != &"play": errors.append("Packaged acceptance failed to enter Instant Play.")
        errors.append_array(_capture("07-instant-play-1280x720.png"))
        mode_switch.call("set_mode", &"build")
        for _frame in range(3): await get_tree().process_frame

    var export_layer := get_node_or_null("/root/ExportWorkspace")
    if export_layer == null:
        errors.append("Packaged acceptance could not find the Export workspace layer.")
    else:
        var bind_result: Dictionary = export_layer.call("bind_workspace", workspace)
        if not bind_result.get("ok", false): errors.append("Packaged acceptance could not bind the Export surface.")
        export_layer.call("open_panel")
        for _frame in range(3): await get_tree().process_frame
        if not bool(export_layer.call("is_panel_open")): errors.append("Packaged Export surface did not open.")
        errors.append_array(_capture("08-export-1280x720.png"))
        export_layer.call("close_panel")

    _finish(errors)

func _joy_focus(button_index: JoyButton, action: String, expected_name: String, label: String) -> Array[String]:
    var errors: Array[String] = []
    var press := InputEventJoypadButton.new()
    press.button_index = button_index
    press.pressed = true
    if not press.is_action(action):
        errors.append("%s is not mapped through a real joypad event." % label)
        return errors
    Input.parse_input_event(press)
    await get_tree().process_frame
    var release := InputEventJoypadButton.new()
    release.button_index = button_index
    release.pressed = false
    Input.parse_input_event(release)
    await get_tree().process_frame
    errors.append_array(_expect_focus(expected_name, label))
    return errors

func _expect_focus(expected_name: String, label: String) -> Array[String]:
    var owner := get_viewport().gui_get_focus_owner()
    if owner == null: return ["%s has no focused control." % label]
    if owner.name != expected_name: return ["%s expected %s but focused %s." % [label, expected_name, owner.name]]
    return []

func _capture(name: String) -> Array[String]:
    var image := get_viewport().get_texture().get_image()
    var save_error := image.save_png(OUTPUT_ROOT.path_join(name))
    return [] if save_error == OK else ["Could not save packaged acceptance evidence: %s" % name]

func _read_state() -> Dictionary:
    if not FileAccess.file_exists(STATE_PATH): return {"ok": false, "errors": ["Packaged acceptance restart state is missing."], "state": {}}
    var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(STATE_PATH))
    if not value is Dictionary: return {"ok": false, "errors": ["Packaged acceptance restart state is malformed."], "state": {}}
    return {"ok": true, "errors": [], "state": value}

func _finish(errors: Array[String]) -> void:
    if errors.is_empty():
        print("PASS: Phase 17 packaged creator UI, controller, accessibility, and major-screen acceptance completed.")
        get_tree().quit(0)
        return
    for error in errors: push_error(error)
    get_tree().quit(1)
