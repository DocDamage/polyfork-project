class_name PlayWorldWorkspaceScreen
extends Control

signal home_requested
signal mode_changed(mode: StringName)
signal tool_selected(tool: StringName)

const EditorSession = preload("res://src/editor/editor_session.gd")

@onready var home_button: Button = %HomeButton
@onready var world_title: Label = %WorldTitle
@onready var world_context: Label = %WorldContext
@onready var mode_switch: Control = $TopBar/TopMargin/TopRow/ModeSlot/ModeSwitch
@onready var mode_badge: Label = %ModeBadge
@onready var inspector_panel: Control = $InspectorLayer/InspectorPanel
@onready var bottom_dock: Control = $BottomDockLayer/BottomToolDock
@onready var transform_toolbar: Control = $TransformToolbar
@onready var placement_toolbar: Control = $PlacementToolbar
@onready var tool_wheel: Control = $ToolWheelLayer/ToolWheel
@onready var editor_viewport: Control = $ViewportFrame/ViewportBackdrop/EditorViewport3D
@onready var viewport_center: Control = $ViewportFrame/ViewportBackdrop/ViewportCenter
@onready var status_mode: Label = %StatusMode
@onready var status_state: Label = $StatusBar/StatusMargin/StatusRow/StatusState

var _configuration: Dictionary = {}
var _mode: StringName = &"build"
var _active_transform_tool: StringName = &"select"
var _session


func _ready() -> void:
    _session = EditorSession.new()
    editor_viewport.get_world_root().add_child(_session)
    _session.selection_changed.connect(_on_selection_changed)
    _session.project_changed.connect(_on_project_changed)
    _session.placement_changed.connect(_on_placement_changed)

    home_button.pressed.connect(_request_home)
    mode_switch.mode_changed.connect(_on_mode_changed)
    bottom_dock.tool_selected.connect(_on_tool_selected)
    transform_toolbar.tool_selected.connect(_on_transform_tool_selected)
    placement_toolbar.action_requested.connect(_on_placement_action)
    tool_wheel.tool_selected.connect(_on_tool_wheel_selected)
    inspector_panel.closed.connect(_on_inspector_closed)
    editor_viewport.runtime_node_pressed.connect(_on_viewport_node_pressed)
    _configure_focus_navigation()
    _apply_mode_label()
    _update_editor_controls()


func bind_project(project, dirty_callback: Callable) -> Dictionary:
    var result := _session.bind_project(project, dirty_callback)
    if not result.get("ok", false):
        status_state.text = "Editor project bind failed"
        return result
    return set_configuration(project.to_dictionary())


func set_configuration(configuration: Dictionary) -> Dictionary:
    _configuration = configuration.duplicate(true)
    world_title.text = str(_configuration.get("title", "Untitled World"))
    var profile := str(_configuration.get("world_profile", "medium")).capitalize()
    var template := str(_configuration.get("template_id", "blank_sandbox")).replace("_", " ").capitalize()
    world_context.text = "%s world  •  %s" % [profile, template]

    var bridge_result: Dictionary = _session.load_preview_records(_configuration.get("entities", []))
    if not bridge_result.get("ok", false):
        status_state.text = "Entity load failed"
        return bridge_result

    _update_project_status()
    _update_editor_controls()
    return {"ok": true, "errors": [], "entity_count": _session.get_bridge().entity_count()}


func get_configuration() -> Dictionary:
    return _configuration.duplicate(true)


func get_mode() -> StringName:
    return _mode


func show_inspector(context: Dictionary) -> void:
    inspector_panel.show_context(context)


func hide_inspector() -> void:
    if _session.get_selected_ids().size() > 0:
        _session.clear_selection()
        return
    inspector_panel.clear_context()


func is_inspector_open() -> bool:
    return inspector_panel.is_open()


func is_asset_drawer_open() -> bool:
    return bottom_dock.is_asset_drawer_open()


func is_tool_wheel_open() -> bool:
    return tool_wheel.is_open()


func close_asset_drawer() -> void:
    bottom_dock.close_asset_drawer()


func open_tool_wheel() -> void:
    tool_wheel.open_wheel()


