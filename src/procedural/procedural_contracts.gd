class_name PlayWorldProceduralContracts
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")

const DOCUMENT_TYPE := "procedural_registry"
const SCHEMA_VERSION := 1
const SOURCE_KINDS: Array[String] = ["primitive", "asset", "prefab"]
const PRIMITIVES: Array[String] = ["grass", "shrub", "tree", "post"]
const STROKE_OPERATIONS: Array[String] = ["paint", "erase"]
const SPLINE_KINDS: Array[String] = ["road", "path", "fence"]


static func empty_document(project_id: String) -> Dictionary:
    return {
        "document_type": DOCUMENT_TYPE,
        "schema_version": SCHEMA_VERSION,
        "project_id": project_id,
        "foliage_sets": [],
        "scatter_layers": [],
        "splines": [],
    }


static func validate_document(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if str(data.get("document_type", "")) != DOCUMENT_TYPE:
        errors.append("Procedural registry document_type is invalid.")
    if int(data.get("schema_version", 0)) != SCHEMA_VERSION:
        errors.append("Procedural registry schema_version is unsupported.")
    if not StableId.is_valid(str(data.get("project_id", ""))):
        errors.append("Procedural registry project_id must be a stable UUID.")
    var foliage_value: Variant = data.get("foliage_sets", [])
    var scatter_value: Variant = data.get("scatter_layers", [])
    var splines_value: Variant = data.get("splines", [])
    if not foliage_value is Array:
        errors.append("Procedural foliage_sets must be an array.")
        return errors
    if not scatter_value is Array:
        errors.append("Procedural scatter_layers must be an array.")
        return errors
    if not splines_value is Array:
        errors.append("Procedural splines must be an array.")
        return errors
    var foliage_ids: Dictionary = {}
    var scatter_ids: Dictionary = {}
    var spline_ids: Dictionary = {}
    for value in foliage_value:
        if not value is Dictionary:
            errors.append("Procedural foliage_sets must contain dictionaries.")
            continue
        var record: Dictionary = value
        errors.append_array(validate_foliage_set(record))
        _track_unique_id(str(record.get("foliage_set_id", "")), foliage_ids, "foliage_set_id", errors)
    for value in scatter_value:
        if not value is Dictionary:
            errors.append("Procedural scatter_layers must contain dictionaries.")
            continue
        var record: Dictionary = value
        errors.append_array(validate_scatter_layer(record, foliage_ids.keys()))
        _track_unique_id(str(record.get("scatter_layer_id", "")), scatter_ids, "scatter_layer_id", errors)
    for value in splines_value:
        if not value is Dictionary:
            errors.append("Procedural splines must contain dictionaries.")
            continue
        var record: Dictionary = value
        errors.append_array(validate_spline(record))
        _track_unique_id(str(record.get("spline_id", "")), spline_ids, "spline_id", errors)
    return errors


static func validate_foliage_set(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if not StableId.is_valid(str(data.get("foliage_set_id", ""))):
        errors.append("Foliage set foliage_set_id must be a stable UUID.")
    if str(data.get("display_name", "")).strip_edges().is_empty():
        errors.append("Foliage set display_name is required.")
    errors.append_array(validate_source(data.get("source", {}), "Foliage set"))
    var scale_range: Variant = data.get("scale_range", [])
    if not scale_range is Array or scale_range.size() != 2:
        errors.append("Foliage set scale_range must contain min and max values.")
    else:
        var scale_min: float = float(scale_range[0])
        var scale_max: float = float(scale_range[1])
        if scale_min <= 0.0 or scale_max < scale_min:
            errors.append("Foliage set scale_range must be positive and ordered.")
    if int(data.get("max_instances_per_cell", 0)) <= 0:
        errors.append("Foliage set max_instances_per_cell must be positive.")
    return errors


static func validate_scatter_layer(data: Dictionary, foliage_ids: Array = []) -> Array[String]:
    var errors: Array[String] = []
    if not StableId.is_valid(str(data.get("scatter_layer_id", ""))):
        errors.append("Scatter layer scatter_layer_id must be a stable UUID.")
    if str(data.get("display_name", "")).strip_edges().is_empty():
        errors.append("Scatter layer display_name is required.")
    var foliage_id: String = str(data.get("foliage_set_id", ""))
    if not StableId.is_valid(foliage_id):
        errors.append("Scatter layer foliage_set_id must be a stable UUID.")
    elif not foliage_ids.is_empty() and not foliage_ids.has(foliage_id):
        errors.append("Scatter layer references a missing foliage set.")
    if float(data.get("density_per_100m2", 0.0)) <= 0.0:
        errors.append("Scatter layer density_per_100m2 must be positive.")
    if float(data.get("minimum_spacing_m", -1.0)) < 0.0:
        errors.append("Scatter layer minimum_spacing_m must be non-negative.")
    errors.append_array(_validate_range(data.get("slope_range_deg", []), 0.0, 90.0, "Scatter slope_range_deg"))
    errors.append_array(_validate_range(data.get("height_range_m", []), -100000.0, 100000.0, "Scatter height_range_m"))
    var biome_ids: Variant = data.get("biome_ids", [])
    if not biome_ids is Array:
        errors.append("Scatter layer biome_ids must be an array.")
    else:
        for biome_id in biome_ids:
            if not StableId.is_valid(str(biome_id)):
                errors.append("Scatter layer biome_ids must contain stable UUIDs.")
    var strokes: Variant = data.get("strokes", [])
    if not strokes is Array:
        errors.append("Scatter layer strokes must be an array.")
    else:
        var seen_strokes: Dictionary = {}
        for value in strokes:
            if not value is Dictionary:
                errors.append("Scatter layer strokes must contain dictionaries.")
                continue
            var stroke: Dictionary = value
            errors.append_array(validate_stroke(stroke))
            _track_unique_id(str(stroke.get("stroke_id", "")), seen_strokes, "stroke_id", errors)
    return errors


static func validate_stroke(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if not StableId.is_valid(str(data.get("stroke_id", ""))):
        errors.append("Scatter stroke stroke_id must be a stable UUID.")
    if not StableId.is_valid(str(data.get("cell_id", ""))):
        errors.append("Scatter stroke cell_id must be a stable UUID.")
    if not STROKE_OPERATIONS.has(str(data.get("operation", ""))):
        errors.append("Scatter stroke operation is invalid.")
    if not _valid_vector3(data.get("center", [])):
        errors.append("Scatter stroke center must contain three numeric values.")
    if float(data.get("radius_m", 0.0)) <= 0.0:
        errors.append("Scatter stroke radius_m must be positive.")
    var strength: float = float(data.get("strength", -1.0))
    if strength < 0.0 or strength > 1.0:
        errors.append("Scatter stroke strength must be between 0 and 1.")
    return errors


static func validate_spline(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if not StableId.is_valid(str(data.get("spline_id", ""))):
        errors.append("Spline spline_id must be a stable UUID.")
    if str(data.get("display_name", "")).strip_edges().is_empty():
        errors.append("Spline display_name is required.")
    if not SPLINE_KINDS.has(str(data.get("kind", ""))):
        errors.append("Spline kind is invalid.")
    if float(data.get("width_m", 0.0)) <= 0.0:
        errors.append("Spline width_m must be positive.")
    if float(data.get("sample_spacing_m", 0.0)) <= 0.0:
        errors.append("Spline sample_spacing_m must be positive.")
    if str(data.get("kind", "")) == "fence":
        errors.append_array(validate_source(data.get("segment_source", {}), "Fence spline"))
    var points: Variant = data.get("points", [])
    if not points is Array:
        errors.append("Spline points must be an array.")
        return errors
    if points.size() < 2:
        errors.append("Spline must contain at least two points.")
    var seen_points: Dictionary = {}
    for value in points:
        if not value is Dictionary:
            errors.append("Spline points must contain dictionaries.")
            continue
        var point: Dictionary = value
        var point_id: String = str(point.get("point_id", ""))
        if not StableId.is_valid(point_id):
            errors.append("Spline point point_id must be a stable UUID.")
        else:
            _track_unique_id(point_id, seen_points, "point_id", errors)
        if not _valid_vector3(point.get("position", [])):
            errors.append("Spline point position must contain three numeric values.")
    return errors


static func validate_source(value: Variant, label: String) -> Array[String]:
    var errors: Array[String] = []
    if not value is Dictionary:
        return ["%s source must be a dictionary." % label]
    var source: Dictionary = value
    var kind: String = str(source.get("kind", ""))
    if not SOURCE_KINDS.has(kind):
        errors.append("%s source kind is invalid." % label)
        return errors
    if kind == "primitive":
        if not PRIMITIVES.has(str(source.get("primitive", ""))):
            errors.append("%s primitive source is invalid." % label)
    elif not StableId.is_valid(str(source.get("source_id", ""))):
        errors.append("%s source_id must be a stable UUID." % label)
    return errors


static func _validate_range(value: Variant, minimum: float, maximum: float, label: String) -> Array[String]:
    if not value is Array or value.size() != 2:
        return ["%s must contain two values." % label]
    var low: float = float(value[0])
    var high: float = float(value[1])
    if low < minimum or high > maximum or high < low:
        return ["%s is outside the supported ordered range." % label]
    return []


static func _track_unique_id(value: String, seen: Dictionary, label: String, errors: Array[String]) -> void:
    if not StableId.is_valid(value):
        return
    if seen.has(value):
        errors.append("Procedural registry contains a duplicate %s." % label)
    else:
        seen[value] = true


static func _valid_vector3(value: Variant) -> bool:
    if not value is Array or value.size() != 3:
        return false
    for component in value:
        if not component is int and not component is float:
            return false
    return true
