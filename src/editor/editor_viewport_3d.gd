class_name PlayWorldEditorViewport3D
extends SubViewportContainer

signal runtime_node_pressed(node: Node, hit_position: Vector3, hit_normal: Vector3)
signal camera_mode_changed(mode: StringName)
signal box_selection_completed(entity_ids: Array[String])

@onready var world_viewport: SubViewport = $WorldViewport
@onready var world_root: Node3D = $WorldViewport/WorldRoot
@onready var camera: Camera3D = $WorldViewport/WorldRoot/Camera3D
@onready var ground: MeshInstance3D = $WorldViewport/WorldRoot/Ground
@onready var ground_collision: CollisionShape3D = $WorldViewport/WorldRoot/GroundBody/CollisionShape3D

var _terrain_view := false
var _camera_mode: StringName = &"free"
var _fly_look_active := false
var _left_drag_active := false
var _drag_start := Vector2.ZERO
var _drag_current := Vector2.ZERO
var _move_speed := 14.0
var _yaw := 0.0
var _pitch := -0.35
var _orbit_yaw := 0.7
var _orbit_pitch := -0.45
var _orbit_distance := 18.0
var _orbit_focus := Vector3.ZERO
var _editor_session: Node
var _gizmo_root: Node3D
var _gizmo_mode: StringName = &"select"

func _ready() -> void:
    stretch = true
    focus_mode = Control.FOCUS_ALL
    world_viewport.transparent_bg = true
    gui_input.connect(_on_gui_input)
    _yaw = camera.rotation.y
    _pitch = camera.rotation.x
    _create_gizmo()
    call_deferred("_bind_editor_session")
    set_process(true)

func get_world_root() -> Node3D: return world_root
func get_camera_mode() -> StringName: return _camera_mode

func set_default_ground_visible(value: bool) -> void:
    if ground != null: ground.visible = value
    if ground_collision != null: ground_collision.disabled = not value

func set_terrain_view(enabled: bool) -> void:
    _terrain_view = enabled
    if camera == null: return
    if enabled:
        camera.position = Vector3(380.0, 300.0, 440.0)
        camera.fov = 62.0
        camera.far = 10000.0
        camera.look_at(Vector3(0.0, 35.0, 0.0), Vector3.UP)
    else:
        camera.fov = 75.0
        camera.far = 4000.0
        _apply_camera_pose()

func is_terrain_view() -> bool: return _terrain_view

func set_camera_mode(mode: StringName) -> Dictionary:
    if not [&"free", &"orbit"].has(mode): return {"ok": false, "errors": ["Unsupported authoring camera mode: %s" % mode]}
    if mode == _camera_mode: return {"ok": true, "errors": [], "mode": mode}
    _camera_mode = mode
    if mode == &"orbit":
        _orbit_focus = _selection_focus()
        _orbit_distance = clampf(camera.global_position.distance_to(_orbit_focus), 3.0, 120.0)
    else:
        _yaw = camera.rotation.y; _pitch = camera.rotation.x
    if not _terrain_view: _apply_camera_pose()
    camera_mode_changed.emit(mode)
    return {"ok": true, "errors": [], "mode": mode}

func toggle_camera_mode() -> StringName:
    var next: StringName = &"orbit" if _camera_mode == &"free" else &"free"
    set_camera_mode(next)
    return next

func focus_selection() -> void:
    _orbit_focus = _selection_focus()
    if _camera_mode == &"orbit" and not _terrain_view: _apply_camera_pose()

func pick_at(screen_position: Vector2) -> Dictionary:
    if camera == null or world_viewport == null: return {"ok": false, "errors": ["Editor viewport camera is unavailable."]}
    var origin: Vector3 = camera.project_ray_origin(screen_position)
    var direction: Vector3 = camera.project_ray_normal(screen_position)
    var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 10000.0)
    var hit: Dictionary = world_viewport.world_3d.direct_space_state.intersect_ray(query)
    if hit.is_empty(): return {"ok": true, "hit": false}
    return {"ok": true, "hit": true, "node": hit.get("collider"), "position": hit.get("position", Vector3.ZERO), "normal": hit.get("normal", Vector3.UP)}