func select_entity(entity_id: String) -> Dictionary:
    return _session.select_entity(entity_id)


func toggle_entity_selection(entity_id: String) -> Dictionary:
    return _session.toggle_entity(entity_id)


func select_runtime_node(node: Node, additive: bool = false) -> Dictionary:
    return _session.select_runtime_node(node, additive)


func clear_selection() -> Dictionary:
    return _session.clear_selection()


func get_selected_entity_id() -> String:
    return _session.get_primary_entity_id()


func get_selected_entity_ids() -> Array[String]:
    return _session.get_selected_ids()


func get_selected_runtime_node():
    return _session.get_primary_node()


func get_runtime_entity_node(entity_id: String):
    return _session.get_bridge().get_entity_node(entity_id)


func get_runtime_entity_count() -> int:
    return _session.get_bridge().entity_count()


func get_runtime_entity_ids() -> Array[String]:
    return _session.get_bridge().entity_ids()


func begin_proxy_placement(display_name: String = "Proxy Object") -> Dictionary:
    var result := _session.begin_proxy_placement(display_name)
    _report_action(result, "Placement preview ready")
    return result


func update_placement_preview(position_value: Vector3, context: Dictionary = {}) -> Dictionary:
    return _session.update_placement_preview(position_value, context)


func commit_placement() -> Dictionary:
    var result := _session.commit_placement()
    _report_action(result, "Object placed")
    return result


func cancel_placement() -> Dictionary:
    var result := _session.cancel_placement()
    _update_editor_controls()
    return result


func nudge_selection(mode: StringName, delta: Vector3) -> Dictionary:
    var result := _session.nudge_selected(mode, delta)
    _report_action(result, "Transform applied")
    return result


func duplicate_selection() -> Dictionary:
    var result := _session.duplicate_selected()
    _report_action(result, "Selection duplicated")
    return result


func delete_selection() -> Dictionary:
    var result := _session.delete_selected()
    _report_action(result, "Selection deleted")
    return result


func group_selection() -> Dictionary:
    var result := _session.group_selected()
    _report_action(result, "Selection grouped")
    return result


func undo_edit() -> Dictionary:
    var result := _session.undo_edit()
    _report_action(result, "Undo")
    return result


func redo_edit() -> Dictionary:
    var result := _session.redo_edit()
    _report_action(result, "Redo")
    return result


func set_snap_enabled(mode: StringName, enabled: bool) -> Dictionary:
    return _session.set_snap_enabled(mode, enabled)


func drop_selection_to_ground() -> Dictionary:
    var result := _session.drop_selection_to_ground()
    _report_action(result, "Dropped to ground")
    return result


func snap_selection_to_surface(position_value: Vector3, normal: Vector3) -> Dictionary:
    var result := _session.snap_selection_to_surface(position_value, normal)
    _report_action(result, "Surface snapped")
    return result


func snap_selection_to_object(candidates: Array) -> Dictionary:
    var result := _session.snap_selection_to_object(candidates)
    _report_action(result, "Object snapped")
    return result


func snap_selection_to_socket(candidates: Array) -> Dictionary:
    var result := _session.snap_selection_to_socket(candidates)
    _report_action(result, "Socket snapped")
    return result


func is_placement_active() -> bool:
    return _session.is_placement_active()


func get_history_counts() -> Dictionary:
    return _session.get_history_counts()


func handle_cancel() -> bool:
    if tool_wheel.is_open():
        tool_wheel.close_wheel()
        call_deferred("focus_primary")
        return true
    if _session.is_placement_active():
        _session.cancel_placement()
        call_deferred("focus_primary")
        return true
    if is_asset_drawer_open():
        close_asset_drawer()
        call_deferred("focus_bottom_dock")
        return true
    if is_inspector_open():
        hide_inspector()
        call_deferred("focus_primary")
        return true
    return false


func focus_primary() -> void:
    mode_switch.focus_primary()


func focus_bottom_dock() -> void:
    bottom_dock.focus_primary()


