class_name PlayWorldAiToolPanel
extends PanelContainer

signal provider_saved(descriptor: Dictionary)
signal provider_selected(provider_id: String)
signal privacy_changed(patch: Dictionary)
signal suggest_requested(prompt: String)
signal preview_requested(prompt: String)
signal execute_requested
signal cancel_requested
signal close_requested

const Tokens = preload("res://src/app/theme/ui_tokens.gd")

var _provider_option: OptionButton
var _scope_option: OptionButton
var _endpoint: LineEdit
var _model: LineEdit
var _credential_env: LineEdit
var _local_only: CheckButton
var _cloud_consent: CheckButton
var _prompt: TextEdit
var _result: RichTextLabel
var _status: Label
var _suggest: Button
var _preview: Button
var _execute: Button
var _cancel: Button
var _busy := false

func _ready() -> void:
    name = "AiToolPanel"
    theme_type_variation = &"DrawerPanel"
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    offset_left = 72.0; offset_right = -72.0; offset_top = -522.0; offset_bottom = -124.0
    _build_ui(); hide()

func open_panel() -> void:
    show()
    if _prompt != null: _prompt.grab_focus()
func close_panel() -> void: hide()
func is_open() -> bool: return visible
func get_prompt() -> String: return _prompt.text if _prompt != null else ""

func set_provider_settings(settings: Dictionary) -> void:
    if _provider_option == null: return
    var active_id: String = str(settings.get("active_provider_id", ""))
    _provider_option.clear()
    for provider in settings.get("providers", []):
        if not provider is Dictionary: continue
        _provider_option.add_item(str(provider.get("display_name", provider.get("provider_id", "Provider"))))
        _provider_option.set_item_metadata(_provider_option.item_count - 1, str(provider.get("provider_id", "")))
    for index in range(_provider_option.item_count):
        if str(_provider_option.get_item_metadata(index)) == active_id: _provider_option.select(index); break
    var privacy: Dictionary = settings.get("privacy", {})
    _local_only.button_pressed = bool(privacy.get("local_only", true))
    _cloud_consent.button_pressed = bool(privacy.get("cloud_consent", false))
    _fill_selected_provider(settings.get("providers", []))

func set_busy(value: bool) -> void:
    _busy = value
    _suggest.disabled = value; _preview.disabled = value; _execute.disabled = value or not bool(_execute.get_meta("preview_ready", false)); _cancel.disabled = not value
    _status.text = "Working…" if value else "Ready"

func set_preview_ready(value: bool) -> void:
    _execute.set_meta("preview_ready", value)
    _execute.disabled = _busy or not value

func show_result(result: Dictionary) -> void:
    if _result == null: return
    if not result.get("ok", false):
        _result.text = "[b]AI request failed[/b]\n%s" % str(result.get("errors", ["Unknown error"])[0]); set_preview_ready(false); return
    var mode: String = str(result.get("mode", "result"))
    var proposal: Dictionary = result.get("proposal", {})
    var lines: Array[String] = ["[b]%s[/b]" % mode.capitalize(), str(proposal.get("summary", result.get("summary", "")))]
    if result.has("preview"):
        var preview_data: Dictionary = result.get("preview", {})
        lines.append("%d validated actions" % int(preview_data.get("action_count", 0)))
        for impact in preview_data.get("impacts", []):
            if impact is Dictionary: lines.append("• %s" % str(impact.get("type", "action")))
        set_preview_ready(bool(result.get("executable", false)))
    elif mode == "suggest":
        for action in proposal.get("actions", []):
            if action is Dictionary: lines.append("• %s — %s" % [str(action.get("type", "action")), str(action.get("reason", ""))])
        set_preview_ready(false)
    elif mode == "execute":
        lines.append("Executed as one Undo step")
        set_preview_ready(false)
    _result.text = "\n".join(lines)

func set_status(message: String, is_error: bool = false) -> void:
    if _status != null: _status.text = ("Error • " if is_error else "") + message

