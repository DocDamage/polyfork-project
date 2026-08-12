class_name PlayWorldRuntimeVehicleService
extends RefCounted

var _gameplay
var _world_runtime
var _vehicles: Dictionary = {}
var _actor_vehicle: Dictionary = {}


func bind_runtime(gameplay_runtime, world_runtime) -> Dictionary:
    clear()
    if gameplay_runtime == null or not gameplay_runtime.has_method("is_loaded") or not gameplay_runtime.is_loaded():
        return _failure("Vehicle runtime requires loaded gameplay state.")
    if world_runtime == null or not world_runtime.has_method("is_loaded") or not world_runtime.is_loaded():
        return _failure("Vehicle runtime requires loaded world state.")
    _gameplay = gameplay_runtime
    _world_runtime = world_runtime
    return {"ok": true, "errors": []}


func clear() -> void:
    _gameplay = null
    _world_runtime = null
    _vehicles.clear()
    _actor_vehicle.clear()


func enter_vehicle(vehicle_entity_id: String, actor_entity_id: String, role: String = "passenger") -> Dictionary:
    var validation: Dictionary = _validate_vehicle(vehicle_entity_id)
    if not validation.get("ok", false):
        return validation
    if not _gameplay.has_entity(actor_entity_id):
        return _failure("Vehicle occupant entity reference does not resolve.")
    if vehicle_entity_id == actor_entity_id:
        return _failure("A vehicle cannot occupy itself.")
    if _actor_vehicle.has(actor_entity_id):
        return _failure("Actor already occupies a vehicle.")
    if not ["driver", "passenger"].has(role):
        return _failure("Vehicle seat role must be driver or passenger.")
    var state: Dictionary = _ensure_vehicle_state(vehicle_entity_id)
    var occupants: Dictionary = state.get("occupants", {}).duplicate(true)
    var seat_count := int(validation.get("seat_count", 1))
    if occupants.size() >= seat_count:
        return _failure("Vehicle has no available seats.")
    if role == "driver" and not str(state.get("driver_entity_id", "")).is_empty():
        return _failure("Vehicle already has a driver.")
    occupants[actor_entity_id] = role
    state["occupants"] = occupants
    if role == "driver":
        state["driver_entity_id"] = actor_entity_id
    _vehicles[vehicle_entity_id] = state
    _actor_vehicle[actor_entity_id] = vehicle_entity_id
    var event_result: Dictionary = _gameplay.emit_event("vehicle.entered", actor_entity_id, vehicle_entity_id, {"role": role})
    if not event_result.get("ok", false):
        return event_result
    return {"ok": true, "errors": [], "vehicle_entity_id": vehicle_entity_id, "actor_entity_id": actor_entity_id, "role": role}


func exit_vehicle(actor_entity_id: String) -> Dictionary:
    if not _actor_vehicle.has(actor_entity_id):
        return _failure("Actor does not occupy a vehicle.")
    var vehicle_entity_id := str(_actor_vehicle[actor_entity_id])
    var state: Dictionary = _vehicles.get(vehicle_entity_id, {}).duplicate(true)
    var occupants: Dictionary = state.get("occupants", {}).duplicate(true)
    var role := str(occupants.get(actor_entity_id, "passenger"))
    occupants.erase(actor_entity_id)
    state["occupants"] = occupants
    if str(state.get("driver_entity_id", "")) == actor_entity_id:
        state["driver_entity_id"] = ""
        state["throttle"] = 0.0
        state["steer"] = 0.0
        state["brake"] = 1.0
    _vehicles[vehicle_entity_id] = state
    _actor_vehicle.erase(actor_entity_id)
    var event_result: Dictionary = _gameplay.emit_event("vehicle.exited", actor_entity_id, vehicle_entity_id, {"role": role})
    if not event_result.get("ok", false):
        return event_result
    return {"ok": true, "errors": [], "vehicle_entity_id": vehicle_entity_id, "actor_entity_id": actor_entity_id, "role": role}


