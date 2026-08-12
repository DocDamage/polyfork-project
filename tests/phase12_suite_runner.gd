extends SceneTree

const Foundation = preload("res://tests/unit/phase12_ai_foundation_contracts.gd")
const Execute = preload("res://tests/integration/phase12_ai_execute_contracts.gd")
const Workspace = preload("res://tests/integration/phase12_ai_workspace_contracts.gd")
const Orchestration = preload("res://tests/integration/phase12_ai_orchestration_contracts.gd")
const Scale = preload("res://tests/integration/phase12_ai_scale_contracts.gd")

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var suite: String = OS.get_environment("PHASE12_SUITE")
    var errors: Array[String] = []
    match suite:
        "foundation": errors.append_array(Foundation.run_checks())
        "execute": errors.append_array(Execute.run_checks(root))
        "workspace": errors.append_array(Workspace.run_checks(root))
        "orchestration": errors.append_array(await Orchestration.run_checks(root))
        "scale": errors.append_array(Scale.run_checks(root))
        _: errors.append("Unknown Phase 12 suite: %s" % suite)
    if errors.is_empty():
        print("PASS: Phase 12 %s contract suite completed." % suite)
        quit(0); return
    for item in errors: push_error(item)
    quit(1)
