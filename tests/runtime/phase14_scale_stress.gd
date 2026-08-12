extends SceneTree

const Benchmarks = preload("res://src/scale/benchmark_contract.gd")
const Profiles = preload("res://src/scale/performance_profiles.gd")

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var errors: Array[String] = []
    var results: Dictionary = {}
    for fixture in Benchmarks.fixtures():
        var fixture_id: String = str(fixture.get("fixture_id", ""))
        var result: Dictionary = _exercise_fixture(fixture)
        results[fixture_id] = result
        if not result.get("ok", false): errors.append_array(result.get("errors", []))
        print("PHASE14_SCALE %s %s" % [fixture_id.to_upper(), JSON.stringify(result)])
    var report: Dictionary = {
        "schema_version": 1,
        "godot_version": Engine.get_version_info().get("string", "unknown"),
        "fixtures": results,
        "profiles": Profiles.all_profiles(),
        "hard_failures": errors.duplicate(),
    }
    var report_result: Dictionary = _write_report(report)
    if not report_result.get("ok", false): errors.append_array(report_result.get("errors", []))
    if errors.is_empty():
        print("PASS: Phase 14 Small/Medium/Large/Stress scale smoke completed.")
        quit(0); return
    for error in errors: push_error(error)
    quit(1)

func _exercise_fixture(fixture: Dictionary) -> Dictionary:
    var errors: Array[String] = []
    var fixture_id: String = str(fixture.get("fixture_id", "unknown"))
    var start_usec: int = Time.get_ticks_usec()
    var entities: Array[Dictionary] = []
    var entity_count: int = int(fixture.get("entity_count", 0))
    entities.resize(entity_count)
    for index in range(entity_count):
        entities[index] = {"entity_id": "scale-%s-%08d" % [fixture_id, index], "cell": index % maxi(1, int(fixture.get("terrain_cell_count", 1))), "component": index % 17}
    var gameplay: PackedInt32Array = PackedInt32Array()
    gameplay.resize(int(fixture.get("gameplay_component_count", 0)))
    for index in range(gameplay.size()): gameplay[index] = index % 31
    var terrain: PackedInt32Array = PackedInt32Array()
    terrain.resize(int(fixture.get("terrain_cell_count", 0)))
    for index in range(terrain.size()): terrain[index] = index
    var procedural: PackedInt32Array = PackedInt32Array()
    procedural.resize(int(fixture.get("procedural_rule_count", 0)))
    for index in range(procedural.size()): procedural[index] = index * 3
    var visual: PackedInt32Array = PackedInt32Array()
    visual.resize(int(fixture.get("visual_graph_count", 0)))
    for index in range(visual.size()): visual[index] = index * 7
    var foliage := MultiMesh.new()
    foliage.transform_format = MultiMesh.TRANSFORM_3D
    foliage.instance_count = int(fixture.get("foliage_instance_count", 0))
    var construction_ms: float = float(Time.get_ticks_usec() - start_usec) / 1000.0

    var iteration_start: int = Time.get_ticks_usec()
    var checksum: int = 0
    for entity in entities: checksum += int(entity.get("cell", 0)) + int(entity.get("component", 0))
    for value in gameplay: checksum += value
    for value in terrain: checksum += value
    for value in procedural: checksum += value
    for value in visual: checksum += value
    var iteration_ms: float = float(Time.get_ticks_usec() - iteration_start) / 1000.0

    var serialize_start: int = Time.get_ticks_usec()
    var serialized: String = JSON.stringify({"fixture_id": fixture_id, "entities": entities, "terrain": Array(terrain), "procedural": Array(procedural), "visual": Array(visual)})
    var serialize_ms: float = float(Time.get_ticks_usec() - serialize_start) / 1000.0
    var clone_start: int = Time.get_ticks_usec()
    var clone: Array[Dictionary] = entities.duplicate(true)
    var clone_ms: float = float(Time.get_ticks_usec() - clone_start) / 1000.0
    var memory_mb: float = float(Performance.get_monitor(Performance.MEMORY_STATIC)) / (1024.0 * 1024.0)
    var budgets: Dictionary = fixture.get("budgets", {})

    if entities.size() != entity_count or clone.size() != entity_count: errors.append("%s entity scale fixture lost records." % fixture_id)
    if foliage.instance_count != int(fixture.get("foliage_instance_count", 0)): errors.append("%s foliage MultiMesh allocation did not preserve the requested instance count." % fixture_id)
    if serialized.is_empty() or checksum <= 0: errors.append("%s scale fixture did not execute deterministic traversal/serialization work." % fixture_id)
    if memory_mb > float(budgets.get("memory_mb", 999999.0)): errors.append("%s static memory %.1f MB exceeded hard budget %.1f MB." % [fixture_id, memory_mb, float(budgets.get("memory_mb", 0.0))])
    if construction_ms > float(budgets.get("project_open_ms", 999999.0)): errors.append("%s construction %.1f ms exceeded project-open budget %.1f ms." % [fixture_id, construction_ms, float(budgets.get("project_open_ms", 0.0))])
    if serialize_ms > float(budgets.get("save_ms", 999999.0)): errors.append("%s serialization %.1f ms exceeded save budget %.1f ms." % [fixture_id, serialize_ms, float(budgets.get("save_ms", 0.0))])
    if clone_ms > float(budgets.get("build_play_ms", 999999.0)): errors.append("%s runtime clone %.1f ms exceeded Build/Play budget %.1f ms." % [fixture_id, clone_ms, float(budgets.get("build_play_ms", 0.0))])
    return {
        "ok": errors.is_empty(),
        "errors": errors,
        "entity_count": entities.size(),
        "terrain_cell_count": terrain.size(),
        "foliage_instance_count": foliage.instance_count,
        "procedural_rule_count": procedural.size(),
        "visual_graph_count": visual.size(),
        "gameplay_component_count": gameplay.size(),
        "construction_ms": construction_ms,
        "iteration_ms": iteration_ms,
        "serialization_ms": serialize_ms,
        "runtime_clone_ms": clone_ms,
        "memory_static_mb": memory_mb,
        "checksum": checksum,
        "budgets": budgets.duplicate(true),
    }

func _write_report(report: Dictionary) -> Dictionary:
    var root: String = "res://artifacts/phase14"
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS: return {"ok": false, "errors": ["Could not create Phase 14 evidence directory."]}
    var path: String = root.path_join("scale-stress-report.json")
    var handle: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if handle == null: return {"ok": false, "errors": ["Could not write Phase 14 scale stress report."]}
    handle.store_string(JSON.stringify(report, "  ", true) + "\n")
    handle.close()
    return {"ok": true, "errors": [], "path": path}
