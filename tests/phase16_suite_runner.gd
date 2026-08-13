extends SceneTree

const ProductCompleteness = preload("res://tests/unit/phase16_product_completeness_contracts.gd")
const IntegrationClosure = preload("res://tests/integration/phase16_integration_closure_contracts.gd")

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var suite := OS.get_environment("PHASE16_SUITE")
    var errors: Array[String] = []
    match suite:
        "product": errors.append_array(await ProductCompleteness.run_checks(self))
        "integration": errors.append_array(await IntegrationClosure.run_checks(self))
        _: errors.append("Unknown Phase 16 suite: %s" % suite)
    if errors.is_empty():
        print("PASS: Phase 16 %s contract suite completed." % suite)
        quit(0); return
    for item in errors: push_error(item)
    quit(1)
