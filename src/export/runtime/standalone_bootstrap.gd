class_name PlayWorldStandaloneBootstrap
extends Node3D

const Loader = preload("res://src/export/runtime/standalone_data_loader.gd")
const AssetResolver = preload("res://src/export/runtime/standalone_asset_resolver.gd")
const SessionAdapter = preload("res://src/export/runtime/standalone_session_adapter.gd")
const PlaySession = preload("res://src/runtime/play_session.gd")
const TerrainRuntime = preload("res://src/terrain/terrain_runtime.gd")
const ProceduralRuntime = preload("res://src/procedural/procedural_runtime.gd")

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
    print("Polyfork standalone runtime started. project=%s entities=%d controller=%s" % [str(_bundle.get("project_data", {}).get("project_id", "")), int(result.get("entity_count", 0)), str(result.get("controller", ""))])
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

    _play_session = PlaySession.new(); add_child(_play_session)
    _play_session.configure_project_directory("user://polyfork_runtime/%s" % str(_bundle.get("project_data", {}).get("project_id", "unknown")))
    _play_session.configure_visual_graph_provider(Callable(self, "_visual_graphs"))
    _play_session.configure_gameplay_state_provider(Callable(self, "_gameplay_snapshot"))
    _play_session.configure_environment_state_provider(Callable(self, "_environment_bundle"))
    _play_session.configure_streaming(Callable(self, "_update_streaming"))
    _play_session.exit_requested.connect(_on_exit_requested)
    return _play_session.enter_play(_adapter)

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
