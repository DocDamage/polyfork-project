extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const PlaySession = preload("res://src/runtime/play_session.gd")
const GameplayInput = preload("res://src/input/gameplay_input_map.gd")
const AutosaveService = preload("res://src/world/autosave_service.gd")

class FakeRepository extends RefCounted:
    var checkpoints: int = 0
    func create_checkpoint(_project) -> Dictionary:
        checkpoints += 1
        return {"ok": true, "errors": []}


static func run_checks(tree_root: Node) -> Array[String]:
    var errors: Array[String] = []
    GameplayInput.uninstall_owned()
    var fixture := Node3D.new(); fixture.name = "Phase7PlayStateFixture"; tree_root.add_child(fixture)
    var project = _project_fixture(); var entity_id: String = str(project.entity_records[0]["entity_id"])
    var editor = EditorSession.new(); fixture.add_child(editor)
    var bind: Dictionary = editor.bind_project(project, func() -> Dictionary: return {"ok": true, "errors": []})
    if not bind.get("ok", false): fixture.queue_free(); return ["Play state fixture could not bind editor session."]
    editor.select_entity(entity_id)
    var play = PlaySession.new(); fixture.add_child(play)
    var streaming_positions: Array[Vector3] = []
    play.configure_streaming(func(position_value: Vector3) -> Dictionary: streaming_positions.append(position_value); return {"ok": true, "errors": []})
    var authored_before: Dictionary = project.to_dictionary(); var history_before: Dictionary = editor.get_history_counts()
    var enter: Dictionary = play.enter_play(editor)
    if not enter.get("ok", false): errors.append("Play session must start from valid authored data: %s" % enter.get("errors", []))
    else:
        if not play.is_active() or play.get_player() == null: errors.append("Third-person Play must create one runtime player session.")
        if not editor.get_selected_ids().is_empty(): errors.append("Build selection must not become gameplay state.")
        if not InputMap.has_action(GameplayInput.MOVE_FORWARD): errors.append("Gameplay input must be active only while Play owns the session.")
        var mutation: Dictionary = play.get_runtime_state().set_entity_position(entity_id, Vector3(99.0, 8.0, 4.0))
        if not mutation.get("ok", false): errors.append("Runtime state fixture mutation must succeed.")
        if project.to_dictionary() != authored_before: errors.append("Play-mode runtime mutations must not modify authored Build data.")
        if editor.get_history_counts() != history_before: errors.append("Runtime-only Play mutations must not enter authoring Undo history.")
        play.call("_physics_process", 0.016)
        if streaming_positions.is_empty(): errors.append("Active Play must drive the configured world-streaming focus from the player.")
        var exit: Dictionary = play.exit_play()
        if not exit.get("ok", false): errors.append("Play session must exit cleanly: %s" % exit.get("errors", []))
        if play.is_active() or play.get_player() != null: errors.append("Leaving Play must destroy the runtime player session.")
        if InputMap.has_action(GameplayInput.MOVE_FORWARD): errors.append("Gameplay input must be inactive after returning to Build.")
        if project.to_dictionary() != authored_before: errors.append("Returning to Build must restore authored project state exactly.")
        if editor.get_primary_entity_id() != entity_id: errors.append("Returning to Build must restore editor selection state.")
    for _index in range(3):
        var repeat_enter: Dictionary = play.enter_play(editor)
        if not repeat_enter.get("ok", false): errors.append("Repeated Build -> Play transition must succeed."); break
        var repeat_exit: Dictionary = play.exit_play()
        if not repeat_exit.get("ok", false): errors.append("Repeated Play -> Build transition must succeed."); break
    if play.get_child_count() != 0: errors.append("Repeated Play transitions must not accumulate disposable runtime nodes.")
    var original_runtime: Dictionary = project.runtime_config.duplicate(true); project.runtime_config["resolved_modules"] = ["unknown.phase7.module"]
    var failed: Dictionary = play.enter_play(editor)
    if failed.get("ok", false) or play.is_active(): errors.append("Failed Play startup must reject and remain safely in Build state.")
    if InputMap.has_action(GameplayInput.MOVE_FORWARD): errors.append("Failed Play startup must not leak gameplay input actions.")
    project.runtime_config = original_runtime
    errors.append_array(_check_input_bindings())
    errors.append_array(_check_autosave_suspension(project))
    GameplayInput.uninstall_owned(); fixture.queue_free()
    return errors


