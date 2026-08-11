extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const TerrainRepository = preload("res://src/terrain/terrain_repository.gd")
const SafeJsonWriter = preload("res://src/world/safe_json_writer.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var root: String = "user://tests/phase5_terrain_%s" % StableId.generate()
    var project_dir: String = root.path_join("project")
    var project = WorldProject.new()
    project.initialize_new("Phase 5 Terrain", &"medium", "blank_sandbox")
    var repository = TerrainRepository.new(project_dir)
    var open_result: Dictionary = repository.open_or_create(project)
    if not open_result.get("ok", false):
        errors.append("Terrain repository must initialize a valid Medium world: %s" % [open_result.get("errors", [])])
        return errors
    var state = open_result.get("state")
    if state == null or project.cell_ids.size() != 9 or state.cell_ids().size() != 9:
        errors.append("Medium terrain initialization must create and attach nine stable project cells.")
        return errors

    var center_id: String = state.cell_id_at_position(Vector3.ZERO)
    var east_id: String = state.cell_id_at_position(Vector3(700.0, 0.0, 0.0))
    if center_id.is_empty() or east_id.is_empty() or center_id == east_id:
        errors.append("Terrain persistence fixture must resolve distinct centered and east cells.")
        return errors
    var east_before: String = FileAccess.get_file_as_string(repository.get_cell_path(east_id))
    var center: Dictionary = state.get_cell(center_id)
    var heights: Array = center.get("heights", []).duplicate()
    heights[int(heights.size() / 2)] = 5.0
    center["heights"] = heights
    center["revision"] = int(center.get("revision", 0)) + 1
    state.set_cell(center, true)
    var flush: Dictionary = repository.flush_dirty(state)
    if not flush.get("ok", false) or flush.get("saved_cells", []).size() != 1 or state.has_dirty_cells():
        errors.append("Dirty-cell flush must persist exactly the changed terrain cell and clear its dirty state.")
    var east_after: String = FileAccess.get_file_as_string(repository.get_cell_path(east_id))
    if east_before != east_after:
        errors.append("Saving one dirty terrain cell must not rewrite an unchanged neighboring cell.")
    var counts: Dictionary = repository.get_write_counts().get("cells", {})
    if int(counts.get(center_id, 0)) != 2 or int(counts.get(east_id, 0)) != 1:
        errors.append("Terrain repository write accounting must prove incremental per-cell persistence.")

    var reopened_project = WorldProject.new()
    reopened_project.load_dictionary(project.to_dictionary())
    var reopened_repo = TerrainRepository.new(project_dir)
    var reopen: Dictionary = reopened_repo.open_or_create(reopened_project)
    if not reopen.get("ok", false):
        errors.append("Terrain state must reopen after incremental persistence.")
        return errors
    var reopened_state = reopen.get("state")
    var reopened_center: Dictionary = reopened_state.get_cell(center_id)
    var reopened_heights: Array = reopened_center.get("heights", [])
    if reopened_heights.is_empty() or float(reopened_heights[int(reopened_heights.size() / 2)]) != 5.0:
        errors.append("Saved terrain heights must survive project restart.")

    _write_text(reopened_repo.get_cell_path(center_id), "{corrupt")
    var recovery_repo = TerrainRepository.new(project_dir)
    var recovered: Dictionary = recovery_repo.open_or_create(reopened_project)
    if not recovered.get("ok", false) or not recovered.get("recovered_cells", []).has(center_id):
        errors.append("A corrupt canonical terrain cell must load the prior validated recovery copy without replacing it silently.")
    else:
        var recovered_cell: Dictionary = recovered.get("state").get_cell(center_id)
        var recovered_heights: Array = recovered_cell.get("heights", [])
        if recovered_heights.is_empty() or float(recovered_heights[int(recovered_heights.size() / 2)]) != 0.0:
            errors.append("Terrain recovery must expose the last known-good pre-save cell data.")
        if FileAccess.get_file_as_string(recovery_repo.get_cell_path(center_id)) != "{corrupt":
            errors.append("Loading recovery data must not silently overwrite a corrupt canonical terrain file.")

    var fault_root: String = "user://tests/phase5_fault_%s" % StableId.generate()
    var fault_project = WorldProject.new()
    fault_project.initialize_new("Fault Terrain", &"small", "blank_sandbox")
    var fault_repo = TerrainRepository.new(fault_root.path_join("project"))
    var fault_open: Dictionary = fault_repo.open_or_create(fault_project)
    if not fault_open.get("ok", false): return errors
    var fault_state = fault_open.get("state")
    var fault_cell_id: String = fault_state.cell_ids()[0]
    var fault_cell: Dictionary = fault_state.get_cell(fault_cell_id)
    var fault_heights: Array = fault_cell.get("heights", []).duplicate()
    fault_heights[0] = 9.0
    fault_cell["heights"] = fault_heights
    fault_cell["revision"] = 1
    fault_state.set_cell(fault_cell, true)
    var writer = SafeJsonWriter.new(func(stage: StringName) -> bool: return stage == &"before_promote")
    var failing_repo = TerrainRepository.new(fault_root.path_join("project"), writer)
    var prior_text: String = FileAccess.get_file_as_string(failing_repo.get_cell_path(fault_cell_id))
    var failed_flush: Dictionary = failing_repo.flush_dirty(fault_state)
    if failed_flush.get("ok", true) or not fault_state.is_dirty(fault_cell_id):
        errors.append("A failed terrain promotion must retain dirty state for retry.")
    if FileAccess.get_file_as_string(failing_repo.get_cell_path(fault_cell_id)) != prior_text:
        errors.append("A failed terrain promotion must leave the previous canonical cell untouched.")
    return errors


static func _write_text(path: String, text: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file != null:
        file.store_string(text)
        file.close()
