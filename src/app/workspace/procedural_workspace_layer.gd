class_name PlayWorldProceduralWorkspaceLayer
extends Control

signal status_changed(message: String, is_error: bool)
signal open_changed(open: bool)

const Tokens = preload("res://src/app/theme/ui_tokens.gd")
const ProceduralPanel = preload("res://src/app/workspace/procedural_tool_panel.gd")
const ProceduralRuntime = preload("res://src/procedural/procedural_runtime.gd")
const ProceduralService = preload("res://src/procedural/procedural_service.gd")
const TerrainChunk = preload("res://src/terrain/terrain_chunk_node.gd")

var _workspace: Control
var _editor_viewport
var _bottom_dock: Control
var _transform_toolbar: Control
var _placement_toolbar: Control
var _viewport_center: Control
var _panel
var _runtime
var _service
var _terrain_controller
var _cursor: MeshInstance3D
var _cursor_position := Vector3.ZERO
var _operation: StringName = &"paint"
var _pending_spline_kind: String = ""
var _pending_first_point: Variant = null
var _bound := false


func _ready() -> void:
    name = "ProceduralWorkspaceLayer"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _panel = ProceduralPanel.new()
    add_child(_panel)
    _wire_panel()
    set_process_unhandled_input(true)


func bind_workspace(workspace: Control) -> Dictionary:
    _workspace = workspace
    _editor_viewport = workspace.get_node_or_null("ViewportFrame/ViewportBackdrop/EditorViewport3D")
    _bottom_dock = workspace.get_node_or_null("BottomDockLayer/BottomToolDock")
    _transform_toolbar = workspace.get_node_or_null("TransformToolbar")
    _placement_toolbar = workspace.get_node_or_null("PlacementToolbar")
    _viewport_center = workspace.get_node_or_null("ViewportFrame/ViewportBackdrop/ViewportCenter")
    if _editor_viewport == null or _bottom_dock == null:
        return _failure("Procedural workspace could not resolve editor viewport or bottom dock.")
    if not _bottom_dock.tool_selected.is_connected(_on_tool_selected):
        _bottom_dock.tool_selected.connect(_on_tool_selected)
    if not _editor_viewport.runtime_node_pressed.is_connected(_on_viewport_pressed):
        _editor_viewport.runtime_node_pressed.connect(_on_viewport_pressed)
    return {"ok": true, "errors": []}


func bind_project(project, project_directory: String, editor_session, dirty_callback: Callable, terrain_controller, asset_library = null, gameplay_service = null) -> Dictionary:
    if _workspace == null:
        return _failure("Procedural workspace must bind workspace before project.")
    if terrain_controller == null or terrain_controller.get_state() == null or terrain_controller.get_runtime() == null:
        return _failure("Procedural workspace requires the bound terrain controller.")
    _terrain_controller = terrain_controller
    if _runtime != null and is_instance_valid(_runtime):
        if _runtime.get_parent() != null: _runtime.get_parent().remove_child(_runtime)
        _runtime.free()
    _runtime = ProceduralRuntime.new()
    _runtime.set_meta("terrain_runtime", terrain_controller.get_runtime())
    _editor_viewport.get_world_root().add_child(_runtime)
    _service = ProceduralService.new()
    var result: Dictionary = _service.bind_project(
        project,
        project_directory,
        editor_session,
        dirty_callback,
        terrain_controller.get_state(),
        _runtime,
        asset_library,
        gameplay_service
    )
    if not result.get("ok", false): return result
    if not _service.procedural_changed.is_connected(_refresh_panel_data): _service.procedural_changed.connect(_refresh_panel_data)
    if not _service.status_changed.is_connected(_on_service_status): _service.status_changed.connect(_on_service_status)
    _ensure_cursor()
    _cursor_position = Vector3.ZERO
    _update_cursor_height()
    _refresh_panel_data()
    _bound = true
    close_tool()
    return result


func open_tool(section: StringName = &"foliage") -> void:
    if not _bound: return
    if _workspace.has_method("close_asset_drawer"): _workspace.close_asset_drawer()
    if _workspace.has_method("clear_selection"): _workspace.clear_selection()
    _pending_spline_kind = ""
    _pending_first_point = null
    _panel.open_panel(section)
    _set_cursor_section(section)
    _set_cursor_visible(true)
    _update_cursor_height()
    if _viewport_center != null: _viewport_center.hide()
    _sync_editor_controls()
    open_changed.emit(true)


