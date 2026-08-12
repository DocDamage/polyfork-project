class_name PlayWorldEnetSessionAdapter
extends Node

signal session_ready(role: String, session_id: String, local_peer_id: int)
signal session_stopped(reason: String)
signal peer_joined(identity: Dictionary)
signal peer_left(peer_id: int)
signal message_received(peer_id: int, message: Dictionary)
signal session_error(errors: Array[String])

const Contract = preload("res://src/network/network_session_contract.gd")
const IdentityRegistry = preload("res://src/network/network_identity_registry.gd")

var _peer: ENetMultiplayerPeer
var _registry = IdentityRegistry.new()
var _config: Dictionary = Contract.default_config()
var _role: String = Contract.ROLE_OFFLINE
var _session_id := ""
var _local_peer_id := 1
var _session_is_ready := false
var _pending_client_peers: Dictionary = {}
var _last_error: Array[String] = []

func _ready() -> void:
    set_process(true)

func _process(_delta: float) -> void:
    poll_once()

func start_session(config: Dictionary) -> Dictionary:
    shutdown("restart")
    var errors: Array[String] = Contract.validate_config(config)
    if not errors.is_empty(): return _record_failure(errors)
    _config = Contract.normalize_config(config)
    _role = str(_config.get("role", Contract.ROLE_OFFLINE))
    if _role == Contract.ROLE_OFFLINE: return _start_offline()
    if _role == Contract.ROLE_HOST: return _start_host()
    if _role == Contract.ROLE_CLIENT: return _start_client()
    return _record_failure(["Unsupported network role: %s" % _role])

func shutdown(reason: String = "shutdown") -> Dictionary:
    var changed: bool = _peer != null or _session_is_ready or _registry.is_active()
    if _peer != null:
        _disconnect_peer_signals()
        _peer.close()
        _peer = null
    _registry.clear()
    _pending_client_peers.clear()
    _session_is_ready = false
    _session_id = ""
    _local_peer_id = 1
    _role = Contract.ROLE_OFFLINE
    _config = Contract.default_config()
    if changed: session_stopped.emit(reason)
    return {"ok": true, "errors": [], "changed": changed}

func poll_once() -> void:
    if _peer == null: return
    _peer.poll()
    while _peer.get_available_packet_count() > 0:
        var sender: int = _peer.get_packet_peer()
        var packet: PackedByteArray = _peer.get_packet()
        var message: Dictionary = Contract.decode(packet)
        if message.is_empty():
            _emit_error(["Received an invalid network packet from peer %d." % sender])
            continue
        var envelope_errors: Array[String] = Contract.validate_envelope(message)
        if not envelope_errors.is_empty():
            _emit_error(envelope_errors)
            continue
        _handle_message(sender, message)

func send_message(message: Dictionary, target_peer: int = MultiplayerPeer.TARGET_PEER_BROADCAST, reliable: bool = true) -> Dictionary:
    if _peer == null: return _failure("Cannot send without an active network peer.")
    var errors: Array[String] = Contract.validate_envelope(message)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    _peer.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE if reliable else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED
    _peer.set_target_peer(target_peer)
    var result: Error = _peer.put_packet(Contract.encode(message))
    _peer.set_target_peer(MultiplayerPeer.TARGET_PEER_BROADCAST)
    if result != OK: return _failure("Network packet send failed with error %d." % int(result))
    return {"ok": true, "errors": []}

func disconnect_peer(peer_id: int) -> Dictionary:
    if _role != Contract.ROLE_HOST or _peer == null: return _failure("Only an active host can disconnect a peer.")
    if peer_id <= 1: return _failure("Host cannot disconnect its own server peer ID.")
    _peer.disconnect_peer(peer_id)
    return {"ok": true, "errors": []}

func is_session_ready() -> bool: return _session_is_ready
func get_role() -> String: return _role
func get_session_id() -> String: return _session_id
func get_local_peer_id() -> int: return _local_peer_id
func get_peer_count() -> int: return _registry.peer_count()
func get_identity_registry(): return _registry
func get_config() -> Dictionary: return _config.duplicate(true)
func get_last_error() -> Array[String]: return _last_error.duplicate()

func get_status() -> Dictionary:
    return {
        "role": _role,
        "ready": _session_is_ready,
        "session_id": _session_id,
        "local_peer_id": _local_peer_id,
        "peer_count": _registry.peer_count(),
        "peers": _registry.snapshot(),
        "last_error": _last_error.duplicate(),
    }

func _start_offline() -> Dictionary:
    _session_id = _requested_or_generated_session_id()
    var begin_result: Dictionary = _registry.begin_session(_session_id)
    if not begin_result.get("ok", false): return begin_result
    var identity_result: Dictionary = _registry.register_peer(1, str(_config.get("player_label", "Player")), str(_config.get("team_id", "")))
    if not identity_result.get("ok", false): return identity_result
    _local_peer_id = 1
    _session_is_ready = true
    session_ready.emit(_role, _session_id, _local_peer_id)
    return {"ok": true, "errors": [], "role": _role, "ready": true, "session_id": _session_id, "local_peer_id": _local_peer_id}

