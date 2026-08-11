class_name PlayWorldToolWheel
extends PanelContainer

signal tool_selected(tool: StringName)
signal closed

@onready var select_button: Button = %SelectButton
@onready var place_button: Button = %PlaceButton
@onready var move_button: Button = %MoveButton
@onready var rotate_button: Button = %RotateButton
@onready var scale_button: Button = %ScaleButton
@onready var duplicate_button: Button = %DuplicateButton
@onready var delete_button: Button = %DeleteButton
@onready var group_button: Button = %GroupButton


func _ready() -> void:
    var mappings := {
        select_button: &"select",
        place_button: &"place",
        move_button: &"move",
        rotate_button: &"rotate",
        scale_button: &"scale",
        duplicate_button: &"duplicate",
        delete_button: &"delete",
        group_button: &"group"
    }
    for button in mappings.keys():
        button.pressed.connect(_choose.bind(mappings[button]))
    hide()
    _configure_focus()


func open_wheel() -> void:
    show()
    call_deferred("focus_primary")


func close_wheel() -> void:
    if not visible:
        return
    hide()
    closed.emit()


func is_open() -> bool:
    return visible


func focus_primary() -> void:
    select_button.grab_focus()


func _choose(tool: StringName) -> void:
    tool_selected.emit(tool)
    close_wheel()


func _configure_focus() -> void:
    var buttons := [select_button, place_button, move_button, rotate_button, scale_button, duplicate_button, delete_button, group_button]
    for index in range(buttons.size()):
        var button: Button = buttons[index]
        var left_index := index - 1 if index % 2 == 1 else index + 1
        var up_index := (index - 2 + buttons.size()) % buttons.size()
        var down_index := (index + 2) % buttons.size()
        button.focus_neighbor_left = button.get_path_to(buttons[left_index])
        button.focus_neighbor_right = button.get_path_to(buttons[left_index])
        button.focus_neighbor_top = button.get_path_to(buttons[up_index])
        button.focus_neighbor_bottom = button.get_path_to(buttons[down_index])
