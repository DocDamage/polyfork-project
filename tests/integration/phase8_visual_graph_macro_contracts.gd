extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/visual_scripting/visual_graph_contracts.gd")
const Compiler = preload("res://src/visual_scripting/visual_graph_compiler.gd")
const Interpreter = preload("res://src/visual_scripting/visual_graph_interpreter.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []; var macro: Dictionary = _double_macro(); var event: Dictionary = _event_graph(str(macro["graph_id"])); var graphs: Array[Dictionary] = [event, macro]
    var compiled: Dictionary = Compiler.new().compile_registry(graphs)
    if not compiled.get("ok", false): return ["Valid macro registry must compile: %s" % str(compiled.get("errors", []))]
    var plans: Dictionary = compiled["plans"]; var runtime = Interpreter.new(); var result: Dictionary = runtime.execute(plans[str(event["graph_id"])], {"plans":plans})
    if not result.get("ok", false): errors.append("Macro call must execute: %s" % str(result.get("errors", [])))
    elif result.get("trace", []) != ["8.0"]: errors.append("Macro parameters and outputs must propagate through nested execution.")
    var first: Dictionary = _empty_macro(); var second: Dictionary = _empty_macro(); _add_macro_call(first, str(second["graph_id"])); _add_macro_call(second, str(first["graph_id"]))
    var cyclic: Array[Dictionary] = [first, second]
    if Compiler.new().compile_registry(cyclic).get("ok", false): errors.append("Compiler must reject macro dependency cycles.")
    var recursive: Dictionary = _empty_macro(); var recursive_id := str(recursive["graph_id"]); _add_macro_call(recursive, recursive_id)
    var recursive_registry: Dictionary = {recursive_id:recursive}; var recursive_compile: Dictionary = Compiler.new().compile_graph(recursive, recursive_registry)
    if not recursive_compile.get("ok", false): errors.append("Runtime recursion guard fixture must compile as a single graph: %s" % str(recursive_compile.get("errors", [])))
    else:
        var recursive_plan: Dictionary = recursive_compile["plan"]; var recursion_runtime = Interpreter.new(); var recursion_result: Dictionary = recursion_runtime.execute(recursive_plan, {"plans":{recursive_id:recursive_plan}})
        if recursion_result.get("ok", false) or not str(recursion_result.get("errors", [])).contains("recursion guard"): errors.append("Runtime must reject recursive macro execution even without registry-level cycle validation.")
    return errors

static func _double_macro() -> Dictionary:
    var entry := StableId.generate(); var add := StableId.generate(); var finish := StableId.generate()
    return _graph("macro", [_node(entry,"macro.entry"),_node(add,"math.add"),_node(finish,"macro.return")],[
        _connection(entry,"next",finish,"in","exec"),_connection(entry,"x",add,"a","data"),_connection(entry,"x",add,"b","data"),_connection(add,"value",finish,"doubled","data")],{"inputs":[{"name":"x","type":"number"}],"outputs":[{"name":"doubled","type":"number"}]})

static func _event_graph(macro_id: String) -> Dictionary:
    var start := StableId.generate(); var literal := StableId.generate(); var call := StableId.generate(); var print_node := StableId.generate()
    return _graph("event", [_node(start,"event.start"),_node(literal,"value.literal",{"value":4}),_node(call,"macro.call",{"macro_graph_id":macro_id}),_node(print_node,"debug.print")],[
        _connection(start,"next",call,"in","exec"),_connection(call,"next",print_node,"in","exec"),_connection(literal,"value",call,"x","data"),_connection(call,"doubled",print_node,"value","data")])

static func _empty_macro() -> Dictionary:
    var entry := StableId.generate(); var finish := StableId.generate(); return _graph("macro",[_node(entry,"macro.entry"),_node(finish,"macro.return")],[_connection(entry,"next",finish,"in","exec")])

static func _add_macro_call(graph: Dictionary, macro_id: String) -> void:
    var entry_id := str(graph["nodes"][0]["node_id"]); var finish_id := str(graph["nodes"][1]["node_id"]); var call_id := StableId.generate(); graph["nodes"].append(_node(call_id,"macro.call",{"macro_graph_id":macro_id})); graph["connections"].clear(); graph["connections"].append(_connection(entry_id,"next",call_id,"in","exec")); graph["connections"].append(_connection(call_id,"next",finish_id,"in","exec"))

static func _graph(kind: String, nodes: Array, connections: Array, interface_value: Dictionary = {"inputs":[],"outputs":[]}) -> Dictionary: return {"document_type":Contracts.GRAPH_DOCUMENT_TYPE,"schema_version":Contracts.SCHEMA_VERSION,"graph_id":StableId.generate(),"display_name":"Macro Fixture","kind":kind,"owner_entity_id":null,"enabled":true,"nodes":nodes,"connections":connections,"variables":[],"interface":interface_value,"editor":{}}
static func _node(node_id: String, type_key: String, properties: Dictionary = {}) -> Dictionary: return {"node_id":node_id,"type_key":type_key,"position":[0.0,0.0],"properties":properties}
static func _connection(from_id: String, from_port: String, to_id: String, to_port: String, kind: String) -> Dictionary: return {"connection_id":StableId.generate(),"from_node_id":from_id,"from_port":from_port,"to_node_id":to_id,"to_port":to_port,"kind":kind}
