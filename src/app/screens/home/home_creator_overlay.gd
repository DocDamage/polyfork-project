class_name PlayWorldHomeCreatorOverlay
extends PanelContainer

signal back_requested
signal item_requested(item_id: String)
signal path_submitted(path: String)
signal primary_requested

var _title: Label
var _subtitle: Label
var _list: VBoxContainer
var _path_row: HBoxContainer
var _path_edit: LineEdit
var _primary_button: Button
var _status: Label

func _ready() -> void:
    name = "HomeCreatorOverlay"
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    theme_type_variation = &"DrawerPanel"
    _build_ui()
    hide()

func present(title: String, subtitle: String, items: Array[Dictionary], options: Dictionary = {}) -> void:
    _title.text = title
    _subtitle.text = subtitle
    _rebuild_items(items)
    var allow_path: bool = bool(options.get("allow_path", false))
    _path_row.visible = allow_path
    _path_edit.placeholder_text = str(options.get("path_placeholder", "Folder path"))
    _primary_button.visible = bool(options.get("show_primary", false))
    _primary_button.text = str(options.get("primary_label", "Refresh"))
    _status.text = str(options.get("status", ""))
    show()
    _focus_first()

func close() -> void:
    hide()
    _status.text = ""

func set_status(message: String) -> void: _status.text = message

func _build_ui() -> void:
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 72)
    margin.add_theme_constant_override("margin_top", 44)
    margin.add_theme_constant_override("margin_right", 72)
    margin.add_theme_constant_override("margin_bottom", 44)
    add_child(margin)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 14)
    margin.add_child(column)
    var top := HBoxContainer.new(); top.add_theme_constant_override("separation", 14); column.add_child(top)
    var back := Button.new(); back.name = "BackButton"; back.text = "Back"; back.theme_type_variation = &"ToolButton"; back.custom_minimum_size = Vector2(100, 46); top.add_child(back)
    back.pressed.connect(func(): back_requested.emit())
    var heading := VBoxContainer.new(); heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(heading)
    _title = Label.new(); _title.theme_type_variation = &"TitleLabel"; heading.add_child(_title)
    _subtitle = Label.new(); _subtitle.theme_type_variation = &"SecondaryLabel"; _subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; heading.add_child(_subtitle)
    var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; column.add_child(scroll)
    _list = VBoxContainer.new(); _list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _list.add_theme_constant_override("separation", 10); scroll.add_child(_list)
    _path_row = HBoxContainer.new(); _path_row.add_theme_constant_override("separation", 10); column.add_child(_path_row)
    _path_edit = LineEdit.new(); _path_edit.custom_minimum_size.y = 48; _path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _path_row.add_child(_path_edit)
    var add_button := Button.new(); add_button.text = "Add Folder"; add_button.theme_type_variation = &"PrimaryButton"; add_button.custom_minimum_size = Vector2(150, 48); _path_row.add_child(add_button)
    add_button.pressed.connect(_submit_path)
    _path_edit.text_submitted.connect(func(_value: String): _submit_path())
    var bottom := HBoxContainer.new(); bottom.alignment = BoxContainer.ALIGNMENT_END; bottom.add_theme_constant_override("separation", 12); column.add_child(bottom)
    _status = Label.new(); _status.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _status.theme_type_variation = &"SecondaryLabel"; _status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; bottom.add_child(_status)
    _primary_button = Button.new(); _primary_button.theme_type_variation = &"PrimaryButton"; _primary_button.custom_minimum_size = Vector2(160, 48); bottom.add_child(_primary_button)
    _primary_button.pressed.connect(func(): primary_requested.emit())

func _rebuild_items(items: Array[Dictionary]) -> void:
    for child in _list.get_children(): child.queue_free()
    if items.is_empty():
        var empty := Label.new(); empty.text = "Nothing here yet."; empty.theme_type_variation = &"SecondaryLabel"; _list.add_child(empty); return
    for item in items:
        var button := Button.new()
        button.theme_type_variation = &"CardButton"
        button.custom_minimum_size = Vector2(0, 72)
        var title: String = str(item.get("title", "Untitled"))
        var subtitle: String = str(item.get("subtitle", ""))
        button.text = title if subtitle.is_empty() else "%s\n%s" % [title, subtitle]
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        var item_id: String = str(item.get("id", ""))
        button.disabled = item_id.is_empty()
        if not item_id.is_empty(): button.pressed.connect(func(): item_requested.emit(item_id))
        _list.add_child(button)

func _submit_path() -> void:
    var value: String = _path_edit.text.strip_edges()
    if value.is_empty(): _status.text = "Enter a folder path first."; return
    path_submitted.emit(value)

func _focus_first() -> void:
    await get_tree().process_frame
    for child in _list.get_children():
        if child is Button and not child.disabled: child.grab_focus(); return
    if _path_row.visible: _path_edit.grab_focus()
