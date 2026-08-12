class_name PlayWorldEnvironmentToolPanel
extends PanelContainer

signal time_requested(hours: float)
signal weather_requested(weather_profile_id: String)
signal create_weather_requested
signal fog_toggled(enabled: bool)
signal wind_toggled(enabled: bool)
signal wind_speed_requested(speed_mps: float)
signal biome_override_requested(biome_id: String, weather_profile_id: String)
signal clear_biome_requested(biome_id: String)
signal create_water_hook_requested
signal close_requested

const Tokens = preload("res://src/app/theme/ui_tokens.gd")

var _time_spin: SpinBox
var _weather_option: OptionButton
var _fog_toggle: CheckButton
var _wind_toggle: CheckButton
var _wind_speed_spin: SpinBox
var _biome_option: OptionButton
var _summary_label: Label
var _water_label: Label
var _synchronizing := false

func _ready() -> void:
    name = "EnvironmentToolPanel"
    theme_type_variation = &"DrawerPanel"
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    offset_left = 72.0
    offset_right = -72.0
    offset_top = -302.0
    offset_bottom = -124.0
    _build_ui()
    hide()

func open_panel() -> void:
    show()
    if _time_spin != null: _time_spin.grab_focus()

func close_panel() -> void: hide()
func is_open() -> bool: return visible

func set_data(authored: Dictionary, profiles: Array, biomes: Array, water_hooks: Array, evaluated: Dictionary = {}) -> void:
    _synchronizing = true
    _time_spin.value = float(authored.get("time_of_day_hours", 10.0))
    _fog_toggle.button_pressed = bool(authored.get("fog_enabled", true))
    _wind_toggle.button_pressed = bool(authored.get("wind_enabled", true))
    var selected_weather_id: String = str(authored.get("default_weather_profile_id", ""))
    _weather_option.clear()
    for value in profiles:
        if not value is Dictionary: continue
        var profile: Dictionary = value
        _weather_option.add_item(str(profile.get("display_name", "Weather")))
        _weather_option.set_item_metadata(_weather_option.item_count - 1, str(profile.get("weather_profile_id", "")))
    _select_metadata(_weather_option, selected_weather_id)
    var selected_profile: Dictionary = _profile_by_id(profiles, selected_weather_id)
    _wind_speed_spin.value = float(selected_profile.get("wind_speed_mps", 0.0))

    var selected_biome_id: String = selected_biome_id()
    _biome_option.clear()
    for value in biomes:
        if not value is Dictionary: continue
        var biome: Dictionary = value
        _biome_option.add_item(str(biome.get("display_name", "Biome")))
        _biome_option.set_item_metadata(_biome_option.item_count - 1, str(biome.get("biome_id", "")))
    if not selected_biome_id.is_empty(): _select_metadata(_biome_option, selected_biome_id)

    _water_label.text = "%d water hook%s" % [water_hooks.size(), "" if water_hooks.size() == 1 else "s"]
    _summary_label.text = _summary(evaluated, selected_profile)
    _synchronizing = false

func selected_weather_id() -> String: return _selected_metadata(_weather_option)
func selected_biome_id() -> String: return _selected_metadata(_biome_option)

func handle_shortcut(event: InputEvent) -> bool:
    if not visible or event.is_echo(): return false
    if event is InputEventJoypadButton and event.pressed:
        match event.button_index:
            JOY_BUTTON_LEFT_SHOULDER:
                _time_spin.value = fposmod(_time_spin.value - 1.0, 24.0)
                time_requested.emit(float(_time_spin.value)); return true
            JOY_BUTTON_RIGHT_SHOULDER:
                _time_spin.value = fposmod(_time_spin.value + 1.0, 24.0)
                time_requested.emit(float(_time_spin.value)); return true
            JOY_BUTTON_X:
                if _weather_option.item_count > 0:
                    _weather_option.select((_weather_option.selected + 1) % _weather_option.item_count)
                    weather_requested.emit(selected_weather_id())
                return true
            JOY_BUTTON_Y:
                _fog_toggle.button_pressed = not _fog_toggle.button_pressed
                fog_toggled.emit(_fog_toggle.button_pressed); return true
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_COMMA:
                _time_spin.value = fposmod(_time_spin.value - 1.0, 24.0)
                time_requested.emit(float(_time_spin.value)); return true
            KEY_PERIOD:
                _time_spin.value = fposmod(_time_spin.value + 1.0, 24.0)
                time_requested.emit(float(_time_spin.value)); return true
    return false

