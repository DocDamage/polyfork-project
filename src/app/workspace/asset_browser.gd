class_name PlayWorldAssetBrowser
extends VBoxContainer

signal placement_requested(asset_record: Dictionary)
signal library_status(message: String, is_error: bool)

const Tokens = preload("res://src/app/theme/ui_tokens.gd")

var _library
var _search_text := ""
var _density: StringName = &"large"
var _selected_asset_id := ""
var _card_buttons: Array[Button] = []

var _source_filter: OptionButton
var _type_filter: OptionButton
var _collection_filter: OptionButton
var _favorites_filter: CheckButton
var _duplicates_filter: CheckButton
var _grid: GridContainer
var _details: Label
var _collection_name: LineEdit
var _file_dialog: FileDialog


func _ready() -> void:
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_theme_constant_override("separation", Tokens.SPACE_2)
    _build_controls()


func bind_library(library) -> void:
    _library = library
    refresh()


func set_search_text(value: String) -> void:
    _search_text = value
    refresh_cards()


func set_density(mode: StringName) -> void:
    if not [&"large", &"compact"].has(mode):
        return
    _density = mode
    refresh_cards()


func refresh() -> void:
    _refresh_filter_options()
    refresh_cards()


func refresh_cards() -> void:
    if _grid == null:
        return
    for child in _grid.get_children():
        child.queue_free()
    _card_buttons.clear()
    _grid.columns = 4 if _density == &"large" else 6
    if _library == null:
        _details.text = "Register a read-only asset source folder to begin."
        return

    var filters := _current_filters()
    var records: Array[Dictionary] = _library.query(_search_text, filters)
    for record in records:
        var card := _create_card(record)
        _grid.add_child(card)
        _card_buttons.append(card)
    if records.is_empty():
        _details.text = "No assets match the current search and filters."
        _selected_asset_id = ""
    elif _selected_asset_id.is_empty() or _library.get_record(_selected_asset_id).is_empty():
        _select_record(records[0])
    _wire_card_focus()


func focus_first_card() -> bool:
    if _card_buttons.is_empty():
        return false
    _card_buttons[0].grab_focus()
    return true


func handle_shortcut(event: InputEvent) -> bool:
    if _library == null or _selected_asset_id.is_empty() or not event.is_pressed() or event.is_echo():
        return false
    var favorite_requested := false
    if event is InputEventKey:
        favorite_requested = event.physical_keycode == KEY_F
    elif event is InputEventJoypadButton:
        favorite_requested = event.button_index == JOY_BUTTON_Y
    if not favorite_requested:
        return false
    var record: Dictionary = _library.get_record(_selected_asset_id)
    if record.is_empty():
        return false
    var result: Dictionary = _library.set_favorite(_selected_asset_id, not bool(record.get("favorite", false)))
    if not result.get("ok", false):
        library_status.emit(str(result.get("errors", ["Favorite update failed."])[0]), true)
        return true
    library_status.emit("Favorite updated", false)
    refresh()
    return true


func get_visible_asset_ids() -> Array[String]:
    var result: Array[String] = []
    for button in _card_buttons:
        result.append(str(button.get_meta(&"asset_id", "")))
    return result


func get_density() -> StringName:
    return _density


func get_selected_asset_id() -> String:
    return _selected_asset_id


func set_filter_state(filters: Dictionary) -> void:
    _set_option_by_value(_source_filter, str(filters.get("source_id", "")))
    _set_option_by_value(_type_filter, str(filters.get("asset_type", "")))
    _set_option_by_value(_collection_filter, str(filters.get("collection", "")))
    _favorites_filter.button_pressed = bool(filters.get("favorites_only", false))
    _duplicates_filter.button_pressed = bool(filters.get("duplicates_only", false))
    refresh_cards()