static func _check_input_bindings() -> Array[String]:
    var errors: Array[String] = []; GameplayInput.install_profile({"profile": "semantic_default"})
    var move_events: Array[InputEvent] = InputMap.action_get_events(GameplayInput.MOVE_FORWARD); var has_key: bool = false; var has_stick: bool = false
    for event in move_events:
        if event is InputEventKey: has_key = true
        if event is InputEventJoypadMotion: has_stick = true
    if not has_key or not has_stick: errors.append("Gameplay movement must map equivalent keyboard and left-stick actions.")
    var look_events: Array[InputEvent] = InputMap.action_get_events(GameplayInput.LOOK_RIGHT); var has_right_stick: bool = false
    for event in look_events:
        if event is InputEventJoypadMotion: has_right_stick = true
    if not has_right_stick: errors.append("Gameplay look must map to right-stick semantic actions.")
    var exit_events: Array[InputEvent] = InputMap.action_get_events(GameplayInput.EXIT); var has_back: bool = false
    for event in exit_events:
        if event is InputEventJoypadButton and event.button_index in [JOY_BUTTON_BACK, JOY_BUTTON_B]: has_back = true
    if not has_back: errors.append("Gameplay input must provide reliable gamepad Back/Cancel behavior.")
    GameplayInput.uninstall_owned(); return errors


static func _check_autosave_suspension(project) -> Array[String]:
    var errors: Array[String] = []; var repository := FakeRepository.new(); var autosave := AutosaveService.new(repository, 0.1)
    if not autosave.attach_project(project).get("ok", false): return ["Autosave Play-mode fixture could not attach project."]
    autosave.mark_dirty(); autosave.set_suspended(true)
    var suspended: Dictionary = autosave.advance(1.0)
    if suspended.get("attempted", true) or suspended.get("reason") != "suspended" or repository.checkpoints != 0: errors.append("Project autosave must not serialize while disposable Play state owns the session.")
    autosave.set_suspended(false); var resumed: Dictionary = autosave.advance(1.0)
    if not resumed.get("ok", false) or repository.checkpoints != 1: errors.append("Authored autosave must resume after returning to Build.")
    return errors


static func _project_fixture():
    var project = WorldProject.new(); project.initialize_new("Play State", &"small", "third_person_adventure")
    var cell_id: String = StableId.generate(); var entity_id: String = StableId.generate()
    var owned_cells: Array[String] = [cell_id]
    project.cell_ids = owned_cells
    var records: Array[Dictionary] = [{"document_type": WorldEntity.DOCUMENT_TYPE, "schema_version": WorldEntity.SCHEMA_VERSION, "entity_id": entity_id, "display_name": "Player Start", "cell_id": cell_id, "asset_id": null, "prefab_id": null, "parent_entity_id": null, "component_instance_ids": [], "transform": {"position": [0.0, 2.0, 0.0], "rotation_degrees": [0.0, 0.0, 0.0], "scale": [1.0, 1.0, 1.0]}}]
    project.entity_records = records
    project.runtime_config = {"schema_version": 1, "template_id": "third_person_adventure", "resolved_modules": ["core.world", "core.semantic_input", "play.third_person"], "planned_modules": [], "starter_entities": [], "starter_entity_ids": {"player_start": entity_id}, "materialized": true, "spawn_entity_id": entity_id, "input_mapping": {"profile": "semantic_default"}, "default_player_archetype": null, "camera_configuration": {"controller": "third_person", "spawn_position": [0.0, 2.0, 0.0]}, "example_graph_references": [], "ui_hud_packages": [], "tutorial_steps": []}
    project.dependencies = project.runtime_config["resolved_modules"].duplicate()
    return project