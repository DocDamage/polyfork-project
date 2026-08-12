class_name PlayWorldNetworkSessionContract
extends RefCounted

const PROTOCOL_VERSION := 1
const RUNTIME_CONTRACT := "polyfork-phase15-v1"

const ROLE_OFFLINE := "offline"
const ROLE_HOST := "host"
const ROLE_CLIENT := "client"
const ROLES: Array[String] = [ROLE_OFFLINE, ROLE_HOST, ROLE_CLIENT]

const DEFAULT_ADDRESS := "127.0.0.1"
const DEFAULT_PORT := 24815
const DEFAULT_MAX_PLAYERS := 4
const MIN_PORT := 1024
const MAX_PORT := 65535
const MIN_PLAYERS := 1
const MAX_PLAYERS := 16

const MESSAGE_HELLO := "session.hello"
const MESSAGE_ACCEPT := "session.accept"
const MESSAGE_REJECT := "session.reject"
const MESSAGE_PEER_JOINED := "session.peer_joined"
const MESSAGE_PEER_LEFT := "session.peer_left"
const MESSAGE_PLAYER_STATE := "player.state"
const MESSAGE_ACTION_REQUEST := "gameplay.action_request"
const MESSAGE_ACTION_RESULT := "gameplay.action_result"
const MESSAGE_GAMEPLAY_STATE := "gameplay.state"
const MESSAGE_SCORE_STATE := "match.score_state"

static func default_config() -> Dictionary:
    return {
        "role": ROLE_OFFLINE,
        "address": DEFAULT_ADDRESS,
        "port": DEFAULT_PORT,
        "max_players": DEFAULT_MAX_PLAYERS,
        "player_label": "Player",
        "team_id": "",
        "session_id": "",
        "project_id": "",
        "runtime_contract": RUNTIME_CONTRACT,
    }

static func normalize_config(config: Dictionary) -> Dictionary:
    var normalized := default_config()
    var role := str(config.get("role", ROLE_OFFLINE)).strip_edges().to_lower()
    normalized["role"] = role if ROLES.has(role) else ROLE_OFFLINE
    var address := str(config.get("address", DEFAULT_ADDRESS)).strip_edges()
    normalized["address"] = DEFAULT_ADDRESS if address.is_empty() else address
    normalized["port"] = clampi(int(config.get("port", DEFAULT_PORT)), MIN_PORT, MAX_PORT)
    normalized["max_players"] = clampi(int(config.get("max_players", DEFAULT_MAX_PLAYERS)), MIN_PLAYERS, MAX_PLAYERS)
    var label := str(config.get("player_label", "Player")).strip_edges()
    normalized["player_label"] = "Player" if label.is_empty() else label.left(48)
    normalized["team_id"] = str(config.get("team_id", "")).strip_edges().left(48)
    normalized["session_id"] = str(config.get("session_id", "")).strip_edges().left(96)
    normalized["project_id"] = str(config.get("project_id", "")).strip_edges().left(128)
    normalized["runtime_contract"] = str(config.get("runtime_contract", RUNTIME_CONTRACT)).strip_edges().left(96)
    return normalized