func _build_ui() -> void:
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", Tokens.SPACE_4)
    margin.add_theme_constant_override("margin_right", Tokens.SPACE_4)
    margin.add_theme_constant_override("margin_top", Tokens.SPACE_3)
    margin.add_theme_constant_override("margin_bottom", Tokens.SPACE_3)
    add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", Tokens.SPACE_2)
    margin.add_child(stack)

    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation", Tokens.SPACE_2)
    stack.add_child(top)
    var title := Label.new()
    title.text = "Environment"
    title.theme_type_variation = &"HeadingLabel"
    title.add_theme_color_override("font_color", Tokens.WATER)
    top.add_child(title)
    _summary_label = Label.new()
    _summary_label.text = "Authored environment ready"
    _summary_label.theme_type_variation = &"SecondaryLabel"
    _summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(_summary_label)
    var close := _button("×", Tokens.TARGET_MIN)
    close.pressed.connect(func() -> void: close_requested.emit())
    top.add_child(close)

    var primary := HBoxContainer.new()
    primary.add_theme_constant_override("separation", Tokens.SPACE_2)
    stack.add_child(primary)
    primary.add_child(_caption("Time"))
    _time_spin = SpinBox.new()
    _time_spin.min_value = 0.0; _time_spin.max_value = 23.75; _time_spin.step = 0.25; _time_spin.custom_minimum_size = Vector2(92, Tokens.TARGET_MIN)
    primary.add_child(_time_spin)
    var set_time := _button("Set Time", 92)
    set_time.pressed.connect(func() -> void: time_requested.emit(float(_time_spin.value)))
    primary.add_child(set_time)
    primary.add_child(_caption("Weather"))
    _weather_option = _option(160)
    primary.add_child(_weather_option)
    var apply_weather := _button("Apply", 78)
    apply_weather.pressed.connect(func() -> void: weather_requested.emit(selected_weather_id()))
    primary.add_child(apply_weather)
    var new_weather := _button("New Profile", 106)
    new_weather.pressed.connect(func() -> void: create_weather_requested.emit())
    primary.add_child(new_weather)
    _fog_toggle = CheckButton.new(); _fog_toggle.text = "Fog"; _fog_toggle.custom_minimum_size = Vector2(82, Tokens.TARGET_MIN)
    _fog_toggle.toggled.connect(func(value: bool) -> void:
        if not _synchronizing: fog_toggled.emit(value))
    primary.add_child(_fog_toggle)
    _wind_toggle = CheckButton.new(); _wind_toggle.text = "Wind"; _wind_toggle.custom_minimum_size = Vector2(88, Tokens.TARGET_MIN)
    _wind_toggle.toggled.connect(func(value: bool) -> void:
        if not _synchronizing: wind_toggled.emit(value))
    primary.add_child(_wind_toggle)
    primary.add_child(_caption("m/s"))
    _wind_speed_spin = SpinBox.new(); _wind_speed_spin.min_value = 0.0; _wind_speed_spin.max_value = 100.0; _wind_speed_spin.step = 0.5; _wind_speed_spin.custom_minimum_size = Vector2(84, Tokens.TARGET_MIN)
    primary.add_child(_wind_speed_spin)
    var set_wind := _button("Set Wind", 88)
    set_wind.pressed.connect(func() -> void: wind_speed_requested.emit(float(_wind_speed_spin.value)))
    primary.add_child(set_wind)

    var coupling := HBoxContainer.new()
    coupling.add_theme_constant_override("separation", Tokens.SPACE_2)
    stack.add_child(coupling)
    coupling.add_child(_caption("Biome coupling"))
    _biome_option = _option(180)
    coupling.add_child(_biome_option)
    var use_weather := _button("Use Weather Here", 132)
    use_weather.pressed.connect(func() -> void:
        var biome_id := selected_biome_id(); var profile_id := selected_weather_id()
        if not biome_id.is_empty() and not profile_id.is_empty(): biome_override_requested.emit(biome_id, profile_id))
    coupling.add_child(use_weather)
    var clear_biome := _button("Clear Override", 116)
    clear_biome.pressed.connect(func() -> void:
        var biome_id := selected_biome_id()
        if not biome_id.is_empty(): clear_biome_requested.emit(biome_id))
    coupling.add_child(clear_biome)
    var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; coupling.add_child(spacer)
    _water_label = _caption("0 water hooks")
    coupling.add_child(_water_label)
    var add_water := _button("Add Water Hook", 132)
    add_water.pressed.connect(func() -> void: create_water_hook_requested.emit())
    coupling.add_child(add_water)
    var hint := Label.new()
    hint.text = "LB/RB time • X weather • Y fog • A focused action"
    hint.theme_type_variation = &"CaptionLabel"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    coupling.add_child(hint)

func _summary(evaluated: Dictionary, selected_profile: Dictionary) -> String:
    if evaluated.is_empty(): return "%s • deterministic Build preview" % str(selected_profile.get("display_name", "Weather"))
    var daylight: int = int(round(float(evaluated.get("daylight", 0.0)) * 100.0))
    var wind: Dictionary = evaluated.get("wind", {})
    var biome_name: String = str(evaluated.get("biome_id", ""))
    if biome_name.length() > 8: biome_name = biome_name.substr(0, 8)
    return "%s • daylight %d%% • wind %.1f m/s%s" % [str(evaluated.get("weather_display_name", "Weather")), daylight, float(wind.get("speed_mps", 0.0)), " • biome " + biome_name if not biome_name.is_empty() else ""]

func _option(width: float) -> OptionButton:
    var option := OptionButton.new(); option.custom_minimum_size = Vector2(width, Tokens.TARGET_MIN); return option

func _button(label: String, width: float) -> Button:
    var button := Button.new(); button.text = label; button.custom_minimum_size = Vector2(width, Tokens.TARGET_MIN); return button

func _caption(text_value: String) -> Label:
    var label := Label.new(); label.text = text_value; label.theme_type_variation = &"CaptionLabel"; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; return label

func _selected_metadata(option: OptionButton) -> String:
    if option == null or option.item_count == 0 or option.selected < 0: return ""
    return str(option.get_item_metadata(option.selected))

func _select_metadata(option: OptionButton, id_value: String) -> void:
    for index in range(option.item_count):
        if str(option.get_item_metadata(index)) == id_value:
            option.select(index); return

func _profile_by_id(profiles: Array, profile_id: String) -> Dictionary:
    for value in profiles:
        if value is Dictionary and str(value.get("weather_profile_id", "")) == profile_id: return value
    return {}
