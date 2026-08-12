extends SceneTree

const SUITES := {
    "components": "res://tests/integration/phase6_component_archetype_contracts.gd",
    "prefabs": "res://tests/integration/phase6_prefab_contracts.gd",
    "sockets": "res://tests/integration/phase6_socket_attachment_contracts.gd",
    "persistence": "res://tests/integration/phase6_persistence_failure_contracts.gd",
    "scale": "res://tests/integration/phase6_scale_performance_contracts.gd",
    "workspace": "res://tests/runtime/phase6_gameplay_workspace_smoke.gd"
}


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var suite := OS.get_environment("PHASE6_SUITE")
    if not SUITES.has(suite):
        push_error("Unknown Phase 6 diagnostic suite: %s" % suite)
        quit(2)
        return
    var script = load(str(SUITES[suite]))
    if script == null:
        push_error("Unable to load Phase 6 suite: %s" % suite)
        quit(2)
        return
    var failures: Array[String] = []
    if suite == "workspace":
        var instance = script.new()
        root.add_child(instance)
        for error in instance.run_checks(): failures.append(str(error))
        instance.queue_free()
        await process_frame
    else:
        for error in script.run_checks(): failures.append(str(error))
    if failures.is_empty():
        print("PASS: Phase 6 %s contract suite completed." % suite)
        quit(0)
        return
    for failure in failures: push_error("FAIL[%s]: %s" % [suite, failure])
    quit(1)
