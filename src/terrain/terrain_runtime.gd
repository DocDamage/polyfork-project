class_name PlayWorldTerrainRuntime
extends Node3D

signal streaming_changed(loaded_cell_ids: Array, unloaded_cell_ids: Array, blocked_dirty_cell_ids: Array)
signal cell_refreshed(cell_id: String)

const TerrainChunk = preload("res://src/terrain/terrain_chunk_node.gd")
const StreamingPolicy = preload("res://src/terrain/terrain_streaming_policy.gd")

var _state
var _loaded_chunks: Dictionary = {}
var _focus_position := Vector3.ZERO
var _blocked_dirty: Dictionary = {}

func _init() -> void: name = "TerrainRuntime"

func bind_state(state) -> Dictionary:
    if state == null: return _failure("Terrain runtime requires a terrain state.")
    clear_runtime(); _state = state
    return update_focus(Vector3.ZERO)

func update_focus(focus_position: Vector3) -> Dictionary:
    if _state == null: return _failure("Terrain runtime is not bound.")
    _focus_position = focus_position
    var target_ids: Array[String] = StreamingPolicy.active_cell_ids(_state.manifest, focus_position)
    var current_ids: Array[String] = get_loaded_cell_ids()
    if _blocked_dirty.is_empty() and target_ids == current_ids:
        return {"ok": true, "errors": [], "changed": false, "active": current_ids, "loaded": [], "unloaded": [], "blocked_dirty": []}
    var previous_blocked: Array[String] = get_blocked_dirty_cell_ids()
    var target_set: Dictionary = {}
    for cell_id in target_ids: target_set[cell_id] = true
    var loaded: Array[String] = []
    var unloaded: Array[String] = []
    for cell_id_value in _loaded_chunks.keys().duplicate():
        var cell_id: String = str(cell_id_value)
        if target_set.has(cell_id): continue
        if _state.is_cell_dirty(cell_id): _blocked_dirty[cell_id] = true; continue
        _unload_chunk(cell_id); unloaded.append(cell_id)
    for cell_id in target_ids:
        if _loaded_chunks.has(cell_id): _blocked_dirty.erase(cell_id); continue
        var load_result: Dictionary = _load_chunk(cell_id)
        if not load_result.get("ok", false): return load_result
        loaded.append(cell_id)
    loaded.sort(); unloaded.sort()
    var blocked: Array[String] = get_blocked_dirty_cell_ids()
    var changed: bool = not loaded.is_empty() or not unloaded.is_empty() or blocked != previous_blocked
    if changed: streaming_changed.emit(loaded.duplicate(), unloaded.duplicate(), blocked.duplicate())
    return {"ok": true, "errors": [], "changed": changed, "active": get_loaded_cell_ids(), "loaded": loaded, "unloaded": unloaded, "blocked_dirty": blocked}

func refresh_cell(cell_id: String) -> Dictionary:
    if _state == null: return _failure("Terrain runtime is not bound.")
    if not _loaded_chunks.has(cell_id): return {"ok": true, "errors": [], "refreshed": false}
    var chunk = _loaded_chunks[cell_id]
    var result: Dictionary = chunk.apply_cell(_state.get_cell(cell_id), _state.manifest)
    if result.get("ok", false): cell_refreshed.emit(cell_id)
    return result

func sample_height(world_position: Vector3) -> float:
    if _state == null: return 0.0
    var cell_id: String = _state.cell_id_at_position(world_position)
    var cell: Dictionary = _state.get_cell(cell_id)
    if cell.is_empty(): return 0.0
    var origin: Vector3 = _state.cell_origin(cell_id)
    var size: float = float(_state.manifest.get("cell_size", 256.0))
    var u: float = clampf((world_position.x - origin.x) / size, 0.0, 1.0)
    var v: float = clampf((world_position.z - origin.z) / size, 0.0, 1.0)
    return _state.sample_height_uv(cell_id, u, v)

func get_loaded_cell_ids() -> Array[String]:
    var result: Array[String] = []
    for key in _loaded_chunks.keys(): result.append(str(key))
    result.sort(); return result

func get_blocked_dirty_cell_ids() -> Array[String]:
    var result: Array[String] = []
    for key in _blocked_dirty.keys(): result.append(str(key))
    result.sort(); return result

func get_chunk(cell_id: String): return _loaded_chunks.get(cell_id)
func get_focus_position() -> Vector3: return _focus_position

func clear_runtime() -> void:
    for cell_id_value in _loaded_chunks.keys().duplicate(): _unload_chunk(str(cell_id_value))
    _loaded_chunks.clear(); _blocked_dirty.clear()

func _load_chunk(cell_id: String) -> Dictionary:
    var cell: Dictionary = _state.get_cell(cell_id)
    if cell.is_empty(): return _failure("Cannot stream missing terrain cell: %s" % cell_id)
    var chunk = TerrainChunk.new(); add_child(chunk)
    var result: Dictionary = chunk.apply_cell(cell, _state.manifest)
    if not result.get("ok", false): remove_child(chunk); chunk.free(); return result
    _loaded_chunks[cell_id] = chunk; _blocked_dirty.erase(cell_id)
    return {"ok": true, "errors": []}

func _unload_chunk(cell_id: String) -> void:
    var chunk = _loaded_chunks.get(cell_id)
    if chunk != null and is_instance_valid(chunk):
        if chunk.get_parent() == self: remove_child(chunk)
        chunk.free()
    _loaded_chunks.erase(cell_id); _blocked_dirty.erase(cell_id)

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
