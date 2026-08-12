class_name PlayWorldVisualGraphInterpreter
extends RefCounted

var step_budget: int = 1024
var _steps: int = 0
var _trace: Array[String] = []
var _variables: Dictionary = {}
var _plan: Dictionary = {}
var _context: Dictionary = {}
var _value_stack: Dictionary = {}
var _macro_inputs: Dictionary = {}
var _macro_outputs: Dictionary = {}
var _macro_results: Dictionary = {}
var _plans: Dictionary = {}
var _macro_stack: Array[String] = []

func execute(plan: Dictionary, context: Dictionary = {}) -> Dictionary:
    _steps = 0; _trace.clear(); _variables.clear(); _value_stack.clear(); _macro_outputs.clear(); _macro_results.clear(); _plan = plan; _context = context
    _macro_inputs = context.get("macro_inputs", {}).duplicate(true); _plans = context.get("plans", {}); _macro_stack.clear()
    for value in context.get("macro_stack", []): _macro_stack.append(str(value))
    if plan.is_empty(): return _failure("Visual graph execution requires a compiled plan.")
    if not bool(plan.get("enabled", true)): return {"ok":true,"errors":[],"steps":0,"trace":[],"variables":{},"outputs":{}}
    for value in plan.get("variables", []):
        var variable: Dictionary = value; _variables[str(variable.get("variable_id", ""))] = variable.get("default")
    var queue: Array[String] = []
    for entry in plan.get("entries", []): queue.append(str(entry))
    while not queue.is_empty():
        var node_id: String = queue.pop_front()
        if not _consume_step(): return _failure("Visual graph execution exceeded the step budget.")
        var node: Dictionary = plan.get("nodes", {}).get(node_id, {}); var type_key := str(node.get("type_key", "")); var next_ports: Array[String] = []
        match type_key:
            "event.start", "macro.entry": next_ports = ["next"]
            "flow.branch":
                var condition: Dictionary = _input_value(node_id, "condition"); if not condition.get("ok", false): return condition
                next_ports = ["true" if bool(condition.get("value", false)) else "false"]
            "flow.sequence": next_ports = ["then_0","then_1"]
            "variable.set":
                var set_value: Dictionary = _input_value(node_id, "value"); if not set_value.get("ok", false): return set_value
                var variable_id := str(node.get("properties", {}).get("variable_id", "")); if not _variables.has(variable_id): return _failure("Set Variable references a missing variable.")
                _variables[variable_id] = set_value.get("value"); next_ports = ["next"]
            "entity.set_position":
                var entity_value: Dictionary = _input_value(node_id, "entity_id"); if not entity_value.get("ok", false): return entity_value
                var position_value: Dictionary = _input_value(node_id, "position"); if not position_value.get("ok", false): return position_value
                var set_result: Dictionary = _set_entity_position(str(entity_value.get("value", "")), position_value.get("value")); if not set_result.get("ok", false): return set_result
                next_ports = ["next"]
            "macro.call":
                var macro_result: Dictionary = _execute_macro(node_id, node); if not macro_result.get("ok", false): return macro_result
                next_ports = ["next"]
            "macro.return":
                for output_value in _plan.get("interface", {}).get("outputs", []):
                    var output: Dictionary = output_value; var output_name := str(output.get("name", "")); var value_result: Dictionary = _input_value(node_id, output_name)
                    if not value_result.get("ok", false): return value_result
                    _macro_outputs[output_name] = value_result.get("value")
            "debug.print":
                var debug_value: Dictionary = _input_value(node_id, "value"); if not debug_value.get("ok", false): return debug_value
                _trace.append(str(debug_value.get("value"))); next_ports = ["next"]
            _:
                if not _plan.get("definitions", {}).get(node_id, {}).get("exec_inputs", []).is_empty(): return _failure("Unsupported executable visual node: %s" % type_key)
        for port in next_ports: _append_exec_targets(queue, node_id, port)
    return {"ok":true,"errors":[],"steps":_steps,"trace":_trace.duplicate(),"variables":_variables.duplicate(true),"outputs":_macro_outputs.duplicate(true)}

func _execute_macro(node_id: String, node: Dictionary) -> Dictionary:
    var macro_id := str(node.get("properties", {}).get("macro_graph_id", "")); var current_graph_id := str(_plan.get("graph_id", ""))
    if macro_id == current_graph_id or _macro_stack.has(macro_id): return _failure("Visual macro recursion guard rejected recursive execution.")
    var macro_plan: Dictionary = _plans.get(macro_id, {})
    if macro_plan.is_empty(): return _failure("Macro runtime plan is missing: %s" % macro_id)
    var inputs: Dictionary = {}
    for input_value in macro_plan.get("interface", {}).get("inputs", []):
        var input: Dictionary = input_value; var input_name := str(input.get("name", "")); var value_result: Dictionary = _input_value(node_id, input_name)
        if not value_result.get("ok", false): return value_result
        inputs[input_name] = value_result.get("value")
    var child = get_script().new(); child.step_budget = max(1, step_budget - _steps)
    var child_stack: Array[String] = _macro_stack.duplicate(); child_stack.append(current_graph_id)
    var child_context: Dictionary = _context.duplicate(false); child_context["macro_inputs"] = inputs; child_context["plans"] = _plans; child_context["macro_stack"] = child_stack
    var result: Dictionary = child.execute(macro_plan, child_context)
    _steps += int(result.get("steps", 0)); if _steps > step_budget: return _failure("Visual graph execution exceeded the step budget.")
    if not result.get("ok", false): return result
    for trace_value in result.get("trace", []): _trace.append(str(trace_value))
    _macro_results[node_id] = result.get("outputs", {}).duplicate(true)
    return {"ok":true,"errors":[]}

