class_name PlayWorldVisualGraphContracts
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")

const SCHEMA_VERSION := 1
const REGISTRY_DOCUMENT_TYPE := "visual_graph_registry"
const GRAPH_DOCUMENT_TYPE := "visual_graph"
const GRAPH_KINDS := ["event", "macro"]
const CONNECTION_KINDS := ["exec", "data"]
const VALUE_TYPES := ["any", "bool", "int", "float", "number", "string", "vector3", "entity"]

static func validate_registry_document(data: Dictionary, known_type_keys: Array[String] = []) -> Array[String]:
    var errors: Array[String] = []
    if data.get("document_type") != REGISTRY_DOCUMENT_TYPE: errors.append("Visual graph registry document_type is invalid.")
    if int(data.get("schema_version", 0)) != SCHEMA_VERSION: errors.append("Visual graph registry schema_version is unsupported.")
    var graphs = data.get("graphs", [])
    if not graphs is Array: errors.append("Visual graph registry graphs must be an array."); return errors
    var seen: Dictionary = {}
    for value in graphs:
        if not value is Dictionary: errors.append("Visual graph registry must contain dictionaries only."); continue
        var graph: Dictionary = value
        errors.append_array(validate_graph(graph, known_type_keys))
        var graph_id := str(graph.get("graph_id", ""))
        if seen.has(graph_id): errors.append("Visual graph registry contains duplicate graph IDs.")
        seen[graph_id] = true
    return errors

static func validate_graph(graph: Dictionary, known_type_keys: Array[String] = []) -> Array[String]:
    var errors: Array[String] = []
    if graph.get("document_type") != GRAPH_DOCUMENT_TYPE: errors.append("Visual graph document_type is invalid.")
    if int(graph.get("schema_version", 0)) != SCHEMA_VERSION: errors.append("Visual graph schema_version is unsupported.")
    if not StableId.is_valid(str(graph.get("graph_id", ""))): errors.append("Visual graph graph_id must be a stable UUID.")
    if str(graph.get("display_name", "")).strip_edges().is_empty(): errors.append("Visual graph display_name is required.")
    if not GRAPH_KINDS.has(str(graph.get("kind", ""))): errors.append("Visual graph kind is invalid.")
    var owner = graph.get("owner_entity_id")
    if owner != null and not str(owner).is_empty() and not StableId.is_valid(str(owner)): errors.append("Visual graph owner_entity_id must be null or a stable UUID.")
    if not graph.get("enabled", true) is bool: errors.append("Visual graph enabled must be boolean.")
    errors.append_array(_validate_variables(graph.get("variables", [])))
    errors.append_array(_validate_interface(graph.get("interface", {})))
    var node_result: Dictionary = _validate_nodes(graph.get("nodes", []), known_type_keys)
    errors.append_array(node_result["errors"])
    errors.append_array(_validate_connections(graph.get("connections", []), node_result["node_ids"]))
    if not graph.get("editor", {}) is Dictionary: errors.append("Visual graph editor metadata must be a dictionary.")
    return errors

static func _validate_nodes(value: Variant, known_type_keys: Array[String]) -> Dictionary:
    var errors: Array[String] = []; var node_ids: Dictionary = {}
    if not value is Array: return {"errors":["Visual graph nodes must be an array."], "node_ids":node_ids}
    for item in value:
        if not item is Dictionary: errors.append("Visual graph nodes must contain dictionaries only."); continue
        var node: Dictionary = item; var node_id := str(node.get("node_id", "")); var type_key := str(node.get("type_key", ""))
        if not StableId.is_valid(node_id): errors.append("Visual graph node_id must be a stable UUID.")
        elif node_ids.has(node_id): errors.append("Visual graph contains duplicate node IDs.")
        node_ids[node_id] = true
        if type_key.strip_edges().is_empty(): errors.append("Visual graph node type_key is required.")
        elif not known_type_keys.is_empty() and not known_type_keys.has(type_key): errors.append("Visual graph node type_key is unsupported: %s" % type_key)
        var position = node.get("position", [])
        if not position is Array or position.size() != 2 or not _is_number(position[0]) or not _is_number(position[1]): errors.append("Visual graph node position must contain two numbers.")
        if not node.get("properties", {}) is Dictionary: errors.append("Visual graph node properties must be a dictionary.")
    return {"errors":errors, "node_ids":node_ids}

static func _validate_connections(value: Variant, node_ids: Dictionary) -> Array[String]:
    var errors: Array[String] = []; var seen: Dictionary = {}
    if not value is Array: return ["Visual graph connections must be an array."]
    for item in value:
        if not item is Dictionary: errors.append("Visual graph connections must contain dictionaries only."); continue
        var connection: Dictionary = item; var connection_id := str(connection.get("connection_id", ""))
        if not StableId.is_valid(connection_id): errors.append("Visual graph connection_id must be a stable UUID.")
        elif seen.has(connection_id): errors.append("Visual graph contains duplicate connection IDs.")
        seen[connection_id] = true
        var from_id := str(connection.get("from_node_id", "")); var to_id := str(connection.get("to_node_id", ""))
        if not node_ids.has(from_id): errors.append("Visual graph connection source node does not resolve.")
        if not node_ids.has(to_id): errors.append("Visual graph connection target node does not resolve.")
        if str(connection.get("from_port", "")).is_empty() or str(connection.get("to_port", "")).is_empty(): errors.append("Visual graph connection ports are required.")
        if not CONNECTION_KINDS.has(str(connection.get("kind", ""))): errors.append("Visual graph connection kind is invalid.")
    return errors

static func _validate_variables(value: Variant) -> Array[String]:
    var errors: Array[String] = []; var seen_ids: Dictionary = {}; var seen_names: Dictionary = {}
    if not value is Array: return ["Visual graph variables must be an array."]
    for item in value:
        if not item is Dictionary: errors.append("Visual graph variables must contain dictionaries only."); continue
        var variable: Dictionary = item; var variable_id := str(variable.get("variable_id", "")); var name := str(variable.get("name", "")); var type_name := str(variable.get("type", ""))
        if not StableId.is_valid(variable_id): errors.append("Visual graph variable_id must be a stable UUID.")
        elif seen_ids.has(variable_id): errors.append("Visual graph contains duplicate variable IDs.")
        seen_ids[variable_id] = true
        if name.strip_edges().is_empty(): errors.append("Visual graph variable name is required.")
        elif seen_names.has(name): errors.append("Visual graph variable names must be unique.")
        seen_names[name] = true
        if not VALUE_TYPES.has(type_name): errors.append("Visual graph variable type is invalid.")
    return errors

static func _validate_interface(value: Variant) -> Array[String]:
    var errors: Array[String] = []
    if not value is Dictionary: return ["Visual graph interface must be a dictionary."]
    for section in ["inputs", "outputs"]:
        var ports = value.get(section, [])
        if not ports is Array: errors.append("Visual graph interface %s must be an array." % section); continue
        var names: Dictionary = {}
        for port_value in ports:
            if not port_value is Dictionary: errors.append("Visual graph interface ports must be dictionaries."); continue
            var port: Dictionary = port_value; var name := str(port.get("name", "")); var type_name := str(port.get("type", ""))
            if name.strip_edges().is_empty(): errors.append("Visual graph interface port name is required.")
            elif names.has(name): errors.append("Visual graph interface port names must be unique within a direction.")
            names[name] = true
            if not VALUE_TYPES.has(type_name): errors.append("Visual graph interface port type is invalid.")
    return errors

static func _is_number(value: Variant) -> bool: return value is int or value is float
