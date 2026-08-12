extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const AssetLibrary = preload("res://src/assets/asset_library_service.gd")
const GameplayService = preload("res://src/gameplay/gameplay_service.gd")
const BuiltinComponents = preload("res://src/gameplay/builtin_component_library.gd")
const VisualService = preload("res://src/visual_scripting/visual_graph_service.gd")
const ProceduralService = preload("res://src/procedural/procedural_service.gd")
const EnvironmentService = preload("res://src/environment/environment_service.gd")
const QueryService = preload("res://src/ai/ai_query_service.gd")
const ActionRegistry = preload("res://src/ai/ai_action_registry.gd")
const PreviewService = preload("res://src/ai/ai_preview_service.gd")
const ExecutionService = preload("res://src/ai/ai_execution_service.gd")
const AiContracts = preload("res://src/ai/ai_contracts.gd")


static func run_checks(tree_root: Node) -> Array[String]:
    var errors: Array[String] = []
    var root_dir: String = "user://tests/phase12/execute-%s" % StableId.generate()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_dir))
    var project = WorldProject.new()
    project.initialize_new("Phase 12 Execute", &"small", "blank_sandbox")
    project.cell_ids = [StableId.generate()]
    var fixture := Node3D.new(); tree_root.add_child(fixture)
    var editor = EditorSession.new(); fixture.add_child(editor)
    var dirty_count := 0
    var dirty_callback := func() -> Dictionary: dirty_count += 1; return {"ok": true, "errors": []}
    var bind_editor: Dictionary = editor.bind_project(project, dirty_callback)
    if not bind_editor.get("ok", false): fixture.queue_free(); return ["Phase 12 execute fixture could not bind EditorSession."]
    var assets = AssetLibrary.new(root_dir); var asset_load: Dictionary = assets.load_library()
    if not asset_load.get("ok", false): fixture.queue_free(); return ["Phase 12 execute fixture could not load empty Asset Library."]
    var gameplay = GameplayService.new(); var gameplay_bind: Dictionary = gameplay.bind_project(project, root_dir, editor, dirty_callback)
    if not gameplay_bind.get("ok", false): fixture.queue_free(); return ["Phase 12 execute fixture could not bind Gameplay service: %s" % gameplay_bind.get("errors", [])]
    var visual = VisualService.new(); var visual_bind: Dictionary = visual.bind_project(project, root_dir, editor, dirty_callback)
    if not visual_bind.get("ok", false): fixture.queue_free(); return ["Phase 12 execute fixture could not bind Visual Scripting service: %s" % visual_bind.get("errors", [])]
    var procedural = ProceduralService.new(); var procedural_bind: Dictionary = procedural.bind_project(project, root_dir, editor, dirty_callback, null, null, assets, gameplay)
    if not procedural_bind.get("ok", false): fixture.queue_free(); return ["Phase 12 execute fixture could not bind Procedural service: %s" % procedural_bind.get("errors", [])]
    var environment = EnvironmentService.new(); var environment_bind: Dictionary = environment.bind_project(project, root_dir, editor, dirty_callback)
    if not environment_bind.get("ok", false): fixture.queue_free(); return ["Phase 12 execute fixture could not bind Environment service: %s" % environment_bind.get("errors", [])]

    var query = QueryService.new(); query.bind(project, editor, assets, null, gameplay, visual, procedural, environment)
    var actions = ActionRegistry.new(); actions.bind(query, gameplay)
    var previewer = PreviewService.new(); previewer.bind(query, actions)
    var executor = ExecutionService.new(); var execute_bind: Dictionary = executor.bind(project, root_dir, editor, dirty_callback, actions, null, gameplay, visual, procedural, null, environment)
    if not execute_bind.get("ok", false): fixture.queue_free(); return ["Phase 12 execute fixture could not bind AI execution service: %s" % execute_bind.get("errors", [])]

    var health_id: String = BuiltinComponents.id_for("health")
    var request_id: String = StableId.generate()
    var proposal: Dictionary = AiContracts.new_proposal(request_id, "Create one interactive AI-authored object", [
        _action("entity.place_proxy", {"display_name": "AI Hero", "position": [2.0, 0.5, 3.0], "result_ref": "hero"}),
        _action("gameplay.add_component", {"entity_ref": "hero", "definition_id": health_id}),
        _action("visual.create_graph", {"display_name": "AI Start Graph", "kind": "event"}),
        _action("procedural.create_foliage_set", {"display_name": "AI Grass", "primitive": "grass"}),
        _action("environment.configure", {"patch": {"time_of_day_hours": 22.0, "fog_enabled": true}}),
    ])
    var proposal_errors: Array[String] = actions.validate_proposal(proposal)
    if not proposal_errors.is_empty(): errors.append("Cross-system proposal with local entity_ref must validate: %s" % proposal_errors)
    var before_project: Dictionary = project.to_dictionary()
    var before_instances: int = gameplay.get_state().instances.size(); var before_graphs: int = visual.get_graphs().size(); var before_foliage: int = procedural.get_foliage_sets().size(); var before_environment: Dictionary = environment.get_state().authored_state.duplicate(true)
    var preview: Dictionary = previewer.preview(proposal)
    if not preview.get("ok", false): errors.append("Cross-system proposal Preview must succeed: %s" % preview.get("errors", []))
    if project.to_dictionary() != before_project or gameplay.get_state().instances.size() != before_instances or visual.get_graphs().size() != before_graphs or procedural.get_foliage_sets().size() != before_foliage or environment.get_state().authored_state != before_environment:
        errors.append("AI Preview must not mutate any authored subsystem.")
    var execute: Dictionary = executor.execute(proposal, "fixture-provider", "fixture prompt", false)
    if not execute.get("ok", false): errors.append("Cross-system AI Execute must succeed: %s" % execute.get("errors", []))
    else:
        if project.entity_records.size() != 1: errors.append("AI Execute must place exactly one staged entity.")
        var entity_id: String = str(project.entity_records[0].get("entity_id", "")) if not project.entity_records.is_empty() else ""
        if entity_id.is_empty() or gameplay.components_for_entity(entity_id).is_empty(): errors.append("Proposal-local entity_ref must resolve to the locally generated entity ID for gameplay composition.")
        if visual.get_graphs().size() != before_graphs + 1: errors.append("AI Execute must create the validated Visual Scripting graph.")
        if procedural.get_foliage_sets().size() != before_foliage + 1: errors.append("AI Execute must create the validated Procedural foliage set.")
        if float(environment.get_state().authored_state.get("time_of_day_hours", 0.0)) != 22.0 or not bool(environment.get_state().authored_state.get("fog_enabled", false)): errors.append("AI Execute must apply staged Environment authoring.")
        var counts: Dictionary = editor.get_history_counts()
        if int(counts.get("undo", 0)) != 1: errors.append("A complete cross-system AI Execute must create exactly one universal Undo entry.")
        var history_entries: Array[Dictionary] = executor.get_history_entries()
        if history_entries.size() != 1 or str(history_entries[0].get("status", "")) != "applied": errors.append("AI Execute must persist one applied execution-history entry.")
        var undo: Dictionary = editor.get_history().undo()
        if not undo.get("ok", false): errors.append("Universal Undo must revert the complete AI Execute transaction.")
        elif project.to_dictionary().get("entities", []) != before_project.get("entities", []) or gameplay.get_state().instances.size() != before_instances or visual.get_graphs().size() != before_graphs or procedural.get_foliage_sets().size() != before_foliage or environment.get_state().authored_state != before_environment:
            errors.append("One Undo must restore every subsystem touched by AI Execute.")
        elif str(executor.get_history_entries()[0].get("status", "")) != "undone": errors.append("Undo must update project-managed AI execution history.")
        var redo: Dictionary = editor.get_history().redo()
        if not redo.get("ok", false): errors.append("Universal Redo must reapply the complete AI Execute transaction.")
        elif project.entity_records.size() != 1 or visual.get_graphs().size() != before_graphs + 1 or procedural.get_foliage_sets().size() != before_foliage + 1 or float(environment.get_state().authored_state.get("time_of_day_hours", 0.0)) != 22.0:
            errors.append("One Redo must reapply every subsystem touched by AI Execute.")
        elif str(executor.get_history_entries()[0].get("status", "")) != "applied": errors.append("Redo must restore applied AI execution-history status.")

    var missing_asset: Dictionary = AiContracts.new_proposal(StableId.generate(), "Missing asset", [_action("entity.place_asset", {"asset_id": StableId.generate(), "position": [0.0, 0.0, 0.0]})])
    if actions.validate_proposal(missing_asset).is_empty(): errors.append("AI proposals must reject asset IDs absent from the real Asset Library.")
    if dirty_count <= 0: errors.append("AI Execute/Undo/Redo must flow through project dirty-state signaling.")
    fixture.queue_free()
    return errors


static func _action(type_name: String, arguments: Dictionary) -> Dictionary:
    return {"action_id": StableId.generate(), "type": type_name, "arguments": arguments, "reason": "Phase 12 contract"}