func handle_shortcut(event: InputEvent) -> bool:
    if not visible or not event is InputEventJoypadButton or not event.pressed: return false
    match event.button_index:
        JOY_BUTTON_Y:
            if not _suggest.disabled: suggest_requested.emit(get_prompt()); return true
        JOY_BUTTON_X:
            if not _preview.disabled: preview_requested.emit(get_prompt()); return true
        JOY_BUTTON_A:
            if not _execute.disabled: execute_requested.emit(); return true
    return false

func _build_ui() -> void:
    var margin := MarginContainer.new(); margin.add_theme_constant_override("margin_left", Tokens.SPACE_4); margin.add_theme_constant_override("margin_right", Tokens.SPACE_4); margin.add_theme_constant_override("margin_top", Tokens.SPACE_3); margin.add_theme_constant_override("margin_bottom", Tokens.SPACE_3); add_child(margin)
    var stack := VBoxContainer.new(); stack.add_theme_constant_override("separation", Tokens.SPACE_2); margin.add_child(stack)
    var header := HBoxContainer.new(); header.add_theme_constant_override("separation", Tokens.SPACE_2); stack.add_child(header)
    var title := Label.new(); title.text = "AI Creation"; title.theme_type_variation = &"HeadingLabel"; title.add_theme_color_override("font_color", Tokens.AI); header.add_child(title)
    _status = Label.new(); _status.text = "Ready"; _status.theme_type_variation = &"SecondaryLabel"; _status.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(_status)
    var close := _button("×", Tokens.TARGET_MIN); close.pressed.connect(func() -> void: close_requested.emit()); header.add_child(close)

    var provider_row := HBoxContainer.new(); provider_row.add_theme_constant_override("separation", Tokens.SPACE_2); stack.add_child(provider_row)
    _provider_option = _option(150); _provider_option.item_selected.connect(_on_provider_selected); provider_row.add_child(_provider_option)
    _scope_option = _option(88); _scope_option.add_item("Local"); _scope_option.set_item_metadata(0, "local"); _scope_option.add_item("Cloud"); _scope_option.set_item_metadata(1, "cloud"); provider_row.add_child(_scope_option)
    _endpoint = LineEdit.new(); _endpoint.placeholder_text = "Endpoint: http://127.0.0.1:11434/v1/chat/completions"; _endpoint.custom_minimum_size = Vector2(330, Tokens.TARGET_MIN); _endpoint.size_flags_horizontal = Control.SIZE_EXPAND_FILL; provider_row.add_child(_endpoint)
    _model = LineEdit.new(); _model.placeholder_text = "Model"; _model.custom_minimum_size = Vector2(150, Tokens.TARGET_MIN); provider_row.add_child(_model)
    _credential_env = LineEdit.new(); _credential_env.placeholder_text = "Credential env name"; _credential_env.tooltip_text = "Only an environment-variable name is stored. Secret values are never saved."; _credential_env.custom_minimum_size = Vector2(170, Tokens.TARGET_MIN); provider_row.add_child(_credential_env)
    var save_provider := _button("Save Provider", 112); save_provider.pressed.connect(_emit_provider); provider_row.add_child(save_provider)

    var privacy_row := HBoxContainer.new(); privacy_row.add_theme_constant_override("separation", Tokens.SPACE_3); stack.add_child(privacy_row)
    _local_only = CheckButton.new(); _local_only.text = "Local only"; _local_only.toggled.connect(func(value: bool) -> void: privacy_changed.emit({"local_only": value})); privacy_row.add_child(_local_only)
    _cloud_consent = CheckButton.new(); _cloud_consent.text = "Allow cloud context sharing"; _cloud_consent.toggled.connect(func(value: bool) -> void: privacy_changed.emit({"cloud_consent": value})); privacy_row.add_child(_cloud_consent)
    var disclosure := Label.new(); disclosure.text = "Cloud mode sends bounded project/catalog metadata to your configured endpoint. Credentials stay outside project files."; disclosure.theme_type_variation = &"CaptionLabel"; disclosure.size_flags_horizontal = Control.SIZE_EXPAND_FILL; privacy_row.add_child(disclosure)

    var body := HSplitContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.custom_minimum_size = Vector2(0, 205); stack.add_child(body)
    _prompt = TextEdit.new(); _prompt.placeholder_text = "Describe what you want to build. Use Suggest to plan or Preview to validate exact project changes."; _prompt.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY; _prompt.custom_minimum_size = Vector2(500, 190); body.add_child(_prompt)
    _result = RichTextLabel.new(); _result.bbcode_enabled = true; _result.fit_content = false; _result.scroll_active = true; _result.text = "[b]No proposal yet[/b]\nPreview validates references and shows changes before Execute."; _result.custom_minimum_size = Vector2(480, 190); body.add_child(_result)

    var actions := HBoxContainer.new(); actions.add_theme_constant_override("separation", Tokens.SPACE_2); stack.add_child(actions)
    _suggest = _button("Suggest  Y", 118); _suggest.pressed.connect(func() -> void: suggest_requested.emit(get_prompt())); actions.add_child(_suggest)
    _preview = _button("Preview  X", 118); _preview.pressed.connect(func() -> void: preview_requested.emit(get_prompt())); actions.add_child(_preview)
    _execute = _button("Execute  A", 118); _execute.set_meta("preview_ready", false); _execute.disabled = true; _execute.pressed.connect(func() -> void: execute_requested.emit()); actions.add_child(_execute)
    _cancel = _button("Cancel", 92); _cancel.disabled = true; _cancel.pressed.connect(func() -> void: cancel_requested.emit()); actions.add_child(_cancel)
    var hint := Label.new(); hint.text = "Preview never mutates • Execute = one Undo step • Y Suggest • X Preview • A Execute"; hint.theme_type_variation = &"CaptionLabel"; hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; actions.add_child(hint)

