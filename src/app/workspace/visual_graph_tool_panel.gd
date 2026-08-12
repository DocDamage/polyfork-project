class_name PlayWorldVisualGraphToolPanel
extends PanelContainer

signal close_requested
signal status_changed(message: String, is_error: bool)

const Tokens = preload("res://src/app/theme/ui_tokens.gd")
const NodeLibrary = preload("res://src/visual_scripting/builtin_visual_node_library.gd")

var _service
var _graph_select: OptionButton
var _search: LineEdit
var _palette: VBoxContainer
var _graph_edit: GraphEdit
var _status: Label
var _properties: LineEdit
var _selected_node_id: String = ""
var _selected_type_key: String = "debug.print"
var _current_graph_id: String = ""
var _rendering := false


func _ready() -> void:
    name = "VisualGraphToolPanel"
    anchors_preset = Control.PRESET_FULL_RECT
    anchor_left = 0.045; anchor_top = 0.11; anchor_right = 0.955; anchor_bottom = 0.84
    offset_left = 0.0; offset_top = 0.0; offset_right = 0.0; offset_bottom = 0.0
    mouse_filter = Control.MOUSE_FILTER_STOP
    theme_type_variation = &"ElevatedPanel"
    _build_ui(); hide()


func bind_service(service) -> void:
    _service = service
    if _service != null and not _service.graphs_changed.is_connected(_on_graphs_changed): _service.graphs_changed.connect(_on_graphs_changed)
    _refresh_graph_selector()


func open_panel() -> void:
    if _service == null: return
    show(); _refresh_graph_selector(); _search.grab_focus()


func close_panel() -> void: hide()
func is_open() -> bool: return visible
func get_graph_edit() -> GraphEdit: return _graph_edit
func get_current_graph_id() -> String: return _current_graph_id


func handle_shortcut(event: InputEvent) -> bool:
    if not visible: return false
    if event is InputEventJoypadButton and event.pressed:
        if event.button_index == JOY_BUTTON_X:
            _add_palette_node(_selected_type_key); return true
        if event.button_index == JOY_BUTTON_Y:
            _create_graph("event"); return true
    return false


func _build_ui() -> void:
    var margin := MarginContainer.new(); margin.add_theme_constant_override("margin_left", 18); margin.add_theme_constant_override("margin_top", 14); margin.add_theme_constant_override("margin_right", 18); margin.add_theme_constant_override("margin_bottom", 14); add_child(margin)
    var root := VBoxContainer.new(); root.add_theme_constant_override("separation", 10); margin.add_child(root)

    var header := HBoxContainer.new(); header.add_theme_constant_override("separation", 8); root.add_child(header)
    var title := Label.new(); title.text = "Visual Scripting"; title.theme_type_variation = &"HeadingLabel"; header.add_child(title)
    _graph_select = OptionButton.new(); _graph_select.custom_minimum_size = Vector2(240, 42); _graph_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _graph_select.item_selected.connect(_on_graph_selected); header.add_child(_graph_select)
    var new_event := Button.new(); new_event.text = "New Event"; new_event.custom_minimum_size = Vector2(104, 42); new_event.pressed.connect(_create_graph.bind("event")); header.add_child(new_event)
    var new_macro := Button.new(); new_macro.text = "New Macro"; new_macro.custom_minimum_size = Vector2(104, 42); new_macro.pressed.connect(_create_graph.bind("macro")); header.add_child(new_macro)
    var close_button := Button.new(); close_button.text = "Close"; close_button.custom_minimum_size = Vector2(76, 42); close_button.pressed.connect(func(): close_requested.emit()); header.add_child(close_button)

    var split := HSplitContainer.new(); split.size_flags_vertical = Control.SIZE_EXPAND_FILL; root.add_child(split)
    var sidebar_panel := PanelContainer.new(); sidebar_panel.custom_minimum_size = Vector2(235, 0); sidebar_panel.theme_type_variation = &"DrawerPanel"; split.add_child(sidebar_panel)
    var sidebar_margin := MarginContainer.new(); sidebar_margin.add_theme_constant_override("margin_left", 10); sidebar_margin.add_theme_constant_override("margin_top", 10); sidebar_margin.add_theme_constant_override("margin_right", 10); sidebar_margin.add_theme_constant_override("margin_bottom", 10); sidebar_panel.add_child(sidebar_margin)
    var sidebar := VBoxContainer.new(); sidebar.add_theme_constant_override("separation", 8); sidebar_margin.add_child(sidebar)
    _search = LineEdit.new(); _search.placeholder_text = "Search nodes..."; _search.custom_minimum_size = Vector2(0, 40); _search.text_changed.connect(_on_search_changed); sidebar.add_child(_search)
    var palette_scroll := ScrollContainer.new(); palette_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; sidebar.add_child(palette_scroll)
    _palette = VBoxContainer.new(); _palette.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _palette.add_theme_constant_override("separation", 5); palette_scroll.add_child(_palette)
    var property_label := Label.new(); property_label.text = "Selected node properties (JSON)"; property_label.theme_type_variation = &"CaptionLabel"; sidebar.add_child(property_label)
    _properties = LineEdit.new(); _properties.placeholder_text = "{}"; _properties.custom_minimum_size = Vector2(0, 40); sidebar.add_child(_properties)
    var apply_properties := Button.new(); apply_properties.text = "Apply Properties"; apply_properties.pressed.connect(_apply_properties); sidebar.add_child(apply_properties)

    _graph_edit = GraphEdit.new(); _graph_edit.name = "VisualGraphEdit"; _graph_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _graph_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL; _graph_edit.custom_minimum_size = Vector2(640, 420); split.add_child(_graph_edit)
    _graph_edit.connection_request.connect(_on_connection_request)
    _graph_edit.disconnection_request.connect(_on_disconnection_request)
    _graph_edit.delete_nodes_request.connect(_on_delete_nodes_request)
    _graph_edit.end_node_move.connect(_persist_node_positions)
    if _graph_edit.has_signal("node_selected"): _graph_edit.connect("node_selected", Callable(self, "_on_node_selected"))

    _status = Label.new(); _status.text = "X: add selected node  •  Y: new event  •  Delete: remove selected  •  Back: close"; _status.theme_type_variation = &"CaptionLabel"; root.add_child(_status)
    _rebuild_palette("")


