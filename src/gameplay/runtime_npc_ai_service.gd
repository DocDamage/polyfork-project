class_name PlayWorldRuntimeNpcAiService
extends RefCounted

var _gameplay
var _world_runtime
var _interaction
var _goals: Dictionary = {}


func bind_runtime(gameplay_runtime, world_runtime, interaction_service = null) -> Dictionary:
    clear()
    if gameplay_runtime == null or not gameplay_runtime.has_method("is_loaded") or not gameplay_runtime.is_loaded():
        return _failure("NPC AI requires loaded gameplay runtime state.")
    if world_runtime == null or not world_runtime.has_method("is_loaded") or not world_runtime.is_loaded():
        return _failure("NPC AI requires loaded world runtime state.")
    _gameplay = gameplay_runtime
    _world_runtime = world_runtime
    _interaction = interaction_service
    return {"ok": true, "errors": []}


func clear() -> void:
    _gameplay = null
    _world_runtime = null
    _interaction = null
    _goals.clear()


func set_destination(npc_entity_id: String, destination: Vector3, arrival_distance: float = 0.25) -> Dictionary:
    var valid: Dictionary = _validate_npc(npc_entity_id)
    if not valid.get("ok", false): return valid
    if arrival_distance < 0.0: return _failure("NPC arrival distance cannot be negative.")
    _goals[npc_entity_id] = {
        "kind": "destination",
        "destination": _vector_to_array(destination),
        "arrival_distance": arrival_distance,
    }
    _gameplay.emit_event("npc.goal_changed", npc_entity_id, "", {"kind": "destination", "destination": _vector_to_array(destination)})
    return {"ok": true, "errors": [], "npc_entity_id": npc_entity_id}


func follow_entity(npc_entity_id: String, target_entity_id: String, arrival_distance: float = 1.25, interact_on_arrival: bool = false) -> Dictionary:
    var valid: Dictionary = _validate_npc(npc_entity_id)
    if not valid.get("ok", false): return valid
    if not _gameplay.has_entity(target_entity_id): return _failure("NPC follow target entity reference does not resolve.")
    if npc_entity_id == target_entity_id: return _failure("NPC cannot follow itself.")
    if arrival_distance < 0.0: return _failure("NPC arrival distance cannot be negative.")
    _goals[npc_entity_id] = {
        "kind": "follow_entity",
        "target_entity_id": target_entity_id,
        "arrival_distance": arrival_distance,
        "interact_on_arrival": interact_on_arrival,
    }
    _gameplay.emit_event("npc.goal_changed", npc_entity_id, target_entity_id, {"kind": "follow_entity"})
    return {"ok": true, "errors": [], "npc_entity_id": npc_entity_id, "target_entity_id": target_entity_id}


func wait(npc_entity_id: String, duration_seconds: float) -> Dictionary:
    var valid: Dictionary = _validate_npc(npc_entity_id)
    if not valid.get("ok", false): return valid
    if duration_seconds < 0.0: return _failure("NPC wait duration cannot be negative.")
    _goals[npc_entity_id] = {"kind": "wait", "remaining": duration_seconds}
    _gameplay.emit_event("npc.goal_changed", npc_entity_id, "", {"kind": "wait", "duration": duration_seconds})
    return {"ok": true, "errors": [], "npc_entity_id": npc_entity_id}


func idle(npc_entity_id: String) -> Dictionary:
    var valid: Dictionary = _validate_npc(npc_entity_id)
    if not valid.get("ok", false): return valid
    _goals.erase(npc_entity_id)
    _gameplay.emit_event("npc.idle", npc_entity_id, "", {})
    return {"ok": true, "errors": [], "npc_entity_id": npc_entity_id}


func get_goal(npc_entity_id: String) -> Dictionary:
    return _goals.get(npc_entity_id, {}).duplicate(true)


func advance(delta: float) -> Dictionary:
    if _gameplay == null or _world_runtime == null: return _failure("NPC AI service is not bound.")
    if delta < 0.0: return _failure("NPC AI delta cannot be negative.")
    var ids: Array[String] = []
    for entity_id in _goals.keys(): ids.append(str(entity_id))
    ids.sort()
    var advanced := 0
    var completed := 0
    var failed := 0
    for npc_entity_id in ids:
        var result: Dictionary = _advance_npc(npc_entity_id, delta)
        if result.get("advanced", false): advanced += 1
        if result.get("completed", false): completed += 1
        if result.get("failed", false): failed += 1
    return {"ok": true, "errors": [], "advanced": advanced, "completed": completed, "failed": failed}


func get_runtime_snapshot() -> Dictionary:
    var goals: Dictionary = {}
    for entity_id in _goals.keys(): goals[str(entity_id)] = _goals[entity_id].duplicate(true)
    return {"goals": goals}


