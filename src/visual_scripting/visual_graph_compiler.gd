class_name PlayWorldVisualGraphCompiler
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/visual_scripting/visual_graph_contracts.gd")
const NodeLibrary = preload("res://src/visual_scripting/builtin_visual_node_library.gd")

func compile_graph(graph: Dictionary, graph_registry: Dictionary = {}) -> Dictionary:
    var errors: Array[String] = Contracts.validate_graph(graph, NodeLibrary.keys())
    if not errors.is_empty(): return {"ok":false,"errors":errors}
    var nodes: Dictionary = {}; var definitions: Dictionary = {}; var entries: Array[String] = []; var macro_dependencies: Array[String] = []
    for value in graph.get("nodes", []):
        var node: Dictionary = value; var node_id := str(node.get("node_id", "")); var type_key := str(node.get("type_key", "")); var definition := NodeLibrary.get_definition(type_key)
        if type_key == "macro.entry":
            definition["value_outputs"] = _interface_types(graph.get("interface", {}).get("inputs", []))
            if str(graph.get("kind", "")) == "macro": entries.append(node_id)
        elif type_key == "macro.return": definition["value_inputs"] = _interface_types(graph.get("interface", {}).get("outputs", []))
        elif type_key == "macro.call":
            var macro_id := str(node.get("properties", {}).get("macro_graph_id", ""))
            if macro_id.is_empty() or not StableId.is_valid(macro_id): errors.append("Macro Call node requires a stable macro_graph_id.")
            elif graph_registry.is_empty():
                if not macro_dependencies.has(macro_id): macro_dependencies.append(macro_id)
            else:
                var macro: Dictionary = graph_registry.get(macro_id, {})
                if macro.is_empty(): errors.append("Macro Call references a missing graph: %s" % macro_id)
                elif str(macro.get("kind", "")) != "macro": errors.append("Macro Call target must be a macro graph: %s" % macro_id)
                else:
                    definition["value_inputs"] = _interface_types(macro.get("interface", {}).get("inputs", [])); definition["value_outputs"] = _interface_types(macro.get("interface", {}).get("outputs", []))
                    if not macro_dependencies.has(macro_id): macro_dependencies.append(macro_id)
        elif type_key == "event.start" and str(graph.get("kind", "event")) == "event": entries.append(node_id)
        nodes[node_id] = node.duplicate(true); definitions[node_id] = definition
    var graph_kind := str(graph.get("kind", "event"))
    if graph_kind == "event" and entries.is_empty(): errors.append("Event visual graph requires at least one Start node.")
    if graph_kind == "macro" and entries.size() != 1: errors.append("Macro visual graph requires exactly one Macro Entry node.")
    entries.sort(); macro_dependencies.sort()
    var exec_out: Dictionary = {}; var data_in: Dictionary = {}; var connections: Array[Dictionary] = []
    for value in graph.get("connections", []): connections.append(value.duplicate(true))
    connections.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("connection_id", "")) < str(b.get("connection_id", "")))
    for connection in connections:
        var from_id := str(connection.get("from_node_id", "")); var to_id := str(connection.get("to_node_id", "")); var from_port := str(connection.get("from_port", "")); var to_port := str(connection.get("to_port", "")); var kind := str(connection.get("kind", ""))
        var source_definition: Dictionary = definitions.get(from_id, {}); var target_definition: Dictionary = definitions.get(to_id, {})
        if kind == "exec":
            if not source_definition.get("exec_outputs", []).has(from_port): errors.append("Exec source port does not exist: %s.%s" % [from_id, from_port]); continue
            if not target_definition.get("exec_inputs", []).has(to_port): errors.append("Exec target port does not exist: %s.%s" % [to_id, to_port]); continue
            var source_outputs: Dictionary = exec_out.get(from_id, {}); var targets: Array[String] = []
            for target_value in source_outputs.get(from_port, []): targets.append(str(target_value))
            targets.append(to_id); targets.sort(); source_outputs[from_port] = targets; exec_out[from_id] = source_outputs
        else:
            var source_outputs: Dictionary = source_definition.get("value_outputs", {}); var target_inputs: Dictionary = target_definition.get("value_inputs", {})
            if not source_outputs.has(from_port): errors.append("Data source port does not exist: %s.%s" % [from_id, from_port]); continue
            if not target_inputs.has(to_port): errors.append("Data target port does not exist: %s.%s" % [to_id, to_port]); continue
            var target_key := "%s:%s" % [to_id, to_port]
            if data_in.has(target_key): errors.append("Data input may have only one incoming connection: %s" % target_key); continue
            var source_type := str(source_outputs[from_port]); var target_type := str(target_inputs[to_port])
            if not _types_compatible(source_type, target_type): errors.append("Incompatible visual graph data types: %s -> %s" % [source_type, target_type]); continue
            data_in[target_key] = {"node_id":from_id,"port":from_port,"type":source_type}
    if not errors.is_empty(): return {"ok":false,"errors":errors}
    return {"ok":true,"errors":[],"plan":{"graph_id":str(graph.get("graph_id", "")),"kind":graph_kind,"enabled":bool(graph.get("enabled", true)),"nodes":nodes,"definitions":definitions,"entries":entries,"exec_out":exec_out,"data_in":data_in,"variables":graph.get("variables", []).duplicate(true),"interface":graph.get("interface", {}).duplicate(true),"macro_dependencies":macro_dependencies}}

