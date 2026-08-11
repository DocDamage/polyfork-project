extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const Repository = preload("res://src/world/project_repository.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const PlaceEntityCommand = preload("res://src/commands/place_entity_command.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new()
    project.initialize_new("Phase 3 Session", &"medium", "blank_sandbox")
    var dirty_counter: Array[int] = [0]
    var session = EditorSession.new()
    var bind_result: Dictionary = session.bind_project(project, func() -> Dictionary:
        dirty_counter[0] += 1
        return {"ok": true, "errors": []}
    )
    if not bind_result.get("ok", false):
        errors.append("Editor session must bind a valid project: %s" % bind_result.get("errors", []))
        session.free()
        return errors

    var begin_result: Dictionary = session.begin_proxy_placement("Milestone Cube")
    if not begin_result.get("ok", false) or not session.is_placement_active():
        errors.append("Editor session must create a live placement ghost without mutating the project.")
    if not project.entity_records.is_empty() or dirty_counter[0] != 0:
        errors.append("Placement preview must remain non-authoring state until committed.")

    var duplicate_begin: Dictionary = session.begin_proxy_placement("Second Ghost")
    if duplicate_begin.get("ok", false) or not project.entity_records.is_empty():
        errors.append("A second concurrent placement preview must fail without partial project mutation.")

    var preview_result: Dictionary = session.update_placement_preview(Vector3(2.2, 0.5, 3.8))
    if not preview_result.get("ok", false):
        errors.append("Placement ghost must accept snapped preview updates.")
    var commit_result: Dictionary = session.commit_placement()
    if not commit_result.get("ok", false) or project.entity_records.size() != 1 or project.cell_ids.size() != 1:
        errors.append("Placement commit must add one valid project-owned entity and owning cell.")
        session.free()
        return errors
    if dirty_counter[0] != 1:
        errors.append("Successful placement must mark the project dirty exactly once.")

    var original_id: String = str(commit_result.get("entity_id", ""))
    if not StableId.is_valid(original_id) or not session.get_bridge().has_entity(original_id):
        errors.append("Committed placement must preserve a stable entity ID across project and runtime bridge.")
        session.free()
        return errors

    var moved: Dictionary = session.nudge_selected(&"move", Vector3(1.0, 0.0, 0.0))
    if not moved.get("ok", false) or dirty_counter[0] != 2:
        errors.append("Command-backed move must mutate the selected entity and signal dirty state.")
    var moved_position: Array = _record(project, original_id).get("transform", {}).get("position", [])
    if moved_position.size() != 3 or float(moved_position[0]) != 3.0:
        errors.append("Grid-snapped move must persist the expected authored position.")

    var undo_move: Dictionary = session.undo_edit()
    if not undo_move.get("ok", false) or dirty_counter[0] != 3:
        errors.append("Undo must restore project/runtime state and mark the project dirty.")
    var undone_position: Array = _record(project, original_id).get("transform", {}).get("position", [])
    if undone_position.size() != 3 or float(undone_position[0]) != 2.0:
        errors.append("Undo must restore the pre-move entity transform.")

    var redo_move: Dictionary = session.redo_edit()
    if not redo_move.get("ok", false) or dirty_counter[0] != 4:
        errors.append("Redo must reapply the authored transform and dirty the project.")

    session.select_entity(original_id)
    var duplicate_result: Dictionary = session.duplicate_selected()
    var copy_ids: Array[String] = duplicate_result.get("entity_ids", [])
    if not duplicate_result.get("ok", false) or copy_ids.size() != 1 or project.entity_records.size() != 2:
        errors.append("Duplicate must create exactly one stable-ID copy through command history.")
        session.free()
        return errors
    var copy_id: String = copy_ids[0]
    if copy_id == original_id or not StableId.is_valid(copy_id):
        errors.append("Duplicate must allocate a new stable UUID rather than reuse source identity.")

    var toggle_result: Dictionary = session.toggle_entity(original_id)
    if not toggle_result.get("ok", false) or session.get_selected_ids().size() != 2:
        errors.append("Multi-selection must support additive stable-ID selection.")
    var group_result: Dictionary = session.group_selected()
    var group_id: String = str(group_result.get("group_id", ""))
    if not group_result.get("ok", false) or not StableId.is_valid(group_id) or project.entity_records.size() != 3:
        errors.append("Grouping must create one generic stable-ID group entity.")
    if _parent_id(project, original_id) != group_id or _parent_id(project, copy_id) != group_id:
        errors.append("Grouping must persist child parent references using the group stable ID.")

    var delete_result: Dictionary = session.delete_selected()
    if not delete_result.get("ok", false) or not project.entity_records.is_empty():
        errors.append("Deleting a selected group must remove the group and its descendant closure atomically.")
    var undo_delete: Dictionary = session.undo_edit()
    if not undo_delete.get("ok", false) or project.entity_records.size() != 3:
        errors.append("Undo delete must restore the full group descendant closure.")
    var undo_group: Dictionary = session.undo_edit()
    if not undo_group.get("ok", false) or project.entity_records.size() != 2:
        errors.append("Undo group must remove the group entity and restore original parent relationships.")
    if not _parent_id(project, original_id).is_empty() or not _parent_id(project, copy_id).is_empty():
        errors.append("Undo group must restore the children to their original unparented state.")

    session.select_entity(original_id)
    var surface_result: Dictionary = session.snap_selection_to_surface(Vector3(7.0, 2.0, 8.0), Vector3.UP)
    if not surface_result.get("ok", false):
        errors.append("Surface snapping must route through command-backed transform editing.")
    var object_result: Dictionary = session.snap_selection_to_object([
        {"id": "target-a", "position": Vector3(8.0, 3.0, 8.0)}
    ])
    if not object_result.get("ok", false) or object_result.get("snap_id") != "target-a":
        errors.append("Object snapping must use deterministic candidate identity and persist through commands.")
    var socket_result: Dictionary = session.snap_selection_to_socket([
        {"id": "socket-a", "position": Vector3(8.0, 3.0, 9.0)}
    ])
    if not socket_result.get("ok", false) or socket_result.get("snap_id") != "socket-a":
        errors.append("Socket snapping must author the selected entity through the command framework.")
    var ground_result: Dictionary = session.drop_selection_to_ground(0.5)
    if not ground_result.get("ok", false):
        errors.append("Drop-to-ground must be available as a command-backed transform operation.")

    var dirty_before_failure: int = dirty_counter[0]
    session.clear_selection()
    var invalid_duplicate: Dictionary = session.duplicate_selected()
    if invalid_duplicate.get("ok", false) or dirty_counter[0] != dirty_before_failure:
        errors.append("Invalid editor actions must fail without dirty signaling or partial mutation.")

    var duplicate_record: Dictionary = _record(project, original_id)
    var duplicate_command = PlaceEntityCommand.new(project, duplicate_record)
    var project_before_failure := JSON.stringify(project.to_dictionary())
    if duplicate_command.execute() or JSON.stringify(project.to_dictionary()) != project_before_failure:
        errors.append("Duplicate-ID placement command failure must leave authored project state unchanged.")

    var root := "user://tests/phase3_editor_session_%s" % StableId.generate()
    var repository = Repository.new(root)
    var save_result: Dictionary = repository.save_project(project)
    if not save_result.get("ok", false):
        errors.append("Phase 3 authored project must save through the Phase 2 crash-safe repository.")
    else:
        var reopened: Dictionary = repository.open_project(project.project_id)
        if not reopened.get("ok", false):
            errors.append("Phase 3 authored project must reopen after save.")
        else:
            var reopened_ids: Array[String] = []
            for record in reopened["project"].entity_records:
                reopened_ids.append(str(record.get("entity_id", "")))
            reopened_ids.sort()
            var expected_ids: Array[String] = []
            for record in project.entity_records:
                expected_ids.append(str(record.get("entity_id", "")))
            expected_ids.sort()
            if reopened_ids != expected_ids:
                errors.append("Phase 3 save/reopen must preserve all stable entity identities.")

    session.free()
    return errors


static func _record(project, entity_id: String) -> Dictionary:
    for record in project.entity_records:
        if str(record.get("entity_id", "")) == entity_id:
            return record
    return {}


static func _parent_id(project, entity_id: String) -> String:
    var record: Dictionary = _record(project, entity_id)
    var parent = record.get("parent_entity_id")
    return "" if parent == null else str(parent)