func select_in_rect(rect: Rect2) -> Array[String]:
    var result: Array[String] = []
    if _editor_session == null or not _editor_session.has_method("get_bridge"): return result
    var bridge = _editor_session.call("get_bridge")
    if bridge == null: return result
    for entity_id in bridge.entity_ids():
        var node := bridge.get_entity_node(entity_id) as Node3D
        if node == null or camera.is_position_behind(node.global_position): continue
        var point: Vector2 = camera.unproject_position(node.global_position)
        if rect.has_point(point): result.append(str(entity_id))
    result.sort()
    return result

func _process(delta: float) -> void:
    if camera == null or _terrain_view: return
    _sync_gizmo()
    var joypad: int = _active_joypad()
    if _camera_mode == &"free":
        var move := Vector3.ZERO
        if _fly_look_active:
            if Input.is_key_pressed(KEY_W): move.z -= 1.0
            if Input.is_key_pressed(KEY_S): move.z += 1.0
            if Input.is_key_pressed(KEY_A): move.x -= 1.0
            if Input.is_key_pressed(KEY_D): move.x += 1.0
            if Input.is_key_pressed(KEY_Q): move.y -= 1.0
            if Input.is_key_pressed(KEY_E): move.y += 1.0
        if joypad >= 0 and has_focus():
            move.x += Input.get_joy_axis(joypad, JOY_AXIS_LEFT_X)
            move.z += Input.get_joy_axis(joypad, JOY_AXIS_LEFT_Y)
            _yaw -= Input.get_joy_axis(joypad, JOY_AXIS_RIGHT_X) * delta * 2.2
            _pitch = clampf(_pitch - Input.get_joy_axis(joypad, JOY_AXIS_RIGHT_Y) * delta * 2.0, -1.45, 1.45)
        if move.length() > 0.05:
            move = move.normalized()
            var basis: Basis = camera.global_transform.basis
            camera.global_position += (basis.x * move.x + Vector3.UP * move.y + -basis.z * -move.z) * _move_speed * delta
        camera.rotation = Vector3(_pitch, _yaw, 0.0)
    else:
        if joypad >= 0 and has_focus():
            _orbit_yaw -= Input.get_joy_axis(joypad, JOY_AXIS_RIGHT_X) * delta * 2.2
            _orbit_pitch = clampf(_orbit_pitch - Input.get_joy_axis(joypad, JOY_AXIS_RIGHT_Y) * delta * 2.0, -1.35, 1.2)
        _apply_orbit_pose()

func _unhandled_input(event: InputEvent) -> void:
    if not is_visible_in_tree() or _terrain_view: return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
        toggle_camera_mode(); grab_focus(); get_viewport().set_input_as_handled(); return
    if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y:
        toggle_camera_mode(); grab_focus(); get_viewport().set_input_as_handled()

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_RIGHT:
            _fly_look_active = mouse.pressed
            if mouse.pressed: grab_focus(); Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
            else: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
            accept_event(); return
        if mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
            if _camera_mode == &"orbit": _orbit_distance = maxf(3.0, _orbit_distance * 0.88)
            else: _move_speed = minf(80.0, _move_speed * 1.15)
            accept_event(); return
        if mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
            if _camera_mode == &"orbit": _orbit_distance = minf(120.0, _orbit_distance * 1.12)
            else: _move_speed = maxf(2.0, _move_speed / 1.15)
            accept_event(); return
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            if mouse.pressed:
                grab_focus(); _left_drag_active = true; _drag_start = mouse.position; _drag_current = mouse.position; queue_redraw(); accept_event(); return
            if _left_drag_active:
                _left_drag_active = false; _drag_current = mouse.position; queue_redraw()
                if _drag_start.distance_to(_drag_current) >= 8.0: _complete_box_selection()
                else: _complete_click(mouse.position)
                accept_event(); return
    if event is InputEventMouseMotion:
        var motion := event as InputEventMouseMotion
        if _fly_look_active:
            if _camera_mode == &"free":
                _yaw -= motion.relative.x * 0.0035; _pitch = clampf(_pitch - motion.relative.y * 0.0035, -1.45, 1.45)
            else:
                _orbit_yaw -= motion.relative.x * 0.004; _orbit_pitch = clampf(_orbit_pitch - motion.relative.y * 0.004, -1.35, 1.2)
            accept_event(); return
        if _left_drag_active:
            _drag_current = motion.position; queue_redraw(); accept_event()

