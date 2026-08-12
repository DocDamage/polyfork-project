class_name PlayWorldRuntimeHealthService
extends RefCounted

var _runtime
var _dead_entities: Dictionary = {}


func bind_runtime(runtime) -> Dictionary:
    clear()
    if runtime == null or not runtime.has_method("is_loaded") or not runtime.is_loaded():
        return _failure("Health runtime requires loaded gameplay state.")
    _runtime = runtime
    return {"ok": true, "errors": []}


func clear() -> void:
    _runtime = null
    _dead_entities.clear()


func apply_damage(target_entity_id: String, amount: float, source_entity_id: String = "") -> Dictionary:
    if amount <= 0.0:
        return _failure("Damage amount must be positive.")
    var health: Dictionary = _health_values(target_entity_id)
    if health.is_empty():
        return _failure("Damage target does not have a Health component.")
    if not source_entity_id.is_empty() and not _runtime.has_entity(source_entity_id):
        return _failure("Damage source entity reference does not resolve.")

    var damageable: Dictionary = _runtime.get_component_values(target_entity_id, "damageable")
    if not damageable.is_empty() and bool(damageable.get("invulnerable", false)):
        _runtime.emit_event("health.damage_blocked", source_entity_id, target_entity_id, {"amount": amount, "reason": "invulnerable"})
        return {"ok": true, "errors": [], "applied": 0.0, "current_health": float(health.get("current_health", 0.0)), "blocked": true}

    var armor := float(damageable.get("armor", 0.0)) if not damageable.is_empty() else 0.0
    var applied := maxf(0.0, amount - armor)
    var current := float(health.get("current_health", 0.0))
    var next := maxf(0.0, current - applied)
    var set_result: Dictionary = _runtime.set_component_value(target_entity_id, "health", "current_health", next)
    if not set_result.get("ok", false):
        return set_result
    _runtime.emit_event("health.damaged", source_entity_id, target_entity_id, {"requested": amount, "applied": applied, "previous": current, "current": next})
    var died := next <= 0.0 and current > 0.0
    if died:
        _dead_entities[target_entity_id] = true
        _runtime.emit_event("entity.died", source_entity_id, target_entity_id, {})
    return {"ok": true, "errors": [], "applied": applied, "current_health": next, "died": died, "blocked": false}


func heal(target_entity_id: String, amount: float, source_entity_id: String = "") -> Dictionary:
    if amount <= 0.0:
        return _failure("Heal amount must be positive.")
    var health: Dictionary = _health_values(target_entity_id)
    if health.is_empty():
        return _failure("Heal target does not have a Health component.")
    if not source_entity_id.is_empty() and not _runtime.has_entity(source_entity_id):
        return _failure("Heal source entity reference does not resolve.")
    var maximum := float(health.get("max_health", 1.0))
    var current := float(health.get("current_health", 0.0))
    var next := minf(maximum, current + amount)
    var applied := next - current
    var set_result: Dictionary = _runtime.set_component_value(target_entity_id, "health", "current_health", next)
    if not set_result.get("ok", false):
        return set_result
    if next > 0.0:
        _dead_entities.erase(target_entity_id)
    _runtime.emit_event("health.healed", source_entity_id, target_entity_id, {"requested": amount, "applied": applied, "previous": current, "current": next})
    return {"ok": true, "errors": [], "applied": applied, "current_health": next}


func set_health(target_entity_id: String, value: float, source_entity_id: String = "") -> Dictionary:
    var health: Dictionary = _health_values(target_entity_id)
    if health.is_empty():
        return _failure("Health target does not have a Health component.")
    var maximum := float(health.get("max_health", 1.0))
    var next := clampf(value, 0.0, maximum)
    var result: Dictionary = _runtime.set_component_value(target_entity_id, "health", "current_health", next)
    if not result.get("ok", false):
        return result
    if next <= 0.0:
        _dead_entities[target_entity_id] = true
    else:
        _dead_entities.erase(target_entity_id)
    _runtime.emit_event("health.set", source_entity_id, target_entity_id, {"current": next})
    return {"ok": true, "errors": [], "current_health": next}


func is_dead(entity_id: String) -> bool:
    if _dead_entities.has(entity_id):
        return true
    var health: Dictionary = _health_values(entity_id)
    return not health.is_empty() and float(health.get("current_health", 0.0)) <= 0.0


func get_health(entity_id: String) -> Dictionary:
    var health: Dictionary = _health_values(entity_id)
    if health.is_empty():
        return _failure("Entity does not have a Health component.")
    return {"ok": true, "errors": [], "entity_id": entity_id, "values": health, "dead": is_dead(entity_id)}


func get_runtime_snapshot() -> Dictionary:
    var dead_ids: Array[String] = []
    for entity_id in _dead_entities.keys():
        dead_ids.append(str(entity_id))
    dead_ids.sort()
    return {"dead_entity_ids": dead_ids}


func _health_values(entity_id: String) -> Dictionary:
    if _runtime == null or not _runtime.has_entity(entity_id):
        return {}
    return _runtime.get_component_values(entity_id, "health")


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