func set_controls(vehicle_entity_id: String, driver_entity_id: String, throttle: float, steer: float, brake: float) -> Dictionary:
    var validation: Dictionary = _validate_vehicle(vehicle_entity_id)
    if not validation.get("ok", false):
        return validation
    var state: Dictionary = _ensure_vehicle_state(vehicle_entity_id)
    if str(state.get("driver_entity_id", "")) != driver_entity_id:
        return _failure("Only the current driver may control the vehicle.")
    state["throttle"] = clampf(throttle, -1.0, 1.0)
    state["steer"] = clampf(steer, -1.0, 1.0)
    state["brake"] = clampf(brake, 0.0, 1.0)
    _vehicles[vehicle_entity_id] = state
    return {"ok": true, "errors": [], "controls": {"throttle": state["throttle"], "steer": state["steer"], "brake": state["brake"]}}


func advance(delta: float) -> Dictionary:
    if _gameplay == null or _world_runtime == null:
        return _failure("Vehicle service is not bound.")
    if delta < 0.0:
        return _failure("Vehicle delta cannot be negative.")
    var vehicle_ids: Array[String] = []
    for vehicle_id_value in _vehicles.keys():
        vehicle_ids.append(str(vehicle_id_value))
    vehicle_ids.sort()
    var moved := 0
    for vehicle_id in vehicle_ids:
        var result: Dictionary = _advance_vehicle(vehicle_id, delta)
        if result.get("moved", false):
            moved += 1
    return {"ok": true, "errors": [], "moved": moved}


func get_vehicle_state(vehicle_entity_id: String) -> Dictionary:
    var validation: Dictionary = _validate_vehicle(vehicle_entity_id)
    if not validation.get("ok", false):
        return validation
    return {"ok": true, "errors": [], "state": _ensure_vehicle_state(vehicle_entity_id).duplicate(true)}


func vehicle_for_actor(actor_entity_id: String) -> String:
    return str(_actor_vehicle.get(actor_entity_id, ""))


func get_runtime_snapshot() -> Dictionary:
    var vehicles: Dictionary = {}
    for vehicle_id in _vehicles.keys():
        vehicles[str(vehicle_id)] = _vehicles[vehicle_id].duplicate(true)
    var actor_vehicle: Dictionary = {}
    for actor_id in _actor_vehicle.keys():
        actor_vehicle[str(actor_id)] = str(_actor_vehicle[actor_id])
    return {"vehicles": vehicles, "actor_vehicle": actor_vehicle}


func restore_runtime_snapshot(snapshot: Dictionary) -> Dictionary:
    if _gameplay == null or _world_runtime == null:
        return _failure("Vehicle service is not bound.")
    var incoming = snapshot.get("vehicles", {})
    if not incoming is Dictionary:
        return _failure("Vehicle runtime snapshot vehicles must be a dictionary.")
    var restored_vehicles: Dictionary = {}
    var restored_actor_vehicle: Dictionary = {}
    for vehicle_id_value in incoming.keys():
        var vehicle_id := str(vehicle_id_value)
        var validation: Dictionary = _validate_vehicle(vehicle_id)
        if not validation.get("ok", false):
            return validation
        var value = incoming[vehicle_id_value]
        if not value is Dictionary:
            return _failure("Vehicle runtime snapshot vehicle state must be a dictionary.")
        var state: Dictionary = value
        var occupants = state.get("occupants", {})
        if not occupants is Dictionary:
            return _failure("Vehicle runtime snapshot occupants must be a dictionary.")
        if occupants.size() > int(validation.get("seat_count", 1)):
            return _failure("Vehicle runtime snapshot exceeds seat capacity.")
        for actor_id_value in occupants.keys():
            var actor_id := str(actor_id_value)
            if not _gameplay.has_entity(actor_id):
                return _failure("Vehicle runtime snapshot occupant entity does not resolve.")
            if restored_actor_vehicle.has(actor_id):
                return _failure("Vehicle runtime snapshot assigns an actor to multiple vehicles.")
            restored_actor_vehicle[actor_id] = vehicle_id
        var driver_id := str(state.get("driver_entity_id", ""))
        if not driver_id.is_empty() and str(occupants.get(driver_id, "")) != "driver":
            return _failure("Vehicle runtime snapshot driver does not occupy the driver role.")
        restored_vehicles[vehicle_id] = state.duplicate(true)
    _vehicles = restored_vehicles
    _actor_vehicle = restored_actor_vehicle
    return {"ok": true, "errors": [], "restored": restored_vehicles.size()}