func _unhandled_input(event: InputEvent) -> void:
    if not visible or _mode != &"build":
        return
    if _is_tool_wheel_event(event):
        tool_wheel.open_wheel()
        get_viewport().set_input_as_handled()
        return
    if tool_wheel.is_open():
        return
    if _session.is_placement_active() and _is_confirm_event(event):
        commit_placement()
        get_viewport().set_input_as_handled()
        return
    var direction := _direction_from_event(event)
    if direction != Vector2.ZERO and _apply_direction(direction):
        get_viewport().set_input_as_handled()


func _apply_direction(direction: Vector2) -> bool:
    if _session.is_placement_active():
        var ghost = _session.get_ghost()
        _session.update_placement_preview(ghost.position + Vector3(direction.x, 0.0, direction.y))
        return true
    if _session.get_selected_ids().is_empty():
        return false
    match _active_transform_tool:
        &"move": return nudge_selection(&"move", Vector3(direction.x, 0.0, direction.y)).get("ok", false)
        &"rotate": return nudge_selection(&"rotate", Vector3(0.0, direction.x * 15.0, 0.0)).get("ok", false)
        &"scale": return nudge_selection(&"scale", Vector3.ONE * direction.y * 0.1).get("ok", false)
    return false


func _on_selection_changed(entity_ids: Array, primary_entity_id: String, runtime_node: Node3D) -> void:
    if primary_entity_id.is_empty() or runtime_node == null:
        if inspector_panel.get_context().get("source") == "entity_selection":
            inspector_panel.clear_context()
        _update_editor_controls()
        return
    var record: Dictionary = _session.get_bridge().get_entity_record(primary_entity_id)
    if record.is_empty():
        inspector_panel.clear_context()
        return
    inspector_panel.show_context(_entity_inspector_context(record, entity_ids.size()))
    _update_editor_controls()


func _on_project_changed(project_data: Dictionary) -> void:
    _configuration = project_data.duplicate(true)
    _update_project_status()
    var primary := _session.get_primary_entity_id()
    if not primary.is_empty():
        var record := _session.get_bridge().get_entity_record(primary)
        if not record.is_empty():
            inspector_panel.show_context(_entity_inspector_context(record, _session.get_selected_ids().size()))
    _update_editor_controls()


func _on_placement_changed(active: bool, _preview_record: Dictionary) -> void:
    viewport_center.visible = not active and get_runtime_entity_count() == 0
    _update_editor_controls()


func _on_viewport_node_pressed(node: Node, hit_position: Vector3, hit_normal: Vector3) -> void:
    if _session.is_placement_active():
        var context := {"surface_position": hit_position, "surface_normal": hit_normal}
        _session.update_placement_preview(hit_position, context)
        commit_placement()
        return
    var additive := Input.is_key_pressed(KEY_SHIFT)
    var result := _session.select_runtime_node(node, additive)
    if not result.get("ok", false):
        _session.clear_selection()


func _on_placement_action(action: StringName, enabled: bool) -> void:
    match action:
        &"place":
            if _session.is_placement_active(): _session.cancel_placement()
            else: begin_proxy_placement()
        &"grid", &"surface", &"object", &"socket": _session.set_snap_enabled(action, enabled)
        &"ground": drop_selection_to_ground()
        &"group": group_selection()
        &"undo": undo_edit()
        &"redo": redo_edit()
    _update_editor_controls()


func _on_tool_wheel_selected(tool: StringName) -> void:
    match tool:
        &"place": begin_proxy_placement()
        &"duplicate": duplicate_selection()
        &"delete": delete_selection()
        &"group": group_selection()
        _:
            _active_transform_tool = tool
            _session.set_tool(tool)
            transform_toolbar.select_tool(tool)
            tool_selected.emit(tool)


func _on_transform_tool_selected(tool: StringName) -> void:
    match tool:
        &"duplicate": duplicate_selection()
        &"delete": delete_selection()
        _:
            _active_transform_tool = tool
            _session.set_tool(tool)
            tool_selected.emit(tool)


func _on_inspector_closed() -> void:
    if not _session.get_selected_ids().is_empty():
        _session.clear_selection()


