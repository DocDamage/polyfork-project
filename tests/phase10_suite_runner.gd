extends SceneTree

const Foundation = preload("res://tests/unit/phase10_runtime_gameplay_contracts.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := OS.get_environment("PHASE10_SUITE")
    var errors: Array[String] = []
    if suite == "foundation":
        errors.append_array(Foundation.run_checks())
    else:
        errors.append("Unknown Phase 10 suite")
    if errors.is_empty():
        print("PASS: Phase 10 %s contract suite completed." % suite)
        quit(0)
        return
    for item in errors:
        push_error(item)
    quit(1)
