extends RefCounted

const HomeScene = preload("res://src/app/screens/home/HomeScreen.tscn")

static func run_checks(tree: SceneTree) -> Array[String]:
    var errors: Array[String] = []
    var home: Control = HomeScene.instantiate()
    tree.root.add_child(home)
    await tree.process_frame
    var create_button := home.get_node_or_null("SafeArea/Content/Hub/CreateButton") as Button
    var settings_button := home.get_node_or_null("SafeArea/Content/Header/HeaderActions/SettingsButton") as Button
    if create_button == null or settings_button == null:
        errors.append("Phase 14 Home accessibility fixture must expose canonical interactive controls.")
    else:
        if create_button.focus_mode != Control.FOCUS_ALL or settings_button.focus_mode != Control.FOCUS_ALL: errors.append("Primary Home controls must be keyboard/gamepad focusable.")
        if create_button.custom_minimum_size.y < 44.0 or settings_button.custom_minimum_size.y < 44.0: errors.append("Interactive controls must preserve a touch-ready minimum target height.")
        var scale_service: Node = tree.root.get_node_or_null("ScalePolish")
        if scale_service == null:
            errors.append("Phase 14 scale/accessibility service must be available application-wide.")
        else:
            var joy := InputEventJoypadButton.new(); joy.button_index = JOY_BUTTON_A; joy.pressed = true
            scale_service.call("_input", joy)
            if not create_button.tooltip_text.begins_with("A"): errors.append("Controller input must switch visible control hints to gamepad glyphs.")
            var key := InputEventKey.new(); key.keycode = KEY_ENTER; key.pressed = true
            scale_service.call("_input", key)
            if not create_button.tooltip_text.begins_with("Enter"): errors.append("Keyboard input must restore keyboard control hints.")
        settings_button.pressed.emit()
        await tree.process_frame
        var settings_screen := home.get_node_or_null("SettingsScreen") as Control
        if settings_screen == null or not settings_screen.visible: errors.append("Settings must be reachable without pointer-only interaction.")
        else:
            var preset := settings_screen.find_child("PresetOption", true, false) as OptionButton
            var back := settings_screen.find_child("BackButton", true, false) as Button
            if preset == null or back == null or preset.focus_mode != Control.FOCUS_ALL or back.focus_mode != Control.FOCUS_ALL: errors.append("Settings controls must participate in focus navigation.")
            if preset != null and preset.custom_minimum_size.y < 44.0: errors.append("Settings selection controls must remain touch-ready.")
    home.queue_free()
    await tree.process_frame
    return errors
