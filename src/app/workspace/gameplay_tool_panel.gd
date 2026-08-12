class_name PlayWorldGameplayToolPanel
extends PanelContainer

signal archetype_requested(archetype_id: String)
signal component_requested(definition_id: String)
signal save_prefab_requested(display_name: String)
signal instantiate_prefab_requested(prefab_id: String)
signal socket_requested(socket_name: String, category: String)
signal attach_requested
signal close_requested

const Tokens = preload("res://src/app/theme/ui_tokens.gd")
const SOCKET_CATEGORIES := ["Grip", "Seat", "Mount", "DoorHandle", "Light", "LootSpawn", "Wheel", "Muzzle", "Camera", "InteractionPoint"]

var _selection_label: Label
var _summary_label: Label
var _archetype_option: OptionButton
var _component_option: OptionButton
var _prefab_option: OptionButton
var _prefab_name: LineEdit
var _socket_name: LineEdit
var _socket_category: OptionButton
var _apply_archetype_button: Button
var _add_component_button: Button
var _save_prefab_button: Button
var _spawn_prefab_button: Button
var _add_socket_button: Button
var _attach_button: Button


func _ready() -> void:
    name = "GameplayToolPanel"
    theme_type_variation = &"DrawerPanel"
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    offset_left = 72.0; offset_right = -72.0; offset_top = -284.0; offset_bottom = -124.0
    _build_ui(); hide()


func open_panel() -> void:
    show()
    if _archetype_option != null: _archetype_option.grab_focus()


func close_panel() -> void: hide()
func is_open() -> bool: return visible


func set_selection(entity_ids: Array[String], primary_name: String, components: Array, sockets: Array, prefab_name: String = "") -> void:
    var count := entity_ids.size()
    if _selection_label != null:
        if count == 0: _selection_label.text = "Select an object to compose"
        elif count == 1: _selection_label.text = "%s  •  %s" % [primary_name, entity_ids[0].substr(0, 8)]
        else: _selection_label.text = "%d objects selected" % count
    if _summary_label != null:
        var component_names: Array[String] = []
        for item in components:
            if item is Dictionary: component_names.append(str(item.get("display_name", "Component")))
        var socket_names: Array[String] = []
        for item in sockets:
            if item is Dictionary: socket_names.append(str(item.get("name", "Socket")))
        var parts: Array[String] = []
        parts.append("Components: %s" % (", ".join(component_names) if not component_names.is_empty() else "None"))
        parts.append("Sockets: %s" % (", ".join(socket_names) if not socket_names.is_empty() else "None"))
        if not prefab_name.is_empty(): parts.append("Prefab: %s" % prefab_name)
        _summary_label.text = "   •   ".join(parts)
    var single := count == 1
    if _apply_archetype_button != null: _apply_archetype_button.disabled = not single
    if _add_component_button != null: _add_component_button.disabled = not single
    if _save_prefab_button != null: _save_prefab_button.disabled = not single
    if _add_socket_button != null: _add_socket_button.disabled = not single
    if _attach_button != null: _attach_button.disabled = count != 2


func set_definitions(definitions: Array) -> void:
    _component_option.clear()
    for definition in definitions:
        if not definition is Dictionary: continue
        _component_option.add_item(str(definition.get("display_name", "Component")))
        _component_option.set_item_metadata(_component_option.item_count - 1, str(definition.get("definition_id", "")))


func set_archetypes(archetypes: Array) -> void:
    _archetype_option.clear()
    for archetype in archetypes:
        if not archetype is Dictionary: continue
        _archetype_option.add_item(str(archetype.get("display_name", "Archetype")))
        _archetype_option.set_item_metadata(_archetype_option.item_count - 1, str(archetype.get("archetype_id", "")))


func set_prefabs(prefabs: Array) -> void:
    var selected_id := selected_prefab_id()
    _prefab_option.clear()
    for prefab in prefabs:
        if not prefab is Dictionary: continue
        _prefab_option.add_item(str(prefab.get("display_name", "Prefab")))
        _prefab_option.set_item_metadata(_prefab_option.item_count - 1, str(prefab.get("prefab_id", "")))
    if not selected_id.is_empty():
        for index in range(_prefab_option.item_count):
            if str(_prefab_option.get_item_metadata(index)) == selected_id: _prefab_option.select(index); break
    _spawn_prefab_button.disabled = _prefab_option.item_count == 0


func selected_archetype_id() -> String: return _selected_metadata(_archetype_option)
func selected_component_id() -> String: return _selected_metadata(_component_option)
func selected_prefab_id() -> String: return _selected_metadata(_prefab_option)


