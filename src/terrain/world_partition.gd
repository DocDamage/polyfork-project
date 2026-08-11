class_name PlayWorldPartition
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProfile = preload("res://src/world/world_profile.gd")
const TerrainSchema = preload("res://src/terrain/terrain_schema.gd")


static func profile_contract(profile_id: StringName) -> Dictionary:
    match profile_id:
        WorldProfile.SMALL:
            return {"dimension": 1, "cell_size_m": 1024.0, "streaming": false, "load_radius": 0, "area_km2": 1.0}
        WorldProfile.MEDIUM:
            return {"dimension": 3, "cell_size_m": 1024.0, "streaming": false, "load_radius": 1, "area_km2": 9.0}
        WorldProfile.LARGE:
            return {"dimension": 5, "cell_size_m": 1024.0, "streaming": true, "load_radius": 1, "area_km2": 25.0}
    return {}


static func build_manifest(project_id: String, profile_id: StringName, existing_ids: Array[String]) -> Dictionary:
    var contract: Dictionary = profile_contract(profile_id)
    if contract.is_empty() or not StableId.is_valid(project_id): return {}
    var coords: Array[Vector2i] = _ordered_coords(int(contract["dimension"]))
    var ids: Array[String] = []
    var seen: Dictionary = {}
    for value in existing_ids:
        var cell_id: String = str(value)
        if StableId.is_valid(cell_id) and not seen.has(cell_id):
            ids.append(cell_id)
            seen[cell_id] = true
    while ids.size() < coords.size():
        var generated: String = StableId.generate()
        if not seen.has(generated):
            ids.append(generated)
            seen[generated] = true
    var cells: Array[Dictionary] = []
    for index in range(coords.size()):
        var coord: Vector2i = coords[index]
        cells.append({"cell_id": ids[index], "coord": [coord.x, coord.y]})
    return {
        "document_type": TerrainSchema.MANIFEST_TYPE,
        "schema_version": TerrainSchema.SCHEMA_VERSION,
        "project_id": project_id,
        "profile_id": str(profile_id),
        "streaming": bool(contract["streaming"]),
        "cell_size_m": float(contract["cell_size_m"]),
        "resolution": TerrainSchema.DEFAULT_RESOLUTION,
        "load_radius": int(contract["load_radius"]),
        "cells": cells
    }


static func required_cell_count(profile_id: StringName) -> int:
    var contract: Dictionary = profile_contract(profile_id)
    if contract.is_empty(): return 0
    var dimension: int = int(contract["dimension"])
    return dimension * dimension


static func cell_ids(manifest: Dictionary) -> Array[String]:
    var result: Array[String] = []
    for item in manifest.get("cells", []): result.append(str(item.get("cell_id", "")))
    return result


static func coord_for_position(manifest: Dictionary, position_value: Vector3) -> Vector2i:
    var size: float = float(manifest.get("cell_size_m", TerrainSchema.DEFAULT_CELL_SIZE_M))
    return Vector2i(int(floor((position_value.x + size * 0.5) / size)), int(floor((position_value.z + size * 0.5) / size)))


static func cell_id_for_position(manifest: Dictionary, position_value: Vector3) -> String:
    var target: Vector2i = coord_for_position(manifest, position_value)
    for item in manifest.get("cells", []):
        var coord: Array = item.get("coord", [])
        if coord.size() == 2 and int(coord[0]) == target.x and int(coord[1]) == target.y:
            return str(item.get("cell_id", ""))
    return ""


static func _ordered_coords(dimension: int) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var half: int = int(floor(float(dimension) / 2.0))
    for z in range(-half, half + 1):
        for x in range(-half, half + 1): result.append(Vector2i(x, z))
    result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        var da: int = a.x * a.x + a.y * a.y
        var db: int = b.x * b.x + b.y * b.y
        if da != db: return da < db
        if a.y != b.y: return a.y < b.y
        return a.x < b.x
    )
    return result
