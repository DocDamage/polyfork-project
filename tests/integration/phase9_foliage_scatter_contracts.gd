extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const TerrainRepository = preload("res://src/terrain/terrain_repository.gd")
const TerrainRuntime = preload("res://src/terrain/terrain_runtime.gd")
const ProceduralRuntime = preload("res://src/procedural/procedural_runtime.gd")
const ProceduralService = preload("res://src/procedural/procedural_service.gd")
const SourceResolver = preload("res://src/procedural/procedural_source_resolver.gd")


static func run_checks(tree_root: Node) -> Array[String]:
    var errors: Array[String] = []
    var fixture := Node.new()
    tree_root.add_child(fixture)
    var project = WorldProject.new()
    project.initialize_new("Phase 9 Foliage", &"small", "blank_sandbox")
    var dirty_count: Array[int] = [0]
    var editor = EditorSession.new()
    fixture.add_child(editor)
    var editor_bind: Dictionary = editor.bind_project(project, func() -> Dictionary:
        dirty_count[0] += 1
        return {"ok": true, "errors": []}
    )
    if not editor_bind.get("ok", false):
        fixture.queue_free()
        return ["Phase 9 foliage fixture could not bind editor session."]
    var root: String = "user://tests/phase9_foliage_%s" % StableId.generate()
    var terrain_open: Dictionary = TerrainRepository.new(root).open_or_create(project)
    if not terrain_open.get("ok", false):
        fixture.queue_free()
        return ["Phase 9 foliage fixture could not initialize terrain: %s" % str(terrain_open.get("errors", []))]
    var terrain_state = terrain_open.get("state")
    var terrain_runtime = TerrainRuntime.new()
    fixture.add_child(terrain_runtime)
    var terrain_bind: Dictionary = terrain_runtime.bind_state(terrain_state)
    if not terrain_bind.get("ok", false):
        fixture.queue_free()
        return ["Phase 9 foliage fixture could not bind terrain runtime."]
    var procedural_runtime = ProceduralRuntime.new()
    procedural_runtime.set_meta("terrain_runtime", terrain_runtime)
    fixture.add_child(procedural_runtime)
    var service = ProceduralService.new()
    var service_bind: Dictionary = service.bind_project(project, root, editor, func() -> Dictionary:
        dirty_count[0] += 1
        return {"ok": true, "errors": []}
    , terrain_state, procedural_runtime)
    if not service_bind.get("ok", false):
        fixture.queue_free()
        return ["Phase 9 foliage service could not bind: %s" % str(service_bind.get("errors", []))]

    var foliage_result: Dictionary = service.create_foliage_set("Grass", {"kind": "primitive", "primitive": "grass"}, {"max_instances_per_cell": 512})
    var foliage_id: String = str(foliage_result.get("foliage_set_id", ""))
    if not foliage_result.get("ok", false) or foliage_id.is_empty():
        errors.append("Primitive foliage set creation must be command-backed and return stable identity.")
    var scatter_result: Dictionary = service.create_scatter_layer("Grass Scatter", foliage_id, {"density_per_100m2": 10.0, "minimum_spacing_m": 1.5, "seed": 77})
    var scatter_id: String = str(scatter_result.get("scatter_layer_id", ""))
    if not scatter_result.get("ok", false) or scatter_id.is_empty():
        errors.append("Scatter layer creation must be command-backed and return stable identity.")
    var paint_result: Dictionary = service.add_scatter_stroke(scatter_id, "paint", Vector3.ZERO, 32.0, 1.0)
    if not paint_result.get("ok", false):
        errors.append("Scatter paint must author a stable terrain-owned stroke.")
    var cell_id: String = str(paint_result.get("cell_id", ""))
    var painted_count: int = procedural_runtime.total_instance_count()
    if painted_count <= 0:
        errors.append("Painted scatter must generate real MultiMesh instances on terrain.")
    var batch = procedural_runtime.get_batch(scatter_id, cell_id)
    if batch == null or not batch is MultiMeshInstance3D or batch.multimesh == null:
        errors.append("Scatter runtime must use a real MultiMeshInstance3D batch.")
    var first_pass: Array[Transform3D] = _batch_transforms(batch)
    var refresh: Dictionary = procedural_runtime.refresh_all()
    if not refresh.get("ok", false):
        errors.append("Procedural runtime must regenerate deterministically.")
    var regenerated = procedural_runtime.get_batch(scatter_id, cell_id)
    var second_pass: Array[Transform3D] = _batch_transforms(regenerated)
    if first_pass != second_pass:
        errors.append("Same authored strokes and seed must regenerate identical MultiMesh transforms.")

    var erase_result: Dictionary = service.add_scatter_stroke(scatter_id, "erase", Vector3.ZERO, 32.0, 1.0)
    if not erase_result.get("ok", false):
        errors.append("Scatter erase must author a nondestructive erase stroke.")
    if procedural_runtime.total_instance_count() != 0:
        errors.append("Full-strength erase over the paint stroke must remove generated instances without deleting authored paint data.")
    if not editor.undo_edit().get("ok", false):
        errors.append("Universal Undo must undo the latest procedural erase stroke.")
    elif procedural_runtime.total_instance_count() != painted_count:
        errors.append("Undoing erase must regenerate the prior deterministic foliage result.")
    if not editor.redo_edit().get("ok", false):
        errors.append("Universal Redo must restore the procedural erase stroke.")
    elif procedural_runtime.total_instance_count() != 0:
        errors.append("Redoing erase must regenerate the erased foliage result.")
    if dirty_count[0] < 3:
        errors.append("Procedural authoring must signal project dirty state.")

    var resolver = SourceResolver.new()
    resolver.bind()
    for primitive in ["grass", "shrub", "tree", "post"]:
        var primitive_result: Dictionary = resolver.resolve_mesh({"kind": "primitive", "primitive": primitive})
        if not primitive_result.get("ok", false) or not primitive_result.get("mesh") is Mesh:
            errors.append("Built-in primitive foliage source must resolve: %s" % primitive)
    if resolver.resolve_mesh({"kind": "asset", "source_id": StableId.generate()}).get("ok", false):
        errors.append("Asset-backed foliage without a bound Asset Library must fail closed.")

    fixture.queue_free()
    return errors


static func _batch_transforms(batch) -> Array[Transform3D]:
    var result: Array[Transform3D] = []
    if batch == null or not batch is MultiMeshInstance3D or batch.multimesh == null:
        return result
    for index in range(batch.multimesh.instance_count):
        result.append(batch.multimesh.get_instance_transform(index))
    return result