func _start_host() -> Dictionary:
    _peer = ENetMultiplayerPeer.new()
    var bind_ip := str(_config.get("address", "*")).strip_edges()
    if not bind_ip.is_empty() and bind_ip != Contract.DEFAULT_ADDRESS: _peer.set_bind_ip(bind_ip)
    var max_clients := maxi(1, int(_config.get("max_players", Contract.DEFAULT_MAX_PLAYERS)) - 1)
    var result: Error = _peer.create_server(int(_config.get("port", Contract.DEFAULT_PORT)), max_clients)
    if result != OK:
        _peer = null
        return _record_failure(["Unable to host multiplayer session on UDP port %d (error %d)." % [int(_config.get("port", Contract.DEFAULT_PORT)), int(result)]])
    _connect_peer_signals()
    _session_id = _requested_or_generated_session_id()
    var begin_result: Dictionary = _registry.begin_session(_session_id)
    if not begin_result.get("ok", false): return begin_result
    var identity_result: Dictionary = _registry.register_peer(1, str(_config.get("player_label", "Host")), str(_config.get("team_id", "")))
    if not identity_result.get("ok", false): return identity_result
    _local_peer_id = 1
    _session_is_ready = true
    session_ready.emit(_role, _session_id, _local_peer_id)
    return {"ok": true, "errors": [], "role": _role, "ready": true, "session_id": _session_id, "local_peer_id": _local_peer_id}

func _start_client() -> Dictionary:
    _peer = ENetMultiplayerPeer.new()
    var result: Error = _peer.create_client(str(_config.get("address", Contract.DEFAULT_ADDRESS)), int(_config.get("port", Contract.DEFAULT_PORT)))
    if result != OK:
        _peer = null
        return _record_failure(["Unable to connect to multiplayer host at %s:%d (error %d)." % [str(_config.get("address", Contract.DEFAULT_ADDRESS)), int(_config.get("port", Contract.DEFAULT_PORT)), int(result)]])
    _connect_peer_signals()
    _session_is_ready = false
    return {"ok": true, "errors": [], "role": _role, "ready": false, "connecting": true}

func _connect_peer_signals() -> void:
    if _peer == null: return
    _peer.peer_connected.connect(_on_peer_connected)
    _peer.peer_disconnected.connect(_on_peer_disconnected)

func _disconnect_peer_signals() -> void:
    if _peer == null: return
    if _peer.peer_connected.is_connected(_on_peer_connected): _peer.peer_connected.disconnect(_on_peer_connected)
    if _peer.peer_disconnected.is_connected(_on_peer_disconnected): _peer.peer_disconnected.disconnect(_on_peer_disconnected)

func _on_peer_connected(peer_id: int) -> void:
    if _role == Contract.ROLE_HOST:
        _pending_client_peers[peer_id] = true
        return
    if _role == Contract.ROLE_CLIENT and peer_id == MultiplayerPeer.TARGET_PEER_SERVER:
        var hello: Dictionary = Contract.make_hello(str(_config.get("project_id", "")), str(_config.get("player_label", "Player")), str(_config.get("team_id", "")))
        var result: Dictionary = send_message(hello, MultiplayerPeer.TARGET_PEER_SERVER, true)
        if not result.get("ok", false): _emit_error(_to_string_array(result.get("errors", [])))

func _on_peer_disconnected(peer_id: int) -> void:
    _pending_client_peers.erase(peer_id)
    var removed: Dictionary = _registry.remove_peer(peer_id)
    if removed.get("removed", false): peer_left.emit(peer_id)
    if _role == Contract.ROLE_CLIENT and peer_id == MultiplayerPeer.TARGET_PEER_SERVER:
        _session_is_ready = false
        _emit_error(["Multiplayer host disconnected."])
        session_stopped.emit("host_disconnected")
    elif _role == Contract.ROLE_HOST:
        send_message(Contract.make_peer_left(peer_id), MultiplayerPeer.TARGET_PEER_BROADCAST, true)

func _handle_message(sender: int, message: Dictionary) -> void:
    var message_type := str(message.get("message_type", ""))
    if _role == Contract.ROLE_HOST and message_type == Contract.MESSAGE_HELLO:
        _handle_host_hello(sender, message)
        return
    if _role == Contract.ROLE_CLIENT and message_type == Contract.MESSAGE_ACCEPT:
        _handle_client_accept(message)
        return
    if _role == Contract.ROLE_CLIENT and message_type == Contract.MESSAGE_REJECT:
        var payload: Dictionary = message.get("payload", {})
        var values: Array = payload.get("errors", [])
        var errors: Array[String] = []
        for value in values: errors.append(str(value))
        if errors.is_empty(): errors.append("Multiplayer host rejected the session.")
        _emit_error(errors)
        shutdown("rejected")
        return
    if message_type == Contract.MESSAGE_PEER_JOINED:
        _apply_peer_join_message(message)
        return
    if message_type == Contract.MESSAGE_PEER_LEFT:
        var payload: Dictionary = message.get("payload", {})
        var peer_id := int(payload.get("peer_id", 0))
        var removed: Dictionary = _registry.remove_peer(peer_id)
        if removed.get("removed", false): peer_left.emit(peer_id)
        return
    message_received.emit(sender, message.duplicate(true))

