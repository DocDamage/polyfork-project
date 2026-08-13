class_name PlayWorldNewWorldScreen
extends Control

signal back_requested
signal create_requested(configuration: Dictionary)

const TemplateRegistry = preload("res://src/templates/template_registry.gd")
const BIOMES := [
    {"id": "meadow", "name": "Meadow", "summary": "Temperate grass and rock"},
    {"id": "desert", "name": "Desert", "summary": "Sand and exposed rock"},
    {"id": "alpine", "name": "Alpine", "summary": "Rock and snow"},
]

@onready var back_button: Button = %BackButton
@onready var world_name_edit: LineEdit = %WorldNameEdit
@onready var small_button: Button = %SmallButton
@onready var medium_button: Button = %MediumButton
@onready var large_button: Button = %LargeButton
@onready var biome_option: OptionButton = %BiomeOption
@onready var template_option: OptionButton = %TemplateOption
@onready var create_button: Button = %CreateButton
@onready var create_hint: Label = $SafeArea/Content/BottomRow/CreateHint

var _selected_world_size: StringName = &"medium"
var _template_registry = TemplateRegistry.new()

func _ready() -> void:
    _configure_world_size_buttons()
    _populate_biomes()
    var template_result: Dictionary = _template_registry.load_builtin()
    if template_result.get("ok", false): _populate_templates()
    else:
        template_option.clear(); create_button.disabled = true
        set_error_message("Template registry could not load: %s" % str(template_result.get("errors", [])))
    _configure_focus_navigation()
    back_button.pressed.connect(_request_back)
    create_button.pressed.connect(_request_create)

func focus_primary() -> void: world_name_edit.grab_focus()

func select_template(template_id: String) -> bool:
    for index in range(template_option.item_count):
        if str(template_option.get_item_metadata(index)) == template_id:
            template_option.select(index); return true
    return false

func set_error_message(message: String) -> void:
    create_hint.text = message
    create_hint.add_theme_color_override("font_color", Color("ff665f"))

func clear_error_message() -> void:
    create_hint.text = "Ready with smart defaults."
    create_hint.remove_theme_color_override("font_color")

func _configure_world_size_buttons() -> void:
    var group := ButtonGroup.new(); group.allow_unpress = false
    for button in [small_button, medium_button, large_button]:
        button.toggle_mode = true; button.button_group = group
    small_button.pressed.connect(_select_world_size.bind(&"small"))
    medium_button.pressed.connect(_select_world_size.bind(&"medium"))
    large_button.pressed.connect(_select_world_size.bind(&"large"))
    medium_button.button_pressed = true

func _populate_biomes() -> void:
    biome_option.clear()
    for biome in BIOMES:
        var index := biome_option.item_count
        biome_option.add_item("%s — %s" % [str(biome.name), str(biome.summary)])
        biome_option.set_item_metadata(index, str(biome.id))
    biome_option.select(0)

func _populate_templates() -> void:
    template_option.clear()
    var default_index := 0
    for manifest in _template_registry.list_manifests():
        var index := template_option.item_count
        var template_id := str(manifest.get("template_id", ""))
        var display: Dictionary = manifest.get("display", {})
        template_option.add_item(str(display.get("name", template_id)))
        template_option.set_item_metadata(index, template_id)
        if template_id == "third_person_adventure": default_index = index
    if template_option.item_count > 0: template_option.select(default_index)

func _configure_focus_navigation() -> void:
    back_button.focus_neighbor_bottom = back_button.get_path_to(world_name_edit)
    world_name_edit.focus_neighbor_top = world_name_edit.get_path_to(back_button)
    world_name_edit.focus_neighbor_bottom = world_name_edit.get_path_to(medium_button)
    small_button.focus_neighbor_top = small_button.get_path_to(world_name_edit); small_button.focus_neighbor_right = small_button.get_path_to(medium_button); small_button.focus_neighbor_bottom = small_button.get_path_to(biome_option)
    medium_button.focus_neighbor_top = medium_button.get_path_to(world_name_edit); medium_button.focus_neighbor_left = medium_button.get_path_to(small_button); medium_button.focus_neighbor_right = medium_button.get_path_to(large_button); medium_button.focus_neighbor_bottom = medium_button.get_path_to(biome_option)
    large_button.focus_neighbor_top = large_button.get_path_to(world_name_edit); large_button.focus_neighbor_left = large_button.get_path_to(medium_button); large_button.focus_neighbor_bottom = large_button.get_path_to(biome_option)
    biome_option.focus_neighbor_top = biome_option.get_path_to(medium_button); biome_option.focus_neighbor_bottom = biome_option.get_path_to(template_option)
    template_option.focus_neighbor_top = template_option.get_path_to(biome_option); template_option.focus_neighbor_bottom = template_option.get_path_to(create_button)
    create_button.focus_neighbor_top = create_button.get_path_to(template_option)
    _set_tab_order([back_button, world_name_edit, small_button, medium_button, large_button, biome_option, template_option, create_button])

func _set_tab_order(controls: Array) -> void:
    for index in range(controls.size() - 1):
        var current: Control = controls[index]; var next: Control = controls[index + 1]
        current.focus_next = current.get_path_to(next); next.focus_previous = next.get_path_to(current)

func _select_world_size(world_size: StringName) -> void:
    _selected_world_size = world_size
    clear_error_message()

func _request_back() -> void: back_requested.emit()

func _request_create() -> void:
    clear_error_message()
    var clean_name := world_name_edit.text.strip_edges()
    if clean_name.is_empty():
        set_error_message("Enter a world name before creating the project."); world_name_edit.grab_focus(); return
    if template_option.item_count == 0 or biome_option.item_count == 0:
        set_error_message("A valid template and biome are required."); return
    create_requested.emit({
        "title": clean_name,
        "world_profile": str(_selected_world_size),
        "biome_preset": str(biome_option.get_item_metadata(biome_option.selected)),
        "template_id": str(template_option.get_item_metadata(template_option.selected)),
    })
