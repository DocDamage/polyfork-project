class_name PlayWorldTerrainToolPanel
extends PanelContainer

signal mode_requested(mode: StringName)
signal apply_requested
signal radius_delta_requested(delta: float)
signal strength_delta_requested(delta: float)
signal biome_requested(biome_id: String)
signal close_requested

const Tokens = preload("res://src/app/theme/ui_tokens.gd")
const MODES: Array[StringName] = [&"raise", &"lower", &"smooth", &"flatten"]

var _mode_buttons: Dictionary = {}
var _radius_label: Label
var _strength_label: Label
var _biome_option: OptionButton
var _cell_label: Label
var _suppress_biome_signal := false


func _ready() -> void:
    name = "TerrainToolPanel"
    theme_type_variation = &"DrawerPanel"
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    offset_left = 190.0
    offset_right = -190.0
    offset_top = -196.0
    offset_bottom = -124.0
    _build_ui()
    hide()


func open_panel() -> void:
    show()
    var button: Button = _mode_buttons.get(&"raise")
    if button != null: button.grab_focus()


func close_panel() -> void: hide()
func is_open() -> bool: return visible


func set_brush_state(state: Dictionary) -> void:
    var mode: StringName = StringName(str(state.get("mode", "raise")))
    for key in _mode_buttons.keys():
        var button: Button = _mode_buttons[key]
        button.button_pressed = key == mode
    if _radius_label != null: _radius_label.text = "Radius %.0fm" % float(state.get("radius", 0.0))
    if _strength_label != null: _strength_label.text = "Strength %.1f" % float(state.get("strength", 0.0))
    var cell_id: String = str(state.get("cell_id", ""))
    if _cell_label != null: _cell_label.text = "Cell %s" % (cell_id.substr(0, 8) if not cell_id.is_empty() else "—")


func set_biomes(biomes: Array) -> void:
    if _biome_option == null: return
    _suppress_biome_signal = true
    _biome_option.clear()
    for biome in biomes:
        if not biome is Dictionary: continue
        _biome_option.add_item(str(biome.get("display_name", "Biome")))
        _biome_option.set_item_metadata(_biome_option.item_count - 1, str(biome.get("biome_id", "")))
    _suppress_biome_signal = false


func select_biome(biome_id: String) -> void:
    if _biome_option == null: return
    _suppress_biome_signal = true
    for index in range(_biome_option.item_count):
        if str(_biome_option.get_item_metadata(index)) == biome_id:
            _biome_option.select(index)
            break
    _suppress_biome_signal = false


func _build_ui() -> void:
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", Tokens.SPACE_3)
    margin.add_theme_constant_override("margin_right", Tokens.SPACE_3)
    margin.add_theme_constant_override("margin_top", Tokens.SPACE_2)
    margin.add_theme_constant_override("margin_bottom", Tokens.SPACE_2)
    add_child(margin)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", Tokens.SPACE_2)
    margin.add_child(row)

    var title := Label.new()
    title.text = "Terrain"
    title.theme_type_variation = &"HeadingLabel"
    title.add_theme_color_override("font_color", Tokens.TERRAIN)
    row.add_child(title)

    for mode in MODES:
        var button := Button.new()
        button.text = str(mode).capitalize()
        button.toggle_mode = true
        button.theme_type_variation = &"ToolButton"
        button.custom_minimum_size = Vector2(78, Tokens.TARGET_MIN)
        button.pressed.connect(_on_mode_pressed.bind(mode))
        row.add_child(button)
        _mode_buttons[mode] = button

    _add_adjuster(row, "−", -24.0, true)
    _radius_label = _value_label("Radius 180m", 94)
    row.add_child(_radius_label)
    _add_adjuster(row, "+", 24.0, true)

    _add_adjuster(row, "−", -0.5, false)
    _strength_label = _value_label("Strength 4.0", 92)
    row.add_child(_strength_label)
    _add_adjuster(row, "+", 0.5, false)

    _biome_option = OptionButton.new()
    _biome_option.custom_minimum_size = Vector2(126, Tokens.TARGET_MIN)
    _biome_option.item_selected.connect(_on_biome_selected)
    row.add_child(_biome_option)

    var apply_button := Button.new()
    apply_button.text = "Sculpt  A"
    apply_button.theme_type_variation = &"PrimaryButton"
    apply_button.custom_minimum_size = Vector2(100, Tokens.TARGET_MIN)
    apply_button.pressed.connect(func() -> void: apply_requested.emit())
    row.add_child(apply_button)

    var info_box := VBoxContainer.new()
    info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(info_box)
    _cell_label = Label.new()
    _cell_label.text = "Cell —"
    _cell_label.theme_type_variation = &"AccentCaption"
    info_box.add_child(_cell_label)
    var hint := Label.new()
    hint.text = "D-pad move • A apply • RB mode"
    hint.theme_type_variation = &"CaptionLabel"
    info_box.add_child(hint)

    var close_button := Button.new()
    close_button.text = "×"
    close_button.custom_minimum_size = Vector2(Tokens.TARGET_MIN, Tokens.TARGET_MIN)
    close_button.pressed.connect(func() -> void: close_requested.emit())
    row.add_child(close_button)


func _add_adjuster(row: HBoxContainer, label: String, amount: float, radius: bool) -> void:
    var button := Button.new()
    button.text = label
    button.custom_minimum_size = Vector2(Tokens.TARGET_MIN, Tokens.TARGET_MIN)
    if radius: button.pressed.connect(func() -> void: radius_delta_requested.emit(amount))
    else: button.pressed.connect(func() -> void: strength_delta_requested.emit(amount))
    row.add_child(button)


func _value_label(text_value: String, width: float) -> Label:
    var label := Label.new()
    label.text = text_value
    label.custom_minimum_size = Vector2(width, Tokens.TARGET_MIN)
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.theme_type_variation = &"CaptionLabel"
    return label


func _on_mode_pressed(mode: StringName) -> void:
    mode_requested.emit(mode)


func _on_biome_selected(index: int) -> void:
    if _suppress_biome_signal or index < 0: return
    biome_requested.emit(str(_biome_option.get_item_metadata(index)))
