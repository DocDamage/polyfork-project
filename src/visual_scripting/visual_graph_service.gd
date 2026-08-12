class_name PlayWorldVisualGraphService
extends RefCounted

signal graphs_changed
signal status_changed(message: String, is_error: bool)

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/visual_scripting/visual_graph_contracts.gd")
const NodeLibrary = preload("res://src/visual_scripting/builtin_visual_node_library.gd")
const GraphState = preload("res://src/visual_scripting/visual_graph_state.gd")
const GraphRepository = preload("res://src/visual_scripting/visual_graph_repository.gd")
const SnapshotCommand = preload("res://src/visual_scripting/visual_graph_snapshot_command.gd")

var _project
var _editor_session
var _dirty_callback := Callable()
var _repository
var _state

func bind_project(project, project_directory: String, editor_session, dirty_callback: Callable) -> Dictionary:
    if project == null or editor_session == null: return _failure("Visual graph service requires a project and editor session.")
    if not dirty_callback.is_valid(): return _failure("Visual graph service requires a valid dirty-state callback.")
    _project = project; _editor_session = editor_session; _dirty_callback = dirty_callback; _repository = GraphRepository.new(project_directory)
    var opened: Dictionary = _repository.open_or_create(project)
    if not opened.get("ok", false): _clear(); return opened
    _state = opened["state"]
    if opened.get("registry_changed", false): _dirty_callback.call()
    return {"ok":true,"errors":[],"graph_count":_state.graphs.size(),"created":opened.get("created", false)}

func get_state(): return _state
func get_repository(): return _repository
func get_graphs() -> Array[Dictionary]: return [] if _state == null else _state.snapshot()
func get_graph(graph_id: String) -> Dictionary: return {} if _state == null else _state.get_graph(graph_id)

func create_graph(display_name: String, kind: String = "event", owner_entity_id: Variant = null) -> Dictionary:
    if not _is_bound(): return _failure("Visual graph service is not bound.")
    if display_name.strip_edges().is_empty(): return _failure("Visual graph display name is required.")
    if not Contracts.GRAPH_KINDS.has(kind): return _failure("Visual graph kind is invalid.")
    if owner_entity_id != null and not str(owner_entity_id).is_empty() and not StableId.is_valid(str(owner_entity_id)): return _failure("Visual graph owner must be null or a stable entity ID.")
    var graph_id := StableId.generate(); var graph := {
        "document_type":Contracts.GRAPH_DOCUMENT_TYPE,"schema_version":Contracts.SCHEMA_VERSION,"graph_id":graph_id,
        "display_name":display_name.strip_edges(),"kind":kind,"owner_entity_id":owner_entity_id,"enabled":true,
        "nodes":[],"connections":[],"variables":[],"interface":{"inputs":[],"outputs":[]},"editor":{"zoom":1.0,"scroll":[0.0,0.0]}
    }
    var records := _state.snapshot(); records.append(graph); var result := _execute_records(records, "Create visual graph")
    if result.get("ok", false): result["graph_id"] = graph_id
    return result

func delete_graph(graph_id: String) -> Dictionary:
    if not _is_bound(): return _failure("Visual graph service is not bound.")
    var records := _state.snapshot(); var index := _graph_index(records, graph_id)
    if index < 0: return _failure("Visual graph does not exist.")
    records.remove_at(index); return _execute_records(records, "Delete visual graph")

func configure_graph(graph_id: String, patch: Dictionary) -> Dictionary:
    var records := _state.snapshot(); var index := _graph_index(records, graph_id)
    if index < 0: return _failure("Visual graph does not exist.")
    var graph: Dictionary = records[index].duplicate(true)
    for key in ["display_name","enabled","owner_entity_id"]:
        if patch.has(key): graph[key] = patch[key]
    records[index] = graph; return _execute_records(records, "Configure visual graph")