func _advance_npc(npc_entity_id: String, delta: float) -> Dictionary:
    var goal: Dictionary = _goals.get(npc_entity_id, {}).duplicate(true)
    if goal.is_empty(): return {"advanced": false, "completed": false, "failed": false}
    if str(goal.get("kind", "")) == "wait":
        var remaining := maxf(0.0, float(goal.get("remaining", 0.0)) - delta)
        if remaining <= 0.0:
            _goals.erase(npc_entity_id)
            _gameplay.emit_event("npc.goal_reached", npc_entity_id, "", {"kind": "wait"})
            return {"advanced": true, "completed": true, "failed": false}
        goal["remaining"] = remaining
        _goals[npc_entity_id] = goal
        return {"advanced": true, "completed": false, "failed": false}

    var destination_result: Dictionary = _resolve_destination(goal)
    if not destination_result.get("ok", false):
        _goals.erase(npc_entity_id)
        _gameplay.emit_event("npc.goal_failed", npc_entity_id, str(goal.get("target_entity_id", "")), {"reason": str(destination_result.get("errors", []))})
        return {"advanced": false, "completed": false, "failed": true}
    var entity: Dictionary = _world_runtime.get_entity(npc_entity_id)
    if entity.is_empty():
        _goals.erase(npc_entity_id)
        return {"advanced": false, "completed": false, "failed": true}
    var current := _array_to_vector(entity.get("transform", {}).get("position", []))
    var destination: Vector3 = destination_result.get("destination", current)
    var arrival_distance := float(goal.get("arrival_distance", 0.25))
    var offset := destination - current
    var distance := offset.length()
    if distance <= arrival_distance:
        return _finish_goal(npc_entity_id, goal)

    var controller: Dictionary = _gameplay.get_component_values(npc_entity_id, "character_controller")
    var speed := maxf(0.0, float(controller.get("move_speed", 0.0)))
    if speed <= 0.0: return {"advanced": false, "completed": false, "failed": false}
    var step := minf(distance, speed * delta)
    var next := current + offset.normalized() * step
    var set_result: Dictionary = _world_runtime.set_entity_position(npc_entity_id, next)
    if not set_result.get("ok", false):
        _goals.erase(npc_entity_id)
        _gameplay.emit_event("npc.goal_failed", npc_entity_id, str(goal.get("target_entity_id", "")), {"reason": str(set_result.get("errors", []))})
        return {"advanced": false, "completed": false, "failed": true}
    _gameplay.emit_event("npc.moved", npc_entity_id, str(goal.get("target_entity_id", "")), {"position": _vector_to_array(next)})
    if step >= distance or next.distance_to(destination) <= arrival_distance:
        return _finish_goal(npc_entity_id, goal)
    return {"advanced": true, "completed": false, "failed": false}


func _finish_goal(npc_entity_id: String, goal: Dictionary) -> Dictionary:
    _goals.erase(npc_entity_id)
    var target_id := str(goal.get("target_entity_id", ""))
    _gameplay.emit_event("npc.goal_reached", npc_entity_id, target_id, {"kind": str(goal.get("kind", ""))})
    if bool(goal.get("interact_on_arrival", false)) and not target_id.is_empty() and _interaction != null:
        var interaction_result: Dictionary = _interaction.interact(npc_entity_id, target_id)
        if not interaction_result.get("ok", false):
            _gameplay.emit_event("npc.interaction_failed", npc_entity_id, target_id, {"errors": interaction_result.get("errors", []).duplicate()})
    return {"advanced": true, "completed": true, "failed": false}


func _resolve_destination(goal: Dictionary) -> Dictionary:
    if str(goal.get("kind", "")) == "destination":
        return {"ok": true, "errors": [], "destination": _array_to_vector(goal.get("destination", []))}
    if str(goal.get("kind", "")) == "follow_entity":
        var target_id := str(goal.get("target_entity_id", ""))
        if not _gameplay.has_entity(target_id): return _failure("NPC follow target no longer exists.")
        var target: Dictionary = _world_runtime.get_entity(target_id)
        if target.is_empty(): return _failure("NPC follow target runtime entity no longer exists.")
        return {"ok": true, "errors": [], "destination": _array_to_vector(target.get("transform", {}).get("position", []))}
    return _failure("NPC goal kind is unsupported.")


func _validate_npc(entity_id: String) -> Dictionary:
    if _gameplay == null or _world_runtime == null: return _failure("NPC AI service is not bound.")
    if not _gameplay.has_entity(entity_id): return _failure("NPC entity reference does not resolve.")
    var brain: Dictionary = _gameplay.get_component_values(entity_id, "npc_brain")
    if brain.is_empty() or not bool(brain.get("enabled", true)): return _failure("Entity does not have an enabled NPC Brain component.")
    if not _gameplay.has_component(entity_id, "character_controller"): return _failure("NPC requires a Character Controller component.")
    return {"ok": true, "errors": []}


static func _array_to_vector(value: Variant) -> Vector3:
    if value is Array and value.size() == 3: return Vector3(float(value[0]), float(value[1]), float(value[2]))
    return Vector3.ZERO

static func _vector_to_array(value: Vector3) -> Array[float]:
    return [value.x, value.y, value.z]

static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
