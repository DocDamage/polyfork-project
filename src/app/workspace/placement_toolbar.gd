class_name PlayWorldPlacementToolbar
extends PanelContainer

signal action_requested(action: StringName, enabled: bool)

@onready var place_button: Button = %PlaceButton
@onready var grid_button: Button = %GridButton
@onready var surface_button: Button = %SurfaceButton
@onready var object_button: Button = %ObjectButton
@onready var socket_button: Button = %SocketButton
@onready var ground_button: Button = %GroundButton
@onready var group_button: Button = %GroupButton
@onready var undo_button: Button = %UndoButton
@onready var redo_button: Button = %RedoButton


func _ready() -> void:
    place_button.pressed.connect(_emit_action.bind(&"place"))
    ground_button.pressed.connect(_emit_action.bind(&"ground"))
    group_button.pressed.connect(_emit_action.bind(&"group"))
    undo_button.pressed.connect(_emit_action.bind(&"undo"))
    redo_button.pressed.connect(_emit_action.bind(&"redo"))
    grid_button.toggled.connect(_emit_toggle.bind(&"grid"))
    surface_button.toggled.connect(_emit_toggle.bind(&"surface"))
    object_button.toggled.connect(_emit_toggle.bind(&"object"))
    socket_button.toggled.connect(_emit_toggle.bind(&"socket"))
    grid_button.button_pressed = true
    _configure_focus()


func focus_primary() -> void:
    place_button.grab_focus()


func set_history_state(can_undo: bool, can_redo: bool) -> void:
    undo_button.disabled = not can_undo
    redo_button.disabled = not can_redo


func set_group_enabled(enabled: bool) -> void:
    group_button.disabled = not enabled


func _emit_action(action: StringName) -> void:
    action_requested.emit(action, true)


func _emit_toggle(enabled: bool, action: StringName) -> void:
    action_requested.emit(action, enabled)


func _configure_focus() -> void:
    var buttons: Array[Button] = [place_button, grid_button, surface_button, object_button, socket_button, ground_button, group_button, undo_button, redo_button]
    for index in range(buttons.size()):
        var button: Button = buttons[index]
        var left: Button = buttons[(index - 1 + buttons.size()) % buttons.size()]
        var right: Button = buttons[(index + 1) % buttons.size()]
        button.focus_neighbor_left = button.get_path_to(left)
        button.focus_neighbor_right = button.get_path_to(right)
