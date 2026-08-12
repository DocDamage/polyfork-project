extends RefCounted

const WorldProject = preload("res://src/world/world_project.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const EnvironmentService = preload("res://src/environment/environment_service.gd")
const EnvironmentRepository = preload("res://src/environment/environment_repository.gd")

static func run_checks(tree_root: Node) -> Array[String]:
    var errors: Array[String] = []
    var fixture := Node.new()
    tree_root.add_child(fixture)
    var project = WorldProject.new()
    project.initialize_new("Phase 11 Persistence", &"small", "blank_sandbox")
    var dirty_calls := [0]
    var editor = EditorSession.new()
    fixture.add_child(editor)
    var dirty_callback := func() -> Dictionary:
        dirty_calls[0] = int(dirty_calls[0]) + 1
        return {"ok": true, "errors": []}
    var bind_editor: Dictionary = editor.bind_project(project, dirty_callback)
    if not bind_editor.get("ok", false):
        fixture.queue_free()
        return ["Environment persistence test could not bind editor session."]

    var project_dir := "user://phase11-environment-persistence-%d" % Time.get_ticks_usec()
    var service = EnvironmentService.new()
    var bind: Dictionary = service.bind_project(project, project_dir, editor, dirty_callback)
    if not bind.get("ok", false):
        fixture.queue_free()
        return ["Environment service could not create crash-safe project state: %s" % str(bind.get("errors", []))]
    var initial_time: float = float(service.get_state().authored_state.get("time_of_day_hours", -1.0))
    var edit: Dictionary = service.configure_authored_state({"time_of_day_hours": 18.25})
    if not edit.get("ok", false): errors.append("Environment authored edit must execute through universal history.")
    if editor.get_history_counts().get("undo", 0) != 1: errors.append("Environment authored edit must enter universal Undo history exactly once.")
    if float(service.get_state().authored_state.get("time_of_day_hours", -1.0)) != 18.25: errors.append("Environment authored edit must update in-memory state.")

    var reopened = EnvironmentRepository.new(project_dir)
    var reopen_result: Dictionary = reopened.open_or_create(project)
    if not reopen_result.get("ok", false): errors.append("Environment save/reopen must load persisted authored state.")
    elif float(reopen_result.get("state").authored_state.get("time_of_day_hours", -1.0)) != 18.25: errors.append("Environment save/reopen must preserve authored time exactly.")

    var undo: Dictionary = editor.undo_edit()
    if not undo.get("ok", false): errors.append("Universal Undo must revert an environment snapshot command.")
    elif float(service.get_state().authored_state.get("time_of_day_hours", -1.0)) != initial_time: errors.append("Environment Undo must restore the exact previous authored state.")
    var undo_reopen: Dictionary = reopened.open_or_create(project)
    if not undo_reopen.get("ok", false) or float(undo_reopen.get("state").authored_state.get("time_of_day_hours", -1.0)) != initial_time:
        errors.append("Environment Undo must persist the reverted state crash-safely.")

    var redo: Dictionary = editor.redo_edit()
    if not redo.get("ok", false): errors.append("Universal Redo must reapply an environment snapshot command.")
    elif float(service.get_state().authored_state.get("time_of_day_hours", -1.0)) != 18.25: errors.append("Environment Redo must restore the authored edit.")

    var weather: Dictionary = service.create_weather_profile("Rain", {"precipitation": 0.7})
    if not weather.get("ok", false): errors.append("Environment weather profiles must be command-backed and persisted.")
    var water: Dictionary = service.create_water_hook("River Provider", "test.river", {"flow": 2.0}, ["river"])
    if not water.get("ok", false): errors.append("Environment water hooks must be command-backed and persisted.")
    var weather_id := str(weather.get("weather_profile_id", ""))
    var water_id := str(water.get("water_hook_id", ""))
    if not project.registries.get("environment_weather_profile_ids", []).has(weather_id): errors.append("Weather profile stable IDs must synchronize into project registries.")
    if not project.registries.get("environment_water_hook_ids", []).has(water_id): errors.append("Water hook stable IDs must synchronize into project registries.")
    var final_reopen: Dictionary = reopened.open_or_create(project)
    if not final_reopen.get("ok", false): errors.append("Environment records must reopen after multiple command-backed edits.")
    else:
        if final_reopen.get("state").get_weather_profile(weather_id).is_empty(): errors.append("Weather profile stable identity must survive save/reopen.")
        if final_reopen.get("state").get_water_hook(water_id).is_empty(): errors.append("Water hook stable identity must survive save/reopen.")

    var environment_path: String = reopened.get_path()
    var file := FileAccess.open(environment_path, FileAccess.WRITE)
    if file == null: errors.append("Environment corruption test could not open environment.json.")
    else:
        file.store_string("{broken environment json")
        file.close()
        var corrupt_result: Dictionary = EnvironmentRepository.new(project_dir).open_or_create(project)
        if corrupt_result.get("ok", false): errors.append("Corrupt environment JSON must fail closed instead of silently replacing authored data.")

    if int(dirty_calls[0]) < 3: errors.append("Environment authoring must participate in project dirty-state signaling.")
    fixture.queue_free()
    return errors