func _refresh_graph_selector() -> void:
    if _graph_select == null: return
    var previous := _current_graph_id; _graph_select.clear()
    if _service == null: return
    var graphs: Array[Dictionary] = _service.get_graphs()
    graphs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("display_name", "")) < str(b.get("display_name", "")))
    for graph in graphs:
        var index := _graph_select.item_count; var kind := str(graph.get("kind", "event")).capitalize(); _graph_select.add_item("%s  ·  %s" % [str(graph.get("display_name", "Graph")), kind]); _graph_select.set_item_metadata(index, str(graph.get("graph_id", "")))
    if _graph_select.item_count == 0:
        _current_graph_id = ""; _render_graph(); return
    var selected := 0
    for index in range(_graph_select.item_count):
        if str(_graph_select.get_item_metadata(index)) == previous: selected = index; break
    _graph_select.select(selected); _current_graph_id = str(_graph_select.get_item_metadata(selected)); _render_graph()


func _render_graph() -> void:
    if _graph_edit == null: return
    _rendering = true; _selected_node_id = ""; _properties.text = "{}"
    _graph_edit.clear_connections()
    for child in _graph_edit.get_children():
        if child is GraphNode: child.free()
    if _service == null or _current_graph_id.is_empty(): _rendering = false; return
    var graph: Dictionary = _service.get_graph(_current_graph_id)
    for value in graph.get("nodes", []): _add_graph_node(graph, value)
    for value in graph.get("connections", []):
        var connection: Dictionary = value; var from_id := str(connection.get("from_node_id", "")); var to_id := str(connection.get("to_node_id", ""))
        var from_node := _graph_edit.get_node_or_null(NodePath(from_id)) as GraphNode; var to_node := _graph_edit.get_node_or_null(NodePath(to_id)) as GraphNode
        if from_node == null or to_node == null: continue
        var from_index := _port_index(from_node.get_meta("output_ports", []), str(connection.get("from_port", ""))); var to_index := _port_index(to_node.get_meta("input_ports", []), str(connection.get("to_port", "")))
        if from_index >= 0 and to_index >= 0: _graph_edit.connect_node(StringName(from_id), from_index, StringName(to_id), to_index)
    _rendering = false


