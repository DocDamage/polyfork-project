class_name PlayWorldGameplayInputMap
extends RefCounted

const MOVE_LEFT: StringName = &"play_move_left"
const MOVE_RIGHT: StringName = &"play_move_right"
const MOVE_FORWARD: StringName = &"play_move_forward"
const MOVE_BACK: StringName = &"play_move_back"
const LOOK_LEFT: StringName = &"play_look_left"
const LOOK_RIGHT: StringName = &"play_look_right"
const LOOK_UP: StringName = &"play_look_up"
const LOOK_DOWN: StringName = &"play_look_down"
const JUMP: StringName = &"play_jump"
const INTERACT: StringName = &"play_interact"
const PRIMARY: StringName = &"play_primary"
const PAUSE: StringName = &"play_pause"
const EXIT: StringName = &"play_exit"

static var _owned_actions: Dictionary = {}


static func install_profile(mapping: Dictionary) -> Dictionary:
    var profile := str(mapping.get("profile", "semantic_default"))
    if profile != "semantic_default":
        return {"ok": false, "errors": ["Unsupported gameplay input profile: %s" % profile]}
    return install_defaults()


static func install_defaults() -> Dictionary:
    _ensure_action(MOVE_LEFT, [_key(KEY_A), _joy_axis(JOY_AXIS_LEFT_X, -1.0)])
    _ensure_action(MOVE_RIGHT, [_key(KEY_D), _joy_axis(JOY_AXIS_LEFT_X, 1.0)])
    _ensure_action(MOVE_FORWARD, [_key(KEY_W), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)])
    _ensure_action(MOVE_BACK, [_key(KEY_S), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)])
    _ensure_action(LOOK_LEFT, [_joy_axis(JOY_AXIS_RIGHT_X, -1.0)])
    _ensure_action(LOOK_RIGHT, [_joy_axis(JOY_AXIS_RIGHT_X, 1.0)])
    _ensure_action(LOOK_UP, [_joy_axis(JOY_AXIS_RIGHT_Y, -1.0)])
    _ensure_action(LOOK_DOWN, [_joy_axis(JOY_AXIS_RIGHT_Y, 1.0)])
    _ensure_action(JUMP, [_key(KEY_SPACE), _joy_button(JOY_BUTTON_A)])
    _ensure_action(INTERACT, [_key(KEY_E), _joy_button(JOY_BUTTON_X)])
    _ensure_action(PRIMARY, [_mouse_button(MOUSE_BUTTON_LEFT), _joy_button(JOY_BUTTON_RIGHT_SHOULDER)])
    _ensure_action(PAUSE, [_key(KEY_P), _joy_button(JOY_BUTTON_START)])
    _ensure_action(EXIT, [_key(KEY_ESCAPE), _joy_button(JOY_BUTTON_BACK), _joy_button(JOY_BUTTON_B)])
    return {"ok": true, "errors": [], "actions": action_names()}


static func uninstall_owned() -> Dictionary:
    var removed: Array[StringName] = []
    for action in action_names():
        if bool(_owned_actions.get(action, false)) and InputMap.has_action(action):
            InputMap.erase_action(action)
            removed.append(action)
    _owned_actions.clear()
    return {"ok": true, "errors": [], "removed": removed}


static func action_names() -> Array[StringName]:
    return [MOVE_LEFT, MOVE_RIGHT, MOVE_FORWARD, MOVE_BACK, LOOK_LEFT, LOOK_RIGHT, LOOK_UP, LOOK_DOWN, JUMP, INTERACT, PRIMARY, PAUSE, EXIT]


static func _ensure_action(action: StringName, events: Array) -> void:
    var existed := InputMap.has_action(action)
    if not existed:
        InputMap.add_action(action, 0.2)
        _owned_actions[action] = true
    if not InputMap.action_get_events(action).is_empty(): return
    for event in events: InputMap.action_add_event(action, event)


static func _key(keycode: Key) -> InputEventKey:
    var event := InputEventKey.new(); event.physical_keycode = keycode; return event


static func _joy_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
    var event := InputEventJoypadMotion.new(); event.axis = axis; event.axis_value = value; return event


static func _joy_button(button: JoyButton) -> InputEventJoypadButton:
    var event := InputEventJoypadButton.new(); event.button_index = button; return event


static func _mouse_button(button: MouseButton) -> InputEventMouseButton:
    var event := InputEventMouseButton.new(); event.button_index = button; return event
