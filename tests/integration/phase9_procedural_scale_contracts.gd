extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const TerrainRepository = preload("res://src/terrain/terrain_repository.gd")
const TerrainRuntime = preload("res://src/terrain/terrain_runtime.gd")
const ProceduralState = preload("res://src/procedural/procedural_state.gd")
const ProceduralRuntime = preload("res://src/procedural/procedural_runtime.gd")
const SourceResolver = preload("res://src/procedural/procedural_source_resolver.gd")

const CI_BUDGET_MS := 12000


static func run_checks(tree_root: Node) -> Array[String]:
    var errors: Array[String] = []
    var fixture := Node.new()
    tree_root.add_child(fixture)
    var project = WorldProject.new()
    project.initialize_new("Phase 9 Scale", &"large", "blank_sandbox")
    var root: String = "user://tests/phase9_scale_%s" % StableId.generate()
    var terrain_open: Dictionary = TerrainRepository.new(root).open_or_create(project)
    if not terrain_open.get("ok", false):
        fixture.queue_free()
        return ["Phase 9 scale fixture could not initialize large terrain."]
    var terrain_state = terrain_open.get("state")
    var terrain_runtime = TerrainRuntime.new()
    fixture.add_child(terrain_runtime)
    if not terrain_runtime.bind_state(terrain_state).get("ok", false):
        fixture.queue_free()
        return ["Phase 9 scale fixture could not bind terrain runtime."]

    var foliage_id: String = StableId.generate()
    var scatter_id: String = StableId.generate()
    var strokes: Array[Dictionary] = []
    var focus_points: Array[Vector3] = []
    var cell_size: float = float(terrain_state.manifest.get("cell_size_m", 1024.0))
    for cell_id in terrain_state.cell_ids():
        var cell: Dictionary = terrain_state.get_cell(cell_id)
        var coord: Array = cell.get("coord", [0, 0])
        var center := Vector3(float(coord[0]) * cell_size, 0.0, float(coord[1]) * cell_size)
        focus_points.append(center)
        strokes.append({
            "stroke_id": StableId.generate(),
            "operation": "paint",
            "cell_id": cell_id,
            "center": [center.x, 0.0, center.z],
            "radius_m": 55.0,
            "strength": 1.0,
        })
    if focus_points.size() < 20:
        errors.append("Large Phase 9 scale fixture must expose representative multi-cell terrain.")

    var road_id: String = StableId.generate()
    var fence_id: String = StableId.generate()
    var state = ProceduralState.new()
    var document := {
        "document_type": "procedural_registry",
        "schema_version": 1,
        "project_id": project.project_id,
        "foliage_sets": [{
            "foliage_set_id": foliage_id,
            "display_name": "Scale Grass",
            "source": {"kind": "primitive", "primitive": "grass"},
            "scale_range": [0.85, 1.15],
            "random_yaw": true,
            "align_to_normal": true,
            "cast_shadows": false,
            "max_instances_per_cell": 512,
        }],
        "scatter_layers": [{
            "scatter_layer_id": scatter_id,
            "display_name": "Scale Scatter",
            "foliage_set_id": foliage_id,
            "enabled": true,
            "seed": 9001,
            "density_per_100m2": 2.5,
            "minimum_spacing_m": 1.25,
            "slope_range_deg": [0.0, 50.0],
            "height_range_m": [-10000.0, 10000.0],
            "biome_ids": [],
            "strokes": strokes,
        }],
        "splines": [
            {
                "spline_id": road_id,
                "display_name": "Scale Road",
                "kind": "road",
                "closed": false,
                "width_m": 8.0,
                "sample_spacing_m": 32.0,
                "terrain_conform": true,
                "points": [
                    {"point_id": StableId.generate(), "position": [-2200.0, 0.0, -300.0]},
                    {"point_id": StableId.generate(), "position": [0.0, 0.0, 200.0]},
                    {"point_id": StableId.generate(), "position": [2200.0, 0.0, 500.0]},
                ],
            },
            {
                "spline_id": fence_id,
                "display_name": "Scale Fence",
                "kind": "fence",
                "closed": false,
                "width_m": 1.0,
                "sample_spacing_m": 24.0,
                "terrain_conform": true,
                "segment_source": {"kind": "primitive", "primitive": "post"},
                "points": [
                    {"point_id": StableId.generate(), "position": [-2100.0, 0.0, 700.0]},
                    {"point_id": StableId.generate(), "position": [2100.0, 0.0, 700.0]},
                ],
            }
        ],
    }
    var load_errors: Array[String] = state.load_document(document)
    if not load_errors.is_empty():
        fixture.queue_free()
        return ["Phase 9 scale procedural fixture is invalid: %s" % str(load_errors)]
    var resolver = SourceResolver.new()
    resolver.bind()
    var procedural_runtime = ProceduralRuntime.new()
    fixture.add_child(procedural_runtime)

    var started: int = Time.get_ticks_msec()
    var bind_result: Dictionary = procedural_runtime.bind_state(state, terrain_state, terrain_runtime, resolver)
    if not bind_result.get("ok", false):
        fixture.queue_free()
        return ["Phase 9 scale procedural runtime could not bind: %s" % str(bind_result.get("errors", []))]
    var peak_instances: int = procedural_runtime.total_instance_count()
    var transition_count: int = 0
    for focus in focus_points:
        var focus_result: Dictionary = terrain_runtime.update_focus(focus)
        if not focus_result.get("ok", false):
            errors.append("Large-world terrain focus transition failed during procedural scale verification.")
            break
        transition_count += 1
        peak_instances = maxi(peak_instances, procedural_runtime.total_instance_count())
        if procedural_runtime.get_active_cell_ids() != terrain_runtime.get_loaded_cell_ids():
            errors.append("Procedural runtime active cells must follow terrain streaming exactly.")
            break
        if procedural_runtime.batch_count() > terrain_runtime.get_loaded_cell_ids().size():
            errors.append("Procedural runtime must not retain foliage batches for unloaded terrain cells.")
            break
    var elapsed: int = Time.get_ticks_msec() - started
    if transition_count != focus_points.size():
        errors.append("Procedural scale verification must exercise every representative large-world focus point.")
    if peak_instances < 1000:
        errors.append("Procedural scale fixture must exercise thousands of derived foliage instances, not a trivial workload.")
    if procedural_runtime.get_spline_nodes(road_id).is_empty() or procedural_runtime.get_spline_nodes(fence_id).is_empty():
        errors.append("Procedural scale verification must keep road/fence derived runtime geometry active while streaming.")
    if elapsed > CI_BUDGET_MS:
        errors.append("Phase 9 representative procedural workload exceeded the %d ms CI regression budget (%d ms)." % [CI_BUDGET_MS, elapsed])
    print("Phase 9 representative workload: %d terrain focus transitions, peak %d foliage instances, road+fence regeneration in %d ms (CI budget %d ms)." % [transition_count, peak_instances, elapsed, CI_BUDGET_MS])
    fixture.queue_free()
    return errors