func _add_graph_node(graph: Dictionary, node_value: Variant) -> void:
    if not node_value is Dictionary: return
    var node: Dictionary = node_value; var node_id := str(node.get("node_id", "")); var type_key := str(node.get("type_key", "")); var definition := _definition_for_node(graph, node)
    var graph_node := GraphNode.new(); graph_node.name = node_id; graph_node.title = str(definition.get("display_name", type_key)); graph_node.custom_minimum_size = Vector2(190, 90)
    var position: Array = node.get("position", [0.0, 0.0]); graph_node.position_offset = Vector2(float(position[0]), float(position[1])); graph_node.set_meta("persisted_position", graph_node.position_offset); graph_node.set_meta("type_key", type_key)
    var inputs: Array[Dictionary] = _port_descriptors(definition, true); var outputs: Array[Dictionary] = _port_descriptors(definition, false); graph_node.set_meta("input_ports", inputs); graph_node.set_meta("output_ports", outputs)
    var rows: int = maxi(1, maxi(inputs.size(), outputs.size()))
    for row_index in range(rows):
        var row := HBoxContainer.new(); row.custom_minimum_size = Vector2(176, 28)
        var left := Label.new(); left.size_flags_horizontal = Control.SIZE_EXPAND_FILL; left.text = str(inputs[row_index].get("name", "")) if row_index < inputs.size() else ""; row.add_child(left)
        var right := Label.new(); right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; right.size_flags_horizontal = Control.SIZE_EXPAND_FILL; right.text = str(outputs[row_index].get("name", "")) if row_index < outputs.size() else ""; row.add_child(right)
        graph_node.add_child(row)
        var has_left := row_index < inputs.size(); var has_right := row_index < outputs.size(); var left_type := _port_type(inputs[row_index]) if has_left else 0; var right_type := _port_type(outputs[row_index]) if has_right else 0
        graph_node.set_slot(row_index, has_left, left_type, _port_color(inputs[row_index]) if has_left else Tokens.TEXT_MUTED, has_right, right_type, _port_color(outputs[row_index]) if has_right else Tokens.TEXT_MUTED)
    _graph_edit.add_child(graph_node)


func _definition_for_node(graph: Dictionary, node: Dictionary) -> Dictionary:
    var type_key := str(node.get("type_key", "")); var definition := NodeLibrary.get_definition(type_key)
    if type_key == "macro.entry": definition["value_outputs"] = _interface_types(graph.get("interface", {}).get("inputs", []))
    elif type_key == "macro.return": definition["value_inputs"] = _interface_types(graph.get("interface", {}).get("outputs", []))
    elif type_key == "macro.call" and _service != null:
        var macro_id := str(node.get("properties", {}).get("macro_graph_id", "")); var macro: Dictionary = _service.get_graph(macro_id)
        if not macro.is_empty(): definition["value_inputs"] = _interface_types(macro.get("interface", {}).get("inputs", [])); definition["value_outputs"] = _interface_types(macro.get("interface", {}).get("outputs", []))
    return definition


func _port_descriptors(definition: Dictionary, inputs: bool) -> Array[Dictionary]:
    var result: Array[Dictionary] = []; var exec_key := "exec_inputs" if inputs else "exec_outputs"; var value_key := "value_inputs" if inputs else "value_outputs"
    for name_value in definition.get(exec_key, []): result.append({"name":str(name_value), "kind":"exec", "type":"exec"})
    var values: Dictionary = definition.get(value_key, {}); var names: Array[String] = []
    for key in values.keys(): names.append(str(key))
    names.sort()
    for name in names: result.append({"name":name, "kind":"data", "type":str(values[name])})
    return result


func _create_graph(kind: String) -> void:
    if _service == null: return
    var count: int = _service.get_graphs().size() + 1; var result: Dictionary = _service.create_graph("%s %d" % ["Event Graph" if kind == "event" else "Macro", count], kind)
    if not result.get("ok", false): _report(result); return
    var graph_id := str(result.get("graph_id", ""))
    if kind == "event": _service.add_node(graph_id, "event.start", Vector2(80, 120))
    else:
        _service.add_node(graph_id, "macro.entry", Vector2(80, 120)); _service.add_node(graph_id, "macro.return", Vector2(480, 120))
    _current_graph_id = graph_id; _refresh_graph_selector(); _set_status("%s created" % ("Event graph" if kind == "event" else "Macro"), false)


func _add_palette_node(type_key: String) -> void:
    if _service == null or _current_graph_id.is_empty(): _set_status("Create or select a graph first", true); return
    if ["event.start", "macro.entry", "macro.return"].has(type_key): _set_status("Entry nodes are created with their graph", true); return
    var graph: Dictionary = _service.get_graph(_current_graph_id); var offset := float(graph.get("nodes", []).size() * 28); var result: Dictionary = _service.add_node(_current_graph_id, type_key, Vector2(210 + offset, 120 + offset))
    _report(result)


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
    var source := _graph_edit.get_node_or_null(NodePath(str(from_node))) as GraphNode; var target := _graph_edit.get_node_or_null(NodePath(str(to_node))) as GraphNode
    if source == null or target == null: return
    var outputs: Array = source.get_meta("output_ports", []); var inputs: Array = target.get_meta("input_ports", [])
    if from_port < 0 or from_port >= outputs.size() or to_port < 0 or to_port >= inputs.size(): return
    var output: Dictionary = outputs[from_port]; var input: Dictionary = inputs[to_port]
    if str(output.get("kind", "")) != str(input.get("kind", "")): _set_status("Exec and data ports cannot be mixed", true); return
    _report(_service.connect_nodes(_current_graph_id, str(from_node), str(output.get("name", "")), str(to_node), str(input.get("name", "")), str(output.get("kind", ""))))


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
    var graph: Dictionary = _service.get_graph(_current_graph_id); var source := _graph_edit.get_node_or_null(NodePath(str(from_node))) as GraphNode; var target := _graph_edit.get_node_or_null(NodePath(str(to_node))) as GraphNode
    if source == null or target == null: return
    var outputs: Array = source.get_meta("output_ports", []); var inputs: Array = target.get_meta("input_ports", [])
    if from_port < 0 or from_port >= outputs.size() or to_port < 0 or to_port >= inputs.size(): return
    var from_name := str(outputs[from_port].get("name", "")); var to_name := str(inputs[to_port].get("name", ""))
    for value in graph.get("connections", []):
        var connection: Dictionary = value
        if str(connection.get("from_node_id", "")) == str(from_node) and str(connection.get("to_node_id", "")) == str(to_node) and str(connection.get("from_port", "")) == from_name and str(connection.get("to_port", "")) == to_name:
            _report(_service.disconnect_nodes(_current_graph_id, str(connection.get("connection_id", "")))); return


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
    for node_name in nodes:
        var result: Dictionary = _service.remove_node(_current_graph_id, str(node_name))
        if not result.get("ok", false): _report(result); return


