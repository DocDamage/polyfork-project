class_name PlayWorldModeSwitch
extends PanelContainer

signal mode_changed(mode: StringName)

const BUILD_MODE: StringName = &"build"
const PLAY_MODE: StringName = &"play"

@onready var build_button: Button = %BuildButton
@onready var play_button: Button = %PlayButton

var _mode: StringName = BUILD_MODE


func _ready() -> void:
    var group := ButtonGroup.new()
    group.allow_unpress = false
    build_button.button_group = group
    play_button.button_group = group
    build_button.button_pressed = true
    build_button.pressed.connect(set_mode.bind(BUILD_MODE))
    play_button.pressed.connect(set_mode.bind(PLAY_MODE))


func set_mode(mode: StringName) -> void:
    if mode != BUILD_MODE and mode != PLAY_MODE:
        return

    _mode = mode
    build_button.button_pressed = mode == BUILD_MODE
    play_button.button_pressed = mode == PLAY_MODE
    mode_changed.emit(_mode)


func get_mode() -> StringName:
    return _mode


func focus_primary() -> void:
    if _mode == PLAY_MODE:
        play_button.grab_focus()
    else:
        build_button.grab_focus()
