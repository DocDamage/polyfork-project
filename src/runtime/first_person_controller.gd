class_name PlayWorldFirstPersonController
extends CharacterBody3D

const GameplayInput = preload("res://src/input/gameplay_input_map.gd")

var move_speed := 6.0
var acceleration := 24.0
var jump_velocity := 6.0
var mouse_sensitivity := 0.0025
var stick_look_speed := 2.5
var jump_enabled := true
var eye_height := 1.58
var _gravity := 9.8
var _yaw := 0.0
var _pitch := 0.0
var _camera: Camera3D
var _pointer_look_enabled := false
var _local_input_enabled := true

func configure(config: Dictionary) -> void:
    move_speed = float(config.get("move_speed", move_speed))
    acceleration = float(config.get("acceleration", acceleration))
    jump_velocity = float(config.get("jump_velocity", jump_velocity))
    mouse_sensitivity = float(config.get("mouse_sensitivity", mouse_sensitivity))
    stick_look_speed = float(config.get("stick_look_speed", stick_look_speed))
    jump_enabled = bool(config.get("jump_enabled", true))
    eye_height = clamp(float(config.get("eye_height", eye_height)), 0.8, 2.5)
    _local_input_enabled = bool(config.get("local_input_enabled", true))
    position = _vector3(config.get("spawn_position", [0.0, 2.0, 0.0]))

func _ready() -> void:
    name = "FirstPersonPlayer"
    _gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
    _ensure_body(); _ensure_camera()
    set_local_input_enabled(_local_input_enabled)

func _physics_process(delta: float) -> void:
    if not _local_input_enabled: return
    var look := Input.get_vector(GameplayInput.LOOK_LEFT, GameplayInput.LOOK_RIGHT, GameplayInput.LOOK_UP, GameplayInput.LOOK_DOWN)
    if look.length_squared() > 0.0001: _apply_look(look.x * stick_look_speed * delta, look.y * stick_look_speed * delta)
    var movement := Input.get_vector(GameplayInput.MOVE_LEFT, GameplayInput.MOVE_RIGHT, GameplayInput.MOVE_FORWARD, GameplayInput.MOVE_BACK)
    var forward := -global_transform.basis.z; var right := global_transform.basis.x
    var direction := (right * movement.x + forward * -movement.y); direction.y = 0.0; direction = direction.normalized()
    velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
    velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)
    if not is_on_floor(): velocity.y -= _gravity * delta
    elif jump_enabled and Input.is_action_just_pressed(GameplayInput.JUMP): velocity.y = jump_velocity
    move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
    if not _local_input_enabled: return
    if event is InputEventMouseMotion and _pointer_look_enabled: _apply_look(event.relative.x * mouse_sensitivity, event.relative.y * mouse_sensitivity)

func set_local_input_enabled(enabled: bool) -> void:
    _local_input_enabled = enabled
    _pointer_look_enabled = enabled
    if _camera != null: _camera.current = enabled
    if enabled: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func is_local_input_enabled() -> bool: return _local_input_enabled

func apply_network_state(position_value: Vector3, rotation_y_value: float) -> void:
    global_position = position_value
    rotation.y = rotation_y_value
    _yaw = rotation_y_value

func get_network_state() -> Dictionary:
    return {"position": global_position, "rotation_y": rotation.y, "velocity": velocity}

func release_pointer() -> void:
    _pointer_look_enabled = false
    if _local_input_enabled: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func get_camera() -> Camera3D: return _camera

func _apply_look(yaw_delta: float, pitch_delta: float) -> void:
    _yaw -= yaw_delta; _pitch = clamp(_pitch - pitch_delta, -1.45, 1.45); rotation.y = _yaw
    if _camera != null: _camera.rotation.x = _pitch

func _ensure_body() -> void:
    var collision := CollisionShape3D.new(); collision.name = "PlayerCollision"
    var shape := CapsuleShape3D.new(); shape.radius = 0.38; shape.height = 1.8
    collision.shape = shape; collision.position.y = 0.9; add_child(collision)

func _ensure_camera() -> void:
    _camera = Camera3D.new(); _camera.name = "FirstPersonCamera"; _camera.position = Vector3(0.0, eye_height, 0.0); _camera.current = _local_input_enabled; add_child(_camera)

static func _vector3(value: Variant) -> Vector3:
    if not value is Array or value.size() != 3: return Vector3(0.0, 2.0, 0.0)
    return Vector3(float(value[0]), float(value[1]), float(value[2]))
