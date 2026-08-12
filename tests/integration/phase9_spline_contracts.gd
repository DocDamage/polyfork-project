extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const TerrainRepository = preload("res://src/terrain/terrain_repository.gd")
const TerrainRuntime = preload("res://src/terrain/terrain_runtime.gd")
const ProceduralRuntime = preload("res://src/procedural/procedural_runtime.gd")
const ProceduralService = preload("res://src/procedural/procedural_service.gd")


static func run_checks(tree_root: Node) -> Array[String]:
    var errors: Array[String] = []
    var fixture := Node.new()
    tree_root.add_child(fixture)
    var project = WorldProject.new()
    project.initialize_new("Phase 9 Splines", &"small", "blank_sandbox")
    var editor = EditorSession.new()
    fixture.add_child(editor)
    var editor_bind: Dictionary = editor.bind_project(project, func() -> Dictionary: return {"ok": true, "errors": []})
    if not editor_bind.get("ok", false):
        fixture.queue_free()
        return ["Phase 9 spline fixture could not bind editor session."]
    var root: String = "user://tests/phase9_splines_%s" % StableId.generate()
    var terrain_open: Dictionary = TerrainRepository.new(root).open_or_create(project)
    if not terrain_open.get("ok", false):
        fixture.queue_free()
        return ["Phase 9 spline fixture could not initialize terrain."]
    var terrain_state = terrain_open.get("state")
    var terrain_runtime = TerrainRuntime.new()
    fixture.add_child(terrain_runtime)
    if not terrain_runtime.bind_state(terrain_state).get("ok", false):
        fixture.queue_free()
        return ["Phase 9 spline fixture could not bind terrain runtime."]
    var runtime = ProceduralRuntime.new()
    runtime.set_meta("terrain_runtime", terrain_runtime)
    fixture.add_child(runtime)
    var service = ProceduralService.new()
    var service_bind: Dictionary = service.bind_project(project, root, editor, func() -> Dictionary: return {"ok": true, "errors": []}, terrain_state, runtime)
    if not service_bind.get("ok", false):
        fixture.queue_free()
        return ["Phase 9 spline service could not bind: %s" % str(service_bind.get("errors", []))]

    var road_result: Dictionary = service.create_spline("Main Road", "road", [Vector3(-48, 0, -24), Vector3(0, 0, 12), Vector3(52, 0, 30)], {"width_m": 7.0, "sample_spacing_m": 4.0})
    var road_id: String = str(road_result.get("spline_id", ""))
    if not road_result.get("ok", false) or road_id.is_empty():
        errors.append("Road spline creation must be command-backed and return stable identity.")
    var road_nodes: Array[Node3D] = runtime.get_spline_nodes(road_id)
    if road_nodes.size() != 1 or not road_nodes[0] is MeshInstance3D:
        errors.append("Road spline must generate one streamed MeshInstance3D ribbon.")
    else:
        var road_mesh := (road_nodes[0] as MeshInstance3D).mesh
        if road_mesh == null or road_mesh.get_surface_count() == 0:
            errors.append("Road spline ribbon must contain real generated mesh geometry.")

    var point_ids: Array = road_result.get("point_ids", [])
    if point_ids.size() < 3:
        errors.append("Spline creation must return stable point identities.")
    else:
        var before_spline: Dictionary = service.get_state().get_spline(road_id)
        if not service.move_spline_point(road_id, str(point_ids[1]), Vector3(0, 0, 64)).get("ok", false):
            errors.append("Spline control points must be command-backed editable.")
        if service.get_state().get_spline(road_id) == before_spline:
            errors.append("Moving a spline point must change authored spline data.")
        if not editor.undo_edit().get("ok", false):
            errors.append("Universal Undo must restore spline point edits.")
        elif service.get_state().get_spline(road_id) != before_spline:
            errors.append("Undo must restore spline control points exactly.")
        if not editor.redo_edit().get("ok", false):
            errors.append("Universal Redo must reapply spline point edits.")

    var path_result: Dictionary = service.create_spline("Walking Path", "path", [Vector3(-20, 0, 40), Vector3(40, 0, 55)], {"width_m": 2.25, "sample_spacing_m": 2.0})
    if not path_result.get("ok", false) or runtime.get_spline_nodes(str(path_result.get("spline_id", ""))).is_empty():
        errors.append("Path spline must generate terrain-conforming ribbon geometry.")

    var fence_result: Dictionary = service.create_spline("Fence", "fence", [Vector3(-30, 0, -60), Vector3(40, 0, -60)], {"sample_spacing_m": 5.0, "segment_source": {"kind": "primitive", "primitive": "post"}})
    var fence_nodes: Array[Node3D] = runtime.get_spline_nodes(str(fence_result.get("spline_id", "")))
    if not fence_result.get("ok", false) or fence_nodes.size() != 1 or not fence_nodes[0] is MultiMeshInstance3D:
        errors.append("Fence spline must generate a real MultiMesh segment batch.")
    elif (fence_nodes[0] as MultiMeshInstance3D).multimesh == null or (fence_nodes[0] as MultiMeshInstance3D).multimesh.instance_count < 2:
        errors.append("Fence spline MultiMesh must contain repeated sampled segments.")

    var road_before_raise: Array[Node3D] = runtime.get_spline_nodes(road_id)
    var before_y: float = _mesh_min_y(road_before_raise)
    var cell_id: String = terrain_state.cell_id_at_position(Vector3.ZERO)
    var cell: Dictionary = terrain_state.get_cell(cell_id)
    var heights: Array = cell.get("heights", []).duplicate()
    for index in range(heights.size()): heights[index] = float(heights[index]) + 7.0
    cell["heights"] = heights
    cell["revision"] = int(cell.get("revision", 0)) + 1
    if not terrain_state.set_cell(cell, false).get("ok", false):
        errors.append("Terrain test fixture must be able to stage a height change.")
    elif not terrain_runtime.refresh_cell(cell_id).get("ok", false):
        errors.append("Terrain runtime refresh must succeed for procedural coupling.")
    else:
        var road_after_raise: Array[Node3D] = runtime.get_spline_nodes(road_id)
        var after_y: float = _mesh_min_y(road_after_raise)
        if after_y < before_y + 6.5:
            errors.append("Terrain cell refresh must automatically regenerate conforming spline geometry at the new terrain height.")

    if service.delete_spline_point(road_id, str(point_ids[0])).get("ok", false) and service.delete_spline_point(road_id, str(point_ids[1])).get("ok", false):
        errors.append("Spline point deletion must never reduce a spline below two control points.")

    fixture.queue_free()
    return errors


static func _mesh_min_y(nodes: Array[Node3D]) -> float:
    for node in nodes:
        if node is MeshInstance3D:
            var mesh := (node as MeshInstance3D).mesh
            if mesh != null: return mesh.get_aabb().position.y
    return -100000.0
