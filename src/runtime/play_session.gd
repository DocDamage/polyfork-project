class_name PlayWorldPlaySession
extends Node3D

signal exit_requested
signal state_changed(active: bool)

const GameplayInput = preload("res://src/input/gameplay_input_map.gd")
const RuntimeState = preload("res://src/runtime/play_runtime_state.gd")
const ThirdPersonController = preload("res://src/runtime/third_person_controller.gd")
const FirstPersonController = preload("res://src/runtime/first_person_controller.gd")

var _runtime_state = RuntimeState.new()
var _editor_session
var _player: CharacterBody3D
var _active := false
var _selected_ids: Array[String] = []
var _primary_id := ""


func _init() -> void:
    name = "PlaySession"


func enter_play(editor_session) -> Dictionary:
    if _active:
        return _failure("Play session is already active.")
    if editor_session == null:
        return _failure("Play session requires an editor session.")
    var project_data: Dictionary = editor_session.get_project_data()
    if project_data.is_empty():
        return _failure("Play session requires authored project data.")

    var input_result: Dictionary = GameplayInput.install_defaults()
    if not input_result.get("ok", false):
        return input_result
    var state_result: Dictionary = _runtime_state.load_authored_project(project_data)
    if not state_result.get("ok", false):
        return state_result

    _editor_session = editor_session
    _selected_ids = editor_session.get_selected_ids()
    _primary_id = editor_session.get_primary_entity_id()
    editor_session.clear_selection()

    var runtime_config: Dictionary = project_data.get("runtime", {})
    var camera_config: Dictionary = runtime_config.get("camera_configuration", {})
    var controller := str(camera_config.get("controller", "none"))
    var spawn_result: Dictionary = _spawn_player(controller, camera_config)
    if not spawn_result.get("ok", false):
        _rollback_startup()
        return spawn_result

    _active = true
    state_changed.emit(true)
    return {"ok": true, "errors": [], "controller": controller, "entity_count": state_result.get("entity_count", 0)}


func exit_play() -> Dictionary:
    if not _active and _editor_session == null:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        return {"ok": true, "errors": [], "changed": false}
    _free_player()
    _runtime_state.clear()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var editor_session = _editor_session
    _editor_session = null
    _active = false
    if editor_session != null:
        var refresh_result: Dictionary = editor_session.refresh_runtime(false)
        if not refresh_result.get("ok", false):
            state_changed.emit(false)
            return refresh_result
        if editor_session.has_method("restore_selection"):
            editor_session.restore_selection(_selected_ids, _primary_id)
    _selected_ids.clear()
    _primary_id = ""
    state_changed.emit(false)
    return {"ok": true, "errors": [], "changed": true}


func is_active() -> bool:
    return _active


func get_runtime_state():
    return _runtime_state


func get_player():
    return _player


func _unhandled_input(event: InputEvent) -> void:
    if not _active:
        return
    if event.is_action_pressed(GameplayInput.EXIT):
        exit_requested.emit()
        get_viewport().set_input_as_handled()


func _spawn_player(controller: String, config: Dictionary) -> Dictionary:
    match controller:
        "none":
            return {"ok": true, "errors": [], "controller": controller}
        "third_person":
            var third_person = ThirdPersonController.new()
            third_person.configure(config)
            add_child(third_person)
            _player = third_person
        "first_person":
            var first_person = FirstPersonController.new()
            first_person.configure(config)
            add_child(first_person)
            _player = first_person
        _:
            return _failure("Unsupported Play controller: %s" % controller)
    return {"ok": true, "errors": [], "controller": controller}


func _rollback_startup() -> void:
    _free_player()
    _runtime_state.clear()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if _editor_session != null and _editor_session.has_method("restore_selection"):
        _editor_session.restore_selection(_selected_ids, _primary_id)
    _editor_session = null
    _selected_ids.clear()
    _primary_id = ""


func _free_player() -> void:
    if _player == null:
        return
    if _player.has_method("release_pointer"):
        _player.release_pointer()
    if _player.get_parent() == self:
        remove_child(_player)
    _player.free()
    _player = null


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
