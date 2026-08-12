extends RefCounted

const Contract = preload("res://src/network/network_session_contract.gd")
const Registry = preload("res://src/network/network_identity_registry.gd")
const MatchState = preload("res://src/network/network_match_state.gd")

const CASES := [
    {"name": "Small", "peers": 2},
    {"name": "Medium", "peers": 4},
    {"name": "Large", "peers": 8},
]

static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    for case_value in CASES:
        var case_data: Dictionary = case_value
        var label: String = str(case_data.get("name", ""))
        var peer_count: int = int(case_data.get("peers", 0))
        var registry = Registry.new()
        var begin_result: Dictionary = registry.begin_session("phase15-scale-%s" % label.to_lower())
        if not begin_result.get("ok", false): errors.append("%s network registry failed to initialize." % label); continue
        var match_state = MatchState.new()
        var capability: Dictionary = {
            "enabled": true, "mode": "coop", "min_players": 1, "max_players": peer_count,
            "spawn_strategy": "offset", "spawn_spacing": 2.5, "teams": [], "score_mode": "objective", "rejoin_allowed": true,
        }
        if not match_state.configure(capability).get("ok", false): errors.append("%s match state failed to configure." % label); continue
        var total_packet_bytes := 0
        for peer_id in range(1, peer_count + 1):
            var identity_result: Dictionary = registry.register_peer(peer_id, "Player %d" % peer_id)
            if not identity_result.get("ok", false): errors.append("%s failed to register peer %d." % [label, peer_id]); continue
            var player_result: Dictionary = match_state.add_player(peer_id)
            if not player_result.get("ok", false): errors.append("%s failed to add match peer %d." % [label, peer_id])
            var packet: PackedByteArray = Contract.encode(Contract.make_player_state(peer_id, "", Vector3(float(peer_id), 2.0, float(peer_id) * 1.5), 0.1 * peer_id, peer_id))
            total_packet_bytes += packet.size()
        if registry.peer_count() != peer_count: errors.append("%s registry did not retain all bounded peers." % label)
        if match_state.player_count() != peer_count: errors.append("%s match snapshot did not retain all bounded peers." % label)
        if match_state.snapshot().get("players", []).size() != peer_count: errors.append("%s serialized match membership is incomplete." % label)
        if total_packet_bytes <= 0 or total_packet_bytes > peer_count * 1024: errors.append("%s player-state packet budget is unexpectedly large." % label)
        if peer_count > 1 and match_state.spawn_offset_for_peer(peer_count) == Vector3.ZERO: errors.append("%s additional peers must receive deterministic spawn separation." % label)
        if match_state.add_player(peer_count + 1).get("ok", true): errors.append("%s match must enforce its declared player limit." % label)
        registry.clear(); match_state.clear()
    return errors
