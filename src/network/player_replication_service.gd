class_name PlayWorldPlayerReplicationService
extends Node

signal remote_player_spawned(peer_id: int, player: CharacterBody3D)
signal remote_player_removed(peer_id: int)
signal replication_error(errors: Array[String])

const Contract = preload("res://src/network/network_session_contract.gd")
const ThirdPersonController = preload("res://src/runtime/third_person_controller.gd")
const FirstPersonController = preload("res://src/runtime/first_person_controller.gd")

const SEND_INTERVAL := 0.05
const MAX_WORLD_COORDINATE := 1000000.0

var _adapter
var _owner_node: Node
var _local_player: CharacterBody3D
var _controller_kind := "none"
var _controller_config: Dictionary = {}
var _remote_players: Dictionary = {}
var _last_sequence_by_peer: Dictionary = {}
var _sequence := 0
var _elapsed := 0.0
var _bound := false

func bind_runtime(adapter, owner_node: Node, local_player: CharacterBody3D, controller_kind: String, controller_config: Dictionary = {}) -> Dictionary:
    clear()
    if adapter == null or not adapter.has_method("is_session_ready"): return _failure("Player replication requires a network session adapter.")
    if owner_node == null: return _failure("Player replication requires a runtime owner node.")
    if local_player == null or not is_instance_valid(local_player): return _failure("Player replication requires a local player node.")
    if controller_kind != "third_person" and controller_kind != "first_person": return _failure("Player replication requires a supported local controller.")
    _adapter = adapter
    _owner_node = owner_node
    _local_player = local_player
    _controller_kind = controller_kind
    _controller_config = controller_config.duplicate(true)
    _adapter.peer_joined.connect(_on_peer_joined)
    _adapter.peer_left.connect(_on_peer_left)
    _adapter.message_received.connect(_on_message_received)
    _bound = true
    _sync_existing_peers()
    return {"ok": true, "errors": [], "remote_peer_count": _remote_players.size()}

func clear() -> void:
    if _adapter != null:
        if _adapter.peer_joined.is_connected(_on_peer_joined): _adapter.peer_joined.disconnect(_on_peer_joined)
        if _adapter.peer_left.is_connected(_on_peer_left): _adapter.peer_left.disconnect(_on_peer_left)
        if _adapter.message_received.is_connected(_on_message_received): _adapter.message_received.disconnect(_on_message_received)
    for peer_id in _remote_players.keys(): _free_remote_player(int(peer_id))
    _remote_players.clear()
    _last_sequence_by_peer.clear()
    _adapter = null
    _owner_node = null
    _local_player = null
    _controller_kind = "none"
    _controller_config.clear()
    _sequence = 0
    _elapsed = 0.0
    _bound = false

func _exit_tree() -> void:
    clear()

func _physics_process(delta: float) -> void:
    if not _bound or _adapter == null or not _adapter.is_session_ready() or not is_instance_valid(_local_player): return
    _elapsed += delta
    if _elapsed < SEND_INTERVAL: return
    _elapsed = 0.0
    _sequence += 1
    var message := Contract.make_player_state(
        _adapter.get_local_peer_id(),
        "",
        _local_player.global_position,
        _local_player.rotation.y,
        _sequence
    )
    var target := MultiplayerPeer.TARGET_PEER_BROADCAST if _adapter.get_role() == Contract.ROLE_HOST else MultiplayerPeer.TARGET_PEER_SERVER
    var result: Dictionary = _adapter.send_message(message, target, false)
    if not result.get("ok", false): replication_error.emit(_to_string_array(result.get("errors", [])))

func get_remote_player(peer_id: int) -> CharacterBody3D:
    var value = _remote_players.get(peer_id)
    return value if value is CharacterBody3D and is_instance_valid(value) else null

func get_remote_peer_ids() -> Array[int]:
    var result: Array[int] = []
    for value in _remote_players.keys(): result.append(int(value))
    result.sort()
    return result

func remote_player_count() -> int: return _remote_players.size()

func _sync_existing_peers() -> void:
    if _adapter == null or not _adapter.is_session_ready(): return
    var local_peer_id: int = _adapter.get_local_peer_id()
    for identity in _adapter.get_identity_registry().snapshot():
        var peer_id := int(identity.get("peer_id", 0))
        if peer_id > 0 and peer_id != local_peer_id: _ensure_remote_player(peer_id)

