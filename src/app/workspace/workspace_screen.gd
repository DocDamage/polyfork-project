class_name PlayWorldWorkspaceScreen
extends Control

signal home_requested

@onready var home_button: Button = %HomeButton
@onready var world_title: Label = %WorldTitle
@onready var world_context: Label = %WorldContext

var _configuration: Dictionary = {}


func _ready() -> void:
    home_button.pressed.connect(_request_home)


func set_configuration(configuration: Dictionary) -> void:
    _configuration = configuration.duplicate(true)
    world_title.text = str(_configuration.get("title", "Untitled World"))

    var profile := str(_configuration.get("world_profile", "medium")).capitalize()
    var template := str(_configuration.get("template_id", "blank_sandbox")).replace("_", " ").capitalize()
    world_context.text = "%s world  •  %s" % [profile, template]


func get_configuration() -> Dictionary:
    return _configuration.duplicate(true)


func focus_primary() -> void:
    home_button.grab_focus()


func _request_home() -> void:
    home_requested.emit()