func _persist_node_positions() -> void:
    if _rendering or _service == null: return
    for child in _graph_edit.get_children():
        if not child is GraphNode: continue
        var graph_node := child as GraphNode; var old_position: Vector2 = graph_node.get_meta("persisted_position", graph_node.position_offset)
        if old_position.is_equal_approx(graph_node.position_offset): continue
        var result: Dictionary = _service.move_node(_current_graph_id, str(graph_node.name), graph_node.position_offset)
        if not result.get("ok", false): _report(result); return
        graph_node.set_meta("persisted_position", graph_node.position_offset)


func _on_node_selected(node: Node) -> void:
    if not node is GraphNode: return
    _selected_node_id = str(node.name); var graph: Dictionary = _service.get_graph(_current_graph_id)
    for value in graph.get("nodes", []):
        var record: Dictionary = value
        if str(record.get("node_id", "")) == _selected_node_id: _properties.text = JSON.stringify(record.get("properties", {})); break


func _apply_properties() -> void:
    if _selected_node_id.is_empty(): _set_status("Select a node first", true); return
    var parser := JSON.new(); var parse_error := parser.parse(_properties.text)
    if parse_error != OK or not parser.data is Dictionary: _set_status("Properties must be a JSON object", true); return
    _report(_service.configure_node(_current_graph_id, _selected_node_id, parser.data))


func _on_graph_selected(index: int) -> void:
    if index < 0 or index >= _graph_select.item_count: return
    _current_graph_id = str(_graph_select.get_item_metadata(index)); _render_graph()


func _on_graphs_changed() -> void: _refresh_graph_selector()
func _on_search_changed(value: String) -> void: _rebuild_palette(value)


func _rebuild_palette(filter_text: String) -> void:
    for child in _palette.get_children(): child.queue_free()
    var needle := filter_text.strip_edges().to_lower()
    for definition in NodeLibrary.definitions():
        var type_key := str(definition.get("key", "")); if ["event.start", "macro.entry", "macro.return"].has(type_key): continue
        var label := "%s  ·  %s" % [str(definition.get("display_name", type_key)), str(definition.get("category", "Node"))]
        if not needle.is_empty() and not label.to_lower().contains(needle) and not type_key.contains(needle): continue
        var button := Button.new(); button.text = label; button.alignment = HORIZONTAL_ALIGNMENT_LEFT; button.tooltip_text = type_key; button.focus_entered.connect(func(): _selected_type_key = type_key); button.pressed.connect(_add_palette_node.bind(type_key)); _palette.add_child(button)


func _report(result: Dictionary) -> void:
    if result.get("ok", false): _set_status("Graph updated", false)
    else: _set_status(str(result.get("errors", ["Visual graph action failed."])[0]), true)


func _set_status(message: String, is_error: bool) -> void:
    _status.text = message; _status.add_theme_color_override("font_color", Tokens.DANGER if is_error else Tokens.TEXT_SECONDARY); status_changed.emit(message, is_error)


static func _port_index(ports: Array, port_name: String) -> int:
    for index in range(ports.size()):
        if str(ports[index].get("name", "")) == port_name: return index
    return -1

static func _port_type(port: Dictionary) -> int: return 0 if str(port.get("kind", "")) == "exec" else 1
static func _port_color(port: Dictionary) -> Color: return Tokens.GAMEPLAY if str(port.get("kind", "")) == "exec" else Tokens.CREATE_PURPLE_HOVER
static func _interface_types(ports: Array) -> Dictionary:
    var result: Dictionary = {}
    for value in ports:
        if value is Dictionary: result[str(value.get("name", ""))] = str(value.get("type", "any"))
    return result