func _configure_focus_navigation() -> void:
    var build_button := find_child("BuildButton", true, false) as Button
    var play_button := find_child("PlayButton", true, false) as Button
    var assets_button := find_child("AssetsButton", true, false) as Button
    if build_button == null or play_button == null or assets_button == null:
        return
    home_button.focus_neighbor_right = home_button.get_path_to(build_button)
    home_button.focus_neighbor_bottom = home_button.get_path_to(assets_button)
    build_button.focus_neighbor_left = build_button.get_path_to(home_button)
    build_button.focus_neighbor_bottom = build_button.get_path_to(assets_button)
    play_button.focus_neighbor_bottom = play_button.get_path_to(assets_button)
    assets_button.focus_neighbor_top = assets_button.get_path_to(build_button)


func _entity_inspector_context(record: Dictionary, selected_count: int) -> Dictionary:
    var entity_id := str(record.get("entity_id", ""))
    var cell_id := str(record.get("cell_id", ""))
    var parent = record.get("parent_entity_id")
    var parent_id := "" if parent == null else str(parent)
    var transform_data: Dictionary = record.get("transform", {})
    var title := str(record.get("display_name", "Entity"))
    if selected_count > 1:
        title += "  •  %d selected" % selected_count
    return {
        "source": "entity_selection",
        "title": title,
        "type": "World entity",
        "summary": "Stable entity • %s" % entity_id.substr(0, 8),
        "position": _format_vector(transform_data.get("position", [])),
        "rotation": _format_vector(transform_data.get("rotation_degrees", [])),
        "scale": _format_vector(transform_data.get("scale", [])),
        "advanced_summary": "Entity ID: %s\nCell ID: %s\nParent: %s" % [entity_id, cell_id, "None" if parent_id.is_empty() else parent_id]
    }


func _report_action(result: Dictionary, success_text: String) -> void:
    status_state.text = success_text if result.get("ok", false) else str(result.get("errors", ["Edit failed"])[0])
    _update_editor_controls()


func _update_project_status() -> void:
    var project_id := str(_configuration.get("project_id", ""))
    status_state.text = "Saved project • %s" % project_id.substr(0, 8) if project_id.length() >= 8 else "Session preview"


func _update_editor_controls() -> void:
    var counts := _session.get_history_counts()
    placement_toolbar.set_history_state(int(counts.get("undo", 0)) > 0, int(counts.get("redo", 0)) > 0)
    placement_toolbar.set_group_enabled(_session.get_selected_ids().size() >= 2)
    viewport_center.visible = not _session.is_placement_active() and get_runtime_entity_count() == 0
    placement_toolbar.visible = _mode == &"build"
    transform_toolbar.visible = _mode == &"build"


func _on_mode_changed(mode: StringName) -> void:
    _mode = mode
    _apply_mode_label()
    _update_editor_controls()
    mode_changed.emit(_mode)


func _on_tool_selected(tool: StringName) -> void:
    tool_selected.emit(tool)


func _apply_mode_label() -> void:
    mode_badge.text = "%s MODE" % str(_mode).to_upper()
    status_mode.text = str(_mode).capitalize()


func _request_home() -> void:
    home_requested.emit()


func _format_vector(value: Variant) -> String:
    if not value is Array or value.size() != 3:
        return "—"
    return "%.2f, %.2f, %.2f" % [float(value[0]), float(value[1]), float(value[2])]


func _is_tool_wheel_event(event: InputEvent) -> bool:
    return (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_LEFT_SHOULDER)


func _is_confirm_event(event: InputEvent) -> bool:
    return (event is InputEventKey and event.pressed and not event.echo and [KEY_ENTER, KEY_KP_ENTER].has(event.keycode)) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A)


func _direction_from_event(event: InputEvent) -> Vector2:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_LEFT: return Vector2.LEFT
            KEY_RIGHT: return Vector2.RIGHT
            KEY_UP: return Vector2.UP
            KEY_DOWN: return Vector2.DOWN
    if event is InputEventJoypadButton and event.pressed:
        match event.button_index:
            JOY_BUTTON_DPAD_LEFT: return Vector2.LEFT
            JOY_BUTTON_DPAD_RIGHT: return Vector2.RIGHT
            JOY_BUTTON_DPAD_UP: return Vector2.UP
            JOY_BUTTON_DPAD_DOWN: return Vector2.DOWN
    return Vector2.ZERO
