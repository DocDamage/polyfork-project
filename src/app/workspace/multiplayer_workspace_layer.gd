class_name PlayWorldMultiplayerWorkspaceLayer
extends Node

const Contract = preload("res://src/network/network_session_contract.gd")
const TemplateContract = preload("res://src/network/multiplayer_template_contract.gd")

var _workspace
var _button: Button
var _panel: PanelContainer
var _capability_label: Label
var _player_label: LineEdit
var _address: LineEdit
var _port: SpinBox
var _host_button: Button
var _join_button: Button
var _offline_button: Button
var _close_button: Button
var _status: Label
var _peer_status: Label
var _hint: Label
var _network: Node
var _scale: Node
var _refresh_elapsed := 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _network = get_node_or_null("/root/NetworkRuntime")
    _scale = get_node_or_null("/root/ScalePolish")
    if _network != null:
        if _network.has_signal("status_changed"): _network.status_changed.connect(_on_network_status_changed)
        if _network.has_signal("network_error"): _network.network_error.connect(_on_network_error)
    if _scale != null:
        if _scale.has_signal("input_context_changed"): _scale.input_context_changed.connect(_on_input_context_changed)
        if _scale.has_signal("layout_mode_changed"): _scale.layout_mode_changed.connect(_on_layout_mode_changed)
    call_deferred("_bind_current_workspace")

func _process(delta: float) -> void:
    if _workspace == null or not is_instance_valid(_workspace):
        _refresh_elapsed += delta
        if _refresh_elapsed >= 0.5:
            _refresh_elapsed = 0.0
            _bind_current_workspace()
        return
    _refresh_elapsed += delta
    if _refresh_elapsed >= 0.2:
        _refresh_elapsed = 0.0
        refresh_state()

func _unhandled_input(event: InputEvent) -> void:
    if _panel != null and _panel.visible and event.is_action_pressed("ui_cancel"):
        close_panel()
        get_viewport().set_input_as_handled()

func bind_workspace(workspace) -> Dictionary:
    if workspace == null: return _failure("Multiplayer workspace requires the canonical workspace screen.")
    var top_row = workspace.get_node_or_null("TopBar/TopMargin/TopRow")
    if top_row == null: return _failure("Multiplayer workspace could not find the canonical top bar.")
    _workspace = workspace
    if _button == null:
        _button = Button.new()
        _button.name = "MultiplayerButton"
        _button.text = "Multiplayer"
        _button.custom_minimum_size = Vector2(116, 44)
        _button.focus_mode = Control.FOCUS_ALL
        _button.tooltip_text = "Configure Offline, Host, or Join for Play"
        top_row.add_child(_button)
        _button.pressed.connect(_toggle_panel)
    if _panel == null: _create_panel()
    refresh_state()
    return {"ok": true, "errors": []}

func refresh_state() -> void:
    if _workspace == null or _button == null: return
    var configuration: Dictionary = _workspace.get_configuration() if _workspace.has_method("get_configuration") else {}
    var runtime: Dictionary = configuration.get("runtime", {})
    var capability: Dictionary = TemplateContract.normalize(runtime.get("multiplayer", null))
    var supported: bool = bool(capability.get("enabled", false))
    _button.disabled = not supported
    if _capability_label != null:
        if supported:
            _capability_label.text = "%s • %d–%d players • %s" % [
                str(capability.get("mode", "coop")).capitalize(),
                int(capability.get("min_players", 1)),
                int(capability.get("max_players", 1)),
                str(capability.get("score_mode", "none")).replace("_", " ").capitalize(),
            ]
        else:
            _capability_label.text = "This template is offline-only."
    var status: Dictionary = _network.get_status() if _network != null and _network.has_method("get_status") else {}
    var role: String = str(status.get("role", Contract.ROLE_OFFLINE))
    var ready: bool = bool(status.get("ready", false))
    var peer_count: int = int(status.get("peer_count", 0))
    if role == Contract.ROLE_OFFLINE:
        _button.text = "Multiplayer"
    elif ready:
        _button.text = "%s • %d" % ["Host" if role == Contract.ROLE_HOST else "Joined", peer_count]
    else:
        _button.text = "Host Armed" if role == Contract.ROLE_HOST else "Join Armed"
    if _peer_status != null: _peer_status.text = "Peers • %d" % peer_count if ready else "No active network peers"
    if _status != null: _status.text = _status_text(status)
    var in_play: bool = bool(_workspace.has_method("get_mode") and _workspace.get_mode() == &"play")
    if _host_button != null: _host_button.disabled = not supported or in_play or ready
    if _join_button != null: _join_button.disabled = not supported or in_play or ready
    if _offline_button != null: _offline_button.disabled = role == Contract.ROLE_OFFLINE and not ready
    _update_input_hint()

