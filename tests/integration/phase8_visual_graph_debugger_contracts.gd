extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/visual_scripting/visual_graph_contracts.gd")
const Debugger = preload("res://src/visual_scripting/visual_graph_debugger.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []; var graph: Dictionary = _graph(); var graph_id := str(graph["graph_id"]); var print_id := str(graph["nodes"][2]["node_id"]); var debugger = Debugger.new(); debugger.set_breakpoint(graph_id, print_id, true)
    var graphs: Array[Dictionary] = [graph]; var run: Dictionary = debugger.run_graph(graph_id, graphs)
    if not run.get("ok", false): return ["Debugger fixture must run: %s" % str(run.get("errors", []))]
    var state: Dictionary = debugger.get_state()
    if state.get("status") != "paused" or str(state.get("node_id", "")) != print_id: errors.append("Debugger must pause before executing a breakpoint node.")
    if not state.get("trace", []).is_empty(): errors.append("Breakpoint must pause before the node contributes trace output.")
    var resume: Dictionary = debugger.resume()
    if not resume.get("ok", false) or debugger.get_state().get("status") != "completed": errors.append("Debugger resume must continue the existing execution state to completion.")
    if debugger.get_state().get("trace", []) != ["debug-value"]: errors.append("Debugger trace must include runtime debug output after resume.")
    var invalid: Dictionary = graph.duplicate(true); invalid["connections"][0]["from_port"] = "missing"
    var invalid_graphs: Array[Dictionary] = [invalid]
    if debugger.validate_graphs(invalid_graphs).get("ok", false): errors.append("Debugger validation must surface compiler diagnostics before execution.")
    return errors

static func _graph() -> Dictionary:
    var start := StableId.generate(); var literal := StableId.generate(); var print_node := StableId.generate()
    return {"document_type": Contracts.GRAPH_DOCUMENT_TYPE, "schema_version": Contracts.SCHEMA_VERSION, "graph_id": StableId.generate(), "display_name": "Debugger", "kind": "event", "owner_entity_id": null, "enabled": true, "nodes": [_node(start, "event.start"), _node(literal, "value.literal", {"value": "debug-value"}), _node(print_node, "debug.print")], "connections": [_connection(start, "next", print_node, "in", "exec"), _connection(literal, "value", print_node, "value", "data")], "variables": [], "interface": {"inputs": [], "outputs": []}, "editor": {}}
static func _node(id: String, key: String, properties: Dictionary = {}) -> Dictionary: return {"node_id": id, "type_key": key, "position": [0.0, 0.0], "properties": properties}
static func _connection(a: String, ap: String, b: String, bp: String, kind: String) -> Dictionary: return {"connection_id": StableId.generate(), "from_node_id": a, "from_port": ap, "to_node_id": b, "to_port": bp, "kind": kind}