func _handle_host_hello(sender: int, message: Dictionary) -> void:
    if not _pending_client_peers.has(sender) and _registry.has_peer(sender): return
    var hello_errors: Array[String] = Contract.validate_hello(message, str(_config.get("project_id", "")))
    if not hello_errors.is_empty():
        send_message(Contract.make_reject(hello_errors), sender, true)
        _pending_client_peers.erase(sender)
        _peer.disconnect_peer(sender)
        return
    var payload: Dictionary = message.get("payload", {})
    var register_result: Dictionary = _registry.register_peer(sender, str(payload.get("player_label", "Player")), str(payload.get("team_id", "")))
    if not register_result.get("ok", false):
        send_message(Contract.make_reject(_to_string_array(register_result.get("errors", []))), sender, true)
        _peer.disconnect_peer(sender)
        return
    _pending_client_peers.erase(sender)
    var identity: Dictionary = register_result.get("identity", {})
    var accept: Dictionary = Contract.make_accept(_session_id, sender, identity, _registry.snapshot())
    var accept_result: Dictionary = send_message(accept, sender, true)
    if not accept_result.get("ok", false):
        _registry.remove_peer(sender)
        _emit_error(_to_string_array(accept_result.get("errors", [])))
        return
    send_message(Contract.make_peer_joined(identity), -sender, true)
    peer_joined.emit(identity.duplicate(true))

func _handle_client_accept(message: Dictionary) -> void:
    var payload: Dictionary = message.get("payload", {})
    if int(payload.get("protocol_version", -1)) != Contract.PROTOCOL_VERSION or str(payload.get("runtime_contract", "")) != Contract.RUNTIME_CONTRACT:
        _emit_error(["Host accepted with an incompatible network contract."])
        shutdown("incompatible_accept")
        return
    _session_id = str(payload.get("session_id", "")).strip_edges()
    _local_peer_id = int(payload.get("peer_id", 0))
    if _session_id.is_empty() or _local_peer_id <= 1:
        _emit_error(["Host returned invalid session identity."])
        shutdown("invalid_accept")
        return
    var begin_result: Dictionary = _registry.begin_session(_session_id)
    if not begin_result.get("ok", false):
        _emit_error(_to_string_array(begin_result.get("errors", [])))
        return
    var peers: Array = payload.get("peers", [])
    for value in peers:
        if not value is Dictionary: continue
        var identity: Dictionary = value
        var register_result: Dictionary = _registry.register_peer(
            int(identity.get("peer_id", 0)),
            str(identity.get("player_label", "Player")),
            str(identity.get("team_id", "")),
            str(identity.get("authored_entity_id", "")),
            str(identity.get("network_id", ""))
        )
        if not register_result.get("ok", false):
            _emit_error(_to_string_array(register_result.get("errors", [])))
            return
    _session_is_ready = true
    session_ready.emit(_role, _session_id, _local_peer_id)

func _apply_peer_join_message(message: Dictionary) -> void:
    var payload: Dictionary = message.get("payload", {})
    var identity: Dictionary = payload.get("identity", {})
    var peer_id := int(identity.get("peer_id", 0))
    if peer_id <= 0 or _registry.has_peer(peer_id): return
    var result: Dictionary = _registry.register_peer(
        peer_id,
        str(identity.get("player_label", "Player")),
        str(identity.get("team_id", "")),
        str(identity.get("authored_entity_id", "")),
        str(identity.get("network_id", ""))
    )
    if not result.get("ok", false):
        _emit_error(_to_string_array(result.get("errors", [])))
        return
    peer_joined.emit(result.get("identity", {}).duplicate(true))

func _requested_or_generated_session_id() -> String:
    var requested := str(_config.get("session_id", "")).strip_edges()
    if not requested.is_empty(): return requested
    return "session-%d-%d" % [Time.get_ticks_usec(), randi()]

func _record_failure(errors: Array[String]) -> Dictionary:
    _last_error = errors.duplicate()
    session_error.emit(_last_error.duplicate())
    return {"ok": false, "errors": _last_error.duplicate()}

func _emit_error(errors: Array[String]) -> void:
    _last_error = errors.duplicate()
    session_error.emit(_last_error.duplicate())

static func _to_string_array(values: Variant) -> Array[String]:
    var result: Array[String] = []
    if values is Array:
        for value in values: result.append(str(value))
    return result

static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
