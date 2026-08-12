extends SceneTree

const GraphContracts = preload("res://tests/unit/phase8_visual_graph_contracts.gd")
const GraphAuthoring = preload("res://tests/integration/phase8_visual_graph_authoring_contracts.gd")
const GraphCompiler = preload("res://tests/unit/phase8_visual_graph_compiler_contracts.gd")
const GraphRuntime = preload("res://tests/integration/phase8_visual_graph_runtime_contracts.gd")
const GraphMacros = preload("res://tests/integration/phase8_visual_graph_macro_contracts.gd")
const GraphWorkspace = preload("res://tests/integration/phase8_visual_graph_workspace_contracts.gd")

func _init() -> void: call_deferred("_run")
func _run() -> void:
    var suite := OS.get_environment("PHASE8_SUITE"); var errors: Array[String] = []
    match suite:
        "foundation": errors.append_array(GraphContracts.run_checks())
        "authoring": errors.append_array(GraphAuthoring.run_checks(root))
        "compiler": errors.append_array(GraphCompiler.run_checks())
        "runtime": errors.append_array(GraphRuntime.run_checks())
        "macros": errors.append_array(GraphMacros.run_checks())
        "workspace":
            var test := GraphWorkspace.new(); root.add_child(test); errors.append_array(test.run_checks()); test.queue_free()
        _: errors.append("Unknown Phase 8 suite: %s" % suite)
    if errors.is_empty(): print("PASS: Phase 8 %s contract suite completed." % suite); quit(0); return
    for error in errors: push_error(error)
    quit(1)
