extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/visual_scripting/visual_graph_contracts.gd")
const Compiler = preload("res://src/visual_scripting/visual_graph_compiler.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []; var compiler = Compiler.new(); var graph: Dictionary = _simple_graph()
    var compiled: Dictionary = compiler.compile_graph(graph)
    if not compiled.get("ok", false): return ["Valid visual graph must compile: %s" % compiled.get("errors", [])]
    var compiled_again: Dictionary = compiler.compile_graph(graph)
    if compiled.get("plan", {}) != compiled_again.get("plan", {}): errors.append("Visual graph compilation must be deterministic.")
    var invalid_port: Dictionary = graph.duplicate(true); invalid_port["connections"][0]["from_port"] = "missing"
    if compiler.compile_graph(invalid_port).get("ok", false): errors.append("Compiler must reject missing ports.")
    var duplicate_data: Dictionary = _duplicate_data_input_graph()
    if compiler.compile_graph(duplicate_data).get("ok", false): errors.append("Compiler must reject multiple connections into one data input.")
    var mismatch: Dictionary = _type_mismatch_graph()
    if compiler.compile_graph(mismatch).get("ok", false): errors.append("Compiler must reject incompatible data port types.")
    var missing_macro: Dictionary = _macro_call_graph(StableId.generate())
    var registry: Dictionary = {str(missing_macro["graph_id"]):missing_macro}
    if compiler.compile_graph(missing_macro, registry).get("ok", false): errors.append("Compiler must reject unresolved macro graph references.")
    return errors

static func _simple_graph() -> Dictionary:
    var start := StableId.generate(); var literal := StableId.generate(); var print_node := StableId.generate()
    return _graph([_node(start,"event.start"),_node(literal,"value.literal",{"value":"hello"}),_node(print_node,"debug.print")],[
        _connection(start,"next",print_node,"in","exec"),_connection(literal,"value",print_node,"value","data")])

static func _duplicate_data_input_graph() -> Dictionary:
    var graph: Dictionary = _simple_graph(); var extra := StableId.generate(); graph["nodes"].append(_node(extra,"value.literal",{"value":"second"})); var print_id := str(graph["nodes"][2]["node_id"]); graph["connections"].append(_connection(extra,"value",print_id,"value","data")); return graph

static func _type_mismatch_graph() -> Dictionary:
    var start := StableId.generate(); var entity_set := StableId.generate(); var entity_value := StableId.generate(); var number_value := StableId.generate()
    return _graph([_node(start,"event.start"),_node(entity_set,"entity.set_position"),_node(entity_value,"value.literal",{"value":"entity"}),_node(number_value,"math.add")],[
        _connection(start,"next",entity_set,"in","exec"),_connection(entity_value,"value",entity_set,"entity_id","data"),_connection(number_value,"value",entity_set,"position","data")])

static func _macro_call_graph(macro_id: String) -> Dictionary:
    var start := StableId.generate(); var call := StableId.generate(); return _graph([_node(start,"event.start"),_node(call,"macro.call",{"macro_graph_id":macro_id})],[_connection(start,"next",call,"in","exec")])

static func _graph(nodes: Array, connections: Array) -> Dictionary:
    return {"document_type":Contracts.GRAPH_DOCUMENT_TYPE,"schema_version":Contracts.SCHEMA_VERSION,"graph_id":StableId.generate(),"display_name":"Compiler Graph","kind":"event","owner_entity_id":null,"enabled":true,"nodes":nodes,"connections":connections,"variables":[],"interface":{"inputs":[],"outputs":[]},"editor":{}}

static func _node(node_id: String, type_key: String, properties: Dictionary = {}) -> Dictionary: return {"node_id":node_id,"type_key":type_key,"position":[0.0,0.0],"properties":properties}
static func _connection(from_id: String, from_port: String, to_id: String, to_port: String, kind: String) -> Dictionary: return {"connection_id":StableId.generate(),"from_node_id":from_id,"from_port":from_port,"to_node_id":to_id,"to_port":to_port,"kind":kind}
