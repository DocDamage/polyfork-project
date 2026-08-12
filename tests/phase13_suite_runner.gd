extends SceneTree

const Foundation = preload("res://tests/unit/phase13_export_foundation_contracts.gd")
const Runtime = preload("res://tests/unit/phase13_export_runtime_contracts.gd")
const Workspace = preload("res://tests/unit/phase13_export_workspace_contracts.gd")

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var suite: String = OS.get_environment("PHASE13_SUITE")
    var errors: Array[String] = []
    match suite:
        "foundation": errors.append_array(Foundation.run_checks())
        "runtime": errors.append_array(Runtime.run_checks())
        "workspace": errors.append_array(Workspace.run_checks(self))
        _: errors.append("Unknown Phase 13 suite: %s" % suite)
    if errors.is_empty():
        print("PASS: Phase 13 %s contract suite completed." % suite)
        quit(0); return
    for item in errors: push_error(item)
    quit(1)
