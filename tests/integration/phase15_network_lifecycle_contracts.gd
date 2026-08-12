extends RefCounted

const Contract = preload("res://src/network/network_session_contract.gd")
const Adapter = preload("res://src/network/enet_session_adapter.gd")
const NetworkRuntime = preload("res://src/network/network_runtime_service.gd")

static func run_checks(tree: SceneTree) -> Array[String]:
    var errors: Array[String] = []
    var port: int = 33500 + int(Time.get_ticks_msec() % 500)

    var host = Adapter.new()
    var mismatched = Adapter.new()
    tree.root.add_child(host)
    tree.root.add_child(mismatched)
    var host_config: Dictionary = Contract.default_config()
    host_config["role"] = Contract.ROLE_HOST
    host_config["address"] = "*"
    host_config["port"] = port
    host_config["project_id"] = "phase15-project-a"
    host_config["session_id"] = "phase15-lifecycle"
    host_config["player_label"] = "Host"
    var host_start: Dictionary = host.start_session(host_config)
    if not host_start.get("ok", false):
        _cleanup([mismatched, host])
        return ["Lifecycle host failed to start: %s" % str(host_start.get("errors", []))]

    var bad_config: Dictionary = Contract.default_config()
    bad_config["role"] = Contract.ROLE_CLIENT
    bad_config["address"] = "127.0.0.1"
    bad_config["port"] = port
    bad_config["project_id"] = "phase15-project-b"
    bad_config["player_label"] = "Wrong Project"
    var bad_start: Dictionary = mismatched.start_session(bad_config)
    if not bad_start.get("ok", false): errors.append("Mismatched client should reach compatibility handshake before rejection.")
    for _index in range(180):
        await tree.process_frame
        if host.get_peer_count() == 1 and not mismatched.is_session_ready() and not mismatched.get_last_error().is_empty(): break
    if mismatched.is_session_ready(): errors.append("Project-identity mismatch must never become session-ready.")
    if host.get_peer_count() != 1: errors.append("Rejected incompatible client must not remain in the host identity registry.")

    mismatched.shutdown("mismatch_complete")
    if mismatched.get_peer_count() != 0 or mismatched.is_session_ready(): errors.append("Client shutdown must clear all disposable identity/session state.")

    var client = Adapter.new()
    tree.root.add_child(client)
    var client_config: Dictionary = Contract.default_config()
    client_config["role"] = Contract.ROLE_CLIENT
    client_config["address"] = "127.0.0.1"
    client_config["port"] = port
    client_config["project_id"] = "phase15-project-a"
    client_config["player_label"] = "Client"
    var client_start: Dictionary = client.start_session(client_config)
    if not client_start.get("ok", false): errors.append("Compatible lifecycle client must start connecting.")
    for _index in range(240):
        await tree.process_frame
        if client.is_session_ready() and host.get_peer_count() == 2: break
    if not client.is_session_ready(): errors.append("Compatible lifecycle client must complete handshake.")
    var first_peer_id: int = int(client.get_local_peer_id())
    if first_peer_id <= 1: errors.append("Connected client must receive a non-host peer identity.")

    host.shutdown("host_terminated")
    for _index in range(180):
        await tree.process_frame
        if not client.is_session_ready(): break
    if client.is_session_ready(): errors.append("Host termination must make the client session non-ready.")
    if client.get_last_error().is_empty(): errors.append("Host termination must surface an explicit client error.")

    var restarted_host = Adapter.new()
    tree.root.add_child(restarted_host)
    var restart_host_result: Dictionary = restarted_host.start_session(host_config)
    if not restart_host_result.get("ok", false): errors.append("Host must be able to bind again after complete shutdown.")
    var reconnect_result: Dictionary = client.start_session(client_config)
    if not reconnect_result.get("ok", false): errors.append("Client adapter must support a clean reconnect attempt after host termination.")
    for _index in range(240):
        await tree.process_frame
        if client.is_session_ready() and restarted_host.get_peer_count() == 2: break
    if not client.is_session_ready(): errors.append("Client must be able to rejoin a restarted compatible host.")
    if restarted_host.get_peer_count() != 2: errors.append("Restarted host must contain exactly host plus rejoined client identities.")

    client.shutdown("repeat_cleanup")
    client.shutdown("repeat_cleanup_again")
    if client.get_peer_count() != 0 or client.is_session_ready(): errors.append("Repeated network shutdown must be idempotent and leak-free.")

    var runtime_service = NetworkRuntime.new()
    var client_authority_config: Dictionary = Contract.default_config()
    client_authority_config["role"] = Contract.ROLE_CLIENT
    client_authority_config["address"] = "127.0.0.1"
    var authority_result: Dictionary = runtime_service.configure_session(client_authority_config)
    if not authority_result.get("ok", false): errors.append("Runtime service must accept a client role configuration while Build is inactive.")
    if runtime_service.can_persist_runtime_state(): errors.append("Client role must never have authoritative runtime save permission.")
    runtime_service.set_offline()
    if not runtime_service.can_persist_runtime_state(): errors.append("Offline role must retain existing local runtime save authority.")
    runtime_service.free()

    _cleanup([client, mismatched, restarted_host, host])
    return errors

static func _cleanup(nodes: Array) -> void:
    for node in nodes:
        if node == null or not is_instance_valid(node): continue
        if node.has_method("shutdown"): node.shutdown("cleanup")
        if node.get_parent() != null: node.get_parent().remove_child(node)
        node.free()
