class_name PlayWorldNetworkRuntimeService
extends Node

signal status_changed(status: Dictionary)
signal peer_count_changed(count: int)
signal network_error(errors: Array[String])
signal multiplayer_action_committed(action: String, result: Dictionary)
signal multiplayer_action_rejected(action: String, errors: Array[String])

const Contract = preload("res://src/network/network_session_contract.gd")
const TemplateContract = preload("res://src/network/multiplayer_template_contract.gd")
const Adapter = preload("res://src/network/enet_session_adapter.gd")
const PlayerReplication = preload("res://src/network/player_replication_service.gd")
const GameplayReplication = preload("res://src/network/gameplay_replication_service.gd")
const MatchState = preload("res://src/network/network_match_state.gd")

var _desired_config: Dictionary = Contract.default_config()
var _play_session: Node
var _adapter: Node
var _player_replication: Node
var _gameplay_replication: Node
var _match_state = MatchState.new()
var _last_status_key := ""
var _scan_elapsed := 0.0
var _replication_bound := false
var _last_error: Array[String] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_process(true)

func _process(delta: float) -> void:
    _scan_elapsed += delta
    if _scan_elapsed < 0.1: return
    _scan_elapsed = 0.0
    var active_session := _find_active_play_session(get_tree().root)
    if active_session != _play_session:
        _detach_runtime("play_session_changed")
        _play_session = active_session
    if _play_session == null:
        _emit_status_if_changed()
        return
    var role := str(_desired_config.get("role", Contract.ROLE_OFFLINE))
    if role == Contract.ROLE_OFFLINE:
        if _adapter != null: _teardown_network("offline_mode")
        _emit_status_if_changed()
        return
    if _adapter == null:
        _start_for_play_session()
        return
    if _adapter.is_session_ready() and not _replication_bound:
        _bind_runtime_services()
    _emit_status_if_changed()

func configure_session(config: Dictionary) -> Dictionary:
    var normalized: Dictionary = Contract.normalize_config(config)
    var errors: Array[String] = Contract.validate_config(normalized)
    if not errors.is_empty(): return _failure(errors)
    var capability := current_multiplayer_capability()
    if str(normalized.get("role", Contract.ROLE_OFFLINE)) != Contract.ROLE_OFFLINE:
        if _play_session != null and not bool(capability.get("enabled", false)):
            return _failure(["The active template does not declare multiplayer support."])
        if bool(capability.get("enabled", false)):
            normalized["max_players"] = mini(int(normalized.get("max_players", Contract.DEFAULT_MAX_PLAYERS)), int(capability.get("max_players", Contract.DEFAULT_MAX_PLAYERS)))
    var changed := normalized != _desired_config
    _desired_config = normalized
    _last_error.clear()
    if changed and _adapter != null: _teardown_network("configuration_changed")
    _emit_status_if_changed(true)
    return {"ok": true, "errors": [], "config": _desired_config.duplicate(true), "changed": changed}

func set_offline() -> Dictionary:
    var config := _desired_config.duplicate(true)
    config["role"] = Contract.ROLE_OFFLINE
    return configure_session(config)

func host(port: int = Contract.DEFAULT_PORT, player_label: String = "Host") -> Dictionary:
    var config := _desired_config.duplicate(true)
    config["role"] = Contract.ROLE_HOST
    config["address"] = "*"
    config["port"] = port
    config["player_label"] = player_label
    return configure_session(config)

func join(address: String, port: int = Contract.DEFAULT_PORT, player_label: String = "Player") -> Dictionary:
    var config := _desired_config.duplicate(true)
    config["role"] = Contract.ROLE_CLIENT
    config["address"] = address
    config["port"] = port
    config["player_label"] = player_label
    return configure_session(config)

func stop_session() -> Dictionary:
    var result := set_offline()
    if _adapter != null: _teardown_network("user_stop")
    return result

func get_configuration() -> Dictionary: return _desired_config.duplicate(true)

