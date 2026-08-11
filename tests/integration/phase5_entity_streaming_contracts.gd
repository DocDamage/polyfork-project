extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const TerrainRepository = preload("res://src/terrain/terrain_repository.gd")
const TerrainController = preload("res://src/terrain/terrain_controller.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var root: String = "user://tests/phase5_entity_stream_%s" % StableId.generate()
    var project = WorldProject.new()
    project.initialize_new("Entity Stream", &"large", "blank_sandbox")
    var repository = TerrainRepository.new(root.path_join("project"))
    var terrain_open: Dictionary = repository.open_or_create(project)
    if not terrain_open.get("ok", false):
        errors.append("Entity streaming fixture requires a valid Large terrain partition.")
        return errors
    var state = terrain_open.get("state")
    var origin_cell: String = state.cell_id_at_position(Vector3.ZERO)
    var far_cell: String = state.cell_id_at_position(Vector3(2048.0, 0.0, 0.0))
    if origin_cell.is_empty() or far_cell.is_empty() or origin_cell == far_cell:
        errors.append("Entity streaming fixture requires distinct origin and far terrain cells.")
        return errors

    var parent = WorldEntity.new()
    parent.initialize_new("Origin Parent", origin_cell)
    var child = WorldEntity.new()
    child.initialize_new("Far Child", far_cell)
    child.parent_entity_id = parent.entity_id
    child.transform["position"] = [2048.0, 0.5, 0.0]
    var entity_records: Array[Dictionary] = [parent.to_dictionary(), child.to_dictionary()]
    project.entity_records = entity_records
    if not project.validate().is_empty():
        errors.append("Cross-cell parent/child fixture must be a valid persisted project before streaming.")
        return errors

    var session = EditorSession.new()
    var bind_result: Dictionary = session.bind_project(project, func() -> Dictionary: return {"ok": true, "errors": []})
    if not bind_result.get("ok", false) or session.get_bridge().entity_count() != 2:
        errors.append("Before Large streaming is attached, both valid persisted entities must bridge normally.")
        session.free()
        return errors
    var controller = TerrainController.new()
    var controller_bind: Dictionary = controller.bind_project(project, root.path_join("project"), session, func() -> Dictionary: return {"ok": true, "errors": []})
    if not controller_bind.get("ok", false):
        errors.append("Terrain controller must synchronize Large-world entity streaming: %s" % [controller_bind.get("errors", [])])
        controller.free()
        session.free()
        return errors
    var bridge = session.get_bridge()
    if not bridge.is_cell_filter_enabled() or not bridge.has_entity(parent.entity_id) or bridge.has_entity(child.entity_id):
        errors.append("At the origin, Large-world entity streaming must keep the origin entity and unload the far-cell entity.")

    var shift: Dictionary = controller.update_streaming_focus(Vector3(2048.0, 0.0, 0.0))
    if not shift.get("ok", false) or bridge.has_entity(parent.entity_id) or not bridge.has_entity(child.entity_id):
        errors.append("Moving streaming focus must swap runtime entities according to stable owning cell IDs.")
    var child_node = bridge.get_entity_node(child.entity_id)
    if child_node == null or child_node.get_parent() != bridge:
        errors.append("A loaded child whose valid parent is temporarily unloaded must attach safely at the bridge root.")
    var persisted_child: Dictionary = _record(project.entity_records, child.entity_id)
    if str(persisted_child.get("parent_entity_id", "")) != parent.entity_id:
        errors.append("Streaming must never rewrite a persistent cross-cell parent stable ID when its target is unloaded.")

    var back: Dictionary = controller.update_streaming_focus(Vector3.ZERO)
    if not back.get("ok", false) or not bridge.has_entity(parent.entity_id) or bridge.has_entity(child.entity_id):
        errors.append("Returning streaming focus must deterministically restore the origin entity set.")

    var invalid_far: Dictionary = child.to_dictionary()
    invalid_far["parent_entity_id"] = StableId.generate()
    var invalid_records: Array[Dictionary] = [parent.to_dictionary(), invalid_far]
    var rejected: Dictionary = bridge.rebuild(invalid_records)
    if rejected.get("ok", false) or not bridge.has_entity(parent.entity_id):
        errors.append("Cell filtering must still validate references in unloaded records and preserve the prior known-good runtime mapping on failure.")

    controller.free()
    session.free()
    return errors


static func _record(records: Array, entity_id: String) -> Dictionary:
    for record in records:
        if str(record.get("entity_id", "")) == entity_id: return record
    return {}
