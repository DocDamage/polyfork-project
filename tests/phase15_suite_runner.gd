extends SceneTree

const Identity = preload("res://tests/unit/phase15_network_identity_contracts.gd")
const Loopback = preload("res://tests/integration/phase15_network_loopback_contracts.gd")
const Replication = preload("res://tests/integration/phase15_replication_contracts.gd")
const Templates = preload("res://tests/unit/phase15_template_match_contracts.gd")
const Lifecycle = preload("res://tests/integration/phase15_network_lifecycle_contracts.gd")
const MatchReplication = preload("res://tests/integration/phase15_match_replication_contracts.gd")
const ExportContracts = preload("res://tests/unit/phase15_export_contracts.gd")

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var suite := OS.get_environment("PHASE15_SUITE")
    var errors: Array[String] = []
    match suite:
        "identity": errors.append_array(Identity.run_checks())
        "loopback": errors.append_array(await Loopback.run_checks(self))
        "replication": errors.append_array(await Replication.run_checks(self))
        "templates": errors.append_array(Templates.run_checks())
        "lifecycle": errors.append_array(await Lifecycle.run_checks(self))
        "match": errors.append_array(await MatchReplication.run_checks(self))
        "export": errors.append_array(ExportContracts.run_checks())
        _: errors.append("Unknown Phase 15 suite: %s" % suite)
    if errors.is_empty():
        print("PASS: Phase 15 %s contract suite completed." % suite)
        quit(0); return
    for item in errors: push_error(item)
    quit(1)
