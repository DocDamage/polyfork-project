class_name PlayWorldVisualGraphDebugToolbar
extends PanelContainer

signal status_changed(message: String, is_error: bool)

const Tokens = preload("res://src/app/theme/ui_tokens.gd")
const Debugger = preload("res://src/visual_scripting/visual_graph_debugger.gd")

var _service
var _panel
var _debugger = Debugger.new()
var _node_select: OptionButton
var _status: Label
var _breakpoint_button: Button
var _resume_button: Button

func _ready() -> void:
    name = "VisualGraphDebugToolbar"
    anchor_left = 0.045; anchor_top = 0.84; anchor_right = 0.955; anchor_bottom = 0.905
    offset_left = 0.0; offset_top = 2.0; offset_right = 0.0; offset_bottom = -2.0
    mouse_filter = Control.MOUSE_FILTER_STOP; theme_type_variation = &"DrawerPanel"
    var margin := MarginContainer.new(); margin.add_theme_constant_override("margin_left", 12); margin.add_theme_constant_override("margin_right", 12); margin.add_theme_constant_override("margin_top", 6); margin.add_theme_constant_override("margin_bottom", 6); add_child(margin)
    var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 8); margin.add_child(row)
    var label := Label.new(); label.text = "DEBUG"; label.theme_type_variation = &"CaptionLabel"; row.add_child(label)
    _node_select = OptionButton.new(); _node_select.custom_minimum_size = Vector2(210, 38); row.add_child(_node_select)
    for spec in [["Validate", Callable(self, "_validate_graphs")], ["Run", Callable(self, "_run_graph")]]:
        var button := Button.new(); button.text = spec[0]; button.custom_minimum_size = Vector2(82, 38); button.pressed.connect(spec[1]); row.add_child(button)
    _breakpoint_button = Button.new(); _breakpoint_button.text = "Breakpoint"; _breakpoint_button.custom_minimum_size = Vector2(104, 38); _breakpoint_button.pressed.connect(_toggle_breakpoint); row.add_child(_breakpoint_button)
    _resume_button = Button.new(); _resume_button.text = "Resume"; _resume_button.custom_minimum_size = Vector2(82, 38); _resume_button.disabled = true; _resume_button.pressed.connect(_resume); row.add_child(_resume_button)
    _status = Label.new(); _status.text = "Idle"; _status.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; row.add_child(_status)
    _debugger.state_changed.connect(_on_debug_state_changed); hide()

func bind_service(service, panel) -> void:
    _service = service; _panel = panel
    if _service != null and not _service.graphs_changed.is_connected(_refresh_nodes): _service.graphs_changed.connect(_refresh_nodes)
    _refresh_nodes()

func open_toolbar() -> void: _refresh_nodes(); show()
func close_toolbar() -> void: hide()
func get_debugger(): return _debugger
func select_node(node_id: String) -> bool:
    _refresh_nodes()
    for index in range(_node_select.item_count):
        if str(_node_select.get_item_metadata(index)) == node_id: _node_select.select(index); _sync_breakpoint_label(); return true
    return false

func _current_graph_id() -> String:
    if _panel == null: return ""
    return str(_panel.get_current_graph_id())

func _refresh_nodes() -> void:
    if _node_select == null: return
    var previous := ""
    if _node_select.selected >= 0 and _node_select.selected < _node_select.item_count: previous = str(_node_select.get_item_metadata(_node_select.selected))
    _node_select.clear()
    if _service == null: return
    var graph: Dictionary = _service.get_graph(_current_graph_id())
    for value in graph.get("nodes", []):
        var node: Dictionary = value; var index := _node_select.item_count; _node_select.add_item(str(node.get("type_key", "node"))); _node_select.set_item_metadata(index, str(node.get("node_id", "")))
        if str(node.get("node_id", "")) == previous: _node_select.select(index)
    _sync_breakpoint_label()

func _validate_graphs() -> void:
    if _service == null: return
    var result: Dictionary = _debugger.validate_graphs(_service.get_graphs())
    if result.get("ok", false): _set_status("Valid · %d graph(s)" % int(result.get("graph_count", 0)), false)
    else: _set_status(str(result.get("errors", ["Validation failed"])[0]), true)

func _run_graph() -> void:
    if _service == null or _current_graph_id().is_empty(): _set_status("Select a graph first", true); return
    var result: Dictionary = _debugger.run_graph(_current_graph_id(), _service.get_graphs())
    if not result.get("ok", false): _set_status(str(result.get("errors", ["Debug run failed"])[0]), true)

func _toggle_breakpoint() -> void:
    var node_id := _selected_node_id()
    if node_id.is_empty() or _current_graph_id().is_empty(): _set_status("Select a debug node first", true); return
    var enabled := not _debugger.has_breakpoint(_current_graph_id(), node_id); _debugger.set_breakpoint(_current_graph_id(), node_id, enabled); _sync_breakpoint_label(); _set_status("Breakpoint %s" % ("enabled" if enabled else "disabled"), false)

func _resume() -> void:
    var result: Dictionary = _debugger.resume()
    if not result.get("ok", false): _set_status(str(result.get("errors", ["Resume failed"])[0]), true)

func _selected_node_id() -> String:
    if _node_select == null or _node_select.selected < 0 or _node_select.selected >= _node_select.item_count: return ""
    return str(_node_select.get_item_metadata(_node_select.selected))

func _sync_breakpoint_label() -> void:
    if _breakpoint_button == null: return
    var node_id := _selected_node_id(); _breakpoint_button.text = "● Breakpoint" if not node_id.is_empty() and _debugger.has_breakpoint(_current_graph_id(), node_id) else "Breakpoint"

func _on_debug_state_changed(state: Dictionary) -> void:
    var status := str(state.get("status", "idle")); var trace: Array = state.get("trace", []); var suffix := ""
    if status == "paused": suffix = " · node %s" % str(state.get("node_id", "")).left(8)
    elif not trace.is_empty(): suffix = " · trace: %s" % " | ".join(trace)
    _resume_button.disabled = status != "paused"; _set_status(status.capitalize() + suffix, status == "error")

func _set_status(message: String, is_error: bool) -> void:
    if _status != null: _status.text = message; _status.add_theme_color_override("font_color", Tokens.DANGER if is_error else Tokens.TEXT_SECONDARY)
    status_changed.emit(message, is_error)