func _on_peer_joined(identity: Dictionary) -> void:
    var peer_id := int(identity.get("peer_id", 0))
    if _adapter == null or peer_id <= 0 or peer_id == _adapter.get_local_peer_id(): return
    _ensure_remote_player(peer_id)

func _on_peer_left(peer_id: int) -> void:
    _free_remote_player(peer_id)
    _last_sequence_by_peer.erase(peer_id)

func _on_message_received(sender_peer_id: int, message: Dictionary) -> void:
    if str(message.get("message_type", "")) != Contract.MESSAGE_PLAYER_STATE: return
    var payload: Dictionary = message.get("payload", {})
    var peer_id := int(payload.get("peer_id", 0))
    if peer_id <= 0 or _adapter == null: return
    if _adapter.get_role() == Contract.ROLE_HOST:
        if sender_peer_id != peer_id: 
            replication_error.emit(["Rejected player state whose claimed peer does not match its sender."])
            return
    elif sender_peer_id != MultiplayerPeer.TARGET_PEER_SERVER:
        replication_error.emit(["Client rejected player state that did not come from the host authority."])
        return
    if peer_id == _adapter.get_local_peer_id(): return
    var state_result := _validate_state(payload)
    if not state_result.get("ok", false):
        replication_error.emit(_to_string_array(state_result.get("errors", [])))
        return
    var sequence := int(payload.get("sequence", 0))
    var previous := int(_last_sequence_by_peer.get(peer_id, -1))
    if sequence <= previous: return
    _last_sequence_by_peer[peer_id] = sequence
    var player := _ensure_remote_player(peer_id)
    if player == null: return
    var values: Array = payload.get("position", [])
    var position_value := Vector3(float(values[0]), float(values[1]), float(values[2]))
    if player.has_method("apply_network_state"): player.apply_network_state(position_value, float(payload.get("rotation_y", 0.0)))
    else:
        player.global_position = position_value
        player.rotation.y = float(payload.get("rotation_y", 0.0))
    if _adapter.get_role() == Contract.ROLE_HOST:
        var relay_result: Dictionary = _adapter.send_message(message, -sender_peer_id, false)
        if not relay_result.get("ok", false): replication_error.emit(_to_string_array(relay_result.get("errors", [])))

func _validate_state(payload: Dictionary) -> Dictionary:
    var values = payload.get("position", [])
    if not values is Array or values.size() != 3: return _failure("Player replication position must contain three values.")
    for value in values:
        var coordinate := float(value)
        if absf(coordinate) > MAX_WORLD_COORDINATE: return _failure("Player replication rejected an out-of-bounds coordinate.")
    if int(payload.get("sequence", 0)) <= 0: return _failure("Player replication sequence must be positive.")
    return {"ok": true, "errors": []}

func _ensure_remote_player(peer_id: int) -> CharacterBody3D:
    var existing := get_remote_player(peer_id)
    if existing != null: return existing
    if _owner_node == null: return null
    var config := _controller_config.duplicate(true)
    config["local_input_enabled"] = false
    var player: CharacterBody3D
    if _controller_kind == "third_person": player = ThirdPersonController.new()
    elif _controller_kind == "first_person": player = FirstPersonController.new()
    else: return null
    player.configure(config)
    player.name = "NetworkPlayer_%d" % peer_id
    player.collision_layer = 0
    player.collision_mask = 0
    _owner_node.add_child(player)
    if player.has_method("set_local_input_enabled"): player.set_local_input_enabled(false)
    _remote_players[peer_id] = player
    remote_player_spawned.emit(peer_id, player)
    return player

func _free_remote_player(peer_id: int) -> void:
    var player := get_remote_player(peer_id)
    _remote_players.erase(peer_id)
    if player == null: return
    if player.get_parent() != null: player.get_parent().remove_child(player)
    player.free()
    remote_player_removed.emit(peer_id)

static func _to_string_array(values: Variant) -> Array[String]:
    var result: Array[String] = []
    if values is Array:
        for value in values: result.append(str(value))
    return result

static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
