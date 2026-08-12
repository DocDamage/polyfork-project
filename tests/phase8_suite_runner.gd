extends SceneTree

const GraphContracts = preload("res://tests/unit/phase8_visual_graph_contracts.gd")

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var suite := OS.get_environment("PHASE8_SUITE")
    var errors: Array[String] = []
    match suite:
        "foundation": errors.append_array(GraphContracts.run_checks())
        _: errors.append("Unknown Phase 8 suite: %s" % suite)
    if errors.is_empty():
        print("PASS: Phase 8 %s contract suite completed." % suite)
        quit(0); return
    for error in errors: push_error(error)
    quit(1)