func add_node(graph_id: String, type_key: String, position: Vector2 = Vector2.ZERO, properties: Dictionary = {}) -> Dictionary:
    if not NodeLibrary.has_key(type_key): return _failure("Unsupported visual node type: %s" % type_key)
    var records := _state.snapshot(); var index := _graph_index(records, graph_id)
    if index < 0: return _failure("Visual graph does not exist.")
    var graph: Dictionary = records[index].duplicate(true); var node_id := StableId.generate(); var definition := NodeLibrary.get_definition(type_key)
    var merged_properties: Dictionary = definition.get("properties", {}).duplicate(true)
    for key in properties.keys(): merged_properties[key] = properties[key]
    graph["nodes"].append({"node_id":node_id,"type_key":type_key,"position":[position.x,position.y],"properties":merged_properties})
    records[index] = graph; var result := _execute_records(records, "Add visual node")
    if result.get("ok", false): result["node_id"] = node_id
    return result

func remove_node(graph_id: String, node_id: String) -> Dictionary:
    var records := _state.snapshot(); var index := _graph_index(records, graph_id)
    if index < 0: return _failure("Visual graph does not exist.")
    var graph: Dictionary = records[index].duplicate(true); var nodes: Array = graph.get("nodes", []).duplicate(true); var found := false
    for node_index in range(nodes.size() - 1, -1, -1):
        if str(nodes[node_index].get("node_id", "")) == node_id: nodes.remove_at(node_index); found = true
    if not found: return _failure("Visual node does not exist.")
    var connections: Array = []
    for value in graph.get("connections", []):
        var connection: Dictionary = value
        if str(connection.get("from_node_id", "")) != node_id and str(connection.get("to_node_id", "")) != node_id: connections.append(connection.duplicate(true))
    graph["nodes"] = nodes; graph["connections"] = connections; records[index] = graph
    return _execute_records(records, "Remove visual node")

func move_node(graph_id: String, node_id: String, position: Vector2) -> Dictionary: return _patch_node(graph_id, node_id, {"position":[position.x,position.y]}, "Move visual node")
func configure_node(graph_id: String, node_id: String, properties: Dictionary) -> Dictionary: return _patch_node(graph_id, node_id, {"properties":properties.duplicate(true)}, "Configure visual node")

func connect_nodes(graph_id: String, from_node_id: String, from_port: String, to_node_id: String, to_port: String, kind: String) -> Dictionary:
    if not Contracts.CONNECTION_KINDS.has(kind): return _failure("Visual graph connection kind is invalid.")
    var records := _state.snapshot(); var index := _graph_index(records, graph_id)
    if index < 0: return _failure("Visual graph does not exist.")
    var graph: Dictionary = records[index].duplicate(true)
    if _node_index(graph.get("nodes", []), from_node_id) < 0 or _node_index(graph.get("nodes", []), to_node_id) < 0: return _failure("Visual graph connection endpoints must exist.")
    var connection_id := StableId.generate(); graph["connections"].append({"connection_id":connection_id,"from_node_id":from_node_id,"from_port":from_port,"to_node_id":to_node_id,"to_port":to_port,"kind":kind})
    records[index] = graph; var result := _execute_records(records, "Connect visual nodes")
    if result.get("ok", false): result["connection_id"] = connection_id
    return result

func disconnect(graph_id: String, connection_id: String) -> Dictionary:
    var records := _state.snapshot(); var index := _graph_index(records, graph_id)
    if index < 0: return _failure("Visual graph does not exist.")
    var graph: Dictionary = records[index].duplicate(true); var connections: Array = graph.get("connections", []).duplicate(true); var found := false
    for connection_index in range(connections.size() - 1, -1, -1):
        if str(connections[connection_index].get("connection_id", "")) == connection_id: connections.remove_at(connection_index); found = true
    if not found: return _failure("Visual connection does not exist.")
    graph["connections"] = connections; records[index] = graph; return _execute_records(records, "Disconnect visual nodes")

