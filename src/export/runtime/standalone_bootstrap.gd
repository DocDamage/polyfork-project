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

func _ready() -> void:
    var result: Dictionary = start_runtime()
    if not result.get("ok", false):
        push_error("Standalone runtime failed: %s" % str(result.get("errors", [])))
        get_tree().quit(1); return
    var input_result: Dictionary = _verify_input_contract()
    if not input_result.get("ok", false):
        push_error("Standalone runtime input verification failed: %s" % str(input_result.get("errors", [])))
        get_tree().quit(1); return
    print("Polyfork standalone runtime started. project=%s entities=%d controller=%s preset=%s" % [str(_bundle.get("project_data", {}).get("project_id", "")), int(result.get("entity_count", 0)), str(result.get("controller", "")), str(_bundle.get("performance_profile", {}).get("preset_id", "balanced"))])
    print("Polyfork standalone input verified. keyboard_mouse=%s gamepad=%s" % [str(input_result.get("keyboard_mouse", false)), str(input_result.get("gamepad", false))])
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
    _adapter = SessionAdapter.new(); add_child(_adapter)
    var adapter_bind: Dictionary = _adapter.bind_project(_bundle.get("project_data", {}), Callable(_assets, "instantiate_asset_scene"))
    if not adapter_bind.get("ok", false): return adapter_bind
    _terrain_runtime = TerrainRuntime.new(); add_child(_terrain_runtime)
    var terrain_bind: Dictionary = _terrain_runtime.bind_state(_bundle.get("terrain_state"))
    if not terrain_bind.get("ok", false): return terrain_bind
    var initial_cells: Array[String] = _terrain_runtime.get_loaded_cell_ids()
    var entity_stream: Dictionary = _adapter.set_active_cell_ids(initial_cells)
    if not entity_stream.get("ok", false): return entity_stream
    _procedural_runtime = ProceduralRuntime.new(); add_child(_procedural_runtime)
    var procedural_bind: Dictionary = _procedural_runtime.bind_state(_bundle.get("procedural_state"), _bundle.get("terrain_state"), _terrain_runtime, _assets)
    if not procedural_bind.get("ok", false): return procedural_bind
    var profile_value: Variant = _bundle.get("performance_profile", {})
    if profile_value is Dictionary and not profile_value.is_empty():
        var quality_result: Dictionary = _procedural_runtime.configure_performance_profile(profile_value)
        if not quality_result.get("ok", false): return quality_result
    _play_session = PlaySession.new(); add_child(_play_session)
    _play_session.configure_project_directory("user://polyfork_runtime/%s" % str(_bundle.get("project_data", {}).get("project_id", "unknown")))
    _play_session.configure_visual_graph_provider(Callable(self, "_visual_graphs"))
    _play_session.configure_gameplay_state_provider(Callable(self, "_gameplay_snapshot"))
    _play_session.configure_environment_state_provider(Callable(self, "_environment_bundle"))
    _play_session.configure_streaming(Callable(self, "_update_streaming"))
    _play_session.exit_requested.connect(_on_exit_requested)
    return _play_session.enter_play(_adapter)

func _verify_input_contract() -> Dictionary:
    var keyboard_mouse := false; var gamepad := false; var missing: Array[String] = []
    for action in GameplayInput.action_names():
        if not InputMap.has_action(action): missing.append(str(action)); continue
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
    if _play_session != null: _play_session.exit_play()
    get_tree().quit(0)
static func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path): return {"ok": false, "errors": ["Standalone export manifest is missing."]}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not parsed is Dictionary: return {"ok": false, "errors": ["Standalone export manifest is invalid JSON."]}
    return {"ok": true, "errors": [], "data": parsed}
