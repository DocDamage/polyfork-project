class_name PlayWorldVisualGraphDebugger
extends RefCounted

signal state_changed(state: Dictionary)

const Compiler = preload("res://src/visual_scripting/visual_graph_compiler.gd")
const Interpreter = preload("res://src/visual_scripting/visual_graph_interpreter.gd")

var _compiler = Compiler.new()
var _interpreter = Interpreter.new()
var _breakpoints: Dictionary = {}
var _plans: Dictionary = {}
var _current_graph_id: String = ""
var _state: Dictionary = {"status": "idle", "errors": [], "trace": [], "node_id": ""}

func set_breakpoint(graph_id: String, node_id: String, enabled: bool) -> void:
    var graph_points: Dictionary = _breakpoints.get(graph_id, {})
    if enabled: graph_points[node_id] = true
    else: graph_points.erase(node_id)
    _breakpoints[graph_id] = graph_points

func has_breakpoint(graph_id: String, node_id: String) -> bool: return _breakpoints.get(graph_id, {}).has(node_id)

func validate_graphs(graphs: Array[Dictionary]) -> Dictionary:
    var result: Dictionary = _compiler.compile_registry(graphs)
    if result.get("ok", false): return {"ok": true, "errors": [], "graph_count": result.get("plans", {}).size()}
    return result

func run_graph(graph_id: String, graphs: Array[Dictionary], context: Dictionary = {}) -> Dictionary:
    var compiled: Dictionary = _compiler.compile_registry(graphs)
    if not compiled.get("ok", false): return _set_error(compiled.get("errors", []))
    _plans = compiled["plans"]; _current_graph_id = graph_id
    var plan: Dictionary = _plans.get(graph_id, {})
    if plan.is_empty(): return _set_error(["Debug graph does not exist: %s" % graph_id])
    var runtime_context: Dictionary = context.duplicate(false); runtime_context["plans"] = _plans
    var points: Array[String] = []
    for node_id in _breakpoints.get(graph_id, {}).keys(): points.append(str(node_id))
    runtime_context["breakpoints"] = points
    var begin_result: Dictionary = _interpreter.begin(plan, runtime_context)
    if not begin_result.get("ok", false): return _set_error(begin_result.get("errors", []))
    return _consume_debug_result(_interpreter.continue_execution())

func resume() -> Dictionary:
    if _state.get("status") != "paused": return _set_error(["Debugger is not paused."])
    return _consume_debug_result(_interpreter.continue_execution(_interpreter.get_paused_node_id()))

func get_state() -> Dictionary: return _state.duplicate(true)
func get_current_graph_id() -> String: return _current_graph_id

func _consume_debug_result(result: Dictionary) -> Dictionary:
    if not result.get("ok", false): return _set_error(result.get("errors", []))
    _state = {"status": str(result.get("status", "completed")), "errors": [], "trace": result.get("trace", []).duplicate(), "node_id": str(result.get("node_id", "")), "steps": int(result.get("steps", 0))}
    state_changed.emit(get_state()); return {"ok": true, "errors": [], "state": get_state()}

func _set_error(errors_value: Array) -> Dictionary:
    var errors: Array[String] = []
    for value in errors_value: errors.append(str(value))
    _state = {"status": "error", "errors": errors, "trace": _interpreter.get_trace(), "node_id": _interpreter.get_paused_node_id(), "steps": 0}
    state_changed.emit(get_state()); return {"ok": false, "errors": errors, "state": get_state()}
