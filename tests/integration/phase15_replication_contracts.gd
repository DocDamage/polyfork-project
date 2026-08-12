extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const GameplayContracts = preload("res://src/gameplay/gameplay_contracts.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const RuntimeGameplay = preload("res://src/gameplay/runtime_gameplay_state.gd")
const Health = preload("res://src/gameplay/runtime_health_service.gd")
const Interaction = preload("res://src/gameplay/runtime_interaction_service.gd")
const Contract = preload("res://src/network/network_session_contract.gd")
const Adapter = preload("res://src/network/enet_session_adapter.gd")
const GameplayReplication = preload("res://src/network/gameplay_replication_service.gd")

static func run_checks(tree: SceneTree) -> Array[String]:
    var errors: Array[String] = []
    var fixture: Dictionary = _build_fixture()
    var project_data: Dictionary = fixture["project_data"]
    var gameplay_data: Dictionary = fixture["gameplay_data"]
    var host_actor_id: String = str(fixture["host_actor_id"])
    var client_actor_id: String = str(fixture["client_actor_id"])
    var target_id: String = str(fixture["target_id"])
    var door_id: String = str(fixture["door_id"])

    var host_adapter = Adapter.new()
    var client_adapter = Adapter.new()
    tree.root.add_child(host_adapter)
    tree.root.add_child(client_adapter)
    var port: int = 32500 + int(Time.get_ticks_msec() % 500)
    var host_config: Dictionary = Contract.default_config()
    host_config["role"] = Contract.ROLE_HOST
    host_config["address"] = "*"
    host_config["port"] = port
    host_config["player_label"] = "Host"
    host_config["project_id"] = str(project_data.get("project_id", ""))
    host_config["session_id"] = "phase15-replication-session"
    var host_start: Dictionary = host_adapter.start_session(host_config)
    if not host_start.get("ok", false):
        _cleanup_nodes([client_adapter, host_adapter])
        return ["Replication host failed to start: %s" % str(host_start.get("errors", []))]

    var client_config: Dictionary = Contract.default_config()
    client_config["role"] = Contract.ROLE_CLIENT
    client_config["address"] = "127.0.0.1"
    client_config["port"] = port
    client_config["player_label"] = "Client"
    client_config["project_id"] = str(project_data.get("project_id", ""))
    var client_start: Dictionary = client_adapter.start_session(client_config)
    if not client_start.get("ok", false):
        _cleanup_nodes([client_adapter, host_adapter])
        return ["Replication client failed to start: %s" % str(client_start.get("errors", []))]
    for _index in range(240):
        await tree.process_frame
        if client_adapter.is_session_ready() and host_adapter.get_peer_count() == 2: break
    if not client_adapter.is_session_ready():
        _cleanup_nodes([client_adapter, host_adapter])
        return ["Replication client did not complete the host handshake."]

    var client_peer_id: int = int(client_adapter.get_local_peer_id())
    var host_assign: Dictionary = host_adapter.get_identity_registry().assign_authored_entity(1, host_actor_id)
    var host_client_assign: Dictionary = host_adapter.get_identity_registry().assign_authored_entity(client_peer_id, client_actor_id)
    var client_host_assign: Dictionary = client_adapter.get_identity_registry().assign_authored_entity(1, host_actor_id)
    var client_self_assign: Dictionary = client_adapter.get_identity_registry().assign_authored_entity(client_peer_id, client_actor_id)
    for assignment in [host_assign, host_client_assign, client_host_assign, client_self_assign]:
        if not assignment.get("ok", false): errors.append("Replication identity fixture failed to assign authored ownership: %s" % str(assignment.get("errors", [])))

    var host_services: Dictionary = _make_services(project_data, gameplay_data)
    var client_services: Dictionary = _make_services(project_data, gameplay_data)
    if not host_services.get("ok", false) or not client_services.get("ok", false):
        errors.append("Replication gameplay fixtures failed to initialize.")
        _cleanup_services(host_services); _cleanup_services(client_services)
        _cleanup_nodes([client_adapter, host_adapter])
        return errors

    var host_replication = GameplayReplication.new()
    var client_replication = GameplayReplication.new()
    tree.root.add_child(host_replication)
    tree.root.add_child(client_replication)
    var host_bind: Dictionary = host_replication.bind_runtime(host_adapter, host_services["runtime"], host_services["health"], host_services["interaction"])
    var client_bind: Dictionary = client_replication.bind_runtime(client_adapter, client_services["runtime"], client_services["health"], client_services["interaction"])
    if not host_bind.get("ok", false): errors.append("Host gameplay replication failed to bind: %s" % str(host_bind.get("errors", [])))
    if not client_bind.get("ok", false): errors.append("Client gameplay replication failed to bind: %s" % str(client_bind.get("errors", [])))

    var damage_request: Dictionary = client_replication.request_action(GameplayReplication.ACTION_DAMAGE, {
        "source_entity_id": client_actor_id,
        "target_entity_id": target_id,
        "amount": 25.0,
    })
    if not damage_request.get("ok", false) or not damage_request.get("pending", false): errors.append("Client damage must be sent as a pending host-authoritative request.")
    for _index in range(240):
        await tree.process_frame
        var host_value: float = _current_health(host_services, target_id)
        var client_value: float = _current_health(client_services, target_id)
        if is_equal_approx(host_value, 75.0) and is_equal_approx(client_value, 75.0) and client_replication.pending_request_count() == 0: break
    var host_health: float = _current_health(host_services, target_id)
    var client_health: float = _current_health(client_services, target_id)
    if not is_equal_approx(host_health, 75.0): errors.append("Host must authoritatively commit replicated damage.")
    if not is_equal_approx(client_health, 75.0): errors.append("Client health state must converge to the host result.")
    if client_replication.pending_request_count() != 0: errors.append("Accepted client gameplay requests must leave the pending queue.")

    var door_request: Dictionary = client_replication.request_action(GameplayReplication.ACTION_DOOR_TOGGLE, {
        "actor_entity_id": client_actor_id,
        "target_entity_id": door_id,
    })
    if not door_request.get("ok", false): errors.append("Client door action must be routable to host authority.")
    for _index in range(240):
        await tree.process_frame
        if host_services["interaction"].is_door_open(door_id) and client_services["interaction"].is_door_open(door_id): break
    if not host_services["interaction"].is_door_open(door_id): errors.append("Host must commit replicated door state.")
    if not client_services["interaction"].is_door_open(door_id): errors.append("Client door state must converge to the host result.")

    var spoof_request: Dictionary = client_replication.request_action(GameplayReplication.ACTION_HEAL, {
        "source_entity_id": host_actor_id,
        "target_entity_id": target_id,
        "amount": 10.0,
    })
    if not spoof_request.get("ok", false): errors.append("Spoofed client request must travel to host validation rather than mutating locally.")
    for _index in range(240):
        await tree.process_frame
        if client_replication.pending_request_count() == 0: break
    var health_after_spoof: float = _current_health(host_services, target_id)
    if not is_equal_approx(health_after_spoof, 75.0): errors.append("Host must reject client actions that claim an authored entity owned by another peer.")

    host_replication.clear(); client_replication.clear()
    _cleanup_nodes([client_replication, host_replication])
    _cleanup_services(host_services); _cleanup_services(client_services)
    _cleanup_nodes([client_adapter, host_adapter])
    return errors

static func _current_health(services: Dictionary, entity_id: String) -> float:
    return float(services["health"].get_health(entity_id).get("values", {}).get("current_health", -1.0))

static func _build_fixture() -> Dictionary:
    var project = WorldProject.new()
    project.initialize_new("Phase 15 Replication", &"small", "blank_sandbox")
    var cell_id: String = StableId.generate()
    var cells: Array[String] = [cell_id]
    project.cell_ids = cells
    var host_actor = WorldEntity.new(); host_actor.initialize_new("Host Actor", cell_id)
    var client_actor = WorldEntity.new(); client_actor.initialize_new("Client Actor", cell_id)
    var target = WorldEntity.new(); target.initialize_new("Target", cell_id)
    var door = WorldEntity.new(); door.initialize_new("Door", cell_id)
    var instances: Array[Dictionary] = []
    _attach(target, instances, "health", {"max_health": 100.0, "current_health": 100.0})
    _attach(target, instances, "damageable", {"armor": 0.0})
    _attach(door, instances, "interactable", {"prompt": "Open"})
    _attach(door, instances, "door", {"starts_open": false, "locked": false})
    var records: Array[Dictionary] = [host_actor.to_dictionary(), client_actor.to_dictionary(), target.to_dictionary(), door.to_dictionary()]
    project.entity_records = records
    return {
        "project_data": project.to_dictionary(),
        "gameplay_data": {"definitions": Components.definitions(), "instances": instances, "sockets": [], "attachments": [], "dialogues": [], "quests": []},
        "host_actor_id": host_actor.entity_id,
        "client_actor_id": client_actor.entity_id,
        "target_id": target.entity_id,
        "door_id": door.entity_id,
    }

static func _make_services(project_data: Dictionary, gameplay_data: Dictionary) -> Dictionary:
    var runtime = RuntimeGameplay.new()
    var initialized: Dictionary = runtime.initialize(project_data, gameplay_data)
    if not initialized.get("ok", false): return {"ok": false, "errors": initialized.get("errors", []), "runtime": runtime}
    var health = Health.new()
    var health_bind: Dictionary = health.bind_runtime(runtime)
    if not health_bind.get("ok", false): return {"ok": false, "errors": health_bind.get("errors", []), "runtime": runtime, "health": health}
    var interaction = Interaction.new()
    var interaction_bind: Dictionary = interaction.bind_runtime(runtime)
    if not interaction_bind.get("ok", false): return {"ok": false, "errors": interaction_bind.get("errors", []), "runtime": runtime, "health": health, "interaction": interaction}
    return {"ok": true, "errors": [], "runtime": runtime, "health": health, "interaction": interaction}

static func _cleanup_services(values: Dictionary) -> void:
    if values.has("interaction") and values["interaction"] != null: values["interaction"].clear()
    if values.has("health") and values["health"] != null: values["health"].clear()
    if values.has("runtime") and values["runtime"] != null: values["runtime"].clear()

static func _cleanup_nodes(nodes: Array) -> void:
    for node in nodes:
        if node == null or not is_instance_valid(node): continue
        if node.has_method("shutdown"): node.shutdown("cleanup")
        if node.get_parent() != null: node.get_parent().remove_child(node)
        node.free()

static func _attach(entity, instances: Array[Dictionary], component_key: String, patch: Dictionary) -> void:
    var definition: Dictionary = _definition(component_key)
    var values: Dictionary = GameplayContracts.defaults_for(definition)
    for key in patch.keys(): values[key] = patch[key]
    var record: Dictionary = {
        "document_type": GameplayContracts.COMPONENT_INSTANCE,
        "schema_version": GameplayContracts.SCHEMA_VERSION,
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