func _on_provider_selected(index: int) -> void:
    if index >= 0 and index < _provider_option.item_count: provider_selected.emit(str(_provider_option.get_item_metadata(index)))

func _fill_selected_provider(providers: Array) -> void:
    var provider_id: String = ""
    if _provider_option.item_count > 0 and _provider_option.selected >= 0: provider_id = str(_provider_option.get_item_metadata(_provider_option.selected))
    for provider in providers:
        if not provider is Dictionary or str(provider.get("provider_id", "")) != provider_id: continue
        var scope: String = str(provider.get("scope", "local")); _scope_option.select(1 if scope == "cloud" else 0)
        _endpoint.text = str(provider.get("endpoint", "")); _model.text = str(provider.get("model", "")); _credential_env.text = str(provider.get("credential_env", "")); return
    _scope_option.select(0); _endpoint.text = "http://127.0.0.1:11434/v1/chat/completions"; _model.text = ""; _credential_env.text = ""

func _emit_provider() -> void:
    var provider_id: String = ""
    if _provider_option.item_count > 0 and _provider_option.selected >= 0: provider_id = str(_provider_option.get_item_metadata(_provider_option.selected))
    if provider_id.is_empty(): provider_id = "provider_%d" % Time.get_unix_time_from_system()
    var scope: String = str(_scope_option.get_item_metadata(_scope_option.selected))
    provider_saved.emit({"provider_id": provider_id, "display_name": "Local AI" if scope == "local" else "Cloud AI", "protocol": "openai_compatible_chat_v1", "scope": scope, "endpoint": _endpoint.text.strip_edges(), "model": _model.text.strip_edges(), "credential_env": _credential_env.text.strip_edges(), "timeout_seconds": 45.0, "enabled": true})

func _option(width: float) -> OptionButton:
    var option := OptionButton.new(); option.custom_minimum_size = Vector2(width, Tokens.TARGET_MIN); return option
func _button(label: String, width: float) -> Button:
    var button := Button.new(); button.text = label; button.custom_minimum_size = Vector2(width, Tokens.TARGET_MIN); return button
