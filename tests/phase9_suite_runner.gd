extends SceneTree

const Foundation = preload("res://tests/unit/phase9_procedural_contracts.gd")
const Foliage = preload("res://tests/integration/phase9_foliage_scatter_contracts.gd")
const Splines = preload("res://tests/integration/phase9_spline_contracts.gd")
const Workspace = preload("res://tests/integration/phase9_procedural_workspace_contracts.gd")


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var suite: String = OS.get_environment("PHASE9_SUITE")
    var errors: Array[String] = []
    match suite:
        "foundation": errors.append_array(Foundation.run_checks())
        "foliage": errors.append_array(Foliage.run_checks(root))
        "splines": errors.append_array(Splines.run_checks(root))
        "workspace":
            var workspace = Workspace.new()
            root.add_child(workspace)
            errors.append_array(workspace.run_checks())
            workspace.queue_free()
        _: errors.append("Unknown Phase 9 suite: %s" % suite)
    if errors.is_empty():
        print("PASS: Phase 9 %s contract suite completed." % suite)
        quit(0)
        return
    for error in errors:
        push_error(error)
    quit(1)