func open_panel() -> void:
    if _panel == null or _button == null or _button.disabled: return
    _panel.show()
    refresh_state()
    if _player_label != null: _player_label.call_deferred("grab_focus")

func close_panel() -> void:
    if _panel != null: _panel.hide()
    if _button != null and not _button.disabled: _button.call_deferred("grab_focus")

func is_panel_open() -> bool: return _panel != null and _panel.visible
func get_multiplayer_button() -> Button: return _button
func get_host_button() -> Button: return _host_button
func get_join_button() -> Button: return _join_button
func get_status_label() -> Label: return _status
func get_address_field() -> LineEdit: return _address
func get_port_field() -> SpinBox: return _port

func _bind_current_workspace() -> void:
    var current: Node = get_tree().current_scene
    if current == null: return
    var workspace = current.get_node_or_null("WorkspaceScreen")
    if workspace == null: workspace = current.find_child("WorkspaceScreen", true, false)
    if workspace == null or workspace == _workspace: return
    var result: Dictionary = bind_workspace(workspace)
    if not result.get("ok", false): push_warning("Unable to attach Multiplayer workspace: %s" % str(result.get("errors", [])))

func _toggle_panel() -> void:
    if is_panel_open(): close_panel()
    else: open_panel()

func _create_panel() -> void:
    _panel = PanelContainer.new()
    _panel.name = "MultiplayerPanel"
    _panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    _panel.position = Vector2(-430, 76)
    _panel.size = Vector2(410, 382)
    _panel.z_index = 42
    _panel.hide()
    _workspace.add_child(_panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_bottom", 16)
    _panel.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 9)
    margin.add_child(stack)
    var title := Label.new(); title.text = "Multiplayer Play"; title.theme_type_variation = &"HeadingLabel"; stack.add_child(title)
    _capability_label = Label.new(); _capability_label.name = "MultiplayerCapability"; _capability_label.theme_type_variation = &"AccentCaption"; stack.add_child(_capability_label)
    _player_label = LineEdit.new(); _player_label.name = "MultiplayerPlayerLabel"; _player_label.placeholder_text = "Player name"; _player_label.text = "Player"; _player_label.focus_mode = Control.FOCUS_ALL; stack.add_child(_player_label)
    var endpoint_row := HBoxContainer.new(); endpoint_row.add_theme_constant_override("separation", 8); stack.add_child(endpoint_row)
    _address = LineEdit.new(); _address.name = "MultiplayerAddress"; _address.placeholder_text = "Host address"; _address.text = Contract.DEFAULT_ADDRESS; _address.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _address.focus_mode = Control.FOCUS_ALL; endpoint_row.add_child(_address)
    _port = SpinBox.new(); _port.name = "MultiplayerPort"; _port.min_value = Contract.MIN_PORT; _port.max_value = Contract.MAX_PORT; _port.step = 1.0; _port.value = Contract.DEFAULT_PORT; _port.custom_minimum_size.x = 118; _port.focus_mode = Control.FOCUS_ALL; endpoint_row.add_child(_port)
    var action_row := HBoxContainer.new(); action_row.add_theme_constant_override("separation", 8); stack.add_child(action_row)
    _host_button = Button.new(); _host_button.name = "MultiplayerHostButton"; _host_button.text = "Host & Play"; _host_button.focus_mode = Control.FOCUS_ALL; _host_button.pressed.connect(_host_and_play); action_row.add_child(_host_button)
    _join_button = Button.new(); _join_button.name = "MultiplayerJoinButton"; _join_button.text = "Join & Play"; _join_button.focus_mode = Control.FOCUS_ALL; _join_button.pressed.connect(_join_and_play); action_row.add_child(_join_button)
    _offline_button = Button.new(); _offline_button.name = "MultiplayerOfflineButton"; _offline_button.text = "Offline"; _offline_button.focus_mode = Control.FOCUS_ALL; _offline_button.pressed.connect(_go_offline); action_row.add_child(_offline_button)
    _peer_status = Label.new(); _peer_status.name = "MultiplayerPeerStatus"; _peer_status.theme_type_variation = &"SecondaryLabel"; stack.add_child(_peer_status)
    _status = Label.new(); _status.name = "MultiplayerStatus"; _status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _status.custom_minimum_size.y = 48; stack.add_child(_status)
    _hint = Label.new(); _hint.name = "MultiplayerInputHint"; _hint.theme_type_variation = &"SecondaryLabel"; _hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; stack.add_child(_hint)
    _close_button = Button.new(); _close_button.name = "MultiplayerCloseButton"; _close_button.text = "Close"; _close_button.focus_mode = Control.FOCUS_ALL; _close_button.pressed.connect(close_panel); stack.add_child(_close_button)
    _player_label.focus_neighbor_bottom = _player_label.get_path_to(_address)
    _address.focus_neighbor_top = _address.get_path_to(_player_label); _address.focus_neighbor_right = _address.get_path_to(_port); _address.focus_neighbor_bottom = _address.get_path_to(_host_button)
    _port.focus_neighbor_left = _port.get_path_to(_address); _port.focus_neighbor_bottom = _port.get_path_to(_join_button)
    _host_button.focus_neighbor_top = _host_button.get_path_to(_address); _host_button.focus_neighbor_right = _host_button.get_path_to(_join_button); _host_button.focus_neighbor_bottom = _host_button.get_path_to(_close_button)
    _join_button.focus_neighbor_top = _join_button.get_path_to(_port); _join_button.focus_neighbor_left = _join_button.get_path_to(_host_button); _join_button.focus_neighbor_right = _join_button.get_path_to(_offline_button); _join_button.focus_neighbor_bottom = _join_button.get_path_to(_close_button)
    _offline_button.focus_neighbor_left = _offline_button.get_path_to(_join_button); _offline_button.focus_neighbor_bottom = _offline_button.get_path_to(_close_button)
    _close_button.focus_neighbor_top = _close_button.get_path_to(_join_button)
    refresh_state()

