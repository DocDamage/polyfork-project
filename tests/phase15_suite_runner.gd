extends SceneTree

const Identity = preload("res://tests/unit/phase15_network_identity_contracts.gd")
const Loopback = preload("res://tests/integration/phase15_network_loopback_contracts.gd")

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var suite := OS.get_environment("PHASE15_SUITE")
    var errors: Array[String] = []
    match suite:
        "identity": errors.append_array(Identity.run_checks())
        "loopback": errors.append_array(await Loopback.run_checks(self))
        _: errors.append("Unknown Phase 15 suite: %s" % suite)
    if errors.is_empty():
        print("PASS: Phase 15 %s contract suite completed." % suite)
        quit(0); return
    for item in errors: push_error(item)
    quit(1)
