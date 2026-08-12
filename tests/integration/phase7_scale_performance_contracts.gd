extends RefCounted

const WorldProject = preload("res://src/world/world_project.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const PlaySession = preload("res://src/runtime/play_session.gd")
const TemplateRegistry = preload("res://src/templates/template_registry.gd")
const TemplateApplication = preload("res://src/templates/template_application_service.gd")

const CYCLES_PER_CONTROLLER := 50
const REPRESENTATIVE_BUDGET_MSEC := 12000


static func run_checks(tree_root: Node) -> Array[String]:
    var errors: Array[String] = []
    var registry = TemplateRegistry.new()
    var load_result: Dictionary = registry.load_builtin()
    if not load_result.get("ok", false):
        return ["Phase 7 performance fixture requires the built-in template registry."]

    var started := Time.get_ticks_msec()
    var transitions := 0
    for template_id in ["third_person_adventure", "fps"]:
        var project = WorldProject.new()
        project.initialize_new("Phase 7 Performance %s" % template_id, &"small", template_id)
        var apply_result: Dictionary = TemplateApplication.new().apply_to_project(project, registry.get_manifest(template_id))
        if not apply_result.get("ok", false):
            errors.append("Representative %s performance fixture could not apply its template." % template_id)
            continue

        var editor = EditorSession.new()
        tree_root.add_child(editor)
        var bind_result: Dictionary = editor.bind_project(project, func() -> Dictionary: return {"ok": true, "errors": []})
        if not bind_result.get("ok", false):
            errors.append("Representative %s performance fixture could not bind its editor session." % template_id)
            editor.queue_free()
            continue

        var authored_before: Dictionary = project.to_dictionary()
        var history_before: Dictionary = editor.get_history_counts()
        var play = PlaySession.new()
        tree_root.add_child(play)
        for cycle in range(CYCLES_PER_CONTROLLER):
            var enter: Dictionary = play.enter_play(editor)
            if not enter.get("ok", false):
                errors.append("Representative %s Play cycle %d failed to enter: %s" % [template_id, cycle + 1, enter.get("errors", [])])
                break
            var exit_result: Dictionary = play.exit_play()
            if not exit_result.get("ok", false):
                errors.append("Representative %s Play cycle %d failed to exit: %s" % [template_id, cycle + 1, exit_result.get("errors", [])])
                break
            transitions += 1
        if play.get_child_count() != 0 or play.get_player() != null:
            errors.append("Representative %s transition stress must not accumulate runtime player nodes." % template_id)
        if project.to_dictionary() != authored_before:
            errors.append("Representative %s transition stress must not mutate authored project data." % template_id)
        if editor.get_history_counts() != history_before:
            errors.append("Representative %s transition stress must not add authoring history." % template_id)
        play.queue_free()
        editor.queue_free()

    var elapsed := Time.get_ticks_msec() - started
    print("Phase 7 representative lifecycle: %d Build/Play transitions in %d ms (CI budget %d ms)." % [transitions, elapsed, REPRESENTATIVE_BUDGET_MSEC])
    if transitions != CYCLES_PER_CONTROLLER * 2:
        errors.append("Phase 7 representative lifecycle stress must complete all 100 Build/Play transitions.")
    if elapsed > REPRESENTATIVE_BUDGET_MSEC:
        errors.append("Phase 7 representative Build/Play lifecycle exceeded its broad CI regression budget: %d ms." % elapsed)
    return errors
