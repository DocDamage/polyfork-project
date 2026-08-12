class_name PlayWorldPlaySession
extends Node3D

signal exit_requested
signal state_changed(active: bool)

const GameplayInput = preload("res://src/input/gameplay_input_map.gd")
const RuntimeState = preload("res://src/runtime/play_runtime_state.gd")
const RuntimeModules = preload("res://src/templates/runtime_module_registry.gd")
const ThirdPersonController = preload("res://src/runtime/third_person_controller.gd")
const FirstPersonController = preload("res://src/runtime/first_person_controller.gd")

var _runtime_state = RuntimeState.new()
var _editor_session
var _player: CharacterBody3D
var _active := false
var _selected_ids: Array[String] = []
var _primary_id := ""
var _streaming_callback := Callable()
var _previous_camera: Camera3D
var _spawn_entity_id := ""


func _init() -> void: name = "PlaySession"
func configure_streaming(callback: Callable) -> void: _streaming_callback = callback


func enter_play(editor_session) -> Dictionary:
    if _active: return _failure("Play session is already active.")
    if editor_session == null: return _failure("Play session requires an editor session.")
    var project_data: Dictionary = editor_session.get_project_data()
    if project_data.is_empty(): return _failure("Play session requires authored project data.")
    var runtime_config: Dictionary = project_data.get("runtime", {})
    var module_result: Dictionary = RuntimeModules.new().resolve(runtime_config.get("resolved_modules", []))
    if not module_result.get("ok", false): return module_result
    var input_result: Dictionary = GameplayInput.install_profile(runtime_config.get("input_mapping", {}))
    if not input_result.get("ok", false): return input_result
    var state_result: Dictionary = _runtime_state.load_authored_project(project_data)
    if not state_result.get("ok", false): GameplayInput.uninstall_owned(); return state_result

    _editor_session = editor_session
    _selected_ids = editor_session.get_selected_ids(); _primary_id = editor_session.get_primary_entity_id()
    _previous_camera = get_viewport().get_camera_3d()
    editor_session.clear_selection()
    _spawn_entity_id = str(runtime_config.get("spawn_entity_id", ""))
    var exclusion_result: Dictionary = editor_session.get_bridge().set_excluded_entity_ids([] if _spawn_entity_id.is_empty() else [_spawn_entity_id])
    if not exclusion_result.get("ok", false): _rollback_startup(); return exclusion_result

    var camera_config: Dictionary = runtime_config.get("camera_configuration", {}).duplicate(true)
    _apply_spawn_position(camera_config, runtime_config)
    var controller := str(camera_config.get("controller", "none"))
    var spawn_result: Dictionary = _spawn_player(controller, camera_config)
    if not spawn_result.get("ok", false): _rollback_startup(); return spawn_result

    _active = true; _update_streaming_focus(); state_changed.emit(true)
    return {"ok": true, "errors": [], "controller": controller, "entity_count": state_result.get("entity_count", 0), "spawn_entity_id": _spawn_entity_id}


func exit_play() -> Dictionary:
    if not _active and _editor_session == null:
        GameplayInput.uninstall_owned(); Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        return {"ok": true, "errors": [], "changed": false}
    _free_player(); _runtime_state.clear(); GameplayInput.uninstall_owned(); Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if is_instance_valid(_previous_camera): _previous_camera.current = true
    _previous_camera = null
    var editor_session = _editor_session
    if editor_session != null: editor_session.get_bridge().clear_excluded_entity_ids()
    _editor_session = null; _active = false; _spawn_entity_id = ""
    if editor_session != null:
        var refresh_result: Dictionary = editor_session.refresh_runtime(false)
        if not refresh_result.get("ok", false): state_changed.emit(false); return refresh_result
        if editor_session.has_method("restore_selection"): editor_session.restore_selection(_selected_ids, _primary_id)
    _selected_ids.clear(); _primary_id = ""; state_changed.emit(false)
    return {"ok": true, "errors": [], "changed": true}


func is_active() -> bool: return _active
func get_runtime_state(): return _runtime_state
func get_player(): return _player


func _physics_process(_delta: float) -> void:
    if _active: _update_streaming_focus()


func _unhandled_input(event: InputEvent) -> void:
    if _active and event.is_action_pressed(GameplayInput.EXIT): exit_requested.emit(); get_viewport().set_input_as_handled()


func _spawn_player(controller: String, config: Dictionary) -> Dictionary:
    match controller:
        "none": return {"ok": true, "errors": [], "controller": controller}
        "third_person":
            var player = ThirdPersonController.new(); player.configure(config); add_child(player); _player = player
        "first_person":
            var player = FirstPersonController.new(); player.configure(config); add_child(player); _player = player
        _: return _failure("Unsupported Play controller: %s" % controller)
    return {"ok": true, "errors": [], "controller": controller}


func _apply_spawn_position(config: Dictionary, runtime_config: Dictionary) -> void:
    var spawn_id := str(runtime_config.get("spawn_entity_id", ""))
    if spawn_id.is_empty(): return
    var record: Dictionary = _runtime_state.get_entity(spawn_id)
    if record.is_empty(): return
    var position_value = record.get("transform", {}).get("position", [])
    if position_value is Array and position_value.size() == 3: config["spawn_position"] = position_value.duplicate()


func _update_streaming_focus() -> void:
    if not _streaming_callback.is_valid() or not is_instance_valid(_player): return
    var result: Variant = _streaming_callback.call(_player.global_position)
    if result is Dictionary and not result.get("ok", false): push_warning("Play streaming focus update failed: %s" % str(result.get("errors", [])))


func _rollback_startup() -> void:
    _free_player(); _runtime_state.clear(); GameplayInput.uninstall_owned(); Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if is_instance_valid(_previous_camera): _previous_camera.current = true
    _previous_camera = null
    if _editor_session != null:
        _editor_session.get_bridge().clear_excluded_entity_ids()
        if _editor_session.has_method("restore_selection"): _editor_session.restore_selection(_selected_ids, _primary_id)
    _editor_session = null; _spawn_entity_id = ""; _selected_ids.clear(); _primary_id = ""


func _free_player() -> void:
    if _player == null: return
    if _player.has_method("release_pointer"): _player.release_pointer()
    if _player.get_parent() == self: remove_child(_player)
    _player.free(); _player = null


func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
