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
        _exercise_routes(main_instance, home, new_world, workspace, errors)

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

    var create_button := home.find_child("CreateButton", true, false) as Button
    if create_button != null and create_button.focus_neighbor_right.is_empty():
        errors.append("Home directional focus graph must be configured.")


func _exercise_routes(
    main_instance: Control,
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
    _check_inspector(workspace, errors)
    _check_bottom_dock(workspace, errors)
    _check_cancel_priority(workspace, errors)

    var cancel_event := InputEventAction.new()
    cancel_event.action = &"ui_cancel"
    cancel_event.pressed = true
    main_instance.call("_unhandled_input", cancel_event)
    if not home.visible or workspace.visible:
        errors.append("App-level ui_cancel must leave an idle workspace and return Home.")


func _check_new_world_route(home: Control, new_world: Control, errors: Array[String]) -> void:
    if home.visible or not new_world.visible:
        errors.append("Create New World route must hide Home and show New World.")

    for node_name in ["SmallButton", "MediumButton", "LargeButton", "TemplateOption", "CreateButton"]:
        if new_world.find_child(node_name, true, false) == null:
            errors.append("New World screen is missing %s." % node_name)

    var name_edit := new_world.find_child("WorldNameEdit", true, false) as LineEdit
    if name_edit != null and name_edit.focus_neighbor_bottom.is_empty():
        errors.append("New World directional focus graph must be configured.")


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
    if build_button.focus_neighbor_bottom.is_empty():
        errors.append("Workspace mode control must link into the dock focus graph.")


func _check_inspector(workspace: Control, errors: Array[String]) -> void:
    var inspector := workspace.find_child("InspectorPanel", true, false) as Control
    var advanced_button := workspace.find_child("AdvancedButton", true, false) as Button
    var advanced_panel := workspace.find_child("AdvancedPanel", true, false) as Control

    if inspector == null or advanced_button == null or advanced_panel == null:
        errors.append("Workspace must expose the generic right inspector shell.")
        return

    if inspector.visible:
        errors.append("Inspector must be hidden until a context is supplied.")

    workspace.call("show_inspector", {
        "title": "Smoke Selection",
        "type": "Generic object",
        "summary": "Basic smoke context",
        "advanced_summary": "Advanced smoke context"
    })

    if not inspector.visible:
        errors.append("Inspector must show when a context is supplied.")
    if advanced_panel.visible:
        errors.append("Inspector Advanced content must start collapsed.")

    advanced_button.emit_signal("toggled", true)
    if not advanced_panel.visible:
        errors.append("Inspector Advanced disclosure must expand on request.")

    workspace.call("hide_inspector")
    if inspector.visible:
        errors.append("Inspector clear/hide must remove it from the workspace.")


func _check_bottom_dock(workspace: Control, errors: Array[String]) -> void:
    var required_tools := [
        "TerrainButton",
        "AssetsButton",
        "FoliageButton",
        "RoadsButton",
        "WaterButton",
        "GameplayButton",
        "AIButton",
        "MoreButton"
    ]
    for node_name in required_tools:
        if workspace.find_child(node_name, true, false) == null:
            errors.append("Bottom dock is missing %s." % node_name)

    var assets_button := workspace.find_child("AssetsButton", true, false) as Button
    var drawer := workspace.find_child("AssetDrawer", true, false) as Control
    var density_button := workspace.find_child("DensityButton", true, false) as Button
    var search_edit := workspace.find_child("AssetSearch", true, false) as LineEdit

    if assets_button == null or drawer == null or density_button == null or search_edit == null:
        errors.append("Asset drawer shell is incomplete.")
        return

    if drawer.visible:
        errors.append("Asset drawer must start closed.")
    if density_button.text != "Large Cards":
        errors.append("Asset drawer must default to large-card density.")
    if assets_button.focus_neighbor_left.is_empty() or assets_button.focus_neighbor_right.is_empty():
        errors.append("Bottom dock must provide horizontal controller focus navigation.")

    assets_button.emit_signal("pressed")
    if not drawer.visible:
        errors.append("Assets tool must open the Asset drawer.")

    density_button.emit_signal("pressed")
    if density_button.text != "Compact":
        errors.append("Asset density toggle must change from large to compact.")

    assets_button.emit_signal("pressed")
    if drawer.visible:
        errors.append("Assets tool must toggle the Asset drawer closed.")


func _check_cancel_priority(workspace: Control, errors: Array[String]) -> void:
    var assets_button := workspace.find_child("AssetsButton", true, false) as Button
    var inspector := workspace.find_child("InspectorPanel", true, false) as Control
    if assets_button == null or inspector == null:
        return

    workspace.call("show_inspector", {"title": "Cancel Test"})
    assets_button.emit_signal("pressed")

    var handled := bool(workspace.call("handle_cancel"))
    if not handled or workspace.call("is_asset_drawer_open"):
        errors.append("First workspace Cancel must close the Asset drawer.")
    if not inspector.visible:
        errors.append("Closing the Asset drawer must not also close the inspector.")

    handled = bool(workspace.call("handle_cancel"))
    if not handled or inspector.visible:
        errors.append("Second workspace Cancel must close the inspector.")
