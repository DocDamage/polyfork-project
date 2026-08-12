class_name PlayWorldRuntimeInventoryService
extends RefCounted

var _runtime
var _inventories: Dictionary = {}
var _consumed_pickups: Dictionary = {}


func bind_runtime(runtime) -> Dictionary:
    clear()
    if runtime == null or not runtime.has_method("is_loaded") or not runtime.is_loaded():
        return _failure("Inventory runtime requires loaded gameplay state.")
    _runtime = runtime
    return {"ok": true, "errors": []}


func clear() -> void:
    _runtime = null
    _inventories.clear()
    _consumed_pickups.clear()


func get_inventory(container_entity_id: String) -> Dictionary:
    var ensure := _ensure_container(container_entity_id)
    if not ensure.get("ok", false):
        return ensure
    return {
        "ok": true,
        "errors": [],
        "container_entity_id": container_entity_id,
        "capacity": int(ensure.get("capacity", 0)),
        "slots": _copy_slots(_inventories.get(container_entity_id, [])),
    }


func add_item(container_entity_id: String, item_entity_id: String, quantity: int) -> Dictionary:
    if quantity <= 0:
        return _failure("Inventory add quantity must be positive.")
    var ensure := _ensure_container(container_entity_id)
    if not ensure.get("ok", false):
        return ensure
    if not _runtime.has_entity(item_entity_id):
        return _failure("Inventory item entity reference does not resolve.")
    if bool(ensure.get("locked", false)):
        return _failure("Inventory container is locked.")
    var slots: Array = _inventories.get(container_entity_id, []).duplicate(true)
    for index in range(slots.size()):
        var slot: Dictionary = slots[index]
        if str(slot.get("item_entity_id", "")) == item_entity_id:
            slot["quantity"] = int(slot.get("quantity", 0)) + quantity
            slots[index] = slot
            _inventories[container_entity_id] = slots
            _runtime.emit_event("inventory.changed", container_entity_id, item_entity_id, {"delta": quantity, "quantity": slot["quantity"]})
            return {"ok": true, "errors": [], "merged": true, "slots": _copy_slots(slots)}
    if slots.size() >= int(ensure.get("capacity", 0)):
        return _failure("Inventory container is at capacity.")
    slots.append({"item_entity_id": item_entity_id, "quantity": quantity})
    _inventories[container_entity_id] = slots
    _runtime.emit_event("inventory.changed", container_entity_id, item_entity_id, {"delta": quantity, "quantity": quantity})
    return {"ok": true, "errors": [], "merged": false, "slots": _copy_slots(slots)}


func remove_item(container_entity_id: String, item_entity_id: String, quantity: int) -> Dictionary:
    if quantity <= 0:
        return _failure("Inventory remove quantity must be positive.")
    var ensure := _ensure_container(container_entity_id)
    if not ensure.get("ok", false):
        return ensure
    if bool(ensure.get("locked", false)):
        return _failure("Inventory container is locked.")
    var slots: Array = _inventories.get(container_entity_id, []).duplicate(true)
    for index in range(slots.size()):
        var slot: Dictionary = slots[index]
        if str(slot.get("item_entity_id", "")) != item_entity_id:
            continue
        var current := int(slot.get("quantity", 0))
        if current < quantity:
            return _failure("Inventory item quantity is insufficient.")
        var remaining := current - quantity
        if remaining <= 0:
            slots.remove_at(index)
        else:
            slot["quantity"] = remaining
            slots[index] = slot
        _inventories[container_entity_id] = slots
        _runtime.emit_event("inventory.changed", container_entity_id, item_entity_id, {"delta": -quantity, "quantity": remaining})
        return {"ok": true, "errors": [], "remaining": remaining, "slots": _copy_slots(slots)}
    return _failure("Inventory item does not exist in the container.")


func transfer_item(from_container_id: String, to_container_id: String, item_entity_id: String, quantity: int) -> Dictionary:
    if from_container_id == to_container_id:
        return _failure("Inventory transfer requires different containers.")
    var from_before := get_inventory(from_container_id)
    if not from_before.get("ok", false):
        return from_before
    var to_before := get_inventory(to_container_id)
    if not to_before.get("ok", false):
        return to_before
    var remove_result := remove_item(from_container_id, item_entity_id, quantity)
    if not remove_result.get("ok", false):
        return remove_result
    var add_result := add_item(to_container_id, item_entity_id, quantity)
    if add_result.get("ok", false):
        _runtime.emit_event("inventory.transferred", from_container_id, to_container_id, {"item_entity_id": item_entity_id, "quantity": quantity})
        return {"ok": true, "errors": [], "from": remove_result, "to": add_result}
    _inventories[from_container_id] = from_before.get("slots", []).duplicate(true)
    _inventories[to_container_id] = to_before.get("slots", []).duplicate(true)
    return add_result


func collect_pickup(container_entity_id: String, pickup_entity_id: String) -> Dictionary:
    if _consumed_pickups.has(pickup_entity_id):
        return _failure("Pickup has already been consumed in this Play session.")
    var pickup := _runtime.get_component_values(pickup_entity_id, "pickup")
    if pickup.is_empty():
        return _failure("Target entity is not a pickup.")
    var quantity := int(pickup.get("quantity", 1))
    var add_result := add_item(container_entity_id, pickup_entity_id, quantity)
    if not add_result.get("ok", false):
        return add_result
    _consumed_pickups[pickup_entity_id] = true
    _runtime.emit_event("pickup.collected", container_entity_id, pickup_entity_id, {"quantity": quantity})
    return {"ok": true, "errors": [], "pickup_entity_id": pickup_entity_id, "quantity": quantity}


func is_pickup_consumed(pickup_entity_id: String) -> bool:
    return _consumed_pickups.has(pickup_entity_id)


func get_runtime_snapshot() -> Dictionary:
    var inventories: Dictionary = {}
    for entity_id in _inventories.keys():
        inventories[str(entity_id)] = _copy_slots(_inventories[entity_id])
    var consumed: Array[String] = []
    for entity_id in _consumed_pickups.keys():
        consumed.append(str(entity_id))
    consumed.sort()
    return {"inventories": inventories, "consumed_pickup_ids": consumed}


func _ensure_container(entity_id: String) -> Dictionary:
    if _runtime == null:
        return _failure("Inventory service is not bound.")
    if not _runtime.has_entity(entity_id):
        return _failure("Inventory container entity reference does not resolve.")
    var values := _runtime.get_component_values(entity_id, "inventory_container")
    if values.is_empty():
        return _failure("Entity does not have an Inventory Container component.")
    if not _inventories.has(entity_id):
        _inventories[entity_id] = []
    return {"ok": true, "errors": [], "capacity": int(values.get("capacity", 16)), "locked": bool(values.get("locked", false))}


static func _copy_slots(slots: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for slot in slots:
        if slot is Dictionary:
            result.append(slot.duplicate(true))
    return result


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
