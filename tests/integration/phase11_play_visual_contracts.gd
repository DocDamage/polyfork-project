extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const PlaySession = preload("res://src/runtime/play_session.gd")
const EnvironmentContracts = preload("res://src/environment/environment_contracts.gd")
const VisualContracts = preload("res://src/visual_scripting/visual_graph_contracts.gd")
const VisualLibrary = preload("res://src/visual_scripting/builtin_visual_node_library.gd")

static func run_checks(tree_root: Node) -> Array[String]:
    var errors: Array[String] = []
    for key in ["environment.get_state", "environment.set_time", "environment.set_weather", "environment.clear_weather"]:
        if not VisualLibrary.has_key(key): errors.append("Visual Scripting must expose Phase 11 node: %s" % key)

    var fixture := Node3D.new()
    fixture.name = "Phase11PlayVisualFixture"
    tree_root.add_child(fixture)
    var project = WorldProject.new()
    project.initialize_new("Phase 11 Play", &"small", "blank_sandbox")
    var editor = EditorSession.new()
    fixture.add_child(editor)
    var bind: Dictionary = editor.bind_project(project, func() -> Dictionary: return {"ok": true, "errors": []})
    if not bind.get("ok", false):
        fixture.queue_free()
        return ["Phase 11 Play fixture could not bind editor session."]

    var document: Dictionary = EnvironmentContracts.empty_document(str(project.project_id))
    var clear_id: String = str(document["authored_state"]["default_weather_profile_id"])
    var storm_id: String = StableId.generate()
    var storm: Dictionary = document["weather_profiles"][0].duplicate(true)
    storm["weather_profile_id"] = storm_id
    storm["display_name"] = "Storm"
    storm["fog_density"] = 0.02
    storm["wind_speed_mps"] = 14.0
    storm["precipitation"] = 0.8
    document["weather_profiles"].append(storm)
    var authored_before: Dictionary = document.duplicate(true)
    var history_before: Dictionary = editor.get_history_counts()

    var play = PlaySession.new()
    fixture.add_child(play)
    play.configure_environment_state_provider(func() -> Dictionary:
        return {"document": document.duplicate(true), "terrain_state": null, "procedural_runtime": null}
    )
    var graphs: Array[Dictionary] = [_environment_graph(storm_id)]
    play.configure_visual_graph_provider(func() -> Array[Dictionary]: return graphs.duplicate(true))

    var enter: Dictionary = play.enter_play(editor)
    if not enter.get("ok", false):
        errors.append("PlaySession must start with a valid authored environment bundle: %s" % str(enter.get("errors", [])))
    else:
        var runtime = play.get_environment_runtime()
        if not bool(enter.get("environment_active", false)): errors.append("PlaySession must activate the disposable Phase 11 environment runtime when a provider is configured.")
        if runtime == null: errors.append("Environment-enabled Play must create a disposable environment runtime node.")
        else:
            if runtime.get_time_of_day() != 21.5: errors.append("Visual Scripting Set Time must target the disposable Play environment runtime.")
            if runtime.get_active_weather_profile_id() != storm_id: errors.append("Visual Scripting Set Weather must target the disposable Play environment runtime.")
            if document != authored_before: errors.append("Play environment and Visual Scripting mutations must never mutate authored environment data.")
            if editor.get_history_counts() != history_before: errors.append("Runtime-only environment changes must not enter authored Undo/Redo history.")
            play.call("_physics_process", 1.0)
            if runtime.get_time_of_day() == 21.5: errors.append("Play time progression must advance disposable time when authored progression is enabled.")
            if document != authored_before: errors.append("Advancing Play time must preserve authored environment state exactly.")
            var clear_result: Dictionary = runtime.clear_weather_override(0.0)
            if not clear_result.get("ok", false) or runtime.get_active_weather_profile_id() != clear_id:
                errors.append("Runtime weather overrides must clear safely back to the authored default.")
        var exit: Dictionary = play.exit_play()
        if not exit.get("ok", false): errors.append("Phase 11 Play environment must exit cleanly.")
        if play.get_environment_runtime() != null: errors.append("Leaving Play must free the disposable environment runtime node completely.")
        if document != authored_before: errors.append("Build environment data must be identical after Play exits.")
        if editor.get_history_counts() != history_before: errors.append("Build Undo/Redo history must be identical after disposable Play exits.")

    var missing_play = PlaySession.new()
    fixture.add_child(missing_play)
    var legacy_enter: Dictionary = missing_play.enter_play(editor)
    if not legacy_enter.get("ok", false): errors.append("PlaySession must remain backward-compatible when no environment provider is configured.")
    else:
        if bool(legacy_enter.get("environment_active", true)): errors.append("PlaySession without an environment provider must not fabricate environment state.")
        if missing_play.get_environment_runtime() != null: errors.append("Legacy Play without an environment provider must retain the Phase 7 zero-child disposable-runtime invariant.")
        missing_play.exit_play()

    fixture.queue_free()
    return errors

static func _environment_graph(weather_profile_id: String) -> Dictionary:
    var start: String = StableId.generate()
    var hours: String = StableId.generate()
    var set_time: String = StableId.generate()
    var set_weather: String = StableId.generate()
    return {
        "document_type": VisualContracts.GRAPH_DOCUMENT_TYPE,
        "schema_version": VisualContracts.SCHEMA_VERSION,
        "graph_id": StableId.generate(),
        "display_name": "Phase 11 Environment Runtime",
        "kind": "event",
        "owner_entity_id": null,
        "enabled": true,
        "nodes": [
            _node(start, "event.start"),
            _node(hours, "value.literal", {"value": 21.5}),
            _node(set_time, "environment.set_time"),
            _node(set_weather, "environment.set_weather", {"weather_profile_id": weather_profile_id, "transition_seconds": 0.0}),
        ],
        "connections": [
            _connection(start, "next", set_time, "in", "exec"),
            _connection(hours, "value", set_time, "hours", "data"),
            _connection(set_time, "next", set_weather, "in", "exec"),
        ],
        "variables": [],
        "interface": {"inputs": [], "outputs": []},
        "editor": {},
    }

static func _node(id: String, key: String, properties: Dictionary = {}) -> Dictionary:
    return {"node_id": id, "type_key": key, "position": [0.0, 0.0], "properties": properties}

static func _connection(a: String, ap: String, b: String, bp: String, kind: String) -> Dictionary:
    return {"connection_id": StableId.generate(), "from_node_id": a, "from_port": ap, "to_node_id": b, "to_port": bp, "kind": kind}