static func validate_config(config: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    var role := str(config.get("role", "")).strip_edges().to_lower()
    if not ROLES.has(role): errors.append("Network role must be offline, host, or client.")
    var port := int(config.get("port", -1))
    if port < MIN_PORT or port > MAX_PORT: errors.append("Network port must be between %d and %d." % [MIN_PORT, MAX_PORT])
    var max_players := int(config.get("max_players", 0))
    if max_players < MIN_PLAYERS or max_players > MAX_PLAYERS: errors.append("Network max_players must be between %d and %d." % [MIN_PLAYERS, MAX_PLAYERS])
    if role == ROLE_CLIENT and str(config.get("address", "")).strip_edges().is_empty(): errors.append("Client network sessions require an address.")
    if str(config.get("player_label", "")).strip_edges().is_empty(): errors.append("Network player_label cannot be empty.")
    var runtime_contract := str(config.get("runtime_contract", "")).strip_edges()
    if runtime_contract != RUNTIME_CONTRACT: errors.append("Network runtime contract is incompatible: %s" % runtime_contract)
    return errors

static func make_hello(project_id: String, player_label: String, team_id: String = "") -> Dictionary:
    return _message(MESSAGE_HELLO, {
        "protocol_version": PROTOCOL_VERSION,
        "runtime_contract": RUNTIME_CONTRACT,
        "project_id": project_id,
        "player_label": player_label,
        "team_id": team_id,
    })

static func validate_hello(message: Dictionary, expected_project_id: String) -> Array[String]:
    var errors: Array[String] = []
    if str(message.get("message_type", "")) != MESSAGE_HELLO: errors.append("Expected a session hello message.")
    var payload: Dictionary = message.get("payload", {})
    if int(payload.get("protocol_version", -1)) != PROTOCOL_VERSION: errors.append("Network protocol version is incompatible.")
    if str(payload.get("runtime_contract", "")) != RUNTIME_CONTRACT: errors.append("Network runtime contract is incompatible.")
    var project_id := str(payload.get("project_id", ""))
    if not expected_project_id.is_empty() and project_id != expected_project_id: errors.append("Network project identity does not match the host project.")
    if str(payload.get("player_label", "")).strip_edges().is_empty(): errors.append("Joining peer did not provide a player label.")
    return errors

static func make_accept(session_id: String, peer_id: int, identity: Dictionary, peers: Array[Dictionary]) -> Dictionary:
    return _message(MESSAGE_ACCEPT, {
        "protocol_version": PROTOCOL_VERSION,
        "runtime_contract": RUNTIME_CONTRACT,
        "session_id": session_id,
        "peer_id": peer_id,
        "identity": identity.duplicate(true),
        "peers": peers.duplicate(true),
    })

static func make_reject(errors: Array[String]) -> Dictionary:
    return _message(MESSAGE_REJECT, {"errors": errors.duplicate()})

static func make_peer_joined(identity: Dictionary) -> Dictionary:
    return _message(MESSAGE_PEER_JOINED, {"identity": identity.duplicate(true)})

static func make_peer_left(peer_id: int) -> Dictionary:
    return _message(MESSAGE_PEER_LEFT, {"peer_id": peer_id})

static func make_player_state(peer_id: int, authored_entity_id: String, position: Vector3, rotation_y: float, sequence: int) -> Dictionary:
    return _message(MESSAGE_PLAYER_STATE, {
        "peer_id": peer_id,
        "authored_entity_id": authored_entity_id,
        "position": [position.x, position.y, position.z],
        "rotation_y": rotation_y,
        "sequence": sequence,
    })

static func make_action_request(request_id: String, action: String, payload: Dictionary) -> Dictionary:
    return _message(MESSAGE_ACTION_REQUEST, {
        "request_id": request_id,
        "action": action,
        "data": payload.duplicate(true),
    })

static func make_action_result(request_id: String, action: String, result: Dictionary) -> Dictionary:
    return _message(MESSAGE_ACTION_RESULT, {
        "request_id": request_id,
        "action": action,
        "result": result.duplicate(true),
    })

static func encode(message: Dictionary) -> PackedByteArray:
    return JSON.stringify(message).to_utf8_buffer()

static func decode(packet: PackedByteArray) -> Dictionary:
    var parsed: Variant = JSON.parse_string(packet.get_string_from_utf8())
    if not parsed is Dictionary: return {}
    return parsed

static func validate_envelope(message: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if int(message.get("protocol_version", -1)) != PROTOCOL_VERSION: errors.append("Network message protocol version is incompatible.")
    if str(message.get("runtime_contract", "")) != RUNTIME_CONTRACT: errors.append("Network message runtime contract is incompatible.")
    if str(message.get("message_type", "")).is_empty(): errors.append("Network message_type is required.")
    if not message.get("payload", {}) is Dictionary: errors.append("Network message payload must be a Dictionary.")
    return errors

static func _message(message_type: String, payload: Dictionary) -> Dictionary:
    return {
        "protocol_version": PROTOCOL_VERSION,
        "runtime_contract": RUNTIME_CONTRACT,
        "message_type": message_type,
        "payload": payload.duplicate(true),
    }
