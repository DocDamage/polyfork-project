class_name PlayWorldNetworkMatchState
extends RefCounted

const TemplateContract = preload("res://src/network/multiplayer_template_contract.gd")

var _config: Dictionary = TemplateContract.disabled()
var _players: Dictionary = {}
var _scores: Dictionary = {}
var _objective_state: Dictionary = {}

func configure(config: Dictionary) -> Dictionary:
    var errors: Array[String] = TemplateContract.validate(config)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    clear()
    _config = TemplateContract.normalize(config)
    for team in _config.get("teams", []): _scores[str(team)] = 0
    return {"ok": true, "errors": [], "config": _config.duplicate(true)}

func clear() -> void:
    _config = TemplateContract.disabled()
    _players.clear()
    _scores.clear()
    _objective_state.clear()

func add_player(peer_id: int, team_id: String = "") -> Dictionary:
    if peer_id <= 0: return _failure("Match player peer ID must be positive.")
    if _players.has(peer_id): return _failure("Match player is already registered: %d" % peer_id)
    if _players.size() >= int(_config.get("max_players", 1)): return _failure("Match is at its declared player limit.")
    var resolved_team: String = team_id.strip_edges()
    var teams: Array = _config.get("teams", [])
    if resolved_team.is_empty() and not teams.is_empty(): resolved_team = _least_populated_team(teams)
    if not resolved_team.is_empty() and not teams.has(resolved_team): return _failure("Match team is not declared by the template: %s" % resolved_team)
    _players[peer_id] = {"peer_id": peer_id, "team_id": resolved_team, "joined_order": _players.size()}
    if str(_config.get("score_mode", "none")) == "player": _scores[str(peer_id)] = 0
    return {"ok": true, "errors": [], "player": _players[peer_id].duplicate(true)}

func remove_player(peer_id: int) -> Dictionary:
    if not _players.has(peer_id): return {"ok": true, "errors": [], "removed": false}
    var player: Dictionary = _players[peer_id].duplicate(true)
    _players.erase(peer_id)
    if str(_config.get("score_mode", "none")) == "player": _scores.erase(str(peer_id))
    return {"ok": true, "errors": [], "removed": true, "player": player}

func set_team(peer_id: int, team_id: String) -> Dictionary:
    if not _players.has(peer_id): return _failure("Match player is not registered: %d" % peer_id)
    var teams: Array = _config.get("teams", [])
    if not teams.has(team_id): return _failure("Match team is not declared by the template: %s" % team_id)
    var player: Dictionary = _players[peer_id].duplicate(true)
    player["team_id"] = team_id
    _players[peer_id] = player
    return {"ok": true, "errors": [], "player": player.duplicate(true)}

func add_score(subject_id: String, amount: int) -> Dictionary:
    if amount == 0: return _failure("Score change must be non-zero.")
    var score_mode: String = str(_config.get("score_mode", "none"))
    if score_mode == "none": return _failure("This multiplayer template does not use score state.")
    var key: String = subject_id.strip_edges()
    if key.is_empty(): return _failure("Score subject ID is required.")
    if score_mode == "team" and not _config.get("teams", []).has(key): return _failure("Team score subject is not declared by the template.")
    if score_mode == "player" and not _players.has(int(key)): return _failure("Player score subject is not registered in the match.")
    _scores[key] = int(_scores.get(key, 0)) + amount
    return {"ok": true, "errors": [], "subject_id": key, "score": int(_scores[key])}

func set_objective(objective_id: String, value: Variant) -> Dictionary:
    if str(_config.get("score_mode", "none")) != "objective": return _failure("This multiplayer template does not use objective score state.")
    var key: String = objective_id.strip_edges()
    if key.is_empty(): return _failure("Objective ID is required.")
    _objective_state[key] = value
    return {"ok": true, "errors": [], "objective_id": key, "value": value}

func spawn_offset_for_peer(peer_id: int) -> Vector3:
    if not _players.has(peer_id): return Vector3.ZERO
    if str(_config.get("spawn_strategy", "offset")) != "offset": return Vector3.ZERO
    var order: int = int(_players[peer_id].get("joined_order", 0))
    if order <= 0: return Vector3.ZERO
    var spacing: float = float(_config.get("spawn_spacing", 2.5))
    var ring: int = int(ceil(sqrt(float(order))))
    var slot: int = order - ((ring - 1) * (ring - 1))
    var edge: int = maxi(1, ring * 2)
    var x: float = float((slot % edge) - ring) * spacing
    var z: float = float((slot / edge) - ring) * spacing
    return Vector3(x, 0.0, z)

func get_player(peer_id: int) -> Dictionary:
    return _players.get(peer_id, {}).duplicate(true)

func get_score(subject_id: String) -> int:
    return int(_scores.get(subject_id, 0))

func player_count() -> int: return _players.size()
func minimum_players_met() -> bool: return _players.size() >= int(_config.get("min_players", 1))

func snapshot() -> Dictionary:
    var players: Array[Dictionary] = []
    var ids: Array[int] = []
    for value in _players.keys(): ids.append(int(value))
    ids.sort()
    for peer_id in ids: players.append(_players[peer_id].duplicate(true))
    var scores: Dictionary = _scores.duplicate(true)
    return {"config": _config.duplicate(true), "players": players, "scores": scores, "objectives": _objective_state.duplicate(true)}

func _least_populated_team(teams: Array) -> String:
    var best: String = str(teams[0])
    var best_count := 2147483647
    for team_value in teams:
        var team: String = str(team_value)
        var count := 0
        for player in _players.values():
            if str(player.get("team_id", "")) == team: count += 1
        if count < best_count:
            best_count = count
            best = team
    return best

static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
