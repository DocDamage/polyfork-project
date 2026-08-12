class_name PlayWorldMultiplayerTemplateContract
extends RefCounted

const MODES: Array[String] = ["coop", "competitive"]
const SPAWN_STRATEGIES: Array[String] = ["offset", "spawn_points"]
const SCORE_MODES: Array[String] = ["none", "player", "team", "objective"]
const MAX_PLAYERS := 16

static func disabled() -> Dictionary:
    return {
        "enabled": false,
        "mode": "coop",
        "min_players": 1,
        "max_players": 1,
        "spawn_strategy": "offset",
        "spawn_spacing": 2.5,
        "teams": [],
        "score_mode": "none",
        "rejoin_allowed": true,
    }

static func normalize(value: Variant) -> Dictionary:
    if not value is Dictionary: return disabled()
    var source: Dictionary = value
    var enabled := bool(source.get("enabled", false))
    var mode := str(source.get("mode", "coop")).strip_edges().to_lower()
    if not MODES.has(mode): mode = "coop"
    var min_players := clampi(int(source.get("min_players", 1)), 1, MAX_PLAYERS)
    var max_players := clampi(int(source.get("max_players", max(2, min_players))), min_players, MAX_PLAYERS)
    if not enabled: min_players = 1; max_players = 1
    var strategy := str(source.get("spawn_strategy", "offset")).strip_edges().to_lower()
    if not SPAWN_STRATEGIES.has(strategy): strategy = "offset"
    var score_mode := str(source.get("score_mode", "none")).strip_edges().to_lower()
    if not SCORE_MODES.has(score_mode): score_mode = "none"
    var teams: Array[String] = []
    var seen: Dictionary = {}
    var team_values = source.get("teams", [])
    if team_values is Array:
        for item in team_values:
            var team := str(item).strip_edges().to_lower()
            if team.is_empty() or seen.has(team): continue
            seen[team] = true
            teams.append(team.left(32))
    return {
        "enabled": enabled,
        "mode": mode,
        "min_players": min_players,
        "max_players": max_players,
        "spawn_strategy": strategy,
        "spawn_spacing": clampf(float(source.get("spawn_spacing", 2.5)), 0.5, 50.0),
        "teams": teams,
        "score_mode": score_mode,
        "rejoin_allowed": bool(source.get("rejoin_allowed", true)),
    }

static func validate(value: Variant) -> Array[String]:
    var errors: Array[String] = []
    if value == null: return errors
    if not value is Dictionary:
        errors.append("Template multiplayer capability must be a dictionary.")
        return errors
    var config: Dictionary = value
    if not config.has("enabled") or not config.get("enabled") is bool: errors.append("Template multiplayer.enabled must be a boolean.")
    var enabled := bool(config.get("enabled", false))
    var mode := str(config.get("mode", ""))
    if not MODES.has(mode): errors.append("Template multiplayer.mode must be coop or competitive.")
    var min_players := int(config.get("min_players", 0))
    var max_players := int(config.get("max_players", 0))
    if min_players < 1 or min_players > MAX_PLAYERS: errors.append("Template multiplayer.min_players is out of range.")
    if max_players < min_players or max_players > MAX_PLAYERS: errors.append("Template multiplayer.max_players is out of range.")
    if enabled and max_players < 2: errors.append("Enabled multiplayer templates must support at least two players.")
    if not enabled and max_players != 1: errors.append("Disabled multiplayer templates must use max_players = 1.")
    var strategy := str(config.get("spawn_strategy", ""))
    if not SPAWN_STRATEGIES.has(strategy): errors.append("Template multiplayer.spawn_strategy is unsupported.")
    var spacing := float(config.get("spawn_spacing", 0.0))
    if spacing < 0.5 or spacing > 50.0: errors.append("Template multiplayer.spawn_spacing must be between 0.5 and 50.0.")
    var score_mode := str(config.get("score_mode", ""))
    if not SCORE_MODES.has(score_mode): errors.append("Template multiplayer.score_mode is unsupported.")
    var teams = config.get("teams", [])
    if not teams is Array:
        errors.append("Template multiplayer.teams must be an array.")
    else:
        var seen: Dictionary = {}
        for item in teams:
            var team := str(item).strip_edges()
            if team.is_empty(): errors.append("Template multiplayer.teams cannot contain blank IDs.")
            elif seen.has(team): errors.append("Template multiplayer.teams cannot contain duplicate IDs.")
            else: seen[team] = true
        if mode == "competitive" and enabled and teams.size() < 2: errors.append("Competitive multiplayer templates must declare at least two teams.")
        if mode == "coop" and score_mode == "team" and teams.is_empty(): errors.append("Team-scored co-op templates must declare at least one team.")
    if not config.has("rejoin_allowed") or not config.get("rejoin_allowed") is bool: errors.append("Template multiplayer.rejoin_allowed must be a boolean.")
    return errors

static func supports_multiplayer(manifest: Dictionary) -> bool:
    return bool(normalize(manifest.get("multiplayer", null)).get("enabled", false))
