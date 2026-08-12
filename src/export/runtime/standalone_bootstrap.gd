class_name PlayWorldStandaloneBootstrap
extends Node3D

const Loader = preload("res://src/export/runtime/standalone_data_loader.gd")
const AssetResolver = preload("res://src/export/runtime/standalone_asset_resolver.gd")
const SessionAdapter = preload("res://src/export/runtime/standalone_session_adapter.gd")
const PlaySession = preload("res://src/runtime/play_session.gd")
const TerrainRuntime = preload("res://src/terrain/terrain_runtime.gd")
const ProceduralRuntime = preload("res://src/procedural/procedural_runtime.gd")
const GameplayInput = preload("res://src/input/gameplay_input_map.gd")

var _bundle: Dictionary = {}
var _adapter
var _assets
var _terrain_runtime
var _procedural_runtime
var _play_session
var _network_runtime

func _ready() -> void:
    var result: Dictionary = start_runtime()
    if not result.get("ok", false):
        push_error("Standalone runtime failed: %s" % str(result.get("errors", [])))
        get_tree().quit(1)
        return
    var input_result: Dictionary = _verify_input_contract()
    if not input_result.get("ok", false):
        push_error("Standalone runtime input verification failed: %s" % str(input_result.get("errors", [])))
        get_tree().quit(1)
        return
    print("Polyfork standalone runtime started. project=%s entities=%d controller=%s preset=%s" % [str(_bundle.get("project_data", {}).get("project_id", "")), int(result.get("entity_count", 0)), str(result.get("controller", "")), str(result.get("performance_preset", _bundle.get("performance_profile", {}).get("preset_id", "balanced")))])
    print("Polyfork standalone input verified. keyboard_mouse=%s gamepad=%s" % [str(input_result.get("keyboard_mouse", false)), str(input_result.get("gamepad", false))])
    if OS.get_environment("POLYFORK_MULTIPLAYER_SMOKE") == "1":
        call_deferred("_run_multiplayer_smoke")
        return
    if OS.get_environment("POLYFORK_EXPORT_SMOKE") == "1":
        print("PASS: Phase 13 standalone export runtime smoke completed.")
        get_tree().quit(0)

func start_runtime() -> Dictionary:
    var manifest_read: Dictionary = _read_json("res://export_manifest.json")
    if not manifest_read.get("ok", false): return manifest_read
    _bundle = Loader.load_bundle()
    if not _bundle.get("ok", false): return _bundle
    _assets = AssetResolver.new()
    var asset_bind: Dictionary = _assets.bind_manifest(manifest_read.get("data", {}), _bundle.get("gameplay_state"))
    if not asset_bind.get("ok", false): return asset_bind
    _adapter = SessionAdapter.new()
    add_child(_adapter)
    var adapter_bind: Dictionary = _adapter.bind_project(_bundle.get("project_data", {}), Callable(_assets, "instantiate_asset_scene"))
    if not adapter_bind.get("ok", false): return adapter_bind
    _terrain_runtime = TerrainRuntime.new()
    add_child(_terrain_runtime)
    var terrain_bind: Dictionary = _terrain_runtime.bind_state(_bundle.get("terrain_state"))
    if not terrain_bind.get("ok", false): return terrain_bind
    var initial_cells: Array[String] = _terrain_runtime.get_loaded_cell_ids()
    var entity_stream: Dictionary = _adapter.set_active_cell_ids(initial_cells)
    if not entity_stream.get("ok", false): return entity_stream
    _procedural_runtime = ProceduralRuntime.new()
    add_child(_procedural_runtime)
    var procedural_bind: Dictionary = _procedural_runtime.bind_state(_bundle.get("procedural_state"), _bundle.get("terrain_state"), _terrain_runtime, _assets)
    if not procedural_bind.get("ok", false): return procedural_bind
    var profile_value: Variant = _bundle.get("performance_profile", {})
    if profile_value is Dictionary and not profile_value.is_empty():
        var quality_result: Dictionary = _procedural_runtime.configure_performance_profile(profile_value)
        if not quality_result.get("ok", false): return quality_result
    _play_session = PlaySession.new()
    add_child(_play_session)
    if profile_value is Dictionary and not profile_value.is_empty():
        var play_profile_result: Dictionary = _play_session.configure_performance_profile(profile_value)
        if not play_profile_result.get("ok", false): return play_profile_result
    _play_session.configure_project_directory("user://polyfork_runtime/%s" % str(_bundle.get("project_data", {}).get("project_id", "unknown")))
    _play_session.configure_visual_graph_provider(Callable(self, "_visual_graphs"))
    _play_session.configure_gameplay_state_provider(Callable(self, "_gameplay_snapshot"))
    _play_session.configure_environment_state_provider(Callable(self, "_environment_bundle"))
    _play_session.configure_streaming(Callable(self, "_update_streaming"))
    _play_session.exit_requested.connect(_on_exit_requested)
    var play_result: Dictionary = _play_session.enter_play(_adapter)
    if not play_result.get("ok", false): return play_result
    var multiplayer_result: Dictionary = _start_multiplayer_from_environment()
    if not multiplayer_result.get("ok", false):
        _play_session.exit_play()
        return multiplayer_result
    play_result["multiplayer"] = multiplayer_result
    return play_result

