extends SceneTree

const TemplateContracts = preload("res://tests/unit/phase7_template_contracts.gd")
const TemplateApplicationContracts = preload("res://tests/integration/phase7_template_application_contracts.gd")
const PlayStateContracts = preload("res://tests/integration/phase7_play_state_contracts.gd")


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var suite := OS.get_environment("PHASE7_SUITE")
    var errors: Array[String] = []
    match suite:
        "templates":
            errors.append_array(TemplateContracts.run_checks())
            errors.append_array(TemplateApplicationContracts.run_checks())
        "play": errors.append_array(PlayStateContracts.run_checks(root))
        _: errors.append("Unknown Phase 7 suite: %s" % suite)
    if errors.is_empty():
        print("PASS: Phase 7 %s contract suite completed." % suite)
        quit(0)
        return
    for error in errors: push_error(error)
    quit(1)