func get_status() -> Dictionary:
    var status := {
        "role": str(_desired_config.get("role", Contract.ROLE_OFFLINE)),
        "state": "build" if _play_session == null else "play_offline",
        "ready": false,
        "session_id": "",
        "local_peer_id": 0,
        "peer_count": 0,
        "peers": [],
        "last_error": _last_error.duplicate(),
        "capability": current_multiplayer_capability(),
        "replication_bound": _replication_bound,
    }
    if _adapter != null:
        var adapter_status: Dictionary = _adapter.get_status()
        status["ready"] = bool(adapter_status.get("ready", false))
        status["session_id"] = str(adapter_status.get("session_id", ""))
        status["local_peer_id"] = int(adapter_status.get("local_peer_id", 0))
        status["peer_count"] = int(adapter_status.get("peer_count", 0))
        status["peers"] = adapter_status.get("peers", []).duplicate(true)
        if not adapter_status.get("last_error", []).is_empty(): status["last_error"] = adapter_status.get("last_error", []).duplicate()
        status["state"] = "connected" if bool(adapter_status.get("ready", false)) else "connecting"
    return status

func current_multiplayer_capability() -> Dictionary:
    var project_data := _current_project_data()
    if project_data.is_empty(): return TemplateContract.disabled()
    var runtime: Dictionary = project_data.get("runtime", {})
    return TemplateContract.normalize(runtime.get("multiplayer", null))

func get_match_snapshot() -> Dictionary:
    return _match_state.snapshot()

func request_gameplay_action(action: String, payload: Dictionary) -> Dictionary:
    if _gameplay_replication == null or not _replication_bound: return _failure(["Multiplayer gameplay replication is not ready."])
    return _gameplay_replication.request_action(action, payload)

func get_remote_player(peer_id: int):
    if _player_replication == null: return null
    return _player_replication.get_remote_player(peer_id)

func _start_for_play_session() -> void:
    var project_data := _current_project_data()
    if project_data.is_empty():
        _record_error(["Active Play session does not expose runtime project data."])
        return
    var capability := TemplateContract.normalize(project_data.get("runtime", {}).get("multiplayer", null))
    if not bool(capability.get("enabled", false)):
        _record_error(["This project template does not declare multiplayer support."])
        return
    var config := _desired_config.duplicate(true)
    config["project_id"] = str(project_data.get("project_id", ""))
    config["max_players"] = mini(int(config.get("max_players", Contract.DEFAULT_MAX_PLAYERS)), int(capability.get("max_players", Contract.DEFAULT_MAX_PLAYERS)))
    _adapter = Adapter.new()
    _adapter.name = "NetworkSessionAdapter"
    add_child(_adapter)
    _adapter.session_ready.connect(_on_session_ready)
    _adapter.session_stopped.connect(_on_session_stopped)
    _adapter.peer_joined.connect(_on_peer_joined)
    _adapter.peer_left.connect(_on_peer_left)
    _adapter.session_error.connect(_on_adapter_error)
    var start_result: Dictionary = _adapter.start_session(config)
    if not start_result.get("ok", false):
        _record_error(_strings(start_result.get("errors", [])))
        _teardown_network("start_failed")
        return
    if _adapter.is_session_ready(): _bind_runtime_services()
    _emit_status_if_changed(true)

func _bind_runtime_services() -> void:
    if _play_session == null or _adapter == null or not _adapter.is_session_ready(): return
    var project_data := _current_project_data()
    var runtime: Dictionary = project_data.get("runtime", {})
    var capability := TemplateContract.normalize(runtime.get("multiplayer", null))
    var match_result: Dictionary = _match_state.configure(capability)
    if not match_result.get("ok", false):
        _record_error(_strings(match_result.get("errors", [])))
        return
    for identity in _adapter.get_identity_registry().snapshot():
        var peer_id := int(identity.get("peer_id", 0))
        if peer_id > 0: _match_state.add_player(peer_id, str(identity.get("team_id", "")))
    var local_peer_id := _adapter.get_local_peer_id()
    var spawn_entity_id := str(runtime.get("spawn_entity_id", ""))
    if local_peer_id == 1 and not spawn_entity_id.is_empty(): _adapter.get_identity_registry().assign_authored_entity(local_peer_id, spawn_entity_id)

    var local_player = _play_session.get_player()
    if local_player != null and is_instance_valid(local_player):
        var camera_config: Dictionary = runtime.get("camera_configuration", {}).duplicate(true)
        var controller_kind := str(camera_config.get("controller", "none"))
        _player_replication = PlayerReplication.new()
        _player_replication.name = "PlayerReplication"
        add_child(_player_replication)
        _player_replication.remote_player_spawned.connect(_on_remote_player_spawned)
        _player_replication.replication_error.connect(_record_error)
        var player_result: Dictionary = _player_replication.bind_runtime(_adapter, _play_session, local_player, controller_kind, camera_config)
        if not player_result.get("ok", false):
            _record_error(_strings(player_result.get("errors", [])))
            return
        local_player.global_position += _match_state.spawn_offset_for_peer(local_peer_id)

    var gameplay = _play_session.get_gameplay_runtime()
    var health = _play_session.get_health_runtime()
    var interaction = _play_session.get_interaction_runtime()
    if gameplay != null and health != null and interaction != null:
        _gameplay_replication = GameplayReplication.new()
        _gameplay_replication.name = "GameplayReplication"
        add_child(_gameplay_replication)
        _gameplay_replication.replication_error.connect(_record_error)
        _gameplay_replication.action_committed.connect(_on_action_committed)
        _gameplay_replication.action_rejected.connect(_on_action_rejected)
        var gameplay_result: Dictionary = _gameplay_replication.bind_runtime(_adapter, gameplay, health, interaction)
        if not gameplay_result.get("ok", false):
            _record_error(_strings(gameplay_result.get("errors", [])))
            return
    _replication_bound = true
    _emit_status_if_changed(true)