func _build_controls() -> void:
    var filters := HBoxContainer.new()
    filters.name = "AssetFilters"
    filters.add_theme_constant_override("separation", Tokens.SPACE_2)
    add_child(filters)

    _source_filter = _option("All sources", 150)
    _type_filter = _option("All types", 132)
    _collection_filter = _option("All collections", 150)
    _favorites_filter = CheckButton.new()
    _favorites_filter.text = "Favorites"
    _duplicates_filter = CheckButton.new()
    _duplicates_filter.text = "Duplicates"
    for control in [_source_filter, _type_filter, _collection_filter, _favorites_filter, _duplicates_filter]:
        filters.add_child(control)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    filters.add_child(spacer)
    var rescan := Button.new()
    rescan.text = "Rescan"
    rescan.pressed.connect(_rescan)
    filters.add_child(rescan)
    var add_folder := Button.new()
    add_folder.text = "+ Folder"
    add_folder.pressed.connect(_open_folder_dialog)
    filters.add_child(add_folder)

    _source_filter.item_selected.connect(_filters_changed)
    _type_filter.item_selected.connect(_filters_changed)
    _collection_filter.item_selected.connect(_filters_changed)
    _favorites_filter.toggled.connect(_toggle_filter)
    _duplicates_filter.toggled.connect(_toggle_filter)

    var scroll := ScrollContainer.new()
    scroll.name = "AssetScroll"
    scroll.custom_minimum_size = Vector2(0, 190)
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(scroll)
    _grid = GridContainer.new()
    _grid.name = "AssetGrid"
    _grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _grid.add_theme_constant_override("h_separation", Tokens.SPACE_2)
    _grid.add_theme_constant_override("v_separation", Tokens.SPACE_2)
    scroll.add_child(_grid)

    var footer := HBoxContainer.new()
    footer.add_theme_constant_override("separation", Tokens.SPACE_3)
    add_child(footer)
    _details = Label.new()
    _details.name = "AssetDetails"
    _details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _details.theme_type_variation = &"CaptionLabel"
    _details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    footer.add_child(_details)
    var collection_box := VBoxContainer.new()
    collection_box.custom_minimum_size = Vector2(220, 0)
    footer.add_child(collection_box)
    var hint := Label.new()
    hint.text = "F / Y: favorite"
    hint.theme_type_variation = &"AccentCaption"
    collection_box.add_child(hint)
    var collection_row := HBoxContainer.new()
    collection_box.add_child(collection_row)
    _collection_name = LineEdit.new()
    _collection_name.placeholder_text = "Collection name"
    _collection_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    collection_row.add_child(_collection_name)
    var add_collection := Button.new()
    add_collection.text = "Add"
    add_collection.pressed.connect(_add_collection)
    collection_row.add_child(add_collection)

    _file_dialog = FileDialog.new()
    _file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
    _file_dialog.access = FileDialog.ACCESS_FILESYSTEM
    _file_dialog.title = "Register Read-Only Asset Source"
    _file_dialog.dir_selected.connect(_register_folder)
    add_child(_file_dialog)


func _create_card(record: Dictionary) -> Button:
    var button := Button.new()
    button.name = "Asset_%s" % str(record.get("asset_id", "")).substr(0, 8)
    button.set_meta(&"asset_id", str(record.get("asset_id", "")))
    button.tooltip_text = str(record.get("relative_path", ""))
    button.theme_type_variation = &"CardButton" if _density == &"large" else &"ToolButton"
    button.custom_minimum_size = Vector2(178, 150) if _density == &"large" else Vector2(132, 54)
    button.text = _compact_label(record) if _density == &"compact" else ""
    button.pressed.connect(_request_placement.bind(str(record.get("asset_id", ""))))
    button.focus_entered.connect(_select_asset_id.bind(str(record.get("asset_id", ""))))
    button.mouse_entered.connect(_select_asset_id.bind(str(record.get("asset_id", ""))))
    if _density == &"large":
        var content := VBoxContainer.new()
        content.mouse_filter = Control.MOUSE_FILTER_IGNORE
        content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
        button.add_child(content)
        var thumbnail := TextureRect.new()
        thumbnail.custom_minimum_size = Vector2(0, 92)
        thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
        thumbnail.texture = _thumbnail_texture(record)
        content.add_child(thumbnail)
        var title := Label.new()
        title.text = ("★ " if bool(record.get("favorite", false)) else "") + str(record.get("display_name", "Asset"))
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        title.mouse_filter = Control.MOUSE_FILTER_IGNORE
        content.add_child(title)
        var kind := Label.new()
        kind.text = str(record.get("asset_type", "")).replace("_", " ").to_upper()
        kind.theme_type_variation = &"CaptionLabel"
        kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        kind.mouse_filter = Control.MOUSE_FILTER_IGNORE
        content.add_child(kind)
    return button


func _thumbnail_texture(record: Dictionary) -> Texture2D:
    var path := str(record.get("thumbnail", {}).get("path", ""))
    if path.is_empty() or not FileAccess.file_exists(path):
        return null
    var image := Image.load_from_file(path)
    if image == null or image.is_empty():
        return null
    return ImageTexture.create_from_image(image)


func _select_asset_id(asset_id: String) -> void:
    if _library == null:
        return
    var record: Dictionary = _library.get_record(asset_id)
    if record.is_empty():
        return
    _select_record(record)


