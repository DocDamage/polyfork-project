class_name PlayWorldAiGraphBuilder
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/visual_scripting/visual_graph_contracts.gd")
const NodeLibrary = preload("res://src/visual_scripting/builtin_visual_node_library.gd")
const Compiler = preload("res://src/visual_scripting/visual_graph_compiler.gd")


func build(arguments: Dictionary, existing_graphs: Array[Dictionary]) -> Dictionary:
    var graph_id: String = StableId.generate()
    var kind: String = str(arguments.get("kind", "event"))
    var variable_result: Dictionary = _variables(arguments.get("variables", []))
    if not variable_result.get("ok", false): return variable_result
    var node_result: Dictionary = _nodes(arguments.get("nodes", []), kind, variable_result.get("refs", {}))
    if not node_result.get("ok", false): return node_result
    var connection_result: Dictionary = _connections(arguments.get("connections", []), node_result.get("refs", {}), node_result.get("order", []))
    if not connection_result.get("ok", false): return connection_result
    var graph: Dictionary = {
        "document_type": Contracts.GRAPH_DOCUMENT_TYPE,
        "schema_version": Contracts.SCHEMA_VERSION,
        "graph_id": graph_id,
        "display_name": str(arguments.get("display_name", "AI Graph")).strip_edges(),
        "kind": kind,
        "owner_entity_id": null,
        "enabled": true,
        "nodes": node_result.get("nodes", []),
        "connections": connection_result.get("connections", []),
        "variables": variable_result.get("variables", []),
        "interface": {"inputs": [], "outputs": []},
        "editor": {"zoom": 1.0, "scroll": [0.0, 0.0]},
    }
    var all_graphs: Array[Dictionary] = existing_graphs.duplicate(true)
    all_graphs.append(graph)
    var compile_result: Dictionary = Compiler.new().compile_registry(all_graphs)
    if not compile_result.get("ok", false): return {"ok": false, "errors": compile_result.get("errors", [])}
    return {"ok": true, "errors": [], "graph": graph, "graph_id": graph_id}


func _variables(value: Variant) -> Dictionary:
    if not value is Array: return _failure("AI visual graph variables must be an array.")
    var variables: Array[Dictionary] = []
    var refs: Dictionary = {}
    var index := 0
    for item in value:
        if not item is Dictionary: return _failure("AI visual graph variables must be dictionaries.")
        var name: String = str(item.get("name", "")).strip_edges()
        var type_name: String = str(item.get("type", "any"))
        if name.is_empty() or not Contracts.VALUE_TYPES.has(type_name): return _failure("AI visual graph variable name/type is invalid.")
        var variable_id: String = StableId.generate()
        var ref: String = str(item.get("ref", name if not name.is_empty() else "var_%d" % index)).strip_edges()
        if ref.is_empty() or refs.has(ref): return _failure("AI visual graph variable refs must be unique and non-empty.")
        refs[ref] = variable_id
        variables.append({"variable_id": variable_id, "name": name, "type": type_name, "default": item.get("default", null)})
        index += 1
    return {"ok": true, "errors": [], "variables": variables, "refs": refs}


func _nodes(value: Variant, kind: String, variable_refs: Dictionary) -> Dictionary:
    if not value is Array: return _failure("AI visual graph nodes must be an array.")
    var source_nodes: Array = value.duplicate(true)
    if source_nodes.is_empty():
        source_nodes.append({"ref": "start", "type_key": "event.start" if kind == "event" else "macro.entry", "position": [0.0, 0.0], "properties": {}})
    var nodes: Array[Dictionary] = []
    var refs: Dictionary = {}
    var order: Array[String] = []
    for index in range(source_nodes.size()):
        var item: Variant = source_nodes[index]
        if not item is Dictionary: return _failure("AI visual graph nodes must be dictionaries.")
        var type_key: String = str(item.get("type_key", ""))
        if not NodeLibrary.has_key(type_key): return _failure("AI visual graph uses unsupported node type: %s" % type_key)
        var ref: String = str(item.get("ref", "node_%d" % index)).strip_edges()
        if ref.is_empty() or refs.has(ref): return _failure("AI visual graph node refs must be unique and non-empty.")
        var node_id: String = StableId.generate()
        refs[ref] = node_id
        order.append(node_id)
        var position: Variant = item.get("position", [float(index) * 220.0, 0.0])
        if not position is Array or position.size() != 2: return _failure("AI visual graph node position must contain two numbers.")
        var definition: Dictionary = NodeLibrary.get_definition(type_key)
        var properties: Dictionary = definition.get("properties", {}).duplicate(true)
        var patch: Variant = item.get("properties", {})
        if not patch is Dictionary: return _failure("AI visual graph node properties must be a dictionary.")
        for key_value in patch.keys(): properties[key_value] = patch[key_value]
        if properties.has("variable_ref"):
            var variable_ref: String = str(properties.get("variable_ref", ""))
            if not variable_refs.has(variable_ref): return _failure("AI visual graph node variable_ref does not resolve: %s" % variable_ref)
            properties.erase("variable_ref")
            properties["variable_id"] = variable_refs[variable_ref]
        nodes.append({"node_id": node_id, "type_key": type_key, "position": [float(position[0]), float(position[1])], "properties": properties})
    return {"ok": true, "errors": [], "nodes": nodes, "refs": refs, "order": order}


func _connections(value: Variant, node_refs: Dictionary, order: Array[String]) -> Dictionary:
    if not value is Array: return _failure("AI visual graph connections must be an array.")
    var result: Array[Dictionary] = []
    for item in value:
        if not item is Dictionary: return _failure("AI visual graph connections must be dictionaries.")
        var from_id: String = _node_id(item, "from_ref", "from_index", node_refs, order)
        var to_id: String = _node_id(item, "to_ref", "to_index", node_refs, order)
        if from_id.is_empty() or to_id.is_empty(): return _failure("AI visual graph connection node references do not resolve.")
        result.append({
            "connection_id": StableId.generate(),
            "from_node_id": from_id,
            "from_port": str(item.get("from_port", "")),
            "to_node_id": to_id,
            "to_port": str(item.get("to_port", "")),
            "kind": str(item.get("kind", "exec")),
        })
    return {"ok": true, "errors": [], "connections": result}


static func _node_id(item: Dictionary, ref_key: String, index_key: String, refs: Dictionary, order: Array[String]) -> String:
    if item.has(ref_key): return str(refs.get(str(item.get(ref_key, "")), ""))
    if item.has(index_key):
        var index: int = int(item.get(index_key, -1))
        if index >= 0 and index < order.size(): return order[index]
    return ""


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
