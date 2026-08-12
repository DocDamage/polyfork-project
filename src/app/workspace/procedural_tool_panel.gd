class_name PlayWorldProceduralToolPanel
extends PanelContainer

signal section_requested(section: StringName)
signal create_foliage_requested
signal create_scatter_requested
signal operation_requested(operation: StringName)
signal radius_delta_requested(delta: float)
signal density_delta_requested(delta: float)
signal new_spline_requested(kind: String)
signal add_point_requested
signal close_requested

const Tokens = preload("res://src/app/theme/ui_tokens.gd")

var _section: StringName = &"foliage"
var _section_buttons: Dictionary = {}
var _foliage_group: HBoxContainer
var _spline_group: HBoxContainer
var _foliage_option: OptionButton
var _scatter_option: OptionButton
var _spline_option: OptionButton
var _operation_buttons: Dictionary = {}
var _radius_label: Label
var _density_label: Label
var _hint: Label
var _radius: float = 24.0
var _density: float = 6.0


func _ready() -> void:
    name = "ProceduralToolPanel"
    theme_type_variation = &"DrawerPanel"
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    offset_left = 120.0
    offset_right = -120.0
    offset_top = -244.0
    offset_bottom = -124.0
    _build_ui()
    hide()


func open_panel(section: StringName = &"foliage") -> void:
    set_section(section)
    show()
    var button: Button = _section_buttons.get(section)
    if button != null: button.grab_focus()


func close_panel() -> void: hide()
func is_open() -> bool: return visible
func get_section() -> StringName: return _section
func get_radius() -> float: return _radius
func get_density() -> float: return _density
func get_selected_foliage_id() -> String: return _selected_id(_foliage_option)
func get_selected_scatter_id() -> String: return _selected_id(_scatter_option)
func get_selected_spline_id() -> String: return _selected_id(_spline_option)


func set_section(section: StringName) -> void:
    _section = &"splines" if section == &"splines" else &"foliage"
    for key in _section_buttons.keys(): (_section_buttons[key] as Button).button_pressed = key == _section
    if _foliage_group != null: _foliage_group.visible = _section == &"foliage"
    if _spline_group != null: _spline_group.visible = _section == &"splines"
    if _hint != null:
        _hint.text = "D-pad move • A apply • X paint/erase" if _section == &"foliage" else "D-pad move • A place point • New Road/Path/Fence arms 2-point creation"


func set_data(foliage_sets: Array[Dictionary], scatter_layers: Array[Dictionary], splines: Array[Dictionary]) -> void:
    _fill_option(_foliage_option, foliage_sets, "foliage_set_id", "display_name")
    _fill_option(_scatter_option, scatter_layers, "scatter_layer_id", "display_name")
    _fill_option(_spline_option, splines, "spline_id", "display_name")
    var scatter_id: String = get_selected_scatter_id()
    for layer in scatter_layers:
        if str(layer.get("scatter_layer_id", "")) == scatter_id:
            _density = float(layer.get("density_per_100m2", _density))
            break
    _sync_values()


func select_spline(spline_id: String) -> void: _select_id(_spline_option, spline_id)
func select_scatter(scatter_id: String) -> void: _select_id(_scatter_option, scatter_id)


func set_operation(operation: StringName) -> void:
    var resolved: StringName = &"erase" if operation == &"erase" else &"paint"
    for key in _operation_buttons.keys(): (_operation_buttons[key] as Button).button_pressed = key == resolved


func adjust_radius(delta: float) -> void:
    _radius = clampf(_radius + delta, 2.0, 256.0)
    _sync_values()


func adjust_density(delta: float) -> void:
    _density = clampf(_density + delta, 0.5, 100.0)
    _sync_values()


