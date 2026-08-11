class_name PlayWorldEditorViewport3D
extends SubViewportContainer

signal runtime_node_pressed(node: Node, hit_position: Vector3, hit_normal: Vector3)

@onready var world_viewport: SubViewport = $WorldViewport
@onready var world_root: Node3D = $WorldViewport/WorldRoot
@onready var camera: Camera3D = $WorldViewport/WorldRoot/Camera3D
@onready var ground: MeshInstance3D = $WorldViewport/WorldRoot/Ground
@onready var ground_collision: CollisionShape3D = $WorldViewport/WorldRoot/GroundBody/CollisionShape3D

var _terrain_view := false


func _ready() -> void:
    stretch = true
    world_viewport.transparent_bg = true
    gui_input.connect(_on_gui_input)


func get_world_root() -> Node3D: return world_root


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
        camera.position = Vector3(8.0, 7.0, 10.0)
        camera.rotation_degrees = Vector3(-25.0, 38.0, 0.0)
        camera.fov = 75.0
        camera.far = 4000.0


func is_terrain_view() -> bool: return _terrain_view


func pick_at(screen_position: Vector2) -> Dictionary:
    if camera == null or world_viewport == null: return {"ok": false, "errors": ["Editor viewport camera is unavailable."]}
    var origin: Vector3 = camera.project_ray_origin(screen_position)
    var direction: Vector3 = camera.project_ray_normal(screen_position)
    var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 10000.0)
    var hit: Dictionary = world_viewport.world_3d.direct_space_state.intersect_ray(query)
    if hit.is_empty(): return {"ok": true, "hit": false}
    return {"ok": true, "hit": true, "node": hit.get("collider"), "position": hit.get("position", Vector3.ZERO), "normal": hit.get("normal", Vector3.UP)}


func _on_gui_input(event: InputEvent) -> void:
    if not event is InputEventMouseButton: return
    var mouse_event := event as InputEventMouseButton
    if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed: return
    var result: Dictionary = pick_at(mouse_event.position)
    if result.get("hit", false):
        runtime_node_pressed.emit(result["node"], result["position"], result["normal"])
        accept_event()
