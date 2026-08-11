class_name PlayWorldNewWorldScreen
extends Control

signal back_requested
signal create_requested(configuration: Dictionary)

const TEMPLATES := [
    {"id": "blank_sandbox", "name": "Blank Sandbox"},
    {"id": "third_person_adventure", "name": "Third-Person Adventure"},
    {"id": "fps", "name": "FPS"},
    {"id": "survival", "name": "Survival"},
    {"id": "rpg", "name": "RPG"},
    {"id": "driving", "name": "Driving"},
    {"id": "walking_simulator", "name": "Walking Simulator"}
]

@onready var back_button: Button = %BackButton
@onready var world_name_edit: LineEdit = %WorldNameEdit
@onready var small_button: Button = %SmallButton
@onready var medium_button: Button = %MediumButton
@onready var large_button: Button = %LargeButton
@onready var template_option: OptionButton = %TemplateOption
@onready var create_button: Button = %CreateButton

var _selected_world_size: StringName = &"medium"


func _ready() -> void:
    _configure_world_size_buttons()
    _populate_templates()
    back_button.pressed.connect(_request_back)
    create_button.pressed.connect(_request_create)


func focus_primary() -> void:
    world_name_edit.grab_focus()


func _configure_world_size_buttons() -> void:
    var group := ButtonGroup.new()
    group.allow_unpress = false

    for button in [small_button, medium_button, large_button]:
        button.toggle_mode = true
        button.button_group = group

    small_button.pressed.connect(_select_world_size.bind(&"small"))
    medium_button.pressed.connect(_select_world_size.bind(&"medium"))
    large_button.pressed.connect(_select_world_size.bind(&"large"))
    medium_button.button_pressed = true


func _populate_templates() -> void:
    template_option.clear()
    for template in TEMPLATES:
        var index := template_option.item_count
        template_option.add_item(template["name"])
        template_option.set_item_metadata(index, template["id"])
    template_option.select(1)


func _select_world_size(world_size: StringName) -> void:
    _selected_world_size = world_size


func _request_back() -> void:
    back_requested.emit()


func _request_create() -> void:
    var clean_name := world_name_edit.text.strip_edges()
    if clean_name.is_empty():
        world_name_edit.grab_focus()
        return

    var template_index := template_option.selected
    var configuration := {
        "title": clean_name,
        "world_profile": str(_selected_world_size),
        "template_id": str(template_option.get_item_metadata(template_index))
    }
    create_requested.emit(configuration)
