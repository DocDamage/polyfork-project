extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const TerrainRepository = preload("res://src/terrain/terrain_repository.gd")
const TerrainController = preload("res://src/terrain/terrain_controller.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var root: String = "user://tests/phase5_cell_owner_%s" % StableId.generate()
    var project = WorldProject.new()
    project.initialize_new("Cell Ownership", &"large", "blank_sandbox")
    var terrain_repo = TerrainRepository.new(root.path_join("project"))
    var terrain_open: Dictionary = terrain_repo.open_or_create(project)
    if not terrain_open.get("ok", false):
        errors.append("Cell-ownership fixture requires a valid Large terrain partition.")
        return errors
    var state = terrain_open.get("state")
    var origin_cell: String = state.cell_id_at_position(Vector3.ZERO)
    var far_position := Vector3(2048.0, 0.5, 0.0)
    var far_cell: String = state.cell_id_at_position(far_position)
    if origin_cell.is_empty() or far_cell.is_empty() or origin_cell == far_cell:
        errors.append("Cell-ownership fixture requires distinct origin/far partition cells.")
        return errors

    var dirty_count: Array[int] = [0]
    var session = EditorSession.new()
    var bind_result: Dictionary = session.bind_project(project, func() -> Dictionary:
        dirty_count[0] += 1
        return {"ok": true, "errors": []}
    )
    if not bind_result.get("ok", false):
        errors.append("Cell-ownership fixture requires a bound editor session.")
        session.free()
        return errors
    var controller = TerrainController.new()
    var controller_bind: Dictionary = controller.bind_project(project, root.path_join("project"), session, func() -> Dictionary:
        dirty_count[0] += 1
        return {"ok": true, "errors": []}
    )
    if not controller_bind.get("ok", false):
        errors.append("Terrain controller must bind the partition cell resolver.")
        controller.free(); session.free(); return errors

    var begin: Dictionary = session.begin_proxy_placement("Far Placement")
    var preview: Dictionary = session.update_placement_preview(far_position)
    if not begin.get("ok", false) or not preview.get("ok", false) or str(preview.get("record", {}).get("cell_id", "")) != far_cell:
        errors.append("Placement preview cell ownership must follow its world position before command commit.")
    var commit: Dictionary = session.commit_placement()
    var placed_id: String = str(commit.get("entity_id", ""))
    if not commit.get("ok", false) or str(_record(project.entity_records, placed_id).get("cell_id", "")) != far_cell:
        errors.append("Committed far placement must persist the resolved far terrain cell ID.")
    var undo_place: Dictionary = session.undo_edit()
    if not undo_place.get("ok", false) or not _record(project.entity_records, placed_id).is_empty():
        errors.append("Placement undo must remove the far-cell entity without damaging partition identity.")
    var redo_place: Dictionary = session.redo_edit()
    if not redo_place.get("ok", false) or str(_record(project.entity_records, placed_id).get("cell_id", "")) != far_cell:
        errors.append("Placement redo must restore the same stable far-cell ownership.")

    var origin_entity = WorldEntity.new()
    origin_entity.initialize_new("Mover", origin_cell)
    project.entity_records.append(origin_entity.to_dictionary())
    var refresh: Dictionary = session.refresh_runtime(false)
    if not refresh.get("ok", false):
        errors.append("Origin mover must enter the runtime bridge before movement testing.")
        controller.free(); session.free(); return errors
    session.select_entity(origin_entity.entity_id)
    var move_result: Dictionary = session.nudge_selected(&"move", Vector3(2048.0, 0.0, 0.0))
    var moved_record: Dictionary = _record(project.entity_records, origin_entity.entity_id)
    if not move_result.get("ok", false) or str(moved_record.get("cell_id", "")) != far_cell:
        errors.append("Command-backed entity movement across a partition boundary must update owning cell atomically with transform.")
    var moved_position: Array = moved_record.get("transform", {}).get("position", [])
    if moved_position.size() != 3 or float(moved_position[0]) < 2000.0:
        errors.append("Cross-cell movement must persist the moved transform together with its cell ID.")
    var undo_move: Dictionary = session.undo_edit()
    var restored: Dictionary = _record(project.entity_records, origin_entity.entity_id)
    if not undo_move.get("ok", false) or str(restored.get("cell_id", "")) != origin_cell:
        errors.append("Undoing a cross-cell move must restore the prior owning cell ID.")
    var restored_position: Array = restored.get("transform", {}).get("position", [])
    if restored_position.size() != 3 or not is_equal_approx(float(restored_position[0]), 0.0):
        errors.append("Undoing a cross-cell move must restore the prior transform in the same history operation.")
    var redo_move: Dictionary = session.redo_edit()
    var moved_again: Dictionary = _record(project.entity_records, origin_entity.entity_id)
    if not redo_move.get("ok", false) or str(moved_again.get("cell_id", "")) != far_cell:
        errors.append("Redoing a cross-cell move must restore the far owning cell ID together with the moved transform.")

    controller.free()
    session.free()
    return errors


static func _record(records: Array, entity_id: String) -> Dictionary:
    for record in records:
        if str(record.get("entity_id", "")) == entity_id: return record
    return {}
