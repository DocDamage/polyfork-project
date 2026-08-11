class_name PlayWorldTerrainWorkspaceLayer
extends Control

signal status_changed(message: String, is_error: bool)
signal open_changed(open: bool)

const TerrainController = preload("res://src/terrain/terrain_controller.gd")
const TerrainPanel = preload("res://src/app/workspace/terrain_tool_panel.gd")
const TerrainChunk = preload("res://src/terrain/terrain_chunk_node.gd")

var _workspace: Control
var _editor_viewport
var _session
var _controller
var _panel
var _transform_toolbar: Control
var _placement_toolbar: Control
var _bottom_dock: Control
var _viewport_center: Control
var _bound := false


func _ready() -> void:
    name = "TerrainWorkspaceLayer"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _panel = TerrainPanel.new()
    add_child(_panel)
    _wire_panel()
    set_process_unhandled_input(true)


func bind_workspace(workspace: Control) -> Dictionary:
    _workspace = workspace
    _editor_viewport = workspace.get_node_or_null("ViewportFrame/ViewportBackdrop/EditorViewport3D")
    _viewport_center = workspace.get_node_or_null("ViewportFrame/ViewportBackdrop/ViewportCenter")
    _transform_toolbar = workspace.get_node_or_null("TransformToolbar")
    _placement_toolbar = workspace.get_node_or_null("PlacementToolbar")
    _bottom_dock = workspace.get_node_or_null("BottomDockLayer/BottomToolDock")
    if _editor_viewport == null or _bottom_dock == null: return _failure("Terrain workspace could not resolve editor viewport or bottom dock.")
    if not _bottom_dock.tool_selected.is_connected(_on_tool_selected): _bottom_dock.tool_selected.connect(_on_tool_selected)
    if not _editor_viewport.runtime_node_pressed.is_connected(_on_viewport_pressed): _editor_viewport.runtime_node_pressed.connect(_on_viewport_pressed)
    return {"ok": true, "errors": []}


func bind_project(project, project_directory: String, editor_session, dirty_callback: Callable) -> Dictionary:
    if _workspace == null: return _failure("Terrain workspace must bind its workspace before a project.")
    _session = editor_session
    if _controller != null and is_instance_valid(_controller):
        if _controller.get_parent() != null: _controller.get_parent().remove_child(_controller)
        _controller.free()
    _controller = TerrainController.new()
    _editor_viewport.get_world_root().add_child(_controller)
    var result: Dictionary = _controller.bind_project(project, project_directory, editor_session, dirty_callback)
    if not result.get("ok", false): return result
    if not _controller.terrain_status.is_connected(_on_terrain_status): _controller.terrain_status.connect(_on_terrain_status)
    if not _controller.brush_changed.is_connected(_on_brush_changed): _controller.brush_changed.connect(_on_brush_changed)
    _panel.set_biomes(_controller.get_biomes())
    _panel.set_brush_state(_controller.get_brush_state())
    _sync_selected_biome()
    _editor_viewport.set_default_ground_visible(false)
    _bound = true
    close_tool()
    return result


func toggle_tool() -> void:
    if not _bound: return
    if is_open(): close_tool()
    else: open_tool()


func open_tool() -> void:
    if not _bound: return
    if _session != null and _session.is_placement_active(): _session.cancel_placement()
    if _workspace.has_method("close_asset_drawer"): _workspace.close_asset_drawer()
    if _session != null: _session.clear_selection()
    if _viewport_center != null: _viewport_center.hide()
    _panel.open_panel()
    _controller.set_cursor_visible(true)
    _controller.set_cursor(_controller.get_brush_state().get("cursor", Vector3.ZERO))
    _editor_viewport.set_terrain_view(true)
    _sync_editor_controls()
    open_changed.emit(true)


func close_tool() -> void:
    if _panel != null: _panel.close_panel()
    if _controller != null: _controller.set_cursor_visible(false)
    if _editor_viewport != null: _editor_viewport.set_terrain_view(false)
    _restore_empty_state()
    _sync_editor_controls()
    open_changed.emit(false)


func is_open() -> bool: return _panel != null and _panel.is_open()
func get_controller(): return _controller
func get_panel(): return _panel


func handle_cancel() -> bool:
    if not is_open(): return false
    close_tool()
    return true


func advance(delta: float) -> Dictionary:
    if not _bound or _controller == null: return {"ok": true, "attempted": false, "errors": []}
    return _controller.advance(delta)