func _start_multiplayer_from_environment() -> Dictionary:
    var role: String = OS.get_environment("POLYFORK_MULTIPLAYER_ROLE").strip_edges().to_lower()
    if role.is_empty() or role == "offline": return {"ok": true, "errors": [], "active": false, "role": "offline"}
    if role != "host" and role != "client": return _failure("Standalone multiplayer role must be host, client, or offline.")
    var project_data: Dictionary = _bundle.get("project_data", {})
    var runtime: Dictionary = project_data.get("runtime", {}) if project_data.get("runtime", {}) is Dictionary else {}
    var capability: Dictionary = runtime.get("multiplayer", {}) if runtime.get("multiplayer", {}) is Dictionary else {}
    if not bool(capability.get("enabled", false)): return _failure("This exported project does not declare multiplayer capability.")
    var runtime_path: String = "res://src/network/" + "network_runtime_service.gd"
    var runtime_script: Script = load(runtime_path)
    if runtime_script == null: return _failure("Multiplayer runtime dependency closure could not be loaded from this export.")
    _network_runtime = runtime_script.new()
    _network_runtime.name = "StandaloneNetworkRuntime"
    add_child(_network_runtime)
    var port_text: String = OS.get_environment("POLYFORK_MULTIPLAYER_PORT").strip_edges()
    var port: int = int(port_text) if not port_text.is_empty() else 24815
    var player_label: String = OS.get_environment("POLYFORK_MULTIPLAYER_PLAYER").strip_edges()
    if player_label.is_empty(): player_label = "Host" if role == "host" else "Client"
    var result: Dictionary
    if role == "host":
        result = _network_runtime.host(port, player_label)
    else:
        var address: String = OS.get_environment("POLYFORK_MULTIPLAYER_ADDRESS").strip_edges()
        if address.is_empty(): address = "127.0.0.1"
        result = _network_runtime.join(address, port, player_label)
    if not result.get("ok", false): return result
    return {"ok": true, "errors": [], "active": true, "role": role, "port": port}

