class_name PlayWorldGameplayReplicationService
extends Node

signal action_committed(peer_id: int, request_id: String, action: String, result: Dictionary)
signal action_rejected(peer_id: int, request_id: String, action: String, errors: Array[String])
signal replication_error(errors: Array[String])

const Contract = preload("res://src/network/network_session_contract.gd")

const ACTION_DAMAGE := "health.damage"
const ACTION_HEAL := "health.heal"
const ACTION_INTERACT := "interaction.perform"
const ACTION_DOOR_TOGGLE := "interaction.door_toggle"
const SUPPORTED_ACTIONS: Array[String] = [ACTION_DAMAGE, ACTION_HEAL, ACTION_INTERACT, ACTION_DOOR_TOGGLE]

var _adapter
var _gameplay_runtime
var _health_runtime
var _interaction_runtime
var _bound := false
var _request_counter := 0
var _pending_requests: Dictionary = {}

func bind_runtime(adapter, gameplay_runtime, health_runtime, interaction_runtime) -> Dictionary:
    clear()
    if adapter == null or not adapter.has_method("get_role"): return _failure("Gameplay replication requires a network session adapter.")
    if gameplay_runtime == null or not gameplay_runtime.has_method("is_loaded") or not gameplay_runtime.is_loaded(): return _failure("Gameplay replication requires loaded gameplay runtime state.")
    if health_runtime == null or interaction_runtime == null: return _failure("Gameplay replication requires health and interaction runtime services.")
    _adapter = adapter
    _gameplay_runtime = gameplay_runtime
    _health_runtime = health_runtime
    _interaction_runtime = interaction_runtime
    _adapter.message_received.connect(_on_message_received)
    _bound = true
    return {"ok": true, "errors": []}

func clear() -> void:
    if _adapter != null and _adapter.message_received.is_connected(_on_message_received): _adapter.message_received.disconnect(_on_message_received)
    _adapter = null
    _gameplay_runtime = null
    _health_runtime = null
    _interaction_runtime = null
    _bound = false
    _request_counter = 0
    _pending_requests.clear()

func _exit_tree() -> void:
    clear()

func request_action(action: String, payload: Dictionary) -> Dictionary:
    if not _bound or _adapter == null: return _failure("Gameplay replication is not bound.")
    if not SUPPORTED_ACTIONS.has(action): return _failure("Unsupported replicated gameplay action: %s" % action)
    _request_counter += 1
    var request_id := "%d:%d" % [_adapter.get_local_peer_id(), _request_counter]
    if _adapter.get_role() == Contract.ROLE_HOST or _adapter.get_role() == Contract.ROLE_OFFLINE:
        return _commit_host_action(_adapter.get_local_peer_id(), request_id, action, payload)
    _pending_requests[request_id] = {"action": action, "payload": payload.duplicate(true)}
    var send_result: Dictionary = _adapter.send_message(Contract.make_action_request(request_id, action, payload), MultiplayerPeer.TARGET_PEER_SERVER, true)
    if not send_result.get("ok", false):
        _pending_requests.erase(request_id)
        return send_result
    return {"ok": true, "errors": [], "pending": true, "request_id": request_id, "action": action}

func pending_request_count() -> int: return _pending_requests.size()

func _on_message_received(sender_peer_id: int, message: Dictionary) -> void:
    var message_type := str(message.get("message_type", ""))
    if message_type == Contract.MESSAGE_ACTION_REQUEST:
        if _adapter.get_role() != Contract.ROLE_HOST:
            replication_error.emit(["Non-host peer received an authoritative action request."])
            return
        _handle_action_request(sender_peer_id, message)
        return
    if message_type == Contract.MESSAGE_ACTION_RESULT:
        _handle_action_result(sender_peer_id, message)
        return
    if message_type == Contract.MESSAGE_GAMEPLAY_STATE:
        _handle_state_update(sender_peer_id, message)

func _handle_action_request(sender_peer_id: int, message: Dictionary) -> void:
    var payload: Dictionary = message.get("payload", {})
    var request_id := str(payload.get("request_id", ""))
    var action := str(payload.get("action", ""))
    var data: Dictionary = payload.get("data", {})
    if request_id.is_empty() or not SUPPORTED_ACTIONS.has(action):
        _send_rejection(sender_peer_id, request_id, action, ["Replicated gameplay action request is invalid."])
        return
    var authority_errors := _validate_sender_authority(sender_peer_id, action, data)
    if not authority_errors.is_empty():
        _send_rejection(sender_peer_id, request_id, action, authority_errors)
        return
    _commit_host_action(sender_peer_id, request_id, action, data)

