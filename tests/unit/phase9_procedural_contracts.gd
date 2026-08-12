extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const Contracts = preload("res://src/procedural/procedural_contracts.gd")
const Repository = preload("res://src/procedural/procedural_repository.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new()
    project.initialize_new("Phase 9 Foundation", &"small", "blank_sandbox")
    var root: String = "user://tests/phase9_foundation_%s" % StableId.generate()
    var repository = Repository.new(root)
    var open_result: Dictionary = repository.open_or_create(project)
    if not open_result.get("ok", false):
        return ["Phase 9 procedural repository could not initialize: %s" % str(open_result.get("errors", []))]
    if not bool(open_result.get("created", false)):
        errors.append("Phase 9 procedural repository must report first-run creation.")
    var state = open_result.get("state")
    if state == null:
        return ["Phase 9 procedural repository did not return state."]
    var foliage_id: String = StableId.generate()
    var scatter_id: String = StableId.generate()
    var spline_id: String = StableId.generate()
    var cell_id: String = StableId.generate()
    var foliage: Dictionary = _foliage(foliage_id)
    var scatter: Dictionary = _scatter(scatter_id, foliage_id, cell_id)
    var spline: Dictionary = _spline(spline_id)
    var document: Dictionary = state.to_document()
    document["foliage_sets"] = [foliage]
    document["scatter_layers"] = [scatter]
    document["splines"] = [spline]
    var replace_errors: Array[String] = state.replace_document(document)
    if not replace_errors.is_empty():
        errors.append("Valid Phase 9 procedural records must load: %s" % str(replace_errors))
    var flush: Dictionary = repository.flush(state, project)
    if not flush.get("ok", false):
        errors.append("Valid Phase 9 procedural records must persist: %s" % str(flush.get("errors", [])))
    if not project.registries.get("procedural_foliage_set_ids", []).has(foliage_id):
        errors.append("WorldProject must mirror procedural foliage stable IDs.")
    if not project.registries.get("procedural_scatter_layer_ids", []).has(scatter_id):
        errors.append("WorldProject must mirror procedural scatter stable IDs.")
    if not project.registries.get("procedural_spline_ids", []).has(spline_id):
        errors.append("WorldProject must mirror procedural spline stable IDs.")
    var reopened: Dictionary = Repository.new(root).open_or_create(project)
    if not reopened.get("ok", false):
        errors.append("Persisted Phase 9 procedural registry must reopen.")
    else:
        var reopened_state = reopened.get("state")
        if reopened_state == null or reopened_state.to_document() != state.to_document():
            errors.append("Phase 9 procedural save/reopen must preserve authored records exactly.")
    var future: Dictionary = state.to_document()
    future["schema_version"] = Contracts.SCHEMA_VERSION + 1
    if Contracts.validate_document(future).is_empty():
        errors.append("Future procedural schema versions must fail closed.")
    var duplicate: Dictionary = state.to_document()
    duplicate["foliage_sets"] = [foliage, foliage.duplicate(true)]
    if Contracts.validate_document(duplicate).is_empty():
        errors.append("Duplicate procedural stable IDs must fail closed.")
    var missing_reference: Dictionary = state.to_document()
    var bad_scatter: Dictionary = scatter.duplicate(true)
    bad_scatter["foliage_set_id"] = StableId.generate()
    missing_reference["scatter_layers"] = [bad_scatter]
    if Contracts.validate_document(missing_reference).is_empty():
        errors.append("Scatter layers referencing missing foliage sets must fail closed.")
    return errors


static func _foliage(foliage_id: String) -> Dictionary:
    return {
        "foliage_set_id": foliage_id,
        "display_name": "Meadow Grass",
        "source": {"kind": "primitive", "primitive": "grass"},
        "scale_range": [0.8, 1.2],
        "random_yaw": true,
        "align_to_normal": true,
        "cast_shadows": false,
        "max_instances_per_cell": 4000,
    }


static func _scatter(scatter_id: String, foliage_id: String, cell_id: String) -> Dictionary:
    return {
        "scatter_layer_id": scatter_id,
        "display_name": "Meadow Scatter",
        "foliage_set_id": foliage_id,
        "enabled": true,
        "seed": 42,
        "density_per_100m2": 8.0,
        "minimum_spacing_m": 1.25,
        "slope_range_deg": [0.0, 35.0],
        "height_range_m": [-1000.0, 1000.0],
        "biome_ids": [],
        "strokes": [{
            "stroke_id": StableId.generate(),
            "operation": "paint",
            "cell_id": cell_id,
            "center": [32.0, 0.0, 32.0],
            "radius_m": 24.0,
            "strength": 0.75,
        }],
    }


static func _spline(spline_id: String) -> Dictionary:
    return {
        "spline_id": spline_id,
        "display_name": "Test Road",
        "kind": "road",
        "closed": false,
        "width_m": 6.0,
        "sample_spacing_m": 3.0,
        "terrain_conform": true,
        "points": [
            {"point_id": StableId.generate(), "position": [0.0, 0.0, 0.0]},
            {"point_id": StableId.generate(), "position": [64.0, 0.0, 32.0]},
        ],
    }
