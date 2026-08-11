class_name PlayWorldTerrainState
extends RefCounted

const TerrainSchema = preload("res://src/terrain/terrain_schema.gd")
const WorldPartition = preload("res://src/terrain/world_partition.gd")

var manifest: Dictionary = {}
var biome_registry: Dictionary = {}
var _cells: Dictionary = {}
var _dirty_cells: Dictionary = {}
var _recovered_cells: Dictionary = {}


func load_data(manifest_data: Dictionary, biome_data: Dictionary, cell_records: Array[Dictionary]) -> Array[String]:
    var errors: Array[String] = []
    errors.append_array(TerrainSchema.validate_manifest(manifest_data))
    errors.append_array(TerrainSchema.validate_biome_registry(biome_data))
    var staged: Dictionary = {}
    for record in cell_records:
        var cell_errors: Array[String] = TerrainSchema.validate_cell(record)
        errors.append_array(cell_errors)
        var cell_id: String = str(record.get("cell_id", ""))
        if staged.has(cell_id): errors.append("Terrain state contains a duplicate cell record.")
        staged[cell_id] = record.duplicate(true)
    if not errors.is_empty(): return errors
    for item in manifest_data.get("cells", []):
        var manifest_cell_id: String = str(item.get("cell_id", ""))
        if not staged.has(manifest_cell_id): errors.append("Terrain manifest references a missing cell record.")
    if not errors.is_empty(): return errors
    manifest = manifest_data.duplicate(true)
    biome_registry = biome_data.duplicate(true)
    _cells = staged
    _dirty_cells.clear()
    _recovered_cells.clear()
    return []


func get_cell(cell_id: String) -> Dictionary:
    if not _cells.has(cell_id): return {}
    return _cells[cell_id].duplicate(true)


func set_cell(record: Dictionary, mark_dirty: bool = true) -> Dictionary:
    var errors: Array[String] = TerrainSchema.validate_cell(record)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    var cell_id: String = str(record.get("cell_id", ""))
    if not _cells.has(cell_id): return _failure("Terrain state cannot replace an unknown cell.")
    _cells[cell_id] = record.duplicate(true)
    if mark_dirty: _dirty_cells[cell_id] = true
    return {"ok": true, "errors": []}


func all_cells() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for cell_id in cell_ids(): result.append(get_cell(cell_id))
    return result


func cell_ids() -> Array[String]:
    var result: Array[String] = []
    for item in manifest.get("cells", []): result.append(str(item.get("cell_id", "")))
    return result


func get_cell_at_position(position_value: Vector3) -> Dictionary:
    var cell_id: String = WorldPartition.cell_id_for_position(manifest, position_value)
    return get_cell(cell_id)


func cell_id_at_position(position_value: Vector3) -> String:
    return WorldPartition.cell_id_for_position(manifest, position_value)


func mark_dirty(cell_id: String) -> Dictionary:
    if not _cells.has(cell_id): return _failure("Cannot dirty an unknown terrain cell.")
    _dirty_cells[cell_id] = true
    return {"ok": true, "errors": []}


func is_dirty(cell_id: String) -> bool: return _dirty_cells.has(cell_id)
func has_dirty_cells() -> bool: return not _dirty_cells.is_empty()


func dirty_cell_ids() -> Array[String]:
    var result: Array[String] = []
    for cell_id in _dirty_cells.keys(): result.append(str(cell_id))
    result.sort()
    return result


func clear_dirty(cell_id: String) -> void: _dirty_cells.erase(cell_id)


func set_recovered(cell_id: String, recovered: bool) -> void:
    if recovered: _recovered_cells[cell_id] = true
    else: _recovered_cells.erase(cell_id)


func recovered_cell_ids() -> Array[String]:
    var result: Array[String] = []
    for cell_id in _recovered_cells.keys(): result.append(str(cell_id))
    result.sort()
    return result


func get_biome(biome_id: String) -> Dictionary:
    for item in biome_registry.get("biomes", []):
        if str(item.get("biome_id", "")) == biome_id: return item.duplicate(true)
    return {}


func biome_ids() -> Array[String]:
    var result: Array[String] = []
    for item in biome_registry.get("biomes", []): result.append(str(item.get("biome_id", "")))
    return result


func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
