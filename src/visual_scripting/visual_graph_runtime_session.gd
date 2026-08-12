class_name PlayWorldVisualGraphRuntimeSession
extends RefCounted

const Compiler = preload("res://src/visual_scripting/visual_graph_compiler.gd")
const Interpreter = preload("res://src/visual_scripting/visual_graph_interpreter.gd")

var step_budget_per_graph: int = 2048

func execute_start(graphs: Array[Dictionary], runtime_state) -> Dictionary:
    if runtime_state == null or not runtime_state.is_loaded(): return _failure("Visual graph Play runtime requires loaded disposable world state.")
    var compiled: Dictionary = Compiler.new().compile_registry(graphs)
    if not compiled.get("ok", false): return compiled
    var plans: Dictionary = compiled["plans"]; var graph_ids: Array[String] = []
    for graph_id in plans.keys(): graph_ids.append(str(graph_id))
    graph_ids.sort()
    var total_steps := 0; var trace: Array[String] = []; var executed := 0
    for graph_id in graph_ids:
        var plan: Dictionary = plans[graph_id]
        if str(plan.get("kind", "")) != "event" or not bool(plan.get("enabled", true)): continue
        var interpreter = Interpreter.new(); interpreter.step_budget = step_budget_per_graph
        var context := {"plans": plans, "get_entity_position": Callable(self, "_get_entity_position").bind(runtime_state), "set_entity_position": Callable(self, "_set_entity_position").bind(runtime_state)}
        var result: Dictionary = interpreter.execute(plan, context)
        if not result.get("ok", false): return {"ok": false, "errors": ["Visual graph %s failed during Play: %s" % [graph_id, str(result.get("errors", []))]], "graph_id": graph_id}
        total_steps += int(result.get("steps", 0)); executed += 1
        for value in result.get("trace", []): trace.append(str(value))
    return {"ok": true, "errors": [], "executed_graphs": executed, "steps": total_steps, "trace": trace}

func _get_entity_position(entity_id: String, runtime_state) -> Variant:
    var record: Dictionary = runtime_state.get_entity(entity_id)
    if record.is_empty(): return null
    return record.get("transform", {}).get("position", []).duplicate()

func _set_entity_position(entity_id: String, value: Variant, runtime_state) -> Dictionary:
    var position := Vector3.ZERO
    if value is Vector3: position = value
    elif value is Array and value.size() == 3: position = Vector3(float(value[0]), float(value[1]), float(value[2]))
    else: return _failure("Set Position requires a Vector3-compatible value.")
    return runtime_state.set_entity_position(entity_id, position)

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
