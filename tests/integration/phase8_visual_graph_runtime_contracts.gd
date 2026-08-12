extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/visual_scripting/visual_graph_contracts.gd")
const Compiler = preload("res://src/visual_scripting/visual_graph_compiler.gd")
const Interpreter = preload("res://src/visual_scripting/visual_graph_interpreter.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []; var compiler = Compiler.new(); var graph: Dictionary = _calculation_graph(); var compiled: Dictionary = compiler.compile_graph(graph)
    if not compiled.get("ok", false): return ["Runtime fixture must compile: %s" % compiled.get("errors", [])]
    var interpreter = Interpreter.new(); var result: Dictionary = interpreter.execute(compiled["plan"])
    if not result.get("ok", false): errors.append("Compiled visual graph must execute: %s" % result.get("errors", []))
    elif result.get("trace", []) != ["5.0"]: errors.append("Visual runtime must evaluate data dependencies and flow deterministically.")
    var entity_graph: Dictionary = _entity_graph(); var entity_compile: Dictionary = compiler.compile_graph(entity_graph)
    var entity_id := str(entity_graph["nodes"][1]["properties"]["value"]); var entities: Dictionary = {entity_id:[0.0,0.0,0.0]}
    var entity_result: Dictionary = interpreter.execute(entity_compile.get("plan", {}), {"entities":entities})
    if not entity_result.get("ok", false): errors.append("Entity visual nodes must execute against runtime context: %s" % entity_result.get("errors", []))
    elif entities.get(entity_id) != [4.0,2.0,1.0]: errors.append("Set Position must mutate the supplied disposable runtime entity context.")
    var loop_graph: Dictionary = _loop_graph(); var loop_compile: Dictionary = compiler.compile_graph(loop_graph); interpreter.step_budget = 12
    var loop_result: Dictionary = interpreter.execute(loop_compile.get("plan", {}))
    if loop_result.get("ok", false) or not str(loop_result.get("errors", [])).contains("step budget"): errors.append("Visual runtime must stop cyclic execution at its hard step budget.")
    return errors

static func _calculation_graph() -> Dictionary:
    var variable_id := StableId.generate(); var start := StableId.generate(); var two := StableId.generate(); var three := StableId.generate(); var add := StableId.generate(); var set_var := StableId.generate(); var get_var := StableId.generate(); var print_node := StableId.generate()
    return _graph([_node(start,"event.start"),_node(two,"value.literal",{"value":2}),_node(three,"value.literal",{"value":3}),_node(add,"math.add"),_node(set_var,"variable.set",{"variable_id":variable_id}),_node(get_var,"variable.get",{"variable_id":variable_id}),_node(print_node,"debug.print")],[
        _connection(start,"next",set_var,"in","exec"),_connection(set_var,"next",print_node,"in","exec"),_connection(two,"value",add,"a","data"),_connection(three,"value",add,"b","data"),_connection(add,"value",set_var,"value","data"),_connection(get_var,"value",print_node,"value","data")],[{"variable_id":variable_id,"name":"Counter","type":"float","default":0.0}])

static func _entity_graph() -> Dictionary:
    var entity_id := StableId.generate(); var start := StableId.generate(); var entity_literal := StableId.generate(); var pos_literal := StableId.generate(); var set_pos := StableId.generate()
    return _graph([_node(start,"event.start"),_node(entity_literal,"value.literal",{"value":entity_id}),_node(pos_literal,"value.literal",{"value":[4.0,2.0,1.0]}),_node(set_pos,"entity.set_position")],[
        _connection(start,"next",set_pos,"in","exec"),_connection(entity_literal,"value",set_pos,"entity_id","data"),_connection(pos_literal,"value",set_pos,"position","data")])

static func _loop_graph() -> Dictionary:
    var start := StableId.generate(); var sequence := StableId.generate()
    return _graph([_node(start,"event.start"),_node(sequence,"flow.sequence")],[_connection(start,"next",sequence,"in","exec"),_connection(sequence,"then_0",sequence,"in","exec")])

static func _graph(nodes: Array, connections: Array, variables: Array = []) -> Dictionary: return {"document_type":Contracts.GRAPH_DOCUMENT_TYPE,"schema_version":Contracts.SCHEMA_VERSION,"graph_id":StableId.generate(),"display_name":"Runtime Graph","kind":"event","owner_entity_id":null,"enabled":true,"nodes":nodes,"connections":connections,"variables":variables,"interface":{"inputs":[],"outputs":[]},"editor":{}}
static func _node(node_id: String, type_key: String, properties: Dictionary = {}) -> Dictionary: return {"node_id":node_id,"type_key":type_key,"position":[0.0,0.0],"properties":properties}
static func _connection(from_id: String, from_port: String, to_id: String, to_port: String, kind: String) -> Dictionary: return {"connection_id":StableId.generate(),"from_node_id":from_id,"from_port":from_port,"to_node_id":to_id,"to_port":to_port,"kind":kind}
