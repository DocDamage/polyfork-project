class_name PlayWorldWorkspaceScreen
extends Control

signal home_requested
signal mode_changed(mode: StringName)

@onready var home_button: Button = %HomeButton
@onready var world_title: Label = %WorldTitle
@onready var world_context: Label = %WorldContext
@onready var mode_switch: Control = $TopBar/TopMargin/TopRow/ModeSlot/ModeSwitch
@onready var mode_badge: Label = $ViewportFrame/ViewportBackdrop/ViewportBadge/BadgeText

var _configuration: Dictionary = {}
var _mode: StringName = &"build"


func _ready() -> void:
    home_button.pressed.connect(_request_home)
    mode_switch.mode_changed.connect(_on_mode_changed)
    _apply_mode_label()


func set_configuration(configuration: Dictionary) -> void:
    _configuration = configuration.duplicate(true)
    world_title.text = str(_configuration.get("title", "Untitled World"))

    var profile := str(_configuration.get("world_profile", "medium")).capitalize()
    var template := str(_configuration.get("template_id", "blank_sandbox")).replace("_", " ").capitalize()
    world_context.text = "%s world  •  %s" % [profile, template]


func get_configuration() -> Dictionary:
    return _configuration.duplicate(true)


func get_mode() -> StringName:
    return _mode


func focus_primary() -> void:
    mode_switch.focus_primary()


func _on_mode_changed(mode: StringName) -> void:
    _mode = mode
    _apply_mode_label()
    mode_changed.emit(_mode)


func _apply_mode_label() -> void:
    mode_badge.text = "%s MODE" % str(_mode).to_upper()


func _request_home() -> void:
    home_requested.emit()
