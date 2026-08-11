extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProfile = preload("res://src/world/world_profile.gd")
const TerrainSchema = preload("res://src/terrain/terrain_schema.gd")
const WorldPartition = preload("res://src/terrain/world_partition.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project_id: String = StableId.generate()
    var existing_cell: String = StableId.generate()

    var small: Dictionary = WorldPartition.build_manifest(project_id, WorldProfile.SMALL, [existing_cell])
    var medium: Dictionary = WorldPartition.build_manifest(project_id, WorldProfile.MEDIUM, [existing_cell])
    var large: Dictionary = WorldPartition.build_manifest(project_id, WorldProfile.LARGE, [existing_cell])
    if small.get("cells", []).size() != 1 or medium.get("cells", []).size() != 9 or large.get("cells", []).size() != 25:
        errors.append("Small/Medium/Large terrain topology must be 1, 9, and 25 centered cells.")
    if str(medium.get("cells", [])[0].get("cell_id", "")) != existing_cell or medium.get("cells", [])[0].get("coord", []) != [0, 0]:
        errors.append("Partition creation must preserve the first existing stable cell ID as the centered origin cell.")
    if bool(small.get("streaming", true)) or bool(medium.get("streaming", true)) or not bool(large.get("streaming", false)):
        errors.append("Only the Large world profile may enable Phase 5 streaming.")
    if float(WorldPartition.profile_contract(WorldProfile.SMALL).get("area_km2", 0.0)) != 1.0 or float(WorldPartition.profile_contract(WorldProfile.MEDIUM).get("area_km2", 0.0)) != 9.0 or float(WorldPartition.profile_contract(WorldProfile.LARGE).get("area_km2", 0.0)) != 25.0:
        errors.append("Profile topology must remain inside the documented Small/Medium/Large area ranges.")

    if not TerrainSchema.validate_manifest(medium).is_empty():
        errors.append("Generated terrain manifests must satisfy the versioned schema.")
    var future_manifest: Dictionary = medium.duplicate(true)
    future_manifest["schema_version"] = TerrainSchema.SCHEMA_VERSION + 1
    if TerrainSchema.validate_manifest(future_manifest).is_empty():
        errors.append("Future terrain manifest versions must fail validation instead of being interpreted as current.")

    var biome_id: String = StableId.generate()
    var cell: Dictionary = {
        "document_type": TerrainSchema.CELL_TYPE,
        "schema_version": TerrainSchema.SCHEMA_VERSION,
        "project_id": project_id,
        "cell_id": existing_cell,
        "coord": [0, 0],
        "cell_size_m": 1024.0,
        "resolution": 3,
        "heights": [0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0],
        "revision": 1,
        "biome_id": biome_id,
        "saved_at_msec": 1
    }
    if not TerrainSchema.validate_cell(cell).is_empty():
        errors.append("A valid terrain cell record must satisfy the schema.")
    var broken_cell: Dictionary = cell.duplicate(true)
    broken_cell["heights"] = [0.0]
    if TerrainSchema.validate_cell(broken_cell).is_empty():
        errors.append("Terrain cell validation must reject height arrays that do not match resolution squared.")

    if WorldPartition.cell_id_for_position(medium, Vector3.ZERO) != existing_cell:
        errors.append("World origin must resolve to the centered terrain cell.")
    var east_id: String = WorldPartition.cell_id_for_position(medium, Vector3(700.0, 0.0, 0.0))
    if east_id.is_empty() or east_id == existing_cell:
        errors.append("Position-to-cell resolution must deterministically cross centered cell boundaries.")
    return errors
