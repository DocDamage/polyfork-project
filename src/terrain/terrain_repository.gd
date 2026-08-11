class_name PlayWorldTerrainRepository
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const SafeJsonWriter = preload("res://src/world/safe_json_writer.gd")
const TerrainSchema = preload("res://src/terrain/terrain_schema.gd")
const TerrainState = preload("res://src/terrain/terrain_world_state.gd")
const WorldPartition = preload("res://src/terrain/world_partition.gd")

const MANIFEST_FILE := "manifest.json"
const BIOMES_FILE := "biomes.json"
const CELLS_DIR := "cells"
const RECOVERY_DIR := "recovery"

var root_path: String
var _writer
var _write_counts: Dictionary = {"manifest": 0, "biomes": 0, "cells": {}}


func _init(project_directory: String, safe_writer = null) -> void:
    root_path = project_directory.trim_suffix("/").path_join("terrain")
    _writer = safe_writer if safe_writer != null else SafeJsonWriter.new()


func open_or_create(project) -> Dictionary:
    if project == null: return _failure("Terrain repository requires a project.")
    var make_error: int = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(get_cells_directory()))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS: return _failure("Unable to create terrain storage.")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(get_recovery_directory()))
    if FileAccess.file_exists(get_manifest_path()): return _load_world(project)
    return _create_world(project)


func flush_dirty(state) -> Dictionary:
    if state == null: return _failure("Terrain state is required.")
    var saved: Array[String] = []
    var failed: Array[String] = []
    for cell_id in state.dirty_cell_ids():
        var record: Dictionary = state.get_cell(cell_id)
        var now: int = int(Time.get_unix_time_from_system() * 1000.0)
        record["saved_at_msec"] = max(now, int(record.get("saved_at_msec", 0)) + 1)
        var state_result: Dictionary = state.set_cell(record, false)
        if not state_result.get("ok", false):
            failed.append(cell_id)
            continue
        var write_result: Dictionary = _write_cell_with_recovery(record)
        if not write_result.get("ok", false):
            failed.append(cell_id)
            continue
        state.clear_dirty(cell_id)
        saved.append(cell_id)
        _increment_cell_count(cell_id)
    return {"ok": failed.is_empty(), "errors": [] if failed.is_empty() else ["Terrain cells failed to save: %s" % ", ".join(failed)], "saved_cells": saved, "remaining_dirty": state.dirty_cell_ids()}


func get_write_counts() -> Dictionary: return _write_counts.duplicate(true)
func get_manifest_path() -> String: return root_path.path_join(MANIFEST_FILE)
func get_biomes_path() -> String: return root_path.path_join(BIOMES_FILE)
func get_cells_directory() -> String: return root_path.path_join(CELLS_DIR)
func get_recovery_directory() -> String: return root_path.path_join(RECOVERY_DIR)
func get_cell_path(cell_id: String) -> String: return get_cells_directory().path_join("%s.json" % cell_id)
func get_recovery_path(cell_id: String) -> String: return get_recovery_directory().path_join("%s.json" % cell_id)


func _create_world(project) -> Dictionary:
    var manifest: Dictionary = WorldPartition.build_manifest(project.project_id, project.world_profile, project.cell_ids)
    var manifest_errors: Array[String] = TerrainSchema.validate_manifest(manifest)
    if not manifest_errors.is_empty(): return {"ok": false, "errors": manifest_errors, "state": null}
    var biome_data: Dictionary = _default_biomes(project.project_id)
    var biome_errors: Array[String] = TerrainSchema.validate_biome_registry(biome_data)
    if not biome_errors.is_empty(): return {"ok": false, "errors": biome_errors, "state": null}
    var default_biome: String = str(biome_data["biomes"][0]["biome_id"])
    var cells: Array[Dictionary] = []
    var now: int = max(1, int(Time.get_unix_time_from_system() * 1000.0))
    for item in manifest["cells"]:
        var record: Dictionary = _new_cell(project.project_id, item, manifest, default_biome, now)
        var write_result: Dictionary = _writer.write_validated_dictionary(get_cell_path(str(record["cell_id"])), record, Callable(TerrainSchema, "validate_cell"))
        if not write_result.get("ok", false): return {"ok": false, "errors": write_result.get("errors", ["Terrain cell creation failed."]), "state": null}
        _increment_cell_count(str(record["cell_id"]))
        cells.append(record)
    var biome_write: Dictionary = _writer.write_validated_dictionary(get_biomes_path(), biome_data, Callable(TerrainSchema, "validate_biome_registry"))
    if not biome_write.get("ok", false): return {"ok": false, "errors": biome_write.get("errors", ["Biome registry creation failed."]), "state": null}
    _write_counts["biomes"] = int(_write_counts["biomes"]) + 1
    var manifest_write: Dictionary = _writer.write_validated_dictionary(get_manifest_path(), manifest, Callable(TerrainSchema, "validate_manifest"))
    if not manifest_write.get("ok", false): return {"ok": false, "errors": manifest_write.get("errors", ["Terrain manifest creation failed."]), "state": null}
    _write_counts["manifest"] = int(_write_counts["manifest"]) + 1
    var state = TerrainState.new()
    var load_errors: Array[String] = state.load_data(manifest, biome_data, cells)
    if not load_errors.is_empty(): return {"ok": false, "errors": load_errors, "state": null}
    var before_ids: Array[String] = project.cell_ids.duplicate()
    for cell_id in WorldPartition.cell_ids(manifest):
        if not project.cell_ids.has(cell_id): project.cell_ids.append(cell_id)
    return {"ok": true, "errors": [], "state": state, "created": true, "project_changed": before_ids != project.cell_ids}