func _input_value(node_id: String, port: String) -> Dictionary:
    var source: Dictionary = _plan.get("data_in", {}).get("%s:%s" % [node_id, port], {})
    if source.is_empty(): return _failure("Visual graph input is not connected: %s.%s" % [node_id, port])
    return _output_value(str(source.get("node_id", "")), str(source.get("port", "")))

func _output_value(node_id: String, port: String) -> Dictionary:
    var stack_key := "%s:%s" % [node_id, port]
    if _value_stack.has(stack_key): return _failure("Visual graph data dependency cycle detected at %s." % stack_key)
    if not _consume_step(): return _failure("Visual graph execution exceeded the step budget.")
    _value_stack[stack_key] = true
    var node: Dictionary = _plan.get("nodes", {}).get(node_id, {}); var type_key := str(node.get("type_key", "")); var result: Dictionary
    match type_key:
        "value.literal": result = {"ok":true,"errors":[],"value":node.get("properties", {}).get("value")}
        "math.add", "math.subtract", "math.multiply", "math.divide": result = _math_value(node_id, type_key)
        "logic.equal":
            var left: Dictionary = _input_value(node_id, "a"); var right: Dictionary = _input_value(node_id, "b")
            result = left if not left.get("ok", false) else right if not right.get("ok", false) else {"ok":true,"errors":[],"value":left.get("value") == right.get("value")}
        "variable.get", "variable.set":
            var variable_id := str(node.get("properties", {}).get("variable_id", "")); result = {"ok":true,"errors":[],"value":_variables[variable_id]} if _variables.has(variable_id) else _failure("Variable node references a missing variable.")
        "entity.get_position":
            var entity_value: Dictionary = _input_value(node_id, "entity_id"); result = entity_value if not entity_value.get("ok", false) else _get_entity_position(str(entity_value.get("value", "")))
        "macro.entry": result = {"ok":true,"errors":[],"value":_macro_inputs[port]} if _macro_inputs.has(port) else _failure("Macro input is missing: %s" % port)
        "macro.call":
            var outputs: Dictionary = _macro_results.get(node_id, {}); result = {"ok":true,"errors":[],"value":outputs[port]} if outputs.has(port) else _failure("Macro output was read before execution or does not exist: %s" % port)
        _: result = _failure("Unsupported visual value node: %s.%s" % [type_key, port])
    _value_stack.erase(stack_key); return result

func _math_value(node_id: String, type_key: String) -> Dictionary:
    var left: Dictionary = _input_value(node_id, "a"); if not left.get("ok", false): return left
    var right: Dictionary = _input_value(node_id, "b"); if not right.get("ok", false): return right
    if not _is_number(left.get("value")) or not _is_number(right.get("value")): return _failure("Math node inputs must be numeric.")
    var a := float(left.get("value")); var b := float(right.get("value")); var value: float = 0.0
    match type_key:
        "math.add": value = a + b
        "math.subtract": value = a - b
        "math.multiply": value = a * b
        "math.divide":
            if is_zero_approx(b): return _failure("Visual graph division by zero.")
            value = a / b
    return {"ok":true,"errors":[],"value":value}

func _append_exec_targets(queue: Array[String], node_id: String, port: String) -> void:
    var ports: Dictionary = _plan.get("exec_out", {}).get(node_id, {})
    for target in ports.get(port, []): queue.append(str(target))

func _get_entity_position(entity_id: String) -> Dictionary:
    var callback: Callable = _context.get("get_entity_position", Callable())
    if callback.is_valid(): return {"ok":true,"errors":[],"value":callback.call(entity_id)}
    var entities: Dictionary = _context.get("entities", {}); if not entities.has(entity_id): return _failure("Get Position references a missing runtime entity.")
    return {"ok":true,"errors":[],"value":entities[entity_id]}

func _set_entity_position(entity_id: String, position_value: Variant) -> Dictionary:
    var callback: Callable = _context.get("set_entity_position", Callable())
    if callback.is_valid():
        var result: Variant = callback.call(entity_id, position_value); if result is Dictionary: return result
        return {"ok":bool(result),"errors":[] if bool(result) else ["Runtime entity position callback failed."]}
    var entities: Dictionary = _context.get("entities", {}); if not entities.has(entity_id): return _failure("Set Position references a missing runtime entity.")
    entities[entity_id] = position_value; _context["entities"] = entities; return {"ok":true,"errors":[]}

func _consume_step() -> bool: _steps += 1; return _steps <= step_budget
static func _is_number(value: Variant) -> bool: return value is int or value is float
static func _failure(message: String) -> Dictionary: return {"ok":false,"errors":[message]}