func _select_record(record: Dictionary) -> void:
    _selected_asset_id = str(record.get("asset_id", ""))
    var detail: Dictionary = _library.source_details(_selected_asset_id)
    var source: Dictionary = detail.get("source", {})
    var license: Dictionary = detail.get("license", {})
    var license_name := str(license.get("spdx", "Unspecified"))
    if license_name.is_empty(): license_name = "Unspecified"
    var collections: Array = record.get("collections", [])
    _details.text = "%s  •  %s\nRead-only source: %s\nLicense: %s  •  Author: %s\nCollections: %s" % [
        str(record.get("display_name", "Asset")),
        str(record.get("relative_path", "")),
        str(source.get("root_path", "Unavailable")),
        license_name,
        str(license.get("author", "")),
        ", ".join(collections) if not collections.is_empty() else "None"
    ]


func _request_placement(asset_id: String) -> void:
    if _library == null: return
    var record: Dictionary = _library.get_record(asset_id)
    if not record.is_empty(): placement_requested.emit(record)


func _add_collection() -> void:
    if _library == null or _selected_asset_id.is_empty(): return
    var result: Dictionary = _library.add_to_collection(_selected_asset_id, _collection_name.text)
    if result.get("ok", false):
        _collection_name.clear()
        library_status.emit("Collection updated", false)
        refresh()
    else:
        library_status.emit(str(result.get("errors", ["Collection update failed."])[0]), true)


func _rescan() -> void:
    if _library == null: return
    var result: Dictionary = _library.scan_all()
    library_status.emit("Asset sources rescanned" if result.get("ok", false) else str(result.get("errors", ["Rescan failed."])[0]), not result.get("ok", false))
    refresh()


func _open_folder_dialog() -> void:
    _file_dialog.popup_centered_ratio(0.72)


func _register_folder(path: String) -> void:
    if _library == null: return
    var result: Dictionary = _library.register_source(path, path.get_file())
    library_status.emit("Asset source registered" if result.get("ok", false) else str(result.get("errors", ["Folder registration failed."])[0]), not result.get("ok", false))
    refresh()


func _current_filters() -> Dictionary:
    return {
        "source_id": _selected_option_value(_source_filter),
        "asset_type": _selected_option_value(_type_filter),
        "collection": _selected_option_value(_collection_filter),
        "favorites_only": _favorites_filter.button_pressed,
        "duplicates_only": _duplicates_filter.button_pressed
    }


func _refresh_filter_options() -> void:
    _replace_options(_source_filter, "All sources", _source_items())
    _replace_options(_type_filter, "All types", [["GLTF", "gltf"], ["GLB", "glb"], ["Godot scene", "godot_text_scene"], ["Godot binary", "godot_binary_scene"]])
    var collection_items: Array = []
    if _library != null:
        for value in _library.get_collections(): collection_items.append([value, value])
    _replace_options(_collection_filter, "All collections", collection_items)


func _source_items() -> Array:
    var result: Array = []
    if _library != null:
        for source in _library.get_sources(): result.append([str(source.get("display_name", "Source")), str(source.get("source_id", ""))])
    return result


func _replace_options(control: OptionButton, all_label: String, values: Array) -> void:
    var previous := _selected_option_value(control)
    control.clear()
    control.add_item(all_label)
    control.set_item_metadata(0, "")
    for value in values:
        control.add_item(str(value[0]))
        control.set_item_metadata(control.item_count - 1, str(value[1]))
    _set_option_by_value(control, previous)


func _set_option_by_value(control: OptionButton, value: String) -> void:
    for index in range(control.item_count):
        if str(control.get_item_metadata(index)) == value:
            control.select(index)
            return
    control.select(0)


func _selected_option_value(control: OptionButton) -> String:
    if control == null or control.item_count == 0: return ""
    return str(control.get_item_metadata(control.selected))


func _wire_card_focus() -> void:
    if _card_buttons.is_empty(): return
    for index in range(_card_buttons.size()):
        var button := _card_buttons[index]
        button.focus_mode = Control.FOCUS_ALL
        if index > 0: button.focus_previous = button.get_path_to(_card_buttons[index - 1])
        if index + 1 < _card_buttons.size(): button.focus_next = button.get_path_to(_card_buttons[index + 1])


func _compact_label(record: Dictionary) -> String:
    var prefix := "★ " if bool(record.get("favorite", false)) else ""
    var label := str(record.get("display_name", "Asset"))
    var max_name_length := 12 if not prefix.is_empty() else 10
    if label.length() > max_name_length:
        label = label.substr(0, max_name_length - 1) + "…"
    return prefix + label


func _option(label: String, width: float) -> OptionButton:
    var control := OptionButton.new()
    control.custom_minimum_size = Vector2(width, 42)
    control.add_item(label)
    control.set_item_metadata(0, "")
    return control


func _filters_changed(_index: int) -> void: refresh_cards()
func _toggle_filter(_enabled: bool) -> void: refresh_cards()
