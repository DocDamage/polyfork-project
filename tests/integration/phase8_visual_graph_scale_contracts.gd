extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/visual_scripting/visual_graph_contracts.gd")
const Compiler = preload("res://src/visual_scripting/visual_graph_compiler.gd")
const Interpreter = preload("res://src/visual_scripting/visual_graph_interpreter.gd")

const GRAPH_COUNT := 120
const CI_BUDGET_MSEC := 12000

static func run_checks() -> Array[String]:
    var errors: Array[String] = []; var graphs: Array[Dictionary] = []
    for index in range(GRAPH_COUNT): graphs.append(_graph(index))
    var started := Time.get_ticks_msec(); var compiled: Dictionary = Compiler.new().compile_registry(graphs)
    if not compiled.get("ok", false): return ["Representative Phase 8 graph registry must compile: %s" % str(compiled.get("errors", []))]
    var plans: Dictionary = compiled["plans"]; var executed := 0
    for graph in graphs:
        var result: Dictionary = Interpreter.new().execute(plans[str(graph["graph_id"])], {"plans": plans})
        if not result.get("ok", false): errors.append("Representative graph execution failed."); break
        executed += 1
    var elapsed := Time.get_ticks_msec() - started
    print("Phase 8 representative workload: %d graphs compiled + executed in %d ms (CI budget %d ms)." % [executed, elapsed, CI_BUDGET_MSEC])
    if executed != GRAPH_COUNT: errors.append("Representative Phase 8 workload must execute all graphs.")
    if elapsed > CI_BUDGET_MSEC: errors.append("Representative Phase 8 graph workload exceeded its broad CI regression budget.")
    return errors

static func _graph(index: int) -> Dictionary:
    var start := StableId.generate(); var literal := StableId.generate(); var print_node := StableId.generate()
    return {"document_type": Contracts.GRAPH_DOCUMENT_TYPE, "schema_version": Contracts.SCHEMA_VERSION, "graph_id": StableId.generate(), "display_name": "Scale %03d" % index, "kind": "event", "owner_entity_id": null, "enabled": true, "nodes": [_node(start, "event.start"), _node(literal, "value.literal", {"value": index}), _node(print_node, "debug.print")], "connections": [_connection(start, "next", print_node, "in", "exec"), _connection(literal, "value", print_node, "value", "data")], "variables": [], "interface": {"inputs": [], "outputs": []}, "editor": {}}
static func _node(id: String, key: String, properties: Dictionary = {}) -> Dictionary: return {"node_id": id, "type_key": key, "position": [0.0, 0.0], "properties": properties}
static func _connection(a: String, ap: String, b: String, bp: String, kind: String) -> Dictionary: return {"connection_id": StableId.generate(), "from_node_id": a, "from_port": ap, "to_node_id": b, "to_port": bp, "kind": kind}