func _run_multiplayer_smoke() -> void:
    if _network_runtime == null:
        push_error("Phase 15 multiplayer smoke requested without an active network runtime.")
        get_tree().quit(1)
        return
    var expected_text: String = OS.get_environment("POLYFORK_MULTIPLAYER_EXPECTED_PEERS").strip_edges()
    var expected_peers: int = maxi(2, int(expected_text) if not expected_text.is_empty() else 2)
    var ready := false
    var remote_input_disabled := false
    for _index in range(900):
        await get_tree().process_frame
        var status: Dictionary = _network_runtime.get_status()
        if not bool(status.get("ready", false)) or not bool(status.get("replication_bound", false)) or int(status.get("peer_count", 0)) < expected_peers: continue
        var local_peer_id: int = int(status.get("local_peer_id", 0))
        for identity in status.get("peers", []):
            var peer_id: int = int(identity.get("peer_id", 0))
            if peer_id <= 0 or peer_id == local_peer_id: continue
            var remote = _network_runtime.get_remote_player(peer_id)
            if remote != null and is_instance_valid(remote):
                remote_input_disabled = not remote.has_method("is_local_input_enabled") or not bool(remote.is_local_input_enabled())
                if remote_input_disabled: break
        var local_player = _play_session.get_player()
        var local_input_ok: bool = local_player != null and (not local_player.has_method("is_local_input_enabled") or bool(local_player.is_local_input_enabled()))
        if local_input_ok and remote_input_disabled:
            ready = true
            break
    if not ready:
        push_error("Phase 15 standalone multiplayer smoke did not reach converged two-peer player replication.")
        get_tree().quit(1)
        return
    var final_status: Dictionary = _network_runtime.get_status()
    var match_snapshot: Dictionary = _network_runtime.get_match_snapshot()
    if match_snapshot.get("players", []).size() < expected_peers:
        push_error("Phase 15 standalone multiplayer smoke did not converge match membership.")
        get_tree().quit(1)
        return
    var role: String = str(final_status.get("role", "unknown"))
    print("PASS: Phase 15 standalone multiplayer %s connected. peers=%d local_input=true remote_input=false keyboard_mouse=true gamepad=true" % [role, int(final_status.get("peer_count", 0))])
    if role == "host":
        for _linger in range(180): await get_tree().process_frame
    get_tree().quit(0)

func _verify_input_contract() -> Dictionary:
    var keyboard_mouse := false
    var gamepad := false
    var missing: Array[String] = []
    for action in GameplayInput.action_names():
        if not InputMap.has_action(action):
            missing.append(str(action))
            continue
        for event in InputMap.action_get_events(action):
            if event is InputEventKey or event is InputEventMouseButton: keyboard_mouse = true
            if event is InputEventJoypadButton or event is InputEventJoypadMotion: gamepad = true
    if not missing.is_empty(): return {"ok": false, "errors": ["Standalone semantic input actions are missing: %s" % ", ".join(missing)]}
    if not keyboard_mouse: return {"ok": false, "errors": ["Standalone semantic input has no keyboard/mouse bindings."]}
    if not gamepad: return {"ok": false, "errors": ["Standalone semantic input has no gamepad bindings."]}
    return {"ok": true, "errors": [], "keyboard_mouse": true, "gamepad": true}

func _visual_graphs() -> Array[Dictionary]: return _bundle.get("visual_graphs", []).duplicate(true)
func _gameplay_snapshot() -> Dictionary: return _bundle.get("gameplay_snapshot", {}).duplicate(true)
func _environment_bundle() -> Dictionary: return {"document": _bundle.get("environment_document", {}).duplicate(true), "terrain_state": _bundle.get("terrain_state"), "procedural_runtime": _procedural_runtime}
func _update_streaming(position_value: Vector3) -> Dictionary:
    var terrain_result: Dictionary = _terrain_runtime.update_focus(position_value)
    if not terrain_result.get("ok", false): return terrain_result
    var entity_result: Dictionary = _adapter.set_active_cell_ids(_terrain_runtime.get_loaded_cell_ids())
    if not entity_result.get("ok", false): return entity_result
    return {"ok": true, "errors": [], "active": _terrain_runtime.get_loaded_cell_ids()}
func _on_exit_requested() -> void:
    if _network_runtime != null and _network_runtime.has_method("stop_session"): _network_runtime.stop_session()
    if _play_session != null: _play_session.exit_play()
    get_tree().quit(0)
static func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path): return {"ok": false, "errors": ["Standalone export manifest is missing."]}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not parsed is Dictionary: return {"ok": false, "errors": ["Standalone export manifest is invalid JSON."]}
    return {"ok": true, "errors": [], "data": parsed}
static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
