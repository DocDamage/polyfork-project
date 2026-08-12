class_name PlayWorldNetworkIdentityRegistry
extends RefCounted

var _session_id := ""
var _identities_by_peer: Dictionary = {}
var _peer_by_network_id: Dictionary = {}
var _peer_by_entity_id: Dictionary = {}

func begin_session(session_id: String) -> Dictionary:
    clear()
    var normalized := session_id.strip_edges()
    if normalized.is_empty(): return _failure("Network identity registry requires a session ID.")
    _session_id = normalized
    return {"ok": true, "errors": [], "session_id": _session_id}

func clear() -> void:
    _session_id = ""
    _identities_by_peer.clear()
    _peer_by_network_id.clear()
    _peer_by_entity_id.clear()

func is_active() -> bool: return not _session_id.is_empty()
func get_session_id() -> String: return _session_id

func register_peer(peer_id: int, player_label: String, team_id: String = "", authored_entity_id: String = "", network_id: String = "") -> Dictionary:
    if not is_active(): return _failure("Network identity registry has no active session.")
    if peer_id <= 0: return _failure("Network peer ID must be positive.")
    if _identities_by_peer.has(peer_id): return _failure("Network peer ID is already registered: %d" % peer_id)
    var label := player_label.strip_edges()
    if label.is_empty(): return _failure("Network player label cannot be empty.")
    var resolved_network_id := network_id.strip_edges()
    if resolved_network_id.is_empty(): resolved_network_id = "%s:peer:%d" % [_session_id, peer_id]
    if _peer_by_network_id.has(resolved_network_id): return _failure("Network identity is already registered: %s" % resolved_network_id)
    var entity_id := authored_entity_id.strip_edges()
    if not entity_id.is_empty() and _peer_by_entity_id.has(entity_id): return _failure("Authored entity is already owned by another network peer: %s" % entity_id)
    var identity := {
        "session_id": _session_id,
        "peer_id": peer_id,
        "network_id": resolved_network_id,
        "player_label": label.left(48),
        "team_id": team_id.strip_edges().left(48),
        "authored_entity_id": entity_id,
    }
    _identities_by_peer[peer_id] = identity
    _peer_by_network_id[resolved_network_id] = peer_id
    if not entity_id.is_empty(): _peer_by_entity_id[entity_id] = peer_id
    return {"ok": true, "errors": [], "identity": identity.duplicate(true)}

func assign_authored_entity(peer_id: int, authored_entity_id: String) -> Dictionary:
    if not _identities_by_peer.has(peer_id): return _failure("Network peer is not registered: %d" % peer_id)
    var entity_id := authored_entity_id.strip_edges()
    if entity_id.is_empty(): return _failure("Authored entity ID cannot be empty.")
    if _peer_by_entity_id.has(entity_id) and int(_peer_by_entity_id[entity_id]) != peer_id:
        return _failure("Authored entity is already owned by another network peer: %s" % entity_id)
    var identity: Dictionary = _identities_by_peer[peer_id].duplicate(true)
    var previous := str(identity.get("authored_entity_id", ""))
    if not previous.is_empty(): _peer_by_entity_id.erase(previous)
    identity["authored_entity_id"] = entity_id
    _identities_by_peer[peer_id] = identity
    _peer_by_entity_id[entity_id] = peer_id
    return {"ok": true, "errors": [], "identity": identity.duplicate(true)}

func remove_peer(peer_id: int) -> Dictionary:
    if not _identities_by_peer.has(peer_id): return {"ok": true, "errors": [], "removed": false}
    var identity: Dictionary = _identities_by_peer[peer_id]
    _identities_by_peer.erase(peer_id)
    _peer_by_network_id.erase(str(identity.get("network_id", "")))
    var entity_id := str(identity.get("authored_entity_id", ""))
    if not entity_id.is_empty(): _peer_by_entity_id.erase(entity_id)
    return {"ok": true, "errors": [], "removed": true, "identity": identity.duplicate(true)}

func has_peer(peer_id: int) -> bool: return _identities_by_peer.has(peer_id)
func has_entity_owner(authored_entity_id: String) -> bool: return _peer_by_entity_id.has(authored_entity_id)

func get_identity(peer_id: int) -> Dictionary:
    if not _identities_by_peer.has(peer_id): return {}
    return _identities_by_peer[peer_id].duplicate(true)

func peer_for_entity(authored_entity_id: String) -> int:
    return int(_peer_by_entity_id.get(authored_entity_id, 0))

func peer_count() -> int: return _identities_by_peer.size()

func snapshot() -> Array[Dictionary]:
    var peer_ids: Array[int] = []
    for value in _identities_by_peer.keys(): peer_ids.append(int(value))
    peer_ids.sort()
    var result: Array[Dictionary] = []
    for peer_id in peer_ids: result.append(get_identity(peer_id))
    return result

static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