func close_tool() -> void:
    if _panel != null: _panel.close_panel()
    _pending_spline_kind = ""
    _pending_first_point = null
    _set_cursor_visible(false)
    _restore_empty_state()
    _sync_editor_controls()
    open_changed.emit(false)


func toggle_tool(section: StringName) -> void:
    if not _bound: return
    if is_open() and _panel.get_section() == section: close_tool()
    else: open_tool(section)


func is_open() -> bool: return _panel != null and _panel.is_open()
func get_panel(): return _panel
func get_service(): return _service
func get_runtime(): return _runtime
func get_cursor_position() -> Vector3: return _cursor_position


func handle_cancel() -> bool:
    if not is_open(): return false
    if not _pending_spline_kind.is_empty() or _pending_first_point != null:
        _pending_spline_kind = ""
        _pending_first_point = null
        status_changed.emit("Spline creation cancelled", false)
        return true
    close_tool()
    return true


func _unhandled_input(event: InputEvent) -> void:
    if not is_open() or event.is_echo(): return
    var direction: Vector2 = _direction(event)
    if direction != Vector2.ZERO:
        _cursor_position += Vector3(direction.x, 0.0, direction.y) * 8.0
        _update_cursor_height()
        get_viewport().set_input_as_handled()
        return
    if _is_apply_event(event):
        _apply_at_cursor()
        get_viewport().set_input_as_handled()
        return
    if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_X:
        if _panel.get_section() == &"foliage":
            _set_operation(&"erase" if _operation == &"paint" else &"paint")
            get_viewport().set_input_as_handled()
            return
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_BRACKETLEFT: _panel.adjust_radius(-4.0); get_viewport().set_input_as_handled()
            KEY_BRACKETRIGHT: _panel.adjust_radius(4.0); get_viewport().set_input_as_handled()


func _wire_panel() -> void:
    _panel.section_requested.connect(func(section: StringName) -> void:
        _panel.set_section(section)
        _set_cursor_section(section)
        _pending_spline_kind = ""
        _pending_first_point = null)
    _panel.create_foliage_requested.connect(_create_default_foliage)
    _panel.create_scatter_requested.connect(_create_default_scatter)
    _panel.operation_requested.connect(_set_operation)
    _panel.radius_delta_requested.connect(func(delta: float) -> void: _panel.adjust_radius(delta); _sync_cursor_scale())
    _panel.density_delta_requested.connect(_adjust_density)
    _panel.new_spline_requested.connect(_arm_spline_creation)
    _panel.add_point_requested.connect(_add_point_to_selected_spline)
    _panel.close_requested.connect(close_tool)


func _create_default_foliage() -> void:
    var result: Dictionary = _service.create_foliage_set("Grass %d" % (_service.get_foliage_sets().size() + 1), {"kind": "primitive", "primitive": "grass"})
    _report(result, "Foliage set created")


func _create_default_scatter() -> void:
    var foliage_id: String = _panel.get_selected_foliage_id()
    if foliage_id.is_empty():
        _report(_service.create_foliage_set("Grass", {"kind": "primitive", "primitive": "grass"}), "Foliage set created")
        foliage_id = _panel.get_selected_foliage_id()
    if foliage_id.is_empty(): return
    var result: Dictionary = _service.create_scatter_layer("Scatter %d" % (_service.get_scatter_layers().size() + 1), foliage_id, {"density_per_100m2": _panel.get_density()})
    _report(result, "Scatter layer created")
    if result.get("ok", false): _panel.select_scatter(str(result.get("scatter_layer_id", "")))


func _set_operation(operation: StringName) -> void:
    _operation = &"erase" if operation == &"erase" else &"paint"
    _panel.set_operation(_operation)
    status_changed.emit("%s scatter mode" % str(_operation).capitalize(), false)


func _adjust_density(delta: float) -> void:
    _panel.adjust_density(delta)
    var scatter_id: String = _panel.get_selected_scatter_id()
    if scatter_id.is_empty(): return
    _report(_service.configure_scatter_layer(scatter_id, {"density_per_100m2": _panel.get_density()}), "Scatter density updated")


func _arm_spline_creation(kind: String) -> void:
    _pending_spline_kind = kind
    _pending_first_point = null
    status_changed.emit("%s: place first point" % kind.capitalize(), false)


func _add_point_to_selected_spline() -> void:
    var spline_id: String = _panel.get_selected_spline_id()
    if spline_id.is_empty():
        status_changed.emit("Select or create a spline first", true)
        return
    _report(_service.add_spline_point(spline_id, _cursor_position), "Spline point added")


