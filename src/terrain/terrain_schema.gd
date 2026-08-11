class_name PlayWorldTerrainSchema
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProfile = preload("res://src/world/world_profile.gd")

const MANIFEST_TYPE := "terrain_manifest"
const CELL_TYPE := "terrain_cell"
const BIOME_REGISTRY_TYPE := "biome_registry"
const SCHEMA_VERSION := 1
const DEFAULT_RESOLUTION := 17
const DEFAULT_CELL_SIZE_M := 1024.0


static func validate_manifest(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    _validate_header(data, MANIFEST_TYPE, errors)
    var project_id: String = str(data.get("project_id", ""))
    if not StableId.is_valid(project_id): errors.append("Terrain manifest project_id must be a stable UUID.")
    var profile_id: StringName = StringName(str(data.get("profile_id", "")))
    if not WorldProfile.is_valid(profile_id): errors.append("Terrain manifest profile_id is invalid.")
    var cell_size: float = float(data.get("cell_size_m", 0.0))
    if cell_size <= 0.0: errors.append("Terrain manifest cell_size_m must be positive.")
    var resolution: int = int(data.get("resolution", 0))
    if resolution < 3 or resolution % 2 == 0: errors.append("Terrain manifest resolution must be an odd integer >= 3.")
    if int(data.get("load_radius", -1)) < 0: errors.append("Terrain manifest load_radius must be non-negative.")
    var cells: Variant = data.get("cells", [])
    if not cells is Array:
        errors.append("Terrain manifest cells must be an array.")
        return errors
    var seen_ids: Dictionary = {}
    var seen_coords: Dictionary = {}
    for item in cells:
        if not item is Dictionary:
            errors.append("Terrain manifest cells must contain dictionaries.")
            continue
        var record: Dictionary = item
        var cell_id: String = str(record.get("cell_id", ""))
        if not StableId.is_valid(cell_id): errors.append("Terrain manifest cell_id must be a stable UUID.")
        elif seen_ids.has(cell_id): errors.append("Terrain manifest contains a duplicate cell_id.")
        else: seen_ids[cell_id] = true
        var coord: Variant = record.get("coord", [])
        if not _valid_coord(coord):
            errors.append("Terrain manifest cell coord must contain two integers.")
        else:
            var coord_key: String = "%d:%d" % [int(coord[0]), int(coord[1])]
            if seen_coords.has(coord_key): errors.append("Terrain manifest contains a duplicate cell coord.")
            else: seen_coords[coord_key] = true
    if cells.is_empty(): errors.append("Terrain manifest must own at least one cell.")
    return errors


static func validate_cell(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    _validate_header(data, CELL_TYPE, errors)
    if not StableId.is_valid(str(data.get("project_id", ""))): errors.append("Terrain cell project_id must be a stable UUID.")
    if not StableId.is_valid(str(data.get("cell_id", ""))): errors.append("Terrain cell cell_id must be a stable UUID.")
    if not _valid_coord(data.get("coord", [])): errors.append("Terrain cell coord must contain two integers.")
    var cell_size: float = float(data.get("cell_size_m", 0.0))
    if cell_size <= 0.0: errors.append("Terrain cell cell_size_m must be positive.")
    var resolution: int = int(data.get("resolution", 0))
    if resolution < 3 or resolution % 2 == 0: errors.append("Terrain cell resolution must be an odd integer >= 3.")
    var heights: Variant = data.get("heights", [])
    if not heights is Array:
        errors.append("Terrain cell heights must be an array.")
    elif resolution >= 3 and heights.size() != resolution * resolution:
        errors.append("Terrain cell height count must equal resolution squared.")
    if int(data.get("revision", -1)) < 0: errors.append("Terrain cell revision must be non-negative.")
    if not StableId.is_valid(str(data.get("biome_id", ""))): errors.append("Terrain cell biome_id must be a stable UUID.")
    if int(data.get("saved_at_msec", 0)) <= 0: errors.append("Terrain cell saved_at_msec must be positive.")
    return errors


static func validate_biome_registry(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    _validate_header(data, BIOME_REGISTRY_TYPE, errors)
    if not StableId.is_valid(str(data.get("project_id", ""))): errors.append("Biome registry project_id must be a stable UUID.")
    var biomes: Variant = data.get("biomes", [])
    if not biomes is Array:
        errors.append("Biome registry biomes must be an array.")
        return errors
    var seen: Dictionary = {}
    for item in biomes:
        if not item is Dictionary:
            errors.append("Biome registry entries must be dictionaries.")
            continue
        var biome_errors: Array[String] = validate_biome(item)
        errors.append_array(biome_errors)
        var biome_id: String = str(item.get("biome_id", ""))
        if StableId.is_valid(biome_id):
            if seen.has(biome_id): errors.append("Biome registry contains a duplicate biome_id.")
            seen[biome_id] = true
    if biomes.is_empty(): errors.append("Biome registry must contain at least one biome.")
    return errors


static func validate_biome(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if not StableId.is_valid(str(data.get("biome_id", ""))): errors.append("Biome biome_id must be a stable UUID.")
    if str(data.get("display_name", "")).strip_edges().is_empty(): errors.append("Biome display_name is required.")
    var color: Variant = data.get("color", [])
    if not color is Array or color.size() != 4: errors.append("Biome color must contain four channels.")
    var slots: Variant = data.get("terrain_material_slots", [])
    if not slots is Array: errors.append("Biome terrain_material_slots must be an array.")
    if not data.get("future_defaults", {}) is Dictionary: errors.append("Biome future_defaults must be a dictionary.")
    return errors


static func _validate_header(data: Dictionary, expected_type: String, errors: Array[String]) -> void:
    if data.get("document_type") != expected_type: errors.append("%s document_type is invalid." % expected_type)
    if int(data.get("schema_version", 0)) != SCHEMA_VERSION: errors.append("%s schema_version is unsupported." % expected_type)


static func _valid_coord(value: Variant) -> bool:
    if not value is Array or value.size() != 2: return false
    return float(value[0]) == float(int(value[0])) and float(value[1]) == float(int(value[1]))
