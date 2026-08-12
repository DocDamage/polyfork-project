extends RefCounted

const Contract = preload("res://src/network/network_session_contract.gd")
const Adapter = preload("res://src/network/enet_session_adapter.gd")

static func run_checks(tree: SceneTree) -> Array[String]:
    var errors: Array[String] = []
    var host = Adapter.new()
    var client = Adapter.new()
    tree.root.add_child(host)
    tree.root.add_child(client)

    var port: int = 31000 + int(Time.get_ticks_msec() % 1000)
    var host_config: Dictionary = Contract.default_config()
    host_config["role"] = Contract.ROLE_HOST
    host_config["address"] = "*"
    host_config["port"] = port
    host_config["max_players"] = 4
    host_config["player_label"] = "Host"
    host_config["project_id"] = "phase15-loopback"
    host_config["session_id"] = "phase15-loopback-session"
    var host_result: Dictionary = host.start_session(host_config)
    if not host_result.get("ok", false):
        errors.append("Loopback host failed to start: %s" % str(host_result.get("errors", [])))
        _cleanup(host, client)
        return errors

    var client_config: Dictionary = Contract.default_config()
    client_config["role"] = Contract.ROLE_CLIENT
    client_config["address"] = "127.0.0.1"
    client_config["port"] = port
    client_config["max_players"] = 4
    client_config["player_label"] = "Client"
    client_config["project_id"] = "phase15-loopback"
    var client_result: Dictionary = client.start_session(client_config)
    if not client_result.get("ok", false):
        errors.append("Loopback client failed to start: %s" % str(client_result.get("errors", [])))
        _cleanup(host, client)
        return errors

    for _index in range(240):
        await tree.process_frame
        if client.is_session_ready() and host.get_peer_count() == 2: break

    if not client.is_session_ready(): errors.append("Loopback client did not complete the Phase 15 compatibility handshake.")
    if not host.is_session_ready(): errors.append("Loopback host must remain session-ready while accepting a client.")
    if host.get_peer_count() != 2: errors.append("Loopback host identity registry must contain host and accepted client.")
    if client.get_peer_count() != 2: errors.append("Loopback client identity registry must converge to host and client peers.")
    if host.get_session_id() != client.get_session_id(): errors.append("Host and client must converge on one runtime-only session ID.")
    if client.get_local_peer_id() <= 1: errors.append("Connected client must receive a non-host peer ID.")

    var observed: Dictionary = {"received": false, "sender": 0}
    host.message_received.connect(func(peer_id: int, message: Dictionary) -> void:
        if str(message.get("message_type", "")) == "test.loopback":
            observed["received"] = true
            observed["sender"] = peer_id
    )
    var test_message: Dictionary = {
        "protocol_version": Contract.PROTOCOL_VERSION,
        "runtime_contract": Contract.RUNTIME_CONTRACT,
        "message_type": "test.loopback",
        "payload": {"value": 7},
    }
    var send_result: Dictionary = client.send_message(test_message, MultiplayerPeer.TARGET_PEER_SERVER, true)
    if not send_result.get("ok", false): errors.append("Loopback client failed to send a reliable packet.")
    for _index in range(120):
        await tree.process_frame
        if bool(observed.get("received", false)): break
    if not bool(observed.get("received", false)): errors.append("Loopback host did not receive the client packet through the project-owned ENet adapter.")
    if int(observed.get("sender", 0)) != client.get_local_peer_id(): errors.append("Loopback packets must retain their ENet peer identity.")

    var client_peer_id: int = int(client.get_local_peer_id())
    client.shutdown("test_disconnect")
    for _index in range(120):
        await tree.process_frame
        if host.get_peer_count() == 1: break
    if host.get_peer_count() != 1: errors.append("Host must clean disconnected client identity from the disposable session registry.")
    if host.get_identity_registry().has_peer(client_peer_id): errors.append("Disconnected peer identity must not leak after cleanup.")

    _cleanup(host, client)
    return errors

static func _cleanup(host: Node, client: Node) -> void:
    if is_instance_valid(client):
        if client.has_method("shutdown"): client.shutdown("cleanup")
        if client.get_parent() != null: client.get_parent().remove_child(client)
        client.free()
    if is_instance_valid(host):
        if host.has_method("shutdown"): host.shutdown("cleanup")
        if host.get_parent() != null: host.get_parent().remove_child(host)
        host.free()
