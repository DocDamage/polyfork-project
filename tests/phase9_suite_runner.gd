extends SceneTree

const Foundation = preload("res://tests/unit/phase9_procedural_contracts.gd")
const Foliage = preload("res://tests/integration/phase9_foliage_scatter_contracts.gd")


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var suite: String = OS.get_environment("PHASE9_SUITE")
    var errors: Array[String] = []
    match suite:
        "foundation": errors.append_array(Foundation.run_checks())
        "foliage": errors.append_array(Foliage.run_checks(root))
        _: errors.append("Unknown Phase 9 suite: %s" % suite)
    if errors.is_empty():
        print("PASS: Phase 9 %s contract suite completed." % suite)
        quit(0)
        return
    for error in errors:
        push_error(error)
    quit(1)
