class_name PlayWorldRuntimeInteractionService
extends RefCounted

var _runtime
var _inventory
var _door_open_state: Dictionary = {}


func bind_runtime(runtime, inventory_service = null) -> Dictionary:
    clear()
    if runtime == null or not runtime.has_method("is_loaded") or not runtime.is_loaded():
        return _failure("Interaction runtime requires loaded gameplay state.")
    _runtime = runtime
    _inventory = inventory_service
    return {"ok": true, "errors": []}


func clear() -> void:
    _runtime = null
    _inventory = null
    _door_open_state.clear()


func get_prompt(target_entity_id: String) -> Dictionary:
    var values: Dictionary = _interactable_values(target_entity_id)
    if values.is_empty():
        return _failure("Target entity is not interactable.")
    if not bool(values.get("enabled", true)):
        return _failure("Target interaction is disabled.")
    return {
        "ok": true,
        "errors": [],
        "target_entity_id": target_entity_id,
        "prompt": str(values.get("prompt", "Interact")),
        "interaction_distance": float(values.get("interaction_distance", 2.5)),
    }


func interact(actor_entity_id: String, target_entity_id: String) -> Dictionary:
    if _runtime == null:
        return _failure("Interaction service is not bound.")
    if not _runtime.has_entity(actor_entity_id):
        return _failure("Interaction actor entity reference does not resolve.")
    if not _runtime.has_entity(target_entity_id):
        return _failure("Interaction target entity reference does not resolve.")
    var values: Dictionary = _interactable_values(target_entity_id)
    if values.is_empty():
        return _failure("Target entity is not interactable.")
    if not bool(values.get("enabled", true)):
        return _failure("Target interaction is disabled.")

    if _runtime.has_component(target_entity_id, "pickup"):
        if _inventory == null:
            return _failure("Pickup interaction requires an inventory service.")
        var pickup_result: Dictionary = _inventory.collect_pickup(actor_entity_id, target_entity_id)
        if not pickup_result.get("ok", false):
            return pickup_result
        _runtime.emit_event("interaction.performed", actor_entity_id, target_entity_id, {"route": "pickup"})
        pickup_result["route"] = "pickup"
        return pickup_result

    if _runtime.has_component(target_entity_id, "door"):
        var door_result: Dictionary = toggle_door(actor_entity_id, target_entity_id)
        if not door_result.get("ok", false):
            return door_result
        _runtime.emit_event("interaction.performed", actor_entity_id, target_entity_id, {"route": "door"})
        door_result["route"] = "door"
        return door_result

    var event_result: Dictionary = _runtime.emit_event("interaction.performed", actor_entity_id, target_entity_id, {"route": "generic"})
    if not event_result.get("ok", false):
        return event_result
    return {"ok": true, "errors": [], "route": "generic", "target_entity_id": target_entity_id}


func toggle_door(actor_entity_id: String, door_entity_id: String) -> Dictionary:
    if _runtime == null:
        return _failure("Interaction service is not bound.")
    if not _runtime.has_entity(actor_entity_id):
        return _failure("Door interaction actor entity reference does not resolve.")
    var door: Dictionary = _runtime.get_component_values(door_entity_id, "door")
    if door.is_empty():
        return _failure("Target entity is not a door.")
    if bool(door.get("locked", false)):
        _runtime.emit_event("door.blocked", actor_entity_id, door_entity_id, {"reason": "locked"})
        return _failure("Door is locked.")
    return set_door_open(door_entity_id, not is_door_open(door_entity_id), actor_entity_id)


func set_door_open(door_entity_id: String, open: bool, source_entity_id: String = "") -> Dictionary:
    if _runtime == null:
        return _failure("Interaction service is not bound.")
    var door: Dictionary = _runtime.get_component_values(door_entity_id, "door")
    if door.is_empty():
        return _failure("Target entity is not a door.")
    if not source_entity_id.is_empty() and not _runtime.has_entity(source_entity_id):
        return _failure("Door state source entity reference does not resolve.")
    var previous := is_door_open(door_entity_id)
    _door_open_state[door_entity_id] = open
    if previous != open:
        _runtime.emit_event("door.opened" if open else "door.closed", source_entity_id, door_entity_id, {
            "open": open,
            "open_angle": float(door.get("open_angle", 90.0)),
        })
    return {"ok": true, "errors": [], "door_entity_id": door_entity_id, "open": open, "changed": previous != open}


func is_door_open(door_entity_id: String) -> bool:
    if _door_open_state.has(door_entity_id):
        return bool(_door_open_state[door_entity_id])
    if _runtime == null:
        return false
    var door: Dictionary = _runtime.get_component_values(door_entity_id, "door")
    return bool(door.get("starts_open", false)) if not door.is_empty() else false


func get_runtime_snapshot() -> Dictionary:
    var doors: Dictionary = {}
    for entity_id in _door_open_state.keys():
        doors[str(entity_id)] = bool(_door_open_state[entity_id])
    return {"door_open_state": doors}


func _interactable_values(entity_id: String) -> Dictionary:
    if _runtime == null or not _runtime.has_entity(entity_id):
        return {}
    return _runtime.get_component_values(entity_id, "interactable")


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
