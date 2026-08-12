extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const RuntimeGameplay = preload("res://src/gameplay/runtime_gameplay_state.gd")
const Inventory = preload("res://src/gameplay/runtime_inventory_service.gd")
const Interaction = preload("res://src/gameplay/runtime_interaction_service.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new()
    project.initialize_new("Phase 10 Inventory", &"small", "blank_sandbox")
    var cell_id := StableId.generate()
    var cells: Array[String] = [cell_id]
    project.cell_ids = cells

    var actor = WorldEntity.new(); actor.initialize_new("Actor", cell_id)
    var stash = WorldEntity.new(); stash.initialize_new("Stash", cell_id)
    var pickup = WorldEntity.new(); pickup.initialize_new("Pickup", cell_id)
    var door = WorldEntity.new(); door.initialize_new("Door", cell_id)
    var locked_door = WorldEntity.new(); locked_door.initialize_new("Locked Door", cell_id)

    var instances: Array[Dictionary] = []
    _attach(actor, instances, "inventory_container", {"capacity": 2})
    _attach(stash, instances, "inventory_container", {"capacity": 1})
    _attach(pickup, instances, "interactable", {"prompt": "Pick up"})
    _attach(pickup, instances, "pickup", {"quantity": 3})
    _attach(door, instances, "interactable", {"prompt": "Open"})
    _attach(door, instances, "door", {"starts_open": false, "locked": false})
    _attach(locked_door, instances, "interactable", {})
    _attach(locked_door, instances, "door", {"locked": true})
    var records: Array[Dictionary] = [actor.to_dictionary(), stash.to_dictionary(), pickup.to_dictionary(), door.to_dictionary(), locked_door.to_dictionary()]
    project.entity_records = records

    var runtime = RuntimeGameplay.new()
    var load_result := runtime.initialize(project.to_dictionary(), {
        "definitions": Components.definitions(),
        "instances": instances,
        "sockets": [],
        "attachments": [],
    })
    if not load_result.get("ok", false):
        return ["Phase 10 inventory fixture must initialize: %s" % str(load_result.get("errors", []))]
    var inventory = Inventory.new()
    var bind_inventory := inventory.bind_runtime(runtime)
    if not bind_inventory.get("ok", false):
        return ["Inventory service must bind to loaded runtime gameplay state."]
    var interaction = Interaction.new()
    var bind_interaction := interaction.bind_runtime(runtime, inventory)
    if not bind_interaction.get("ok", false):
        return ["Interaction service must bind to runtime gameplay state."]

    var pickup_result := interaction.interact(actor.entity_id, pickup.entity_id)
    if not pickup_result.get("ok", false) or pickup_result.get("route") != "pickup":
        errors.append("Interactable pickups must route through the reusable inventory service.")
    elif not inventory.is_pickup_consumed(pickup.entity_id):
        errors.append("Collected pickups must be consumed only in disposable Play state.")
    var actor_inventory := inventory.get_inventory(actor.entity_id)
    var slots: Array = actor_inventory.get("slots", [])
    if slots.size() != 1 or int(slots[0].get("quantity", 0)) != 3:
        errors.append("Pickup quantity must enter the actor inventory deterministically.")
    if interaction.interact(actor.entity_id, pickup.entity_id).get("ok", false):
        errors.append("A consumed pickup must not be collected twice in one Play session.")

    var transfer := inventory.transfer_item(actor.entity_id, stash.entity_id, pickup.entity_id, 2)
    if not transfer.get("ok", false):
        errors.append("Inventory transfer between stable container entity IDs must succeed.")
    else:
        var actor_slots: Array = inventory.get_inventory(actor.entity_id).get("slots", [])
        var stash_slots: Array = inventory.get_inventory(stash.entity_id).get("slots", [])
        if actor_slots.size() != 1 or int(actor_slots[0].get("quantity", 0)) != 1:
            errors.append("Inventory transfer must subtract the source quantity.")
        if stash_slots.size() != 1 or int(stash_slots[0].get("quantity", 0)) != 2:
            errors.append("Inventory transfer must add the destination quantity.")

    var prompt := interaction.get_prompt(door.entity_id)
    if not prompt.get("ok", false) or str(prompt.get("prompt", "")) != "Open":
        errors.append("Interaction prompt metadata must come from the authored Interactable component.")
    var open_result := interaction.interact(actor.entity_id, door.entity_id)
    if not open_result.get("ok", false) or not bool(open_result.get("open", false)) or not interaction.is_door_open(door.entity_id):
        errors.append("Unlocked doors must toggle open through generic interaction routing.")
    var close_result := interaction.interact(actor.entity_id, door.entity_id)
    if not close_result.get("ok", false) or bool(close_result.get("open", true)):
        errors.append("Door interaction must toggle runtime open state without authoring mutations.")
    var blocked := interaction.interact(actor.entity_id, locked_door.entity_id)
    if blocked.get("ok", false):
        errors.append("Locked doors must fail safely without changing runtime door state.")

    var events := runtime.events_after(0)
    var kinds: Dictionary = {}
    for event in events: kinds[str(event.get("kind", ""))] = true
    for expected in ["pickup.collected", "inventory.transferred", "door.opened", "door.closed", "door.blocked"]:
        if not kinds.has(expected): errors.append("Phase 10 gameplay event bus is missing event: %s" % expected)
    return errors


static func _attach(entity, instances: Array[Dictionary], component_key: String, patch: Dictionary) -> void:
    var definition := _definition(component_key)
    var values: Dictionary = Contracts.defaults_for(definition)
    for key in patch.keys(): values[key] = patch[key]
    var record := {
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
        if str(definition.get("key", "")) == key: return definition.duplicate(true)
    return {}