func _build_ui() -> void:
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", Tokens.SPACE_3)
    margin.add_theme_constant_override("margin_right", Tokens.SPACE_3)
    margin.add_theme_constant_override("margin_top", Tokens.SPACE_2)
    margin.add_theme_constant_override("margin_bottom", Tokens.SPACE_2)
    add_child(margin)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", Tokens.SPACE_2)
    margin.add_child(root)
    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", Tokens.SPACE_2)
    root.add_child(header)
    var title := Label.new()
    title.text = "Procedural"
    title.theme_type_variation = &"HeadingLabel"
    header.add_child(title)
    _add_section_button(header, &"foliage", "Foliage", Tokens.FOLIAGE)
    _add_section_button(header, &"splines", "Roads & Splines", Tokens.ROADS)
    _hint = Label.new()
    _hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _hint.theme_type_variation = &"CaptionLabel"
    header.add_child(_hint)
    var close_button := Button.new()
    close_button.text = "×"
    close_button.custom_minimum_size = Vector2(Tokens.TARGET_MIN, Tokens.TARGET_MIN)
    close_button.pressed.connect(func() -> void: close_requested.emit())
    header.add_child(close_button)

    _foliage_group = HBoxContainer.new()
    _foliage_group.add_theme_constant_override("separation", Tokens.SPACE_2)
    root.add_child(_foliage_group)
    _foliage_option = _option(170)
    _foliage_group.add_child(_foliage_option)
    _button(_foliage_group, "New Grass", func() -> void: create_foliage_requested.emit(), 104)
    _scatter_option = _option(180)
    _foliage_group.add_child(_scatter_option)
    _button(_foliage_group, "New Scatter", func() -> void: create_scatter_requested.emit(), 112)
    _add_operation_button(&"paint", "Paint")
    _add_operation_button(&"erase", "Erase")
    _button(_foliage_group, "−", func() -> void: radius_delta_requested.emit(-4.0), Tokens.TARGET_MIN)
    _radius_label = _value_label("Radius 24m", 92)
    _foliage_group.add_child(_radius_label)
    _button(_foliage_group, "+", func() -> void: radius_delta_requested.emit(4.0), Tokens.TARGET_MIN)
    _button(_foliage_group, "−", func() -> void: density_delta_requested.emit(-1.0), Tokens.TARGET_MIN)
    _density_label = _value_label("Density 6", 92)
    _foliage_group.add_child(_density_label)
    _button(_foliage_group, "+", func() -> void: density_delta_requested.emit(1.0), Tokens.TARGET_MIN)

    _spline_group = HBoxContainer.new()
    _spline_group.add_theme_constant_override("separation", Tokens.SPACE_2)
    root.add_child(_spline_group)
    _spline_option = _option(240)
    _spline_group.add_child(_spline_option)
    _button(_spline_group, "New Road", func() -> void: new_spline_requested.emit("road"), 112)
    _button(_spline_group, "New Path", func() -> void: new_spline_requested.emit("path"), 108)
    _button(_spline_group, "New Fence", func() -> void: new_spline_requested.emit("fence"), 112)
    _button(_spline_group, "Add Point  A", func() -> void: add_point_requested.emit(), 122)
    set_section(&"foliage")
    set_operation(&"paint")
    _sync_values()


func _add_section_button(row: HBoxContainer, section: StringName, label: String, color: Color) -> void:
    var button := Button.new()
    button.text = label
    button.toggle_mode = true
    button.theme_type_variation = &"ToolButton"
    button.custom_minimum_size = Vector2(130, Tokens.TARGET_MIN)
    button.add_theme_color_override("font_color", color)
    button.pressed.connect(func() -> void: section_requested.emit(section))
    row.add_child(button)
    _section_buttons[section] = button


func _add_operation_button(operation: StringName, label: String) -> void:
    var button := Button.new()
    button.text = label
    button.toggle_mode = true
    button.custom_minimum_size = Vector2(72, Tokens.TARGET_MIN)
    button.pressed.connect(func() -> void: operation_requested.emit(operation))
    _foliage_group.add_child(button)
    _operation_buttons[operation] = button


func _button(row: HBoxContainer, label: String, callback: Callable, width: float) -> Button:
    var button := Button.new()
    button.text = label
    button.custom_minimum_size = Vector2(width, Tokens.TARGET_MIN)
    button.pressed.connect(callback)
    row.add_child(button)
    return button


func _option(width: float) -> OptionButton:
    var option := OptionButton.new()
    option.custom_minimum_size = Vector2(width, Tokens.TARGET_MIN)
    return option


func _value_label(text_value: String, width: float) -> Label:
    var label := Label.new()
    label.text = text_value
    label.custom_minimum_size = Vector2(width, Tokens.TARGET_MIN)
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.theme_type_variation = &"CaptionLabel"
    return label


func _sync_values() -> void:
    if _radius_label != null: _radius_label.text = "Radius %.0fm" % _radius
    if _density_label != null: _density_label.text = "Density %.1f" % _density


static func _fill_option(option: OptionButton, records: Array[Dictionary], id_key: String, label_key: String) -> void:
    if option == null: return
    var previous: String = _selected_id(option)
    option.clear()
    for record in records:
        option.add_item(str(record.get(label_key, "Item")))
        option.set_item_metadata(option.item_count - 1, str(record.get(id_key, "")))
    _select_id(option, previous)


static func _select_id(option: OptionButton, expected: String) -> void:
    if option == null or option.item_count == 0: return
    for index in range(option.item_count):
        if str(option.get_item_metadata(index)) == expected:
            option.select(index)
            return
    option.select(0)


static func _selected_id(option: OptionButton) -> String:
    if option == null or option.item_count == 0 or option.selected < 0: return ""
    return str(option.get_item_metadata(option.selected))
