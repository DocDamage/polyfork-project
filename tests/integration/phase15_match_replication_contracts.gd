extends RefCounted

const WorldProject = preload("res://src/world/world_project.gd")
const Contract = preload("res://src/network/network_session_contract.gd")
const Adapter = preload("res://src/network/enet_session_adapter.gd")
const MatchState = preload("res://src/network/network_match_state.gd")
const MatchReplication = preload("res://src/network/match_replication_service.gd")
const RuntimeGameplay = preload("res://src/gameplay/runtime_gameplay_state.gd")

static func run_checks(tree: SceneTree) -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new()
    project.initialize_new("Phase 15 Match Replication", &"small", "fps")
    var project_data: Dictionary = project.to_dictionary()
    var gameplay_snapshot: Dictionary = {"definitions": [], "instances": [], "sockets": [], "attachments": [], "dialogues": [], "quests": []}

    var host = Adapter.new()
    var client = Adapter.new()
    tree.root.add_child(host)
    tree.root.add_child(client)
    var port: int = 34200 + int(Time.get_ticks_msec() % 400)
    var host_config: Dictionary = Contract.default_config()
    host_config["role"] = Contract.ROLE_HOST
    host_config["address"] = "*"
    host_config["port"] = port
    host_config["project_id"] = str(project.project_id)
    host_config["session_id"] = "phase15-match-replication"
    host_config["player_label"] = "Host"
    var host_start: Dictionary = host.start_session(host_config)
    if not host_start.get("ok", false):
        _cleanup_nodes([client, host])
        return ["Match replication host failed to start: %s" % str(host_start.get("errors", []))]
    var client_config: Dictionary = Contract.default_config()
    client_config["role"] = Contract.ROLE_CLIENT
    client_config["address"] = "127.0.0.1"
    client_config["port"] = port
    client_config["project_id"] = str(project.project_id)
    client_config["player_label"] = "Client"
    var client_start: Dictionary = client.start_session(client_config)
    if not client_start.get("ok", false):
        _cleanup_nodes([client, host])
        return ["Match replication client failed to start: %s" % str(client_start.get("errors", []))]
    for _index in range(240):
        await tree.process_frame
        if client.is_session_ready() and host.get_peer_count() == 2: break
    if not client.is_session_ready():
        _cleanup_nodes([client, host])
        return ["Match replication client did not complete the compatibility handshake."]

    var capability: Dictionary = {
        "enabled": true,
        "mode": "competitive",
        "min_players": 2,
        "max_players": 4,
        "spawn_strategy": "offset",
        "spawn_spacing": 3.0,
        "teams": ["blue", "orange"],
        "score_mode": "team",
        "rejoin_allowed": true,
    }
    var host_match = MatchState.new()
    var client_match = MatchState.new()
    if not host_match.configure(capability).get("ok", false) or not client_match.configure(capability).get("ok", false): errors.append("Match replication fixture must configure compatible host/client match state.")
    var host_gameplay = RuntimeGameplay.new()
    var client_gameplay = RuntimeGameplay.new()
    if not host_gameplay.initialize(project_data, gameplay_snapshot).get("ok", false): errors.append("Host gameplay event runtime failed to initialize.")
    if not client_gameplay.initialize(project_data, gameplay_snapshot).get("ok", false): errors.append("Client gameplay event runtime failed to initialize.")

    var host_bridge = MatchReplication.new()
    var client_bridge = MatchReplication.new()
    tree.root.add_child(host_bridge)
    tree.root.add_child(client_bridge)
    var host_bind: Dictionary = host_bridge.bind_runtime(host, host_match, host_gameplay)
    var client_bind: Dictionary = client_bridge.bind_runtime(client, client_match, client_gameplay)
    if not host_bind.get("ok", false): errors.append("Host match replication bridge failed to bind: %s" % str(host_bind.get("errors", [])))
    if not client_bind.get("ok", false): errors.append("Client match replication bridge failed to bind: %s" % str(client_bind.get("errors", [])))

    for _index in range(120):
        await tree.process_frame
        if client_match.player_count() == 2: break
    if host_match.player_count() != 2 or client_match.player_count() != 2: errors.append("Host match snapshot must converge peer membership to the client.")
    var host_team: String = str(host_match.get_player(1).get("team_id", ""))
    if host_team.is_empty(): errors.append("Host must receive a deterministic competitive team before score actions.")

    var score_event: Dictionary = host_gameplay.emit_event(MatchReplication.EVENT_SCORE_ADD, "", "", {"subject_id": host_team, "amount": 4})
    if not score_event.get("ok", false): errors.append("Existing Visual Scripting gameplay-event path must accept multiplayer.score.add.")
    for _index in range(180):
        await tree.process_frame
        if client_match.get_score(host_team) == 4: break
    if host_match.get_score(host_team) != 4: errors.append("Host-authoritative multiplayer score event must update host match state.")
    if client_match.get_score(host_team) != 4: errors.append("Host-authoritative match snapshot must converge score state to the client.")

    var client_error := false
    client_bridge.replication_error.connect(func(_values: Array[String]) -> void: client_error = true)
    var client_team: String = str(client_match.get_player(client.get_local_peer_id()).get("team_id", ""))
    client_gameplay.emit_event(MatchReplication.EVENT_SCORE_ADD, "", "", {"subject_id": client_team, "amount": 99})
    await tree.process_frame
    if not client_error: errors.append("Client Visual Scripting score actions must be explicitly rejected as non-authoritative.")
    if host_match.get_score(client_team) == 99: errors.append("Client-side score events must never mutate host-authoritative match state.")

    var event_kinds: Dictionary = {}
    for event in host_gameplay.events_after(0): event_kinds[str(event.get("kind", ""))] = true
    if not event_kinds.has(MatchReplication.EVENT_SESSION_READY): errors.append("Multiplayer session readiness must surface on the reusable gameplay event bus.")
    if not event_kinds.has(MatchReplication.EVENT_SCORE_ADD): errors.append("Multiplayer Visual Scripting score action must remain represented as a gameplay event.")

    host_bridge.clear(); client_bridge.clear()
    _cleanup_nodes([client_bridge, host_bridge])
    host_gameplay.clear(); client_gameplay.clear()
    _cleanup_nodes([client, host])
    return errors

static func _cleanup_nodes(nodes: Array) -> void:
    for node in nodes:
        if node == null or not is_instance_valid(node): continue
        if node.has_method("shutdown"): node.shutdown("cleanup")
        if node.get_parent() != null: node.get_parent().remove_child(node)
        node.free()