func _unhandled_input(event: InputEvent) -> void:
    if not is_open() or event.is_echo(): return
    if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
        _controller.cycle_mode(); get_viewport().set_input_as_handled(); return
    if _is_apply_event(event):
        _apply(); get_viewport().set_input_as_handled(); return
    var direction: Vector2 = _direction(event)
    if direction != Vector2.ZERO:
        var result: Dictionary = _controller.move_cursor(direction)
        if not result.get("ok", false): _report_result(result)
        get_viewport().set_input_as_handled(); return
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_BRACKETLEFT: _controller.set_radius(float(_controller.get_brush_state().get("radius", 180.0)) - 24.0); get_viewport().set_input_as_handled()
            KEY_BRACKETRIGHT: _controller.set_radius(float(_controller.get_brush_state().get("radius", 180.0)) + 24.0); get_viewport().set_input_as_handled()
            KEY_MINUS: _controller.set_strength(float(_controller.get_brush_state().get("strength", 4.0)) - 0.5); get_viewport().set_input_as_handled()
            KEY_EQUAL: _controller.set_strength(float(_controller.get_brush_state().get("strength", 4.0)) + 0.5); get_viewport().set_input_as_handled()


func _on_tool_selected(tool: StringName) -> void:
    if tool == &"terrain": toggle_tool()
    elif is_open(): close_tool()


func _on_viewport_pressed(node: Node, hit_position: Vector3, _hit_normal: Vector3) -> void:
    if not is_open() or not _is_terrain_node(node): return
    var cursor_result: Dictionary = _controller.set_cursor(hit_position)
    if not cursor_result.get("ok", false): _report_result(cursor_result); return
    _apply()


func _apply() -> void:
    _report_result(_controller.apply_brush())
    _sync_selected_biome()


func _wire_panel() -> void:
    _panel.mode_requested.connect(func(mode: StringName) -> void: _report_result(_controller.set_mode(mode)))
    _panel.apply_requested.connect(_apply)
    _panel.radius_delta_requested.connect(func(delta: float) -> void:
        _report_result(_controller.set_radius(float(_controller.get_brush_state().get("radius", 180.0)) + delta)))
    _panel.strength_delta_requested.connect(func(delta: float) -> void:
        _report_result(_controller.set_strength(float(_controller.get_brush_state().get("strength", 4.0)) + delta)))
    _panel.biome_requested.connect(func(biome_id: String) -> void:
        _report_result(_controller.assign_biome(biome_id)); _sync_selected_biome())
    _panel.close_requested.connect(close_tool)


func _on_terrain_status(message: String, is_error: bool) -> void: status_changed.emit(message, is_error)
func _on_brush_changed(state: Dictionary) -> void: _panel.set_brush_state(state)


func _report_result(result: Dictionary) -> void:
    if result.get("ok", false): status_changed.emit("Terrain ready", false)
    else: status_changed.emit(str(result.get("errors", ["Terrain action failed."])[0]), true)


func _sync_selected_biome() -> void:
    if _controller == null or _controller.get_state() == null: return
    var state = _controller.get_state()
    var cell_id: String = str(_controller.get_brush_state().get("cell_id", ""))
    var cell: Dictionary = state.get_cell(cell_id)
    if not cell.is_empty(): _panel.select_biome(str(cell.get("biome_id", "")))


func _restore_empty_state() -> void:
    if _viewport_center == null or _workspace == null: return
    var should_show := true
    if _workspace.has_method("get_runtime_entity_count"):
        should_show = int(_workspace.call("get_runtime_entity_count")) == 0
    if _workspace.has_method("is_placement_active") and bool(_workspace.call("is_placement_active")):
        should_show = false
    _viewport_center.visible = should_show


func _sync_editor_controls() -> void:
    if _workspace == null: return
    var build_mode: bool = not _workspace.has_method("get_mode") or _workspace.get_mode() == &"build"
    var show_editors: bool = build_mode and not is_open()
    if _transform_toolbar != null: _transform_toolbar.visible = show_editors
    if _placement_toolbar != null: _placement_toolbar.visible = show_editors


func _is_terrain_node(node: Node) -> bool:
    var current := node
    while current != null and current != _editor_viewport.get_world_root():
        if current.has_meta(TerrainChunk.CELL_ID_META): return true
        current = current.get_parent()
    return false


func _is_apply_event(event: InputEvent) -> bool:
    return (event is InputEventKey and event.pressed and [KEY_ENTER, KEY_KP_ENTER].has(event.keycode)) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A)


func _direction(event: InputEvent) -> Vector2:
    if event is InputEventKey and event.pressed:
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


func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