func _advance_vehicle(vehicle_entity_id: String, delta: float) -> Dictionary:
    var validation: Dictionary = _validate_vehicle(vehicle_entity_id)
    if not validation.get("ok", false):
        return {"moved": false}
    var state: Dictionary = _ensure_vehicle_state(vehicle_entity_id)
    var max_speed := float(validation.get("max_speed", 22.0))
    var throttle := float(state.get("throttle", 0.0))
    var brake := float(state.get("brake", 0.0))
    var speed := float(state.get("speed", 0.0))
    var target_speed := throttle * max_speed
    var acceleration := 8.0
    speed = move_toward(speed, target_speed, acceleration * delta)
    if brake > 0.0:
        speed = move_toward(speed, 0.0, 18.0 * brake * delta)
    var heading := float(state.get("heading", 0.0))
    var steer := float(state.get("steer", 0.0))
    if absf(speed) > 0.01:
        heading += steer * 1.5 * delta * signf(speed)
    state["speed"] = clampf(speed, -max_speed, max_speed)
    state["heading"] = heading
    _vehicles[vehicle_entity_id] = state
    if absf(speed) <= 0.0001:
        return {"moved": false}
    var record: Dictionary = _world_runtime.get_entity(vehicle_entity_id)
    if record.is_empty():
        return {"moved": false}
    var current := _position(record)
    var forward := Vector3(sin(heading), 0.0, -cos(heading))
    var next := current + forward * speed * delta
    var move_result: Dictionary = _world_runtime.set_entity_position(vehicle_entity_id, next)
    if not move_result.get("ok", false):
        return {"moved": false}
    _gameplay.emit_event("vehicle.moved", str(state.get("driver_entity_id", "")), vehicle_entity_id, {"position": [next.x, next.y, next.z], "speed": speed, "heading": heading})
    return {"moved": true}


func _ensure_vehicle_state(vehicle_entity_id: String) -> Dictionary:
    if not _vehicles.has(vehicle_entity_id):
        _vehicles[vehicle_entity_id] = {
            "occupants": {},
            "driver_entity_id": "",
            "throttle": 0.0,
            "steer": 0.0,
            "brake": 0.0,
            "speed": 0.0,
            "heading": 0.0,
        }
    return _vehicles[vehicle_entity_id]


func _validate_vehicle(vehicle_entity_id: String) -> Dictionary:
    if _gameplay == null or _world_runtime == null:
        return _failure("Vehicle service is not bound.")
    if not _gameplay.has_entity(vehicle_entity_id):
        return _failure("Vehicle entity reference does not resolve.")
    var values: Dictionary = _gameplay.get_component_values(vehicle_entity_id, "vehicle_body")
    if values.is_empty():
        return _failure("Entity does not have a Vehicle Body component.")
    return {"ok": true, "errors": [], "seat_count": int(values.get("seat_count", 1)), "max_speed": float(values.get("max_speed", 22.0))}


static func _position(record: Dictionary) -> Vector3:
    var value = record.get("transform", {}).get("position", [])
    if value is Array and value.size() == 3:
        return Vector3(float(value[0]), float(value[1]), float(value[2]))
    return Vector3.ZERO


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
