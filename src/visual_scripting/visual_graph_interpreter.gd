class_name PlayWorldVisualGraphInterpreter
extends RefCounted

var step_budget: int = 1024
var _steps: int = 0
var _trace: Array[String] = []
var _variables: Dictionary = {}
var _plan: Dictionary = {}
var _context: Dictionary = {}
var _value_stack: Dictionary = {}

func execute(plan: Dictionary, context: Dictionary = {}) -> Dictionary:
    _steps = 0; _trace.clear(); _variables.clear(); _value_stack.clear(); _plan = plan; _context = context
    if plan.is_empty(): return _failure("Visual graph execution requires a compiled plan.")
    if not bool(plan.get("enabled", true)): return {"ok":true,"errors":[],"steps":0,"trace":[],"variables":{}}
    for value in plan.get("variables", []):
        var variable: Dictionary = value; _variables[str(variable.get("variable_id", ""))] = variable.get("default")
    var queue: Array[String] = []
    for entry in plan.get("entries", []): queue.append(str(entry))
    while not queue.is_empty():
        var node_id: String = queue.pop_front()
        if not _consume_step(): return _failure("Visual graph execution exceeded the step budget.")
        var node: Dictionary = plan.get("nodes", {}).get(node_id, {}); var type_key := str(node.get("type_key", "")); var next_ports: Array[String] = []
        match type_key:
            "event.start": next_ports = ["next"]
            "flow.branch":
                var condition: Dictionary = _input_value(node_id, "condition")
                if not condition.get("ok", false): return condition
                next_ports = ["true" if bool(condition.get("value", false)) else "false"]
            "flow.sequence": next_ports = ["then_0","then_1"]
            "variable.set":
                var set_value: Dictionary = _input_value(node_id, "value")
                if not set_value.get("ok", false): return set_value
                var variable_id := str(node.get("properties", {}).get("variable_id", ""))
                if not _variables.has(variable_id): return _failure("Set Variable references a missing variable.")
                _variables[variable_id] = set_value.get("value"); next_ports = ["next"]
            "entity.set_position":
                var entity_value: Dictionary = _input_value(node_id, "entity_id"); if not entity_value.get("ok", false): return entity_value
                var position_value: Dictionary = _input_value(node_id, "position"); if not position_value.get("ok", false): return position_value
                var set_result: Dictionary = _set_entity_position(str(entity_value.get("value", "")), position_value.get("value"))
                if not set_result.get("ok", false): return set_result
                next_ports = ["next"]
            "debug.print":
                var debug_value: Dictionary = _input_value(node_id, "value")
                if not debug_value.get("ok", false): return debug_value
                _trace.append(str(debug_value.get("value"))); next_ports = ["next"]
            "macro.call": return _failure("Macro execution requires the Phase 8 macro runtime.")
            _:
                if not _plan.get("definitions", {}).get(node_id, {}).get("exec_inputs", []).is_empty(): return _failure("Unsupported executable visual node: %s" % type_key)
        for port in next_ports: _append_exec_targets(queue, node_id, port)
    return {"ok":true,"errors":[],"steps":_steps,"trace":_trace.duplicate(),"variables":_variables.duplicate(true)}

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
        "variable.get":
            var variable_id := str(node.get("properties", {}).get("variable_id", ""))
            result = {"ok":true,"errors":[],"value":_variables[variable_id]} if _variables.has(variable_id) else _failure("Get Variable references a missing variable.")
        "variable.set":
            var variable_id := str(node.get("properties", {}).get("variable_id", ""))
            result = {"ok":true,"errors":[],"value":_variables[variable_id]} if _variables.has(variable_id) else _failure("Set Variable references a missing variable.")
        "entity.get_position":
            var entity_value: Dictionary = _input_value(node_id, "entity_id")
            result = entity_value if not entity_value.get("ok", false) else _get_entity_position(str(entity_value.get("value", "")))
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
    if callback.is_valid():
        var value: Variant = callback.call(entity_id); return {"ok":true,"errors":[],"value":value}
    var entities: Dictionary = _context.get("entities", {})
    if not entities.has(entity_id): return _failure("Get Position references a missing runtime entity.")
    return {"ok":true,"errors":[],"value":entities[entity_id]}

func _set_entity_position(entity_id: String, position_value: Variant) -> Dictionary:
    var callback: Callable = _context.get("set_entity_position", Callable())
    if callback.is_valid():
        var result: Variant = callback.call(entity_id, position_value)
        if result is Dictionary: return result
        return {"ok":bool(result),"errors":[] if bool(result) else ["Runtime entity position callback failed."]}
    var entities: Dictionary = _context.get("entities", {})
    if not entities.has(entity_id): return _failure("Set Position references a missing runtime entity.")
    entities[entity_id] = position_value; _context["entities"] = entities
    return {"ok":true,"errors":[]}

func _consume_step() -> bool:
    _steps += 1; return _steps <= step_budget

static func _is_number(value: Variant) -> bool: return value is int or value is float
static func _failure(message: String) -> Dictionary: return {"ok":false,"errors":[message]}