func _draw() -> void:
    if not _left_drag_active or _drag_start.distance_to(_drag_current) < 4.0: return
    var rect := Rect2(_drag_start, _drag_current - _drag_start).abs()
    draw_rect(rect, Color(0.42, 0.86, 0.98, 0.12), true)
    draw_rect(rect, Color(0.56, 0.92, 1.0, 0.9), false, 2.0)

func _complete_click(position_value: Vector2) -> void:
    var result: Dictionary = pick_at(position_value)
    if result.get("hit", false): runtime_node_pressed.emit(result["node"], result["position"], result["normal"])
    elif _editor_session != null and _editor_session.has_method("clear_selection"): _editor_session.call("clear_selection")

func _complete_box_selection() -> void:
    var rect := Rect2(_drag_start, _drag_current - _drag_start).abs()
    var ids: Array[String] = select_in_rect(rect)
    if _editor_session != null:
        if ids.is_empty(): _editor_session.call("clear_selection")
        else: _editor_session.call("restore_selection", ids, ids.back())
    box_selection_completed.emit(ids)

func _bind_editor_session() -> void:
    _editor_session = world_root.get_node_or_null("EditorSession")
    if _editor_session == null:
        await get_tree().process_frame
        _editor_session = world_root.get_node_or_null("EditorSession")
    if _editor_session != null and _editor_session.has_signal("selection_changed"):
        _editor_session.connect("selection_changed", Callable(self, "_on_session_selection_changed"))

func _on_session_selection_changed(_ids: Array, _primary_id: String, runtime_node: Node3D) -> void:
    if runtime_node != null: _orbit_focus = runtime_node.global_position
    _sync_gizmo(runtime_node)

func _selection_focus() -> Vector3:
    if _editor_session != null and _editor_session.has_method("get_primary_node"):
        var node := _editor_session.call("get_primary_node") as Node3D
        if node != null: return node.global_position
    return Vector3.ZERO

func _apply_camera_pose() -> void:
    if _camera_mode == &"orbit": _apply_orbit_pose()
    else: camera.rotation = Vector3(_pitch, _yaw, 0.0)

func _apply_orbit_pose() -> void:
    var direction := Vector3(cos(_orbit_pitch) * sin(_orbit_yaw), sin(_orbit_pitch), cos(_orbit_pitch) * cos(_orbit_yaw))
    camera.global_position = _orbit_focus + direction * _orbit_distance
    camera.look_at(_orbit_focus, Vector3.UP)

func _create_gizmo() -> void:
    _gizmo_root = Node3D.new(); _gizmo_root.name = "TransformGizmoVisual"; _gizmo_root.visible = false; world_root.add_child(_gizmo_root)
    var mesh := ImmediateMesh.new(); mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    mesh.surface_set_color(Color(0.98, 0.34, 0.38)); mesh.surface_add_vertex(Vector3.ZERO); mesh.surface_add_vertex(Vector3(2.4, 0.0, 0.0))
    mesh.surface_set_color(Color(0.42, 0.92, 0.48)); mesh.surface_add_vertex(Vector3.ZERO); mesh.surface_add_vertex(Vector3(0.0, 2.4, 0.0))
    mesh.surface_set_color(Color(0.38, 0.66, 1.0)); mesh.surface_add_vertex(Vector3.ZERO); mesh.surface_add_vertex(Vector3(0.0, 0.0, 2.4)); mesh.surface_end()
    var instance := MeshInstance3D.new(); instance.mesh = mesh
    var material := StandardMaterial3D.new(); material.vertex_color_use_as_albedo = true; material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; material.no_depth_test = true
    instance.material_override = material; _gizmo_root.add_child(instance)

func _sync_gizmo(runtime_node: Node3D = null) -> void:
    if _gizmo_root == null or _editor_session == null: return
    if runtime_node == null and _editor_session.has_method("get_primary_node"): runtime_node = _editor_session.call("get_primary_node") as Node3D
    var gizmo_state: Variant = _editor_session.get("_gizmo")
    if gizmo_state != null: _gizmo_mode = StringName(str(gizmo_state.get("mode")))
    _gizmo_root.visible = runtime_node != null and _gizmo_mode != &"select"
    if runtime_node != null: _gizmo_root.global_position = runtime_node.global_position

func _active_joypad() -> int:
    var ids := Input.get_connected_joypads()
    return -1 if ids.is_empty() else int(ids[0])
