extends SceneTree

const Foundation = preload("res://tests/unit/phase13_export_foundation_contracts.gd")

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var suite: String = OS.get_environment("PHASE13_SUITE")
    var errors: Array[String] = []
    match suite:
        "foundation": errors.append_array(Foundation.run_checks())
        _: errors.append("Unknown Phase 13 suite: %s" % suite)
    if errors.is_empty():
        print("PASS: Phase 13 %s contract suite completed." % suite)
        quit(0); return
    for item in errors: push_error(item)
    quit(1)