func _apply_at_cursor() -> void:
    if _panel.get_section() == &"foliage":
        var scatter_id: String = _panel.get_selected_scatter_id()
        if scatter_id.is_empty():
            _create_default_scatter()
            scatter_id = _panel.get_selected_scatter_id()
        if scatter_id.is_empty(): return
        _report(_service.add_scatter_stroke(scatter_id, str(_operation), _cursor_position, _panel.get_radius(), 1.0), "%s scatter applied" % str(_operation).capitalize())
        return
    if not _pending_spline_kind.is_empty():
        if _pending_first_point == null:
            _pending_first_point = _cursor_position
            status_changed.emit("%s: place second point" % _pending_spline_kind.capitalize(), false)
            return
        var points: Array[Vector3] = [_pending_first_point as Vector3, _cursor_position]
        var options: Dictionary = {"sample_spacing_m": 3.0}
        if _pending_spline_kind == "fence": options["segment_source"] = {"kind": "primitive", "primitive": "post"}
        var result: Dictionary = _service.create_spline("%s %d" % [_pending_spline_kind.capitalize(), _service.get_splines().size() + 1], _pending_spline_kind, points, options)
        _pending_spline_kind = ""
        _pending_first_point = null
        _report(result, "Spline created")
        if result.get("ok", false): _panel.select_spline(str(result.get("spline_id", "")))
        return
    _add_point_to_selected_spline()


func _on_viewport_pressed(node: Node, hit_position: Vector3, _hit_normal: Vector3) -> void:
    if not is_open() or not _is_terrain_node(node): return
    _cursor_position = hit_position
    _update_cursor_height()
    _apply_at_cursor()


func _on_tool_selected(tool: StringName) -> void:
    if tool == &"foliage": toggle_tool(&"foliage")
    elif tool == &"roads": toggle_tool(&"splines")
    elif is_open(): close_tool()


func _refresh_panel_data() -> void:
    if _service == null: return
    _panel.set_data(_service.get_foliage_sets(), _service.get_scatter_layers(), _service.get_splines())
    _sync_cursor_scale()


func _on_service_status(message: String, is_error: bool) -> void: status_changed.emit(message, is_error)


func _report(result: Dictionary, success_message: String) -> void:
    if result.get("ok", false):
        _refresh_panel_data()
        status_changed.emit(success_message, false)
    else:
        status_changed.emit(str(result.get("errors", ["Procedural action failed."])[0]), true)


func _ensure_cursor() -> void:
    if _cursor != null and is_instance_valid(_cursor): return
    _cursor = MeshInstance3D.new()
    _cursor.name = "ProceduralCursor"
    var mesh := CylinderMesh.new()
    mesh.top_radius = 1.0
    mesh.bottom_radius = 1.0
    mesh.height = 0.05
    mesh.radial_segments = 32
    _cursor.mesh = mesh
    _cursor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    _editor_viewport.get_world_root().add_child(_cursor)
    _set_cursor_section(&"foliage")
    _sync_cursor_scale()
    _set_cursor_visible(false)


func _set_cursor_section(section: StringName) -> void:
    if _cursor == null: return
    var material := StandardMaterial3D.new()
    var color: Color = Tokens.FOLIAGE if section == &"foliage" else Tokens.ROADS
    material.albedo_color = Color(color.r, color.g, color.b, 0.32)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _cursor.material_override = material
    _sync_cursor_scale()


func _sync_cursor_scale() -> void:
    if _cursor == null: return
    var radius: float = _panel.get_radius() if _panel != null and _panel.get_section() == &"foliage" else 1.6
    _cursor.scale = Vector3(radius, 1.0, radius)


func _update_cursor_height() -> void:
    if _cursor == null or _terrain_controller == null: return
    var terrain_runtime = _terrain_controller.get_runtime()
    if terrain_runtime != null: _cursor_position.y = terrain_runtime.sample_height(_cursor_position) + 0.12
    _cursor.position = _cursor_position
    _sync_cursor_scale()


func _set_cursor_visible(visible_value: bool) -> void:
    if _cursor != null: _cursor.visible = visible_value


func _restore_empty_state() -> void:
    if _viewport_center == null or _workspace == null: return
    var should_show: bool = not _workspace.has_method("get_mode") or _workspace.get_mode() == &"build"
    if should_show and _workspace.has_method("get_runtime_entity_count"): should_show = int(_workspace.call("get_runtime_entity_count")) == 0
    if should_show and _workspace.has_method("is_placement_active") and bool(_workspace.call("is_placement_active")): should_show = false
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


static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