func _load_world(project) -> Dictionary:
    var manifest_result: Dictionary = _read_validated(get_manifest_path(), Callable(TerrainSchema, "validate_manifest"))
    if not manifest_result.get("ok", false): return manifest_result
    var manifest: Dictionary = manifest_result["data"]
    if str(manifest.get("project_id", "")) != project.project_id: return _failure("Terrain manifest belongs to another project.")
    if str(manifest.get("profile_id", "")) != str(project.world_profile): return _failure("Terrain manifest profile does not match the project.")
    var biome_result: Dictionary = _read_validated(get_biomes_path(), Callable(TerrainSchema, "validate_biome_registry"))
    if not biome_result.get("ok", false): return biome_result
    var cells: Array[Dictionary] = []
    var recovered: Array[String] = []
    for item in manifest.get("cells", []):
        var cell_id: String = str(item.get("cell_id", ""))
        var cell_result: Dictionary = _read_validated(get_cell_path(cell_id), Callable(TerrainSchema, "validate_cell"))
        if not cell_result.get("ok", false):
            cell_result = _read_validated(get_recovery_path(cell_id), Callable(TerrainSchema, "validate_cell"))
            if not cell_result.get("ok", false): return _failure("Terrain cell %s and its recovery copy are unreadable." % cell_id)
            recovered.append(cell_id)
        var record: Dictionary = cell_result["data"]
        if str(record.get("project_id", "")) != project.project_id or str(record.get("cell_id", "")) != cell_id: return _failure("Terrain cell identity does not match the manifest.")
        cells.append(record)
    var state = TerrainState.new()
    var load_errors: Array[String] = state.load_data(manifest, biome_result["data"], cells)
    if not load_errors.is_empty(): return {"ok": false, "errors": load_errors, "state": null}
    for cell_id in recovered: state.set_recovered(cell_id, true)
    var before_ids: Array[String] = project.cell_ids.duplicate()
    for cell_id in WorldPartition.cell_ids(manifest):
        if not project.cell_ids.has(cell_id): project.cell_ids.append(cell_id)
    return {"ok": true, "errors": [], "state": state, "created": false, "recovered_cells": recovered, "project_changed": before_ids != project.cell_ids}


func _write_cell_with_recovery(record: Dictionary) -> Dictionary:
    var cell_id: String = str(record.get("cell_id", ""))
    var canonical_path: String = get_cell_path(cell_id)
    if FileAccess.file_exists(canonical_path):
        var old_result: Dictionary = _read_validated(canonical_path, Callable(TerrainSchema, "validate_cell"))
        if old_result.get("ok", false):
            var recovery_write: Dictionary = _writer.write_validated_dictionary(get_recovery_path(cell_id), old_result["data"], Callable(TerrainSchema, "validate_cell"))
            if not recovery_write.get("ok", false): return recovery_write
    return _writer.write_validated_dictionary(canonical_path, record, Callable(TerrainSchema, "validate_cell"))


func _read_validated(path: String, validator: Callable) -> Dictionary:
    var read_result: Dictionary = _writer.read_dictionary(path)
    if not read_result.get("ok", false): return {"ok": false, "errors": read_result.get("errors", ["Persistence read failed."]), "data": {}}
    var validation: Variant = validator.call(read_result["data"])
    if not validation is Array: return {"ok": false, "errors": ["Terrain validator returned an invalid result."], "data": {}}
    var errors: Array = validation
    if not errors.is_empty(): return {"ok": false, "errors": errors, "data": {}}
    return {"ok": true, "errors": [], "data": read_result["data"]}


func _new_cell(project_id: String, item: Dictionary, manifest: Dictionary, biome_id: String, now: int) -> Dictionary:
    var resolution: int = int(manifest["resolution"])
    var heights: Array[float] = []
    heights.resize(resolution * resolution)
    heights.fill(0.0)
    return {"document_type": TerrainSchema.CELL_TYPE, "schema_version": TerrainSchema.SCHEMA_VERSION, "project_id": project_id, "cell_id": str(item["cell_id"]), "coord": item["coord"].duplicate(), "cell_size_m": float(manifest["cell_size_m"]), "resolution": resolution, "heights": heights, "revision": 0, "biome_id": biome_id, "saved_at_msec": now}


func _default_biomes(project_id: String) -> Dictionary:
    return {"document_type": TerrainSchema.BIOME_REGISTRY_TYPE, "schema_version": TerrainSchema.SCHEMA_VERSION, "project_id": project_id, "biomes": [
        _biome("Meadow", [0.22, 0.53, 0.29, 1.0], ["ground", "rock"]),
        _biome("Desert", [0.67, 0.48, 0.25, 1.0], ["sand", "rock"]),
        _biome("Alpine", [0.33, 0.42, 0.48, 1.0], ["rock", "snow"])
    ]}


func _biome(display_name: String, color: Array, slots: Array) -> Dictionary:
    return {"biome_id": StableId.generate(), "display_name": display_name, "color": color.duplicate(), "terrain_material_slots": slots.duplicate(), "future_defaults": {"foliage_profile_id": null, "environment_profile_id": null}}


func _increment_cell_count(cell_id: String) -> void:
    var counts: Dictionary = _write_counts["cells"]
    counts[cell_id] = int(counts.get(cell_id, 0)) + 1
    _write_counts["cells"] = counts


func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message], "state": null}
