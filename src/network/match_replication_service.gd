class_name PlayWorldMatchReplicationService
extends Node

signal match_state_changed(snapshot: Dictionary)
signal replication_error(errors: Array[String])

const Contract = preload("res://src/network/network_session_contract.gd")

const EVENT_SCORE_ADD := "multiplayer.score.add"
const EVENT_OBJECTIVE_SET := "multiplayer.objective.set"
const EVENT_SESSION_READY := "multiplayer.session.ready"
const EVENT_PEER_JOINED := "multiplayer.peer.joined"
const EVENT_PEER_LEFT := "multiplayer.peer.left"

var _adapter
var _match_state
var _gameplay
var _bound := false
var _suppress_gameplay_events := false

func bind_runtime(adapter, match_state, gameplay_runtime) -> Dictionary:
    clear()
    if adapter == null or not adapter.has_method("is_session_ready") or not adapter.is_session_ready(): return _failure("Match replication requires a ready network session.")
    if match_state == null or not match_state.has_method("snapshot"): return _failure("Match replication requires match state.")
    if gameplay_runtime == null or not gameplay_runtime.has_signal("gameplay_event"): return _failure("Match replication requires loaded gameplay event state.")
    _adapter = adapter
    _match_state = match_state
    _gameplay = gameplay_runtime
    _adapter.message_received.connect(_on_message_received)
    _adapter.peer_joined.connect(_on_peer_joined)
    _adapter.peer_left.connect(_on_peer_left)
    _gameplay.gameplay_event.connect(_on_gameplay_event)
    _bound = true
    _sync_existing_peers()
    _emit_runtime_event(EVENT_SESSION_READY, {"role": _adapter.get_role(), "peer_id": _adapter.get_local_peer_id(), "session_id": _adapter.get_session_id()})
    if _adapter.get_role() == Contract.ROLE_HOST: _broadcast_snapshot()
    return {"ok": true, "errors": [], "snapshot": _match_state.snapshot()}

func clear() -> void:
    if _adapter != null:
        if _adapter.message_received.is_connected(_on_message_received): _adapter.message_received.disconnect(_on_message_received)
        if _adapter.peer_joined.is_connected(_on_peer_joined): _adapter.peer_joined.disconnect(_on_peer_joined)
        if _adapter.peer_left.is_connected(_on_peer_left): _adapter.peer_left.disconnect(_on_peer_left)
    if _gameplay != null and _gameplay.gameplay_event.is_connected(_on_gameplay_event): _gameplay.gameplay_event.disconnect(_on_gameplay_event)
    _adapter = null
    _match_state = null
    _gameplay = null
    _bound = false
    _suppress_gameplay_events = false

func _exit_tree() -> void: clear()

func get_snapshot() -> Dictionary:
    if _match_state == null: return {}
    return _match_state.snapshot()

func _sync_existing_peers() -> void:
    if _adapter == null or _match_state == null: return
    for identity in _adapter.get_identity_registry().snapshot():
        var peer_id: int = int(identity.get("peer_id", 0))
        if peer_id <= 0 or not _match_state.get_player(peer_id).is_empty(): continue
        var result: Dictionary = _match_state.add_player(peer_id, str(identity.get("team_id", "")))
        if not result.get("ok", false): _emit_error(result.get("errors", []))

func _on_peer_joined(identity: Dictionary) -> void:
    if not _bound or _match_state == null: return
    var peer_id: int = int(identity.get("peer_id", 0))
    if peer_id > 0 and _match_state.get_player(peer_id).is_empty():
        var result: Dictionary = _match_state.add_player(peer_id, str(identity.get("team_id", "")))
        if not result.get("ok", false): _emit_error(result.get("errors", [])); return
    _emit_runtime_event(EVENT_PEER_JOINED, {"peer_id": peer_id, "identity": identity.duplicate(true)})
    if _adapter.get_role() == Contract.ROLE_HOST: _broadcast_snapshot()

func _on_peer_left(peer_id: int) -> void:
    if not _bound or _match_state == null: return
    _match_state.remove_player(peer_id)
    _emit_runtime_event(EVENT_PEER_LEFT, {"peer_id": peer_id})
    if _adapter.get_role() == Contract.ROLE_HOST: _broadcast_snapshot()

func _on_gameplay_event(event: Dictionary) -> void:
    if not _bound or _suppress_gameplay_events or _adapter == null or _match_state == null: return
    var kind: String = str(event.get("kind", ""))
    if kind != EVENT_SCORE_ADD and kind != EVENT_OBJECTIVE_SET: return
    if _adapter.get_role() != Contract.ROLE_HOST:
        _emit_error(["Multiplayer score/objective Visual Scripting actions are host-authoritative."])
        return
    var payload: Dictionary = event.get("payload", {})
    var result: Dictionary
    if kind == EVENT_SCORE_ADD:
        result = _match_state.add_score(str(payload.get("subject_id", "")), int(payload.get("amount", 0)))
    else:
        result = _match_state.set_objective(str(payload.get("objective_id", "")), payload.get("value"))
    if not result.get("ok", false): _emit_error(result.get("errors", [])); return
    _broadcast_snapshot()

func _on_message_received(sender_peer_id: int, message: Dictionary) -> void:
    if not _bound or _adapter == null or _match_state == null: return
    if str(message.get("message_type", "")) != Contract.MESSAGE_SCORE_STATE: return
    if _adapter.get_role() != Contract.ROLE_CLIENT: return
    if sender_peer_id != MultiplayerPeer.TARGET_PEER_SERVER:
        _emit_error(["Client rejected match state that did not come from the host authority."])
        return
    var payload: Dictionary = message.get("payload", {})
    var snapshot_value: Variant = payload.get("snapshot", {})
    if not snapshot_value is Dictionary:
        _emit_error(["Host match state snapshot is invalid."])
        return
    var result: Dictionary = _match_state.apply_snapshot(snapshot_value)
    if not result.get("ok", false): _emit_error(result.get("errors", [])); return
    match_state_changed.emit(_match_state.snapshot())

func _broadcast_snapshot() -> void:
    if _adapter == null or _match_state == null or _adapter.get_role() != Contract.ROLE_HOST: return
    var message := {
        "protocol_version": Contract.PROTOCOL_VERSION,
        "runtime_contract": Contract.RUNTIME_CONTRACT,
        "message_type": Contract.MESSAGE_SCORE_STATE,
        "payload": {"snapshot": _match_state.snapshot()},
    }
    var result: Dictionary = _adapter.send_message(message, MultiplayerPeer.TARGET_PEER_BROADCAST, true)
    if not result.get("ok", false): _emit_error(result.get("errors", [])); return
    match_state_changed.emit(_match_state.snapshot())

func _emit_runtime_event(kind: String, payload: Dictionary) -> void:
    if _gameplay == null or not _gameplay.has_method("emit_event"): return
    _suppress_gameplay_events = true
    var result: Dictionary = _gameplay.emit_event(kind, "", "", payload)
    _suppress_gameplay_events = false
    if not result.get("ok", false): _emit_error(result.get("errors", []))

func _emit_error(values: Variant) -> void:
    var errors: Array[String] = []
    if values is Array:
        for value in values: errors.append(str(value))
    if errors.is_empty(): errors.append("Unknown match replication failure.")
    replication_error.emit(errors)

static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
