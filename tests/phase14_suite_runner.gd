extends SceneTree

const Foundation = preload("res://tests/unit/phase14_scale_foundation_contracts.gd")
const ExportProfile = preload("res://tests/unit/phase14_export_profile_contracts.gd")
const Accessibility = preload("res://tests/unit/phase14_accessibility_contracts.gd")

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var suite: String = OS.get_environment("PHASE14_SUITE")
    var errors: Array[String] = []
    match suite:
        "foundation": errors.append_array(Foundation.run_checks())
        "export": errors.append_array(ExportProfile.run_checks())
        "accessibility": errors.append_array(await Accessibility.run_checks(self))
        _: errors.append("Unknown Phase 14 suite: %s" % suite)
    if errors.is_empty():
        print("PASS: Phase 14 %s contract suite completed." % suite)
        quit(0); return
    for item in errors: push_error(item)
    quit(1)
