extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const TerrainRepository = preload("res://src/terrain/terrain_repository.gd")
const TerrainRuntime = preload("res://src/terrain/terrain_runtime.gd")
const TerrainController = preload("res://src/terrain/terrain_controller.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    errors.append_array(_controller_history_checks())
    errors.append_array(_streaming_checks())
    errors.append_array(_profile_runtime_checks())
    return errors


static func _controller_history_checks() -> Array[String]:
    var errors: Array[String] = []
    var root: String = "user://tests/phase5_controller_%s" % StableId.generate()
    var project = WorldProject.new()
    project.initialize_new("Terrain Controller", &"small", "blank_sandbox")
    var dirty_count: Array[int] = [0]
    var session = EditorSession.new()
    var bind_result: Dictionary = session.bind_project(project, func() -> Dictionary:
        dirty_count[0] += 1
        return {"ok": true, "errors": []}
    )
    if not bind_result.get("ok", false):
        errors.append("Terrain controller test requires a valid Phase 3 editor session.")
        session.free()
        return errors
    var controller = TerrainController.new()
    var terrain_bind: Dictionary = controller.bind_project(project, root.path_join("project"), session, func() -> Dictionary:
        dirty_count[0] += 1
        return {"ok": true, "errors": []}
    )
    if not terrain_bind.get("ok", false):
        errors.append("Terrain controller must bind project persistence/runtime/history: %s" % [terrain_bind.get("errors", [])])
        controller.free()
        session.free()
        return errors
    if project.cell_ids.size() != 1 or dirty_count[0] != 1:
        errors.append("Initial terrain topology must add the stable Small-world cell and mark the project dirty exactly once.")
    var state = controller.get_state()
    var cell_id: String = state.cell_id_at_position(Vector3.ZERO)
    var before: Dictionary = state.get_cell(cell_id)
    var before_heights: Array = before.get("heights", [])
    var center_index: int = int(before_heights.size() / 2)
    controller.set_cursor(Vector3.ZERO)
    controller.set_mode(&"raise")
    var apply_result: Dictionary = controller.apply_brush()
    var raised: Dictionary = state.get_cell(cell_id)
    if not apply_result.get("ok", false) or float(raised.get("heights", [])[center_index]) <= float(before_heights[center_index]):
        errors.append("Terrain controller must execute sculpting through the shared editor command history.")
    if dirty_count[0] != 2 or not state.is_dirty(cell_id):
        errors.append("Committed terrain sculpt must dirty both project autosave state and its owning terrain cell.")
    var undo_result: Dictionary = session.undo_edit()
    var undone: Dictionary = state.get_cell(cell_id)
    if not undo_result.get("ok", false) or not is_equal_approx(float(undone.get("heights", [])[center_index]), float(before_heights[center_index])):
        errors.append("Global editor Undo must restore terrain heights through the same command history.")
    var redo_result: Dictionary = session.redo_edit()
    var redone: Dictionary = state.get_cell(cell_id)
    if not redo_result.get("ok", false) or float(redone.get("heights", [])[center_index]) <= float(before_heights[center_index]):
        errors.append("Global editor Redo must reapply terrain sculpt state and runtime refresh.")

    var biomes: Array = controller.get_biomes()
    if biomes.size() < 2:
        errors.append("Terrain controller must expose data-driven biome presets.")
    else:
        var original_biome: String = str(redone.get("biome_id", ""))
        var target_biome: String = str(biomes[1].get("biome_id", ""))
        var biome_result: Dictionary = controller.assign_biome(target_biome)
        if not biome_result.get("ok", false) or str(state.get_cell(cell_id).get("biome_id", "")) != target_biome:
            errors.append("Biome assignment must be command-backed and persist a stable biome ID on the cell.")
        var biome_undo: Dictionary = session.undo_edit()
        if not biome_undo.get("ok", false) or str(state.get_cell(cell_id).get("biome_id", "")) != original_biome:
            errors.append("Biome assignment must undo through the shared editor command history.")
    controller.free()
    session.free()
    return errors


static func _streaming_checks() -> Array[String]:
    var errors: Array[String] = []
    var root: String = "user://tests/phase5_streaming_%s" % StableId.generate()
    var project = WorldProject.new()
    project.initialize_new("Large Stream", &"large", "blank_sandbox")
    var repository = TerrainRepository.new(root.path_join("project"))
    var open_result: Dictionary = repository.open_or_create(project)
    if not open_result.get("ok", false):
        errors.append("Large terrain streaming fixture must initialize.")
        return errors
    var state = open_result.get("state")
    var runtime = TerrainRuntime.new()
    var bind_result: Dictionary = runtime.bind_state(state)
    if not bind_result.get("ok", false) or runtime.chunk_count() != 9:
        errors.append("Large-world streaming at the origin must load the deterministic 3x3 radius set.")
        runtime.free()
        return errors
    var origin_id: String = state.cell_id_at_position(Vector3.ZERO)
    var origin_cell: Dictionary = state.get_cell(origin_id)
    var origin_heights: Array = origin_cell.get("heights", []).duplicate()
    origin_heights[int(origin_heights.size() / 2)] = 3.0
    origin_cell["heights"] = origin_heights
    origin_cell["revision"] = int(origin_cell.get("revision", 0)) + 1
    state.set_cell(origin_cell, true)
    var shift: Dictionary = runtime.update_focus(Vector3(2048.0, 0.0, 0.0))
    if not shift.get("ok", false) or runtime.chunk_count() != 7 or not shift.get("blocked_dirty", []).has(origin_id):
        errors.append("A dirty terrain cell outside the new streaming radius must remain loaded and report blocked unload.")
    var flush_result: Dictionary = repository.flush_dirty(state)
    var post_flush: Dictionary = runtime.update_focus(Vector3(2048.0, 0.0, 0.0))
    if not flush_result.get("ok", false) or not post_flush.get("ok", false) or runtime.chunk_count() != 6 or runtime.get_loaded_cell_ids().has(origin_id):
        errors.append("Once a dirty cell is safely saved, a subsequent streaming update must be allowed to unload it.")
    var moved_ids: Array[String] = runtime.get_loaded_cell_ids()
    var repeat: Dictionary = runtime.update_focus(Vector3(2048.0, 0.0, 0.0))
    if not repeat.get("ok", false) or repeat.get("loaded", []).size() != 0 or repeat.get("unloaded", []).size() != 0 or runtime.get_loaded_cell_ids() != moved_ids:
        errors.append("Streaming the same focus twice must produce an identical stable active-cell set with no churn.")
    runtime.free()
    return errors


static func _profile_runtime_checks() -> Array[String]:
    var errors: Array[String] = []
    for profile_data in [[&"small", 1], [&"medium", 9]]:
        var profile_id: StringName = profile_data[0]
        var expected: int = int(profile_data[1])
        var root: String = "user://tests/phase5_profile_%s_%s" % [str(profile_id), StableId.generate()]
        var project = WorldProject.new()
        project.initialize_new("Profile Terrain", profile_id, "blank_sandbox")
        var repository = TerrainRepository.new(root.path_join("project"))
        var open_result: Dictionary = repository.open_or_create(project)
        if not open_result.get("ok", false):
            errors.append("%s profile terrain fixture must initialize." % str(profile_id))
            continue
        var runtime = TerrainRuntime.new()
        runtime.bind_state(open_result.get("state"))
        runtime.update_focus(Vector3(100000.0, 0.0, 100000.0))
        if runtime.chunk_count() != expected:
            errors.append("%s profile must keep all %d terrain cells loaded without Large-world streaming behavior." % [str(profile_id), expected])
        runtime.free()
    return errors
