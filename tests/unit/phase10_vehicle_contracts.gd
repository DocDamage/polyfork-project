extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const WorldRuntime = preload("res://src/runtime/play_runtime_state.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const RuntimeGameplay = preload("res://src/gameplay/runtime_gameplay_state.gd")
const Vehicle = preload("res://src/gameplay/runtime_vehicle_service.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new()
    project.initialize_new("Phase 10 Vehicle", &"small", "blank_sandbox")
    var cell_id: String = StableId.generate()
    var cell_ids: Array[String] = [cell_id]
    project.cell_ids = cell_ids

    var vehicle = WorldEntity.new()
    vehicle.initialize_new("Vehicle", cell_id)
    vehicle.transform["position"] = [0.0, 0.0, 0.0]
    var driver = WorldEntity.new()
    driver.initialize_new("Driver", cell_id)
    var passenger = WorldEntity.new()
    passenger.initialize_new("Passenger", cell_id)
    var extra = WorldEntity.new()
    extra.initialize_new("Extra", cell_id)
    var instances: Array[Dictionary] = []
    _attach(vehicle, instances, "vehicle_body", {"max_speed": 10.0, "seat_count": 2})
    var entity_records: Array[Dictionary] = [vehicle.to_dictionary(), driver.to_dictionary(), passenger.to_dictionary(), extra.to_dictionary()]
    project.entity_records = entity_records
    var authored: Dictionary = project.to_dictionary()

    var gameplay = RuntimeGameplay.new()
    var snapshot: Dictionary = {
        "definitions": Components.definitions(),
        "instances": instances,
        "sockets": [],
        "attachments": [],
        "dialogues": [],
        "quests": [],
    }
    var gameplay_result: Dictionary = gameplay.initialize(authored, snapshot)
    if not gameplay_result.get("ok", false):
        return ["Phase 10 vehicle gameplay fixture failed: %s" % str(gameplay_result.get("errors", []))]
    var world = WorldRuntime.new()
    var world_result: Dictionary = world.load_authored_project(authored)
    if not world_result.get("ok", false):
        return ["Phase 10 vehicle world fixture failed."]
    var service = Vehicle.new()
    var bind_result: Dictionary = service.bind_runtime(gameplay, world)
    if not bind_result.get("ok", false):
        return ["Vehicle service must bind to disposable gameplay and world runtime state."]

    var enter_driver: Dictionary = service.enter_vehicle(vehicle.entity_id, driver.entity_id, "driver")
    var enter_passenger: Dictionary = service.enter_vehicle(vehicle.entity_id, passenger.entity_id, "passenger")
    if not enter_driver.get("ok", false) or not enter_passenger.get("ok", false):
        errors.append("Vehicle occupancy must support one driver and reusable passenger seats.")
    if service.enter_vehicle(vehicle.entity_id, extra.entity_id, "passenger").get("ok", false):
        errors.append("Vehicle occupancy must enforce authored seat_count capacity.")
    if service.set_controls(vehicle.entity_id, passenger.entity_id, 1.0, 0.0, 0.0).get("ok", false):
        errors.append("Only the stable-ID driver may control a vehicle.")
    var controls: Dictionary = service.set_controls(vehicle.entity_id, driver.entity_id, 2.0, -2.0, -1.0)
    if not controls.get("ok", false):
        errors.append("The current driver must be able to set semantic vehicle controls.")
    else:
        var values: Dictionary = controls.get("controls", {})
        if float(values.get("throttle", 0.0)) != 1.0 or float(values.get("steer", 0.0)) != -1.0 or float(values.get("brake", -1.0)) != 0.0:
            errors.append("Vehicle controls must clamp to reusable semantic ranges.")

    var advance: Dictionary = service.advance(0.5)
    var runtime_position: Vector3 = _position(world.get_entity(vehicle.entity_id))
    if not advance.get("ok", false) or int(advance.get("moved", 0)) != 1 or runtime_position == Vector3.ZERO:
        errors.append("Driven vehicles must advance the disposable runtime transform.")
    if _position_from_project(authored, vehicle.entity_id) != Vector3.ZERO:
        errors.append("Vehicle movement must never mutate authored Build transforms.")
    var vehicle_state: Dictionary = service.get_vehicle_state(vehicle.entity_id).get("state", {})
    if absf(float(vehicle_state.get("speed", 0.0))) > 10.0:
        errors.append("Vehicle runtime speed must remain within authored max_speed.")

    var exit_driver: Dictionary = service.exit_vehicle(driver.entity_id)
    if not exit_driver.get("ok", false) or not service.vehicle_for_actor(driver.entity_id).is_empty():
        errors.append("Vehicle occupants must exit cleanly and release stable occupancy references.")
    if service.set_controls(vehicle.entity_id, driver.entity_id, 1.0, 0.0, 0.0).get("ok", false):
        errors.append("An actor that exited must no longer control the vehicle.")

    var kinds: Dictionary = {}
    for event in gameplay.events_after(0):
        kinds[str(event.get("kind", ""))] = true
    for expected in ["vehicle.entered", "vehicle.moved", "vehicle.exited"]:
        if not kinds.has(expected):
            errors.append("Vehicle runtime event bus is missing event: %s" % expected)
    return errors


static func _attach(entity, instances: Array[Dictionary], component_key: String, patch: Dictionary) -> void:
    var definition: Dictionary = _definition(component_key)
    var values: Dictionary = Contracts.defaults_for(definition)
    for key in patch.keys():
        values[key] = patch[key]
    var record: Dictionary = {
        "document_type": Contracts.COMPONENT_INSTANCE,
        "schema_version": Contracts.SCHEMA_VERSION,
        "instance_id": StableId.generate(),
        "definition_id": str(definition.get("definition_id", "")),
        "owner_entity_id": entity.entity_id,
        "values": values,
    }
    instances.append(record)
    entity.component_instance_ids.append(str(record["instance_id"]))


static func _definition(key: String) -> Dictionary:
    for definition in Components.definitions():
        if str(definition.get("key", "")) == key:
            return definition.duplicate(true)
    return {}


static func _position(record: Dictionary) -> Vector3:
    var value: Variant = record.get("transform", {}).get("position", [])
    if value is Array and value.size() == 3:
        return Vector3(float(value[0]), float(value[1]), float(value[2]))
    return Vector3.ZERO


static func _position_from_project(project_data: Dictionary, entity_id: String) -> Vector3:
    for record in project_data.get("entities", []):
        if record is Dictionary and str(record.get("entity_id", "")) == entity_id:
            return _position(record)
    return Vector3.ZERO