func compile_registry(graphs: Array[Dictionary]) -> Dictionary:
    var by_id: Dictionary = {}
    for graph in graphs: by_id[str(graph.get("graph_id", ""))] = graph.duplicate(true)
    var plans: Dictionary = {}; var errors: Array[String] = []; var ids: Array[String] = []
    for graph_id in by_id.keys(): ids.append(str(graph_id))
    ids.sort()
    for graph_id in ids:
        var result: Dictionary = compile_graph(by_id[graph_id], by_id)
        if not result.get("ok", false):
            for message in result.get("errors", []): errors.append("%s: %s" % [graph_id, str(message)])
        else: plans[graph_id] = result["plan"]
    errors.append_array(_validate_macro_cycles(plans))
    if not errors.is_empty(): return {"ok":false,"errors":errors}
    return {"ok":true,"errors":[],"plans":plans}

func _validate_macro_cycles(plans: Dictionary) -> Array[String]:
    var errors: Array[String] = []; var visiting: Dictionary = {}; var visited: Dictionary = {}; var ids: Array[String] = []
    for graph_id in plans.keys(): ids.append(str(graph_id))
    ids.sort()
    for graph_id in ids:
        var path: Array[String] = []; _visit_macro(graph_id, plans, visiting, visited, path, errors)
    return errors

func _visit_macro(graph_id: String, plans: Dictionary, visiting: Dictionary, visited: Dictionary, path: Array[String], errors: Array[String]) -> void:
    if visited.has(graph_id): return
    if visiting.has(graph_id):
        var cycle: Array[String] = path.duplicate(); cycle.append(graph_id); errors.append("Visual macro dependency cycle: %s" % " -> ".join(cycle)); return
    visiting[graph_id] = true; path.append(graph_id)
    var plan: Dictionary = plans.get(graph_id, {})
    for dependency in plan.get("macro_dependencies", []):
        if plans.has(str(dependency)): _visit_macro(str(dependency), plans, visiting, visited, path, errors)
    path.pop_back(); visiting.erase(graph_id); visited[graph_id] = true

static func _interface_types(ports: Array) -> Dictionary:
    var result: Dictionary = {}
    for value in ports:
        if value is Dictionary: result[str(value.get("name", ""))] = str(value.get("type", "any"))
    return result

static func _types_compatible(source_type: String, target_type: String) -> bool:
    if source_type == "any" or target_type == "any" or source_type == target_type: return true
    if target_type == "number" and ["int","float","number"].has(source_type): return true
    if source_type == "number" and ["float","number"].has(target_type): return true
    if source_type == "int" and target_type == "float": return true
    return false
