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


func _ready() -> void:
    var group := ButtonGroup.new()
    group.allow_unpress = false
    for button in [select_button, move_button, rotate_button, scale_button]:
        button.toggle_mode = true
        button.button_group = group

    select_button.button_pressed = true
    select_button.pressed.connect(_select.bind(&"select"))
    move_button.pressed.connect(_select.bind(&"move"))
    rotate_button.pressed.connect(_select.bind(&"rotate"))
    scale_button.pressed.connect(_select.bind(&"scale"))
    duplicate_button.pressed.connect(_select.bind(&"duplicate"))
    delete_button.pressed.connect(_select.bind(&"delete"))


func get_active_tool() -> StringName:
    return _active_tool


func _select(tool: StringName) -> void:
    _active_tool = tool
    tool_selected.emit(tool)
