extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const TerrainRepository = preload("res://src/terrain/terrain_repository.gd")
const TerrainRuntime = preload("res://src/terrain/terrain_runtime.gd")
const TerrainBrush = preload("res://src/terrain/terrain_brush.gd")
const MeshBuilder = preload("res://src/terrain/terrain_mesh_builder.gd")

const CI_BUDGET_MSEC := 5000


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var started: int = Time.get_ticks_msec()
    var medium_result: Dictionary = _build_runtime(&"medium", "medium")
    if not medium_result.get("ok", false) or int(medium_result.get("chunks", 0)) != 9:
        errors.append("Representative Medium terrain workload must build all nine non-streaming chunks.")
    if int(medium_result.get("triangles", 0)) != 4608:
        errors.append("Medium terrain workload must have deterministic 17x17 grid triangle counts across nine chunks.")
    var large_result: Dictionary = _build_runtime(&"large", "large")
    if not large_result.get("ok", false) or int(large_result.get("chunks", 0)) != 9:
        errors.append("Representative Large workload must load only its deterministic 3x3 streamed chunk set at origin.")

    var cell: Dictionary = medium_result.get("cell", {})
    if not cell.is_empty():
        for index in range(100):
            var mode: String = ["raise", "lower", "smooth", "flatten"][index % 4]
            var brush: Dictionary = {"mode": mode, "center": Vector3.ZERO, "radius": 180.0, "strength": 0.25}
            if mode == "flatten": brush["target_height"] = 0.0
            var result: Dictionary = TerrainBrush.apply(cell, brush)
            if not result.get("ok", false):
                errors.append("Representative 100-stroke terrain workload must remain behaviorally valid.")
                break
            cell["heights"] = result.get("heights", []).duplicate()
    var elapsed: int = Time.get_ticks_msec() - started
    if elapsed > CI_BUDGET_MSEC:
        errors.append("Representative Phase 5 terrain/streaming CI workload exceeded the %dms regression budget (%dms)." % [CI_BUDGET_MSEC, elapsed])
    return errors


static func _build_runtime(profile: StringName, label: String) -> Dictionary:
    var root: String = "user://tests/phase5_scale_%s_%s" % [label, StableId.generate()]
    var project = WorldProject.new()
    project.initialize_new("Scale Terrain", profile, "blank_sandbox")
    var repository = TerrainRepository.new(root.path_join("project"))
    var open_result: Dictionary = repository.open_or_create(project)
    if not open_result.get("ok", false): return {"ok": false}
    var state = open_result.get("state")
    var runtime = TerrainRuntime.new()
    var bind_result: Dictionary = runtime.bind_state(state)
    if not bind_result.get("ok", false): runtime.free(); return {"ok": false}
    var chunks: int = runtime.chunk_count()
    var center: Dictionary = state.get_cell_at_position(Vector3.ZERO)
    var triangles: int = MeshBuilder.triangle_count(center) * chunks
    runtime.free()
    return {"ok": true, "chunks": chunks, "triangles": triangles, "cell": center}
