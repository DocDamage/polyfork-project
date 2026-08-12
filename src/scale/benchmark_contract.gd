class_name PlayWorldBenchmarkContract
extends RefCounted

const ORDER := [&"small", &"medium", &"large", &"stress"]
const METRIC_KEYS := ["frame_time_ms", "memory_mb", "project_open_ms", "save_ms", "build_play_ms", "streaming_ms", "export_ms"]

const FIXTURES := {
    "small": {
        "fixture_id": "small",
        "entity_count": 500,
        "terrain_cell_count": 9,
        "foliage_instance_count": 10000,
        "procedural_rule_count": 10,
        "visual_graph_count": 5,
        "gameplay_component_count": 250,
        "budgets": {"frame_time_ms": 16.67, "memory_mb": 1024.0, "project_open_ms": 1800.0, "save_ms": 700.0, "build_play_ms": 900.0, "streaming_ms": 24.0, "export_ms": 9000.0},
    },
    "medium": {
        "fixture_id": "medium",
        "entity_count": 5000,
        "terrain_cell_count": 49,
        "foliage_instance_count": 75000,
        "procedural_rule_count": 50,
        "visual_graph_count": 25,
        "gameplay_component_count": 2500,
        "budgets": {"frame_time_ms": 20.0, "memory_mb": 2048.0, "project_open_ms": 3000.0, "save_ms": 1200.0, "build_play_ms": 1500.0, "streaming_ms": 40.0, "export_ms": 18000.0},
    },
    "large": {
        "fixture_id": "large",
        "entity_count": 20000,
        "terrain_cell_count": 121,
        "foliage_instance_count": 250000,
        "procedural_rule_count": 150,
        "visual_graph_count": 75,
        "gameplay_component_count": 10000,
        "budgets": {"frame_time_ms": 25.0, "memory_mb": 3584.0, "project_open_ms": 5500.0, "save_ms": 2400.0, "build_play_ms": 2800.0, "streaming_ms": 70.0, "export_ms": 36000.0},
    },
    "stress": {
        "fixture_id": "stress",
        "entity_count": 50000,
        "terrain_cell_count": 225,
        "foliage_instance_count": 500000,
        "procedural_rule_count": 300,
        "visual_graph_count": 150,
        "gameplay_component_count": 25000,
        "budgets": {"frame_time_ms": 33.34, "memory_mb": 6144.0, "project_open_ms": 9000.0, "save_ms": 4500.0, "build_play_ms": 5000.0, "streaming_ms": 120.0, "export_ms": 60000.0},
    },
}


static func fixture(value: Variant) -> Dictionary:
    var fixture_id := str(value).strip_edges().to_lower()
    if not FIXTURES.has(fixture_id):
        return {}
    return FIXTURES[fixture_id].duplicate(true)


static func fixtures() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for fixture_id in ORDER:
        result.append(fixture(fixture_id))
    return result


static func validate_fixture(value: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    var fixture_id := str(value.get("fixture_id", ""))
    if not FIXTURES.has(fixture_id):
        errors.append("Benchmark fixture_id must be small, medium, large, or stress.")
        return errors
    for key in ["entity_count", "terrain_cell_count", "foliage_instance_count", "procedural_rule_count", "visual_graph_count", "gameplay_component_count"]:
        if int(value.get(key, -1)) < 0:
            errors.append("Benchmark fixture '%s' has invalid %s." % [fixture_id, key])
    var budgets: Dictionary = value.get("budgets", {})
    for metric in METRIC_KEYS:
        if float(budgets.get(metric, 0.0)) <= 0.0:
            errors.append("Benchmark fixture '%s' has no positive budget for %s." % [fixture_id, metric])
    return errors


static func evaluate_sample(fixture_id: Variant, sample: Dictionary) -> Dictionary:
    var definition := fixture(fixture_id)
    if definition.is_empty():
        return {"ok": false, "errors": ["Unknown benchmark fixture."], "violations": []}
    var violations: Array[Dictionary] = []
    var normalized: Dictionary = {}
    var budgets: Dictionary = definition["budgets"]
    for metric in METRIC_KEYS:
        var value := float(sample.get(metric, 0.0))
        normalized[metric] = value
        if value < 0.0:
            violations.append({"metric": metric, "value": value, "budget": budgets[metric], "reason": "negative"})
        elif value > float(budgets[metric]):
            violations.append({"metric": metric, "value": value, "budget": budgets[metric], "reason": "over_budget"})
    return {
        "ok": violations.is_empty(),
        "errors": [],
        "fixture_id": definition["fixture_id"],
        "sample": normalized,
        "budgets": budgets.duplicate(true),
        "violations": violations,
    }


static func stable_fixture_signature(fixture_id: Variant) -> String:
    var value := fixture(fixture_id)
    if value.is_empty():
        return ""
    return "%s|e=%d|t=%d|f=%d|p=%d|v=%d|g=%d" % [
        value["fixture_id"],
        int(value["entity_count"]),
        int(value["terrain_cell_count"]),
        int(value["foliage_instance_count"]),
        int(value["procedural_rule_count"]),
        int(value["visual_graph_count"]),
        int(value["gameplay_component_count"]),
    ]


static func build_report(preset_id: String, samples: Dictionary) -> Dictionary:
    var evaluations: Array[Dictionary] = []
    var all_ok := true
    for fixture_id in ORDER:
        var evaluation := evaluate_sample(fixture_id, samples.get(str(fixture_id), {}))
        evaluations.append(evaluation)
        all_ok = all_ok and bool(evaluation.get("ok", false))
    return {
        "schema_version": 1,
        "preset_id": preset_id,
        "fixture_order": ["small", "medium", "large", "stress"],
        "evaluations": evaluations,
        "ok": all_ok,
    }
