extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const Archetypes = preload("res://src/gameplay/builtin_archetype_library.gd")
const GameplayState = preload("res://src/gameplay/gameplay_state.gd")
const GameplayRepository = preload("res://src/gameplay/gameplay_repository.gd")
const PrefabResolver = preload("res://src/gameplay/prefab_resolver.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var definitions := Components.definitions()
    if definitions.size() != 21: errors.append("Phase 6 initial component library must contain all 21 required definitions.")
    var ids: Dictionary = {}; var keys: Dictionary = {}
    for definition in definitions:
        var contract_errors := Contracts.validate_component_definition(definition)
        if not contract_errors.is_empty(): errors.append("Built-in component definition must validate: %s" % [contract_errors])
        var definition_id := str(definition.get("definition_id", "")); var key := str(definition.get("key", ""))
        if ids.has(definition_id) or keys.has(key): errors.append("Built-in component definitions require unique stable IDs and keys.")
        ids[definition_id] = true; keys[key] = true
    if not ids.has(Components.id_for("network_identity_stub")): errors.append("NetworkIdentityStub must be part of the initial component set.")

    var state = GameplayState.new(); state.definitions = definitions; state.archetypes = Archetypes.definitions()
    var project = WorldProject.new(); project.initialize_new("Gameplay Contracts", &"small", "blank_sandbox")
    var test_cells: Array[String] = [StableId.generate()]
    project.cell_ids = test_cells
    var state_errors := state.validate(project)
    if not state_errors.is_empty(): errors.append("Seed component/archetype state must cross-validate: %s" % [state_errors])
    if state.archetypes.size() != 10: errors.append("Archetype registry must contain the nine Phase 6 presets plus the reusable Phase 7 player archetype.")

    var no_existing: Array[String] = []
    var plan := state.dependency_plan(Components.id_for("vehicle_body"), no_existing)
    var expected := [Components.id_for("collision"), Components.id_for("physics_prop"), Components.id_for("vehicle_body")]
    if not plan.get("ok", false) or plan.get("definition_ids", []) != expected: errors.append("Component dependency plan must be deterministic and dependency-first.")
    var conflict_existing: Array[String] = [Components.id_for("physics_prop")]
    var conflict := state.conflict_for(Components.id_for("character_controller"), conflict_existing)
    if not conflict.get("ok", false) or not conflict.get("conflict", false): errors.append("Explicit component conflicts must be detected without silently removing authored data.")

    var collision := state.get_definition(Components.id_for("collision"))
    var invalid_values := Contracts.defaults_for(collision); invalid_values["layer"] = 99
    if Contracts.validate_values(invalid_values, collision).is_empty(): errors.append("Component property ranges must reject invalid authored values.")

    var root_node := _node("Base Root")
    root_node["components"] = {Components.id_for("health"): Contracts.defaults_for(state.get_definition(Components.id_for("health")))}
    var base_prefab := _prefab("Base Crate", [root_node])
    var socket := _socket(root_node["node_id"], "Grip", "Grip")
    base_prefab["socket_ids"] = [socket["socket_id"]]
    state.prefabs.append(base_prefab); state.sockets.append(socket)
    var derived := _prefab("Derived Crate", [])
    derived["base_prefab_id"] = base_prefab["prefab_id"]
    derived["node_overrides"] = {root_node["node_id"]: {"display_name": "Derived Root", "components": {Components.id_for("health"): {"max_health": 250.0}}}}
    state.prefabs.append(derived)
    var resolved := PrefabResolver.new(state).resolve(derived["prefab_id"])
    if not resolved.get("ok", false): errors.append("Derived prefab must resolve its base and overrides: %s" % [resolved.get("errors", [])])
    else:
        var effective: Dictionary = resolved.get("nodes", [])[0]
        if effective.get("display_name") != "Derived Root" or float(effective.get("components", {}).get(Components.id_for("health"), {}).get("max_health", 0.0)) != 250.0: errors.append("Derived prefab must preserve deterministic meaningful overrides.")
        if resolved.get("sockets", []).size() != 1: errors.append("Derived prefab must inherit base sockets by stable socket ID.")

    var repo_root := "user://tests/phase6_gameplay_%s" % StableId.generate()
    var repository = GameplayRepository.new(repo_root.path_join("project"))
    var open_result := repository.open_or_create(project)
    if not open_result.get("ok", false): errors.append("Gameplay repository must seed valid project-managed registries: %s" % [open_result.get("errors", [])])
    else:
        var reopened: Dictionary = GameplayRepository.new(repo_root.path_join("project")).open_or_create(project)
        if not reopened.get("ok", false): errors.append("Gameplay repository reopen failed: %s" % [reopened.get("errors", [])])
        elif reopened.get("state").definitions.size() != 21: errors.append("Gameplay definitions must survive repository reopen with stable identity.")
    return errors


static func _node(display_name: String) -> Dictionary:
    return {"node_id": StableId.generate(), "parent_node_id": null, "display_name": display_name, "asset_id": null, "transform": _transform(), "components": {}}


static func _prefab(display_name: String, nodes: Array) -> Dictionary:
    return {"document_type": Contracts.PREFAB, "schema_version": Contracts.SCHEMA_VERSION, "prefab_id": StableId.generate(), "display_name": display_name, "base_prefab_id": null, "nodes": nodes.duplicate(true), "node_overrides": {}, "removed_node_ids": [], "socket_ids": [], "socket_overrides": {}, "removed_socket_ids": []}


static func _socket(owner_id: String, name: String, category: String) -> Dictionary:
    return {"document_type": Contracts.SOCKET, "schema_version": Contracts.SCHEMA_VERSION, "socket_id": StableId.generate(), "owner_kind": "prefab_node", "owner_id": owner_id, "name": name, "category": category, "custom_category": "", "local_transform": _transform()}


static func _transform() -> Dictionary: return {"position": [0.0, 0.0, 0.0], "rotation_degrees": [0.0, 0.0, 0.0], "scale": [1.0, 1.0, 1.0]}