func add_variable(graph_id: String, name: String, type_name: String, default_value: Variant = null) -> Dictionary:
    if name.strip_edges().is_empty() or not Contracts.VALUE_TYPES.has(type_name): return _failure("Visual graph variable name/type is invalid.")
    var records := _state.snapshot(); var index := _graph_index(records, graph_id)
    if index < 0: return _failure("Visual graph does not exist.")
    var graph: Dictionary = records[index].duplicate(true); var variable_id := StableId.generate()
    graph["variables"].append({"variable_id":variable_id,"name":name.strip_edges(),"type":type_name,"default":default_value}); records[index] = graph
    var result := _execute_records(records, "Add visual variable"); if result.get("ok", false): result["variable_id"] = variable_id
    return result

func remove_variable(graph_id: String, variable_id: String) -> Dictionary:
    var records := _state.snapshot(); var index := _graph_index(records, graph_id)
    if index < 0: return _failure("Visual graph does not exist.")
    var graph: Dictionary = records[index].duplicate(true); var variables: Array = graph.get("variables", []).duplicate(true); var found := false
    for variable_index in range(variables.size() - 1, -1, -1):
        if str(variables[variable_index].get("variable_id", "")) == variable_id: variables.remove_at(variable_index); found = true
    if not found: return _failure("Visual variable does not exist.")
    for node in graph.get("nodes", []):
        if str(node.get("properties", {}).get("variable_id", "")) == variable_id: return _failure("Visual variable is still referenced by a node.")
    graph["variables"] = variables; records[index] = graph; return _execute_records(records, "Remove visual variable")

func _patch_node(graph_id: String, node_id: String, patch: Dictionary, label: String) -> Dictionary:
    var records := _state.snapshot(); var graph_index := _graph_index(records, graph_id)
    if graph_index < 0: return _failure("Visual graph does not exist.")
    var graph: Dictionary = records[graph_index].duplicate(true); var node_index := _node_index(graph.get("nodes", []), node_id)
    if node_index < 0: return _failure("Visual node does not exist.")
    var node: Dictionary = graph["nodes"][node_index].duplicate(true)
    for key in patch.keys(): node[key] = patch[key]
    graph["nodes"][node_index] = node; records[graph_index] = graph; return _execute_records(records, label)

func _execute_records(records: Array[Dictionary], label: String) -> Dictionary:
    if not _is_bound(): return _failure("Visual graph service is not bound.")
    var stage = GraphState.new(); var validation: Array[String] = stage.replace_records(records)
    if not validation.is_empty(): return {"ok":false,"errors":validation}
    var before_registries: Dictionary = _project.registries.duplicate(true); var after_registries: Dictionary = before_registries.duplicate(true); after_registries["visual_graph_ids"] = stage.graph_ids()
    var command = SnapshotCommand.new(_project, _state, _repository, _state.snapshot(), stage.snapshot(), before_registries, after_registries)
    var history_result: Dictionary = _editor_session.get_history().execute_command(command, label)
    if not history_result.get("ok", false): return _failure(str(history_result.get("error", history_result.get("errors", ["Visual graph command failed."]))))
    var dirty_result: Variant = _dirty_callback.call()
    if dirty_result is Dictionary and not dirty_result.get("ok", false): return _failure("Visual graph edit succeeded but project dirty-state signaling failed.")
    _editor_session.emit_signal("project_changed", _project.to_dictionary()); graphs_changed.emit(); status_changed.emit(label, false)
    return {"ok":true,"errors":[],"project_data":_project.to_dictionary()}

func _is_bound() -> bool: return _project != null and _editor_session != null and _state != null and _repository != null
func _clear() -> void: _project = null; _editor_session = null; _state = null; _repository = null; _dirty_callback = Callable()

static func _graph_index(records: Array, graph_id: String) -> int:
    for index in range(records.size()):
        if str(records[index].get("graph_id", "")) == graph_id: return index
    return -1

static func _node_index(nodes: Array, node_id: String) -> int:
    for index in range(nodes.size()):
        if str(nodes[index].get("node_id", "")) == node_id: return index
    return -1

static func _failure(message: String) -> Dictionary: return {"ok":false,"errors":[message]}