func handle_shortcut(event: InputEvent) -> bool:
    if not visible or not event is InputEventJoypadButton or not event.pressed: return false
    if event.button_index == JOY_BUTTON_Y and not _apply_archetype_button.disabled:
        _emit_archetype(); return true
    if event.button_index == JOY_BUTTON_X and not _add_component_button.disabled:
        _emit_component(); return true
    return false


func _build_ui() -> void:
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", Tokens.SPACE_4); margin.add_theme_constant_override("margin_right", Tokens.SPACE_4)
    margin.add_theme_constant_override("margin_top", Tokens.SPACE_3); margin.add_theme_constant_override("margin_bottom", Tokens.SPACE_3); add_child(margin)
    var stack := VBoxContainer.new(); stack.add_theme_constant_override("separation", Tokens.SPACE_2); margin.add_child(stack)
    var top := HBoxContainer.new(); top.add_theme_constant_override("separation", Tokens.SPACE_2); stack.add_child(top)
    var title := Label.new(); title.text = "Gameplay"; title.theme_type_variation = &"HeadingLabel"; title.add_theme_color_override("font_color", Tokens.GAMEPLAY); top.add_child(title)
    _selection_label = Label.new(); _selection_label.text = "Select an object to compose"; _selection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _selection_label.theme_type_variation = &"SecondaryLabel"; top.add_child(_selection_label)
    _archetype_option = _option(150); top.add_child(_archetype_option)
    _apply_archetype_button = _button("Apply Archetype  Y", 138); _apply_archetype_button.pressed.connect(_emit_archetype); top.add_child(_apply_archetype_button)
    _component_option = _option(168); top.add_child(_component_option)
    _add_component_button = _button("Add Component  X", 132); _add_component_button.pressed.connect(_emit_component); top.add_child(_add_component_button)
    var close := _button("×", Tokens.TARGET_MIN); close.pressed.connect(func() -> void: close_requested.emit()); top.add_child(close)

    _summary_label = Label.new(); _summary_label.text = "Components: None   •   Sockets: None"; _summary_label.theme_type_variation = &"CaptionLabel"; _summary_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; stack.add_child(_summary_label)
    var bottom := HBoxContainer.new(); bottom.add_theme_constant_override("separation", Tokens.SPACE_2); stack.add_child(bottom)
    _prefab_name = LineEdit.new(); _prefab_name.placeholder_text = "Prefab name"; _prefab_name.custom_minimum_size = Vector2(130, Tokens.TARGET_MIN); bottom.add_child(_prefab_name)
    _save_prefab_button = _button("Save Prefab", 102); _save_prefab_button.pressed.connect(func() -> void: save_prefab_requested.emit(_prefab_name.text)); bottom.add_child(_save_prefab_button)
    _prefab_option = _option(160); bottom.add_child(_prefab_option)
    _spawn_prefab_button = _button("Place Prefab", 104); _spawn_prefab_button.pressed.connect(_emit_prefab); bottom.add_child(_spawn_prefab_button)
    _socket_name = LineEdit.new(); _socket_name.placeholder_text = "Socket name"; _socket_name.custom_minimum_size = Vector2(112, Tokens.TARGET_MIN); bottom.add_child(_socket_name)
    _socket_category = _option(128)
    for category in SOCKET_CATEGORIES: _socket_category.add_item(category)
    bottom.add_child(_socket_category)
    _add_socket_button = _button("Add Socket", 96); _add_socket_button.pressed.connect(_emit_socket); bottom.add_child(_add_socket_button)
    _attach_button = _button("Attach 2", 86); _attach_button.pressed.connect(func() -> void: attach_requested.emit()); bottom.add_child(_attach_button)
    var hint := Label.new(); hint.text = "Y archetype • X component • A focused action"; hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; hint.theme_type_variation = &"CaptionLabel"; bottom.add_child(hint)


func _option(width: float) -> OptionButton:
    var option := OptionButton.new(); option.custom_minimum_size = Vector2(width, Tokens.TARGET_MIN); return option


func _button(label: String, width: float) -> Button:
    var button := Button.new(); button.text = label; button.custom_minimum_size = Vector2(width, Tokens.TARGET_MIN); return button


func _selected_metadata(option: OptionButton) -> String:
    if option == null or option.item_count == 0 or option.selected < 0: return ""
    return str(option.get_item_metadata(option.selected))


func _emit_archetype() -> void:
    var id := selected_archetype_id(); if not id.is_empty(): archetype_requested.emit(id)
func _emit_component() -> void:
    var id := selected_component_id(); if not id.is_empty(): component_requested.emit(id)
func _emit_prefab() -> void:
    var id := selected_prefab_id(); if not id.is_empty(): instantiate_prefab_requested.emit(id)
func _emit_socket() -> void:
    if _socket_category.item_count == 0: return
    socket_requested.emit(_socket_name.text, _socket_category.get_item_text(_socket_category.selected))
