extends Node

const MAIN_SCENE := "res://src/main/Main.tscn"


func run_checks() -> Dictionary:
    var errors: Array[String] = []
    var main_resource := load(MAIN_SCENE) as PackedScene

    if main_resource == null:
        errors.append("Main scene must load as a PackedScene.")
        return {"ok": false, "errors": errors}

    var main_instance := main_resource.instantiate()
    if main_instance == null:
        errors.append("Main scene must instantiate.")
        return {"ok": false, "errors": errors}

    add_child(main_instance)

    var home := main_instance.get_node_or_null("HomeScreen") as Control
    var new_world := main_instance.get_node_or_null("NewWorldScreen") as Control
    var workspace := main_instance.get_node_or_null("WorkspaceScreen") as Control

    if not main_instance is Control:
        errors.append("Main scene root must be a Control.")
    if home == null:
        errors.append("Home screen must be the initial application view.")
    else:
        _check_home(home, errors)
    if new_world == null:
        errors.append("New World screen must exist as an app route target.")
    if workspace == null:
        errors.append("Workspace screen must exist as an app route target.")

    if home != null and new_world != null and workspace != null:
        _exercise_routes(home, new_world, workspace, errors)

    main_instance.queue_free()
    return {"ok": errors.is_empty(), "errors": errors}


func _check_home(home: Control, errors: Array[String]) -> void:
    var title := home.get_node_or_null("SafeArea/Content/Header/TitleStack/Title") as Label
    if title == null or title.text != "PlayWorld Studio":
        errors.append("Home screen must display the PlayWorld Studio title.")

    var required_buttons := {
        "CreateButton": "Create New World",
        "ContinueButton": "Continue",
        "WorldsButton": "My Worlds",
        "TemplatesButton": "Templates",
        "AssetLibraryButton": "Asset Library"
    }

    for node_name in required_buttons:
        var button := home.find_child(node_name, true, false) as Button
        if button == null:
            errors.append("Home screen is missing %s." % required_buttons[node_name])
        elif not button.text.contains(required_buttons[node_name]):
            errors.append("Home action %s has unexpected text." % required_buttons[node_name])


func _exercise_routes(
    home: Control,
    new_world: Control,
    workspace: Control,
    errors: Array[String]
) -> void:
    if new_world.visible or workspace.visible:
        errors.append("Home must be the only initial route visible.")

    home.emit_signal("route_requested", &"new_world")
    _check_new_world_route(home, new_world, errors)

    new_world.emit_signal("back_requested")
    if not home.visible or new_world.visible:
        errors.append("Back from New World must return to Home.")

    home.emit_signal("route_requested", &"new_world")
    new_world.emit_signal("create_requested", {
        "title": "Smoke World",
        "world_profile": "medium",
        "template_id": "third_person_adventure"
    })
    _check_workspace_route(home, new_world, workspace, errors)
    _check_mode_switch(workspace, errors)

    workspace.emit_signal("home_requested")
    if not home.visible or workspace.visible:
        errors.append("Workspace Home action must return to Home.")


func _check_new_world_route(home: Control, new_world: Control, errors: Array[String]) -> void:
    if home.visible or not new_world.visible:
        errors.append("Create New World route must hide Home and show New World.")

    for node_name in ["SmallButton", "MediumButton", "LargeButton", "TemplateOption", "CreateButton"]:
        if new_world.find_child(node_name, true, false) == null:
            errors.append("New World screen is missing %s." % node_name)


func _check_workspace_route(
    home: Control,
    new_world: Control,
    workspace: Control,
    errors: Array[String]
) -> void:
    if home.visible or new_world.visible or not workspace.visible:
        errors.append("Create request must route into the workspace shell.")

    var title := workspace.find_child("WorldTitle", true, false) as Label
    if title == null or title.text != "Smoke World":
        errors.append("Workspace must receive the in-memory world title.")

    if workspace.find_child("InspectorLayer", true, false) == null:
        errors.append("Workspace must reserve an inspector layer.")
    if workspace.find_child("BottomDockLayer", true, false) == null:
        errors.append("Workspace must reserve a bottom-dock layer.")


func _check_mode_switch(workspace: Control, errors: Array[String]) -> void:
    var mode_switch := workspace.find_child("ModeSwitch", true, false) as Control
    var build_button := workspace.find_child("BuildButton", true, false) as Button
    var play_button := workspace.find_child("PlayButton", true, false) as Button
    var badge := workspace.find_child("BadgeText", true, false) as Label

    if mode_switch == null or build_button == null or play_button == null:
        errors.append("Workspace must expose a Build | Play segmented control.")
        return

    if not build_button.button_pressed or play_button.button_pressed:
        errors.append("Workspace mode switch must default to Build.")

    play_button.button_pressed = true
    play_button.emit_signal("pressed")
    if not play_button.button_pressed or build_button.button_pressed:
        errors.append("Play selection must update segmented-control state.")
    if badge == null or badge.text != "PLAY MODE":
        errors.append("Workspace must reflect Play selection in mode status.")