func _on_session_ready(_role: String, _session_id: String, _local_peer_id: int) -> void:
    _replication_bound = false
    _emit_status_if_changed(true)

func _on_session_stopped(reason: String) -> void:
    if reason == "host_disconnected": _record_error(["Multiplayer host disconnected."])
    _replication_bound = false
    _emit_status_if_changed(true)

func _on_peer_joined(identity: Dictionary) -> void:
    var peer_id := int(identity.get("peer_id", 0))
    if peer_id > 0 and _match_state.get_player(peer_id).is_empty(): _match_state.add_player(peer_id, str(identity.get("team_id", "")))
    peer_count_changed.emit(_adapter.get_peer_count() if _adapter != null else 0)
    _emit_status_if_changed(true)

func _on_peer_left(peer_id: int) -> void:
    _match_state.remove_player(peer_id)
    peer_count_changed.emit(_adapter.get_peer_count() if _adapter != null else 0)
    _emit_status_if_changed(true)

func _on_remote_player_spawned(peer_id: int, player: CharacterBody3D) -> void:
    var offset := _match_state.spawn_offset_for_peer(peer_id)
    if player != null: player.global_position += offset

func _on_adapter_error(errors: Array[String]) -> void:
    _record_error(errors)

func _on_action_committed(_peer_id: int, _request_id: String, action: String, result: Dictionary) -> void:
    multiplayer_action_committed.emit(action, result.duplicate(true))

func _on_action_rejected(_peer_id: int, _request_id: String, action: String, errors: Array[String]) -> void:
    multiplayer_action_rejected.emit(action, errors.duplicate())

func _detach_runtime(reason: String) -> void:
    _teardown_network(reason)
    _play_session = null
    _match_state.clear()
    _emit_status_if_changed(true)

func _teardown_network(reason: String) -> void:
    _replication_bound = false
    if _gameplay_replication != null:
        _gameplay_replication.clear()
        remove_child(_gameplay_replication)
        _gameplay_replication.free()
        _gameplay_replication = null
    if _player_replication != null:
        _player_replication.clear()
        remove_child(_player_replication)
        _player_replication.free()
        _player_replication = null
    if _adapter != null:
        _adapter.shutdown(reason)
        remove_child(_adapter)
        _adapter.free()
        _adapter = null
    _match_state.clear()

func _current_project_data() -> Dictionary:
    if _play_session == null or not _play_session.has_method("get_runtime_state"): return {}
    var runtime_state = _play_session.get_runtime_state()
    if runtime_state == null or not runtime_state.has_method("get_project_data"): return {}
    return runtime_state.get_project_data()

func _find_active_play_session(node: Node) -> Node:
    for child in node.get_children():
        if child.has_method("is_active") and child.has_method("get_runtime_state") and child.has_method("get_player") and bool(child.is_active()): return child
        var nested := _find_active_play_session(child)
        if nested != null: return nested
    return null

func _record_error(errors: Array[String]) -> void:
    if errors.is_empty(): return
    _last_error = errors.duplicate()
    network_error.emit(_last_error.duplicate())
    _emit_status_if_changed(true)

func _emit_status_if_changed(force: bool = false) -> void:
    var status := get_status()
    var key := JSON.stringify(status)
    if not force and key == _last_status_key: return
    _last_status_key = key
    status_changed.emit(status)

static func _strings(values: Variant) -> Array[String]:
    var result: Array[String] = []
    if values is Array:
        for value in values: result.append(str(value))
    return result

static func _failure(errors: Array[String]) -> Dictionary:
    return {"ok": false, "errors": errors.duplicate()}
