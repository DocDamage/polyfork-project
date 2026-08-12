extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const MAIN_SCENE := "res://src/main/Main.tscn"

static func run_checks(tree_root: Node) -> Array[String]:
    var errors: Array[String] = []
    var old_root: Variant = ProjectSettings.get_setting("playworld/storage/projects_root", null)
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://tests/phase11_workspace_%s" % StableId.generate())
    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null:
        _restore_root(old_root)
        return ["Phase 11 workspace suite must load the real Main scene."]
    var app = packed.instantiate()
    tree_root.add_child(app)
    var home := app.get_node_or_null("HomeScreen") as Control
    var new_world := app.get_node_or_null("NewWorldScreen") as Control
    var workspace := app.get_node_or_null("WorkspaceScreen") as Control
    if home == null or new_world == null or workspace == null:
        errors.append("Phase 11 workspace requires the real app screens.")
    else:
        home.emit_signal("route_requested", &"new_world")
        new_world.emit_signal("create_requested", {"title": "Phase 11 Workspace", "world_profile": "small", "template_id": "blank_sandbox"})
        if not workspace.visible: errors.append("Phase 11 workspace must enter the real project workspace.")
        else: _check_workspace(app, workspace, errors)
    app.queue_free()
    _restore_root(old_root)
    return errors

static func _check_workspace(app: Control, workspace: Control, errors: Array[String]) -> void:
    var layer = app.call("get_environment_workspace")
    var water_button := workspace.find_child("WaterButton", true, false) as Button
    if layer == null or water_button == null:
        errors.append("Real workspace must retain the canonical Water dock entry and attach the Phase 11 Environment layer.")
        return
    var service = layer.call("get_service")
    var runtime = layer.call("get_runtime")
    var panel = layer.call("get_panel")
    if service == null or runtime == null or panel == null:
        errors.append("Environment workspace must bind its authored service, Build runtime, and authoring panel.")
        return
    if not runtime.call("is_rendering_enabled"):
        errors.append("Build mode must render the authored environment through the real viewport.")

    water_button.emit_signal("pressed")
    if not layer.call("is_open"):
        errors.append("Canonical Water dock entry must open the coherent Environment workspace.")
        return
    var new_profile := _button(panel, "New Profile")
    var add_water := _button(panel, "Add Water Hook")
    var use_weather := _button(panel, "Use Weather Here")
    if new_profile == null or add_water == null or use_weather == null:
        errors.append("Environment workspace must expose weather, biome coupling, and water authoring controls.")
        return

    new_profile.emit_signal("pressed")
    if service.get_weather_profiles().size() != 2:
        errors.append("Environment panel weather creation must author a stable project-managed profile.")
    var authored_before_time: float = float(service.get_state().authored_state.get("time_of_day_hours", -1.0))
    var shoulder := InputEventJoypadButton.new()
    shoulder.button_index = JOY_BUTTON_RIGHT_SHOULDER
    shoulder.pressed = true
    layer.call("_unhandled_input", shoulder)
    var authored_after_time: float = float(service.get_state().authored_state.get("time_of_day_hours", -1.0))
    if is_equal_approx(authored_before_time, authored_after_time):
        errors.append("Gamepad shoulder authoring must command-back time-of-day changes.")

    var fog_before: bool = bool(service.get_state().authored_state.get("fog_enabled", true))
    var fog_toggle := InputEventJoypadButton.new()
    fog_toggle.button_index = JOY_BUTTON_Y
    fog_toggle.pressed = true
    layer.call("_unhandled_input", fog_toggle)
    if bool(service.get_state().authored_state.get("fog_enabled", true)) == fog_before:
        errors.append("Gamepad Y must toggle authored fog through the Environment command path.")

    add_water.emit_signal("pressed")
    if service.get_water_hooks().size() != 1:
        errors.append("Environment panel must create stable water integration hooks without requiring a hardcoded provider.")
    use_weather.emit_signal("pressed")
    if service.get_biome_overrides().size() != 1:
        errors.append("Environment panel must author Phase 5 biome/weather coupling.")
    if not workspace.call("undo_edit").get("ok", false):
        errors.append("Universal workspace Undo must revert Environment authoring.")
    elif service.get_biome_overrides().size() != 0:
        errors.append("Undoing biome environment coupling must restore the previous authored environment snapshot.")

    var mode_switch = workspace.find_child("ModeSwitch", true, false)
    if mode_switch == null:
        errors.append("Phase 11 workspace requires the real Build/Play switch.")
    else:
        mode_switch.call("set_mode", &"play")
        var play_session = workspace.call("get_play_session")
        if not play_session.is_active(): errors.append("Real Build/Play switch must enter Play with the Phase 11 environment provider.")
        if runtime.call("is_rendering_enabled"): errors.append("Build Environment renderer must be disabled before disposable Play rendering starts.")
        if layer.call("is_open"): errors.append("Entering Play must close Environment authoring controls.")
        mode_switch.call("set_mode", &"build")
        if play_session.is_active(): errors.append("Returning to Build must dispose the Play environment session.")
        if not runtime.call("is_rendering_enabled"): errors.append("Returning to Build must restore authored Environment rendering.")

    water_button.emit_signal("pressed")
    var cancel := InputEventAction.new()
    cancel.action = &"ui_cancel"
    cancel.pressed = true
    app.call("_unhandled_input", cancel)
    if layer.call("is_open") or not workspace.visible:
        errors.append("Back/Cancel must close Environment before leaving the workspace.")

static func _button(root: Node, text_value: String) -> Button:
    for node in root.find_children("*", "Button", true, false):
        var button := node as Button
        if button != null and button.text == text_value: return button
    return null

static func _restore_root(old_root: Variant) -> void:
    if old_root == null: ProjectSettings.set_setting("playworld/storage/projects_root", null)
    else: ProjectSettings.set_setting("playworld/storage/projects_root", old_root)
