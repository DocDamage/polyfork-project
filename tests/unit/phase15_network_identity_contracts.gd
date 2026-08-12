extends RefCounted

const Contract = preload("res://src/network/network_session_contract.gd")
const Registry = preload("res://src/network/network_identity_registry.gd")
const Adapter = preload("res://src/network/enet_session_adapter.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []

    var defaults: Dictionary = Contract.default_config()
    if str(defaults.get("role", "")) != Contract.ROLE_OFFLINE: errors.append("Phase 15 network sessions must default to offline mode.")
    if int(defaults.get("port", 0)) != Contract.DEFAULT_PORT: errors.append("Phase 15 network sessions must expose a deterministic default port.")
    if not Contract.validate_config(defaults).is_empty(): errors.append("Default network session configuration must validate.")

    var normalized: Dictionary = Contract.normalize_config({"role": "invalid", "port": 1, "max_players": 999, "player_label": ""})
    if str(normalized.get("role", "")) != Contract.ROLE_OFFLINE: errors.append("Unknown network roles must normalize safely to offline.")
    if int(normalized.get("port", 0)) != Contract.MIN_PORT: errors.append("Network port normalization must stay inside the supported range.")
    if int(normalized.get("max_players", 0)) != Contract.MAX_PLAYERS: errors.append("Network player count normalization must be bounded.")
    if str(normalized.get("player_label", "")) != "Player": errors.append("Empty normalized player labels must use a safe default.")

    var invalid_config := defaults.duplicate(true)
    invalid_config["runtime_contract"] = "old-contract"
    if Contract.validate_config(invalid_config).is_empty(): errors.append("Incompatible runtime contracts must be rejected before connecting.")

    var hello := Contract.make_hello("project-a", "Doc", "blue")
    if not Contract.validate_hello(hello, "project-a").is_empty(): errors.append("Compatible session hello must validate.")
    if Contract.validate_hello(hello, "project-b").is_empty(): errors.append("Mismatched project identity must be rejected.")
    var round_trip: Dictionary = Contract.decode(Contract.encode(hello))
    if round_trip != hello: errors.append("Network message encoding must round-trip deterministically.")
    if not Contract.validate_envelope(round_trip).is_empty(): errors.append("Valid network message envelope must validate.")

    var registry = Registry.new()
    if not registry.begin_session("session-test").get("ok", false): errors.append("Network identity registry must start from a runtime-only session ID.")
    var host_result: Dictionary = registry.register_peer(1, "Host", "blue", "entity-host")
    if not host_result.get("ok", false): errors.append("Host network identity must register.")
    var client_result: Dictionary = registry.register_peer(42, "Client", "red")
    if not client_result.get("ok", false): errors.append("Client network identity must register.")
    if registry.register_peer(42, "Duplicate").get("ok", true): errors.append("Duplicate peer IDs must be rejected.")
    if registry.assign_authored_entity(42, "entity-host").get("ok", true): errors.append("Two peers must not own the same authored entity ID.")
    var assign_result: Dictionary = registry.assign_authored_entity(42, "entity-client")
    if not assign_result.get("ok", false): errors.append("Network identity must be able to reference an authored entity without rewriting its ID.")
    if registry.peer_for_entity("entity-client") != 42: errors.append("Authored entity ownership lookup must resolve to the session peer.")
    if registry.snapshot().size() != 2: errors.append("Network identity snapshot must include all session peers.")
    registry.clear()
    if registry.is_active() or registry.peer_count() != 0: errors.append("Network identity must be fully disposable between Play sessions.")

    var offline = Adapter.new()
    var offline_result: Dictionary = offline.start_session(defaults)
    if not offline_result.get("ok", false) or not offline.is_session_ready(): errors.append("Offline network adapter mode must be immediately ready.")
    if offline.get_peer_count() != 1: errors.append("Offline mode must expose only the local authority identity.")
    offline.shutdown("test")
    offline.free()

    return errors
