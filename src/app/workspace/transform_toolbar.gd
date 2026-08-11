class_name PlayWorldTransformToolbar
extends PanelContainer

signal tool_selected(tool: StringName)

@onready var select_button: Button = %SelectButton
@onready var move_button: Button = %MoveButton
@onready var rotate_button: Button = %RotateButton
@onready var scale_button: Button = %ScaleButton
@onready var duplicate_button: Button = %DuplicateButton
@onready var delete_button: Button = %DeleteButton

var _active_tool: StringName = &"select"
var _mode_buttons: Dictionary = {}


func _ready() -> void:
    var group := ButtonGroup.new()
    group.allow_unpress = false
    _mode_buttons = {
        &"select": select_button,
        &"move": move_button,
        &"rotate": rotate_button,
        &"scale": scale_button
    }
    for button in _mode_buttons.values():
        button.toggle_mode = true
        button.button_group = group

    select_button.button_pressed = true
    select_button.pressed.connect(select_tool.bind(&"select", true))
    move_button.pressed.connect(select_tool.bind(&"move", true))
    rotate_button.pressed.connect(select_tool.bind(&"rotate", true))
    scale_button.pressed.connect(select_tool.bind(&"scale", true))
    duplicate_button.pressed.connect(_emit_action.bind(&"duplicate"))
    delete_button.pressed.connect(_emit_action.bind(&"delete"))


func get_active_tool() -> StringName:
    return _active_tool


func select_tool(tool: StringName, emit_signal: bool = false) -> void:
    if not _mode_buttons.has(tool):
        return
    _active_tool = tool
    var button: Button = _mode_buttons[tool]
    button.button_pressed = true
    if emit_signal:
        tool_selected.emit(tool)


func _emit_action(tool: StringName) -> void:
    tool_selected.emit(tool)
