extends Node

const StableId = preload("res://src/world/stable_id.gd")
const MAIN_SCENE := "res://src/main/Main.tscn"


func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var old_root: Variant = ProjectSettings.get_setting("playworld/storage/projects_root", null)
    ProjectSettings.set_setting(
        "playworld/storage/projects_root",
        "user://tests/phase3_runtime_%s" % StableId.generate()
    )

    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null:
        errors.append("Phase 3 runtime smoke must load the real Main scene.")
        _restore_root(old_root)
        return errors
    var main_instance := packed.instantiate()
    add_child(main_instance)
    var home := main_instance.get_node_or_null("HomeScreen") as Control
    var new_world := main_instance.get_node_or_null("NewWorldScreen") as Control
    var workspace := main_instance.get_node_or_null("WorkspaceScreen") as Control
    if home == null or new_world == null or workspace == null:
        errors.append("Phase 3 runtime smoke requires the real Home, New World, and Workspace screens.")
        main_instance.queue_free()
        _restore_root(old_root)
        return errors

    home.emit_signal("route_requested", &"new_world")
    new_world.emit_signal("create_requested", {
        "title": "Phase 3 Runtime",
        "world_profile": "medium",
        "template_id": "blank_sandbox"
    })
    if not workspace.visible:
        errors.append("Phase 3 runtime smoke must enter the real workspace through New World creation.")
    else:
        _check_editor_workspace(workspace, errors)

    main_instance.queue_free()
    _restore_root(old_root)
    return errors


func _check_editor_workspace(workspace: Control, errors: Array[String]) -> void:
    var placement_toolbar := workspace.find_child("PlacementToolbar", true, false) as Control
    var tool_wheel := workspace.find_child("ToolWheel", true, false) as Control
    var editor_viewport := workspace.find_child("EditorViewport3D", true, false) as Control
    if placement_toolbar == null or tool_wheel == null or editor_viewport == null:
        errors.append("Phase 3 workspace must expose placement toolbar, tool wheel, and live editor viewport.")
        return

    var begin_result: Dictionary = workspace.call("begin_proxy_placement", "Runtime Proxy")
    if not begin_result.get("ok", false) or not workspace.call("is_placement_active"):
        errors.append("Real workspace must begin a ghost placement flow.")
        return
    var preview_result: Dictionary = workspace.call("update_placement_preview", Vector3(2.2, 0.5, 3.8))
    if not preview_result.get("ok", false):
        errors.append("Real workspace placement ghost must accept preview movement.")
    var commit_result: Dictionary = workspace.call("commit_placement")
    if not commit_result.get("ok", false) or workspace.call("get_runtime_entity_count") != 1:
        errors.append("Real workspace must commit placement into the runtime bridge.")
        return

    var entity_id := str(commit_result.get("entity_id", ""))
    if workspace.call("get_selected_entity_id") != entity_id:
        errors.append("Committed placement must become the primary editor selection.")
    var inspector := workspace.find_child("InspectorPanel", true, false) as Control
    if inspector == null or not inspector.visible:
        errors.append("Placed entity selection must populate the existing right inspector.")

    var move_button := workspace.find_child("MoveButton", true, false) as Button
    if move_button == null:
        errors.append("Move tool must remain available in the compact transform toolbar.")
    else:
        move_button.button_pressed = true
        move_button.emit_signal("pressed")
        var dpad_right := InputEventJoypadButton.new()
        dpad_right.button_index = JOY_BUTTON_DPAD_RIGHT
        dpad_right.pressed = true
        workspace.call("_unhandled_input", dpad_right)
        var config: Dictionary = workspace.call("get_configuration")
        var record: Dictionary = _record(config.get("entities", []), entity_id)
        var position: Array = record.get("transform", {}).get("position", [])
        if position.size() != 3 or float(position[0]) != 3.0:
            errors.append("Gamepad D-pad must drive the command-backed move tool with grid snapping.")

    var wheel_event := InputEventJoypadButton.new()
    wheel_event.button_index = JOY_BUTTON_LEFT_SHOULDER
    wheel_event.pressed = true
    workspace.call("_unhandled_input", wheel_event)
    if not workspace.call("is_tool_wheel_open"):
        errors.append("Gamepad left shoulder must open the controller-first tool wheel.")
    elif not workspace.call("handle_cancel") or workspace.call("is_tool_wheel_open"):
        errors.append("Cancel must close the tool wheel before leaving the workspace.")

    var duplicate_result: Dictionary = workspace.call("duplicate_selection")
    if not duplicate_result.get("ok", false) or workspace.call("get_selected_entity_ids").size() != 1:
        errors.append("Workspace duplicate action must create and select a stable-ID copy.")
    workspace.call("toggle_entity_selection", entity_id)
    if workspace.call("get_selected_entity_ids").size() != 2:
        errors.append("Workspace must expose additive multi-select behavior.")
    var group_result: Dictionary = workspace.call("group_selection")
    if not group_result.get("ok", false):
        errors.append("Workspace group action must execute through command-backed editor state.")

    var history: Dictionary = workspace.call("get_history_counts")
    if int(history.get("undo", 0)) < 4:
        errors.append("Workspace Phase 3 edits must accumulate reversible command history.")

    workspace.call("clear_selection")
    workspace.call("cancel_placement")
    if inspector != null and inspector.visible:
        workspace.call("hide_inspector")


func _restore_root(old_root: Variant) -> void:
    if old_root == null:
        ProjectSettings.set_setting("playworld/storage/projects_root", null)
    else:
        ProjectSettings.set_setting("playworld/storage/projects_root", old_root)


static func _record(records: Array, entity_id: String) -> Dictionary:
    for record in records:
        if str(record.get("entity_id", "")) == entity_id:
            return record
    return {}