func _host_and_play() -> void:
    if _network == null: _set_status("Multiplayer runtime service is unavailable.", true); return
    var result: Dictionary = _network.host(int(_port.value), _player_label.text.strip_edges())
    if not result.get("ok", false): _set_status(str(result.get("errors", ["Unable to arm host session."])[0]), true); return
    _set_status("Host armed. Entering Play…", false)
    _enter_play()

func _join_and_play() -> void:
    if _network == null: _set_status("Multiplayer runtime service is unavailable.", true); return
    var address: String = _address.text.strip_edges()
    var result: Dictionary = _network.join(address, int(_port.value), _player_label.text.strip_edges())
    if not result.get("ok", false): _set_status(str(result.get("errors", ["Unable to arm client session."])[0]), true); return
    _set_status("Join armed for %s:%d. Entering Play…" % [address, int(_port.value)], false)
    _enter_play()

func _go_offline() -> void:
    if _network == null: return
    var result: Dictionary = _network.stop_session()
    if not result.get("ok", false): _set_status(str(result.get("errors", ["Unable to stop multiplayer session."])[0]), true)
    else: _set_status("Offline Play selected.", false)
    refresh_state()

func _enter_play() -> void:
    if _workspace == null: return
    var play_button: Button = _workspace.find_child("PlayButton", true, false) as Button
    if play_button != null and not play_button.disabled: play_button.emit_signal("pressed")

func _on_network_status_changed(_value: Dictionary) -> void: refresh_state()
func _on_network_error(errors: Array[String]) -> void:
    if not errors.is_empty(): _set_status(errors[0], true)
func _on_input_context_changed(_context: StringName) -> void: _update_input_hint()
func _on_layout_mode_changed(_compact: bool) -> void:
    if _panel == null: return
    _panel.size = Vector2(360, 372) if _is_compact() else Vector2(410, 382)
    _panel.position = Vector2(-380, 68) if _is_compact() else Vector2(-430, 76)

func _update_input_hint() -> void:
    if _hint == null: return
    var gamepad: bool = bool(_scale != null and _scale.has_method("get_input_context") and _scale.get_input_context() == &"gamepad")
    _hint.text = "D-pad / stick: move focus  •  A: select  •  B: close" if gamepad else "Tab / Shift+Tab: move focus  •  Enter: select  •  Esc: close"

func _status_text(status: Dictionary) -> String:
    var role: String = str(status.get("role", Contract.ROLE_OFFLINE))
    var state: String = str(status.get("state", "build"))
    if not status.get("last_error", []).is_empty(): return str(status.get("last_error", ["Network error"])[0])
    if role == Contract.ROLE_OFFLINE: return "Offline Play uses the existing single-player runtime unchanged."
    if state == "build": return "%s armed. Start Play to create the network session." % ("Host" if role == Contract.ROLE_HOST else "Join")
    if state == "connecting": return "Connecting to multiplayer session…"
    if state == "connected": return "%s connected • session %s" % ["Host" if role == Contract.ROLE_HOST else "Client", str(status.get("session_id", ""))]
    return "Multiplayer session is preparing."

func _set_status(message: String, is_error: bool) -> void:
    if _status != null: _status.text = message
    var global_status = _workspace.get_node_or_null("StatusBar/StatusMargin/StatusRow/StatusState") if _workspace != null else null
    if global_status is Label: global_status.text = message
    if is_error: push_warning(message)

func _is_compact() -> bool:
    return _scale != null and _scale.has_method("is_compact_layout") and bool(_scale.is_compact_layout())

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