func _commit_host_action(peer_id: int, request_id: String, action: String, data: Dictionary) -> Dictionary:
    var result: Dictionary
    match action:
        ACTION_DAMAGE:
            result = _health_runtime.apply_damage(str(data.get("target_entity_id", "")), float(data.get("amount", 0.0)), str(data.get("source_entity_id", "")))
        ACTION_HEAL:
            result = _health_runtime.heal(str(data.get("target_entity_id", "")), float(data.get("amount", 0.0)), str(data.get("source_entity_id", "")))
        ACTION_INTERACT:
            result = _interaction_runtime.interact(str(data.get("actor_entity_id", "")), str(data.get("target_entity_id", "")))
        ACTION_DOOR_TOGGLE:
            result = _interaction_runtime.toggle_door(str(data.get("actor_entity_id", "")), str(data.get("target_entity_id", "")))
        _:
            result = _failure("Unsupported replicated gameplay action: %s" % action)
    if not result.get("ok", false):
        if _adapter.get_role() == Contract.ROLE_HOST and peer_id != _adapter.get_local_peer_id(): _send_rejection(peer_id, request_id, action, _to_string_array(result.get("errors", [])))
        action_rejected.emit(peer_id, request_id, action, _to_string_array(result.get("errors", [])))
        return result
    action_committed.emit(peer_id, request_id, action, result.duplicate(true))
    if _adapter.get_role() == Contract.ROLE_HOST:
        if peer_id != _adapter.get_local_peer_id(): _adapter.send_message(Contract.make_action_result(request_id, action, result), peer_id, true)
        var state_message := _build_state_message(action, data, result)
        if not state_message.is_empty(): _adapter.send_message(state_message, MultiplayerPeer.TARGET_PEER_BROADCAST, true)
    return {"ok": true, "errors": [], "pending": false, "request_id": request_id, "action": action, "result": result.duplicate(true)}

func _validate_sender_authority(peer_id: int, action: String, data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    var identity: Dictionary = _adapter.get_identity_registry().get_identity(peer_id)
    if identity.is_empty():
        errors.append("Replicated gameplay request came from an unregistered peer.")
        return errors
    var owned_entity_id := str(identity.get("authored_entity_id", ""))
    var claimed_actor := ""
    if action == ACTION_INTERACT or action == ACTION_DOOR_TOGGLE: claimed_actor = str(data.get("actor_entity_id", ""))
    elif action == ACTION_DAMAGE or action == ACTION_HEAL: claimed_actor = str(data.get("source_entity_id", ""))
    if not claimed_actor.is_empty():
        if owned_entity_id.is_empty(): errors.append("Peer has no authored gameplay entity ownership for this action.")
        elif claimed_actor != owned_entity_id: errors.append("Peer attempted to act as an authored entity it does not own.")
    if (action == ACTION_DAMAGE or action == ACTION_HEAL) and float(data.get("amount", 0.0)) <= 0.0: errors.append("Replicated health action amount must be positive.")
    return errors

func _send_rejection(peer_id: int, request_id: String, action: String, errors: Array[String]) -> void:
    var result := {"ok": false, "errors": errors.duplicate()}
    _adapter.send_message(Contract.make_action_result(request_id, action, result), peer_id, true)
    action_rejected.emit(peer_id, request_id, action, errors.duplicate())

func _handle_action_result(sender_peer_id: int, message: Dictionary) -> void:
    if _adapter.get_role() != Contract.ROLE_CLIENT or sender_peer_id != MultiplayerPeer.TARGET_PEER_SERVER: return
    var payload: Dictionary = message.get("payload", {})
    var request_id := str(payload.get("request_id", ""))
    var action := str(payload.get("action", ""))
    var result: Dictionary = payload.get("result", {})
    _pending_requests.erase(request_id)
    if result.get("ok", false): action_committed.emit(_adapter.get_local_peer_id(), request_id, action, result.duplicate(true))
    else: action_rejected.emit(_adapter.get_local_peer_id(), request_id, action, _to_string_array(result.get("errors", [])))

func _build_state_message(action: String, data: Dictionary, result: Dictionary) -> Dictionary:
    var state: Dictionary = {"action": action}
    if action == ACTION_DAMAGE or action == ACTION_HEAL:
        var target_id := str(data.get("target_entity_id", ""))
        state["health"] = {"entity_id": target_id, "current_health": float(result.get("current_health", 0.0))}
    elif action == ACTION_DOOR_TOGGLE or (action == ACTION_INTERACT and str(result.get("route", "")) == "door"):
        var door_id := str(result.get("door_entity_id", data.get("target_entity_id", "")))
        state["door"] = {"entity_id": door_id, "open": bool(result.get("open", false))}
    else:
        return {}
    return {
        "protocol_version": Contract.PROTOCOL_VERSION,
        "runtime_contract": Contract.RUNTIME_CONTRACT,
        "message_type": Contract.MESSAGE_GAMEPLAY_STATE,
        "payload": state,
    }

func _handle_state_update(sender_peer_id: int, message: Dictionary) -> void:
    if _adapter.get_role() != Contract.ROLE_CLIENT or sender_peer_id != MultiplayerPeer.TARGET_PEER_SERVER: return
    var payload: Dictionary = message.get("payload", {})
    var health: Dictionary = payload.get("health", {})
    if not health.is_empty():
        var result: Dictionary = _health_runtime.set_health(str(health.get("entity_id", "")), float(health.get("current_health", 0.0)))
        if not result.get("ok", false): replication_error.emit(_to_string_array(result.get("errors", [])))
    var door: Dictionary = payload.get("door", {})
    if not door.is_empty():
        if _interaction_runtime.has_method("set_door_open"):
            var result: Dictionary = _interaction_runtime.set_door_open(str(door.get("entity_id", "")), bool(door.get("open", false)))
            if not result.get("ok", false): replication_error.emit(_to_string_array(result.get("errors", [])))
        elif _interaction_runtime.is_door_open(str(door.get("entity_id", ""))) != bool(door.get("open", false)):
            replication_error.emit(["Client interaction runtime cannot apply authoritative door state."])

static func _to_string_array(values: Variant) -> Array[String]:
    var result: Array[String] = []
    if values is Array:
        for value in values: result.append(str(value))
    return result

static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
