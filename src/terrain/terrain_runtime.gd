class_name PlayWorldTerrainRuntime
extends Node3D

signal streaming_changed(loaded_cell_ids: Array, unloaded_cell_ids: Array, blocked_dirty: Array)
signal cell_refreshed(cell_id: String)

const TerrainChunk = preload("res://src/terrain/terrain_chunk_node.gd")
const StreamingPolicy = preload("res://src/terrain/terrain_streaming_policy.gd")
const MeshBuilder = preload("res://src/terrain/terrain_mesh_builder.gd")

var _state
var _loaded_chunks: Dictionary = {}
var _focus_position := Vector3.ZERO
var _blocked_dirty: Array[String] = []


func bind_state(state) -> Dictionary:
    if state == null: return _failure("Terrain runtime requires a terrain state.")
    clear_chunks()
    _state = state
    return update_focus(Vector3.ZERO)


func update_focus(focus_position: Vector3) -> Dictionary:
    if _state == null: return _failure("Terrain runtime is not bound.")
    _focus_position = focus_position
    var target: Array[String] = StreamingPolicy.active_cell_ids(_state.manifest, focus_position)
    var target_set: Dictionary = {}
    for cell_id in target: target_set[cell_id] = true
    var unloaded: Array[String] = []
    _blocked_dirty.clear()
    for cell_id in get_loaded_cell_ids():
        if target_set.has(cell_id): continue
        if _state.is_dirty(cell_id):
            _blocked_dirty.append(cell_id)
            continue
        _unload_cell(cell_id)
        unloaded.append(cell_id)
    var loaded: Array[String] = []
    for cell_id in target:
        if _loaded_chunks.has(cell_id): continue
        var load_result: Dictionary = _load_cell(cell_id)
        if not load_result.get("ok", false): return load_result
        loaded.append(cell_id)
    streaming_changed.emit(get_loaded_cell_ids(), unloaded, _blocked_dirty.duplicate())
    return {"ok": true, "errors": [], "loaded": loaded, "unloaded": unloaded, "blocked_dirty": _blocked_dirty.duplicate(), "active": get_loaded_cell_ids()}


func refresh_cell(cell_id: String) -> Dictionary:
    if _state == null or not _loaded_chunks.has(cell_id): return {"ok": true, "errors": [], "changed": false}
    var chunk = _loaded_chunks[cell_id]
    var cell: Dictionary = _state.get_cell(cell_id)
    var biome: Dictionary = _state.get_biome(str(cell.get("biome_id", "")))
    var result: Dictionary = chunk.apply_cell(cell, biome)
    result["changed"] = result.get("ok", false)
    if result.get("ok", false): cell_refreshed.emit(cell_id)
    return result


func sample_height(world_position: Vector3) -> float:
    if _state == null: return 0.0
    var cell: Dictionary = _state.get_cell_at_position(world_position)
    if cell.is_empty(): return 0.0
    return MeshBuilder.sample_height(cell, world_position)


func get_loaded_cell_ids() -> Array[String]:
    var result: Array[String] = []
    for cell_id in _loaded_chunks.keys(): result.append(str(cell_id))
    result.sort()
    return result


func get_blocked_dirty_ids() -> Array[String]: return _blocked_dirty.duplicate()
func get_chunk(cell_id: String): return _loaded_chunks.get(cell_id)
func chunk_count() -> int: return _loaded_chunks.size()
func focus_position() -> Vector3: return _focus_position


func clear_chunks() -> void:
    for chunk in _loaded_chunks.values():
        if is_instance_valid(chunk):
            remove_child(chunk)
            chunk.free()
    _loaded_chunks.clear()
    _blocked_dirty.clear()


func _load_cell(cell_id: String) -> Dictionary:
    var cell: Dictionary = _state.get_cell(cell_id)
    if cell.is_empty(): return _failure("Streaming requested an unknown terrain cell.")
    var biome: Dictionary = _state.get_biome(str(cell.get("biome_id", "")))
    if biome.is_empty(): return _failure("Terrain cell references an unknown biome.")
    var chunk = TerrainChunk.new()
    chunk.name = "Terrain_%s" % cell_id.substr(0, 8)
    var result: Dictionary = chunk.apply_cell(cell, biome)
    if not result.get("ok", false):
        chunk.free()
        return result
    add_child(chunk)
    _loaded_chunks[cell_id] = chunk
    return {"ok": true, "errors": []}


func _unload_cell(cell_id: String) -> void:
    var chunk = _loaded_chunks.get(cell_id)
    if chunk != null and is_instance_valid(chunk):
        remove_child(chunk)
        chunk.free()
    _loaded_chunks.erase(cell_id)


func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
