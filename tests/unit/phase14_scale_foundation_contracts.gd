extends RefCounted

const Profiles = preload("res://src/scale/performance_profiles.gd")
const Benchmarks = preload("res://src/scale/benchmark_contract.gd")
const Preferences = preload("res://src/scale/user_preferences.gd")
const Glyphs = preload("res://src/scale/controller_glyphs.gd")
const PlaySession = preload("res://src/runtime/play_session.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var profiles: Array[Dictionary] = Profiles.all_profiles()
    if profiles.size() != 3: errors.append("Phase 14 must expose exactly Low, Balanced, and High performance presets.")
    var preset_ids: Array[String] = []
    for profile in profiles:
        var profile_errors: Array[String] = Profiles.validate_profile(profile)
        if not profile_errors.is_empty(): errors.append("Valid performance preset failed validation: %s" % str(profile_errors))
        preset_ids.append(str(profile.get("preset_id", "")))
        if profile.has("entities") or profile.has("terrain") or profile.has("gameplay") or profile.has("visual_graphs"):
            errors.append("Performance policy must not contain authored project semantics.")
    if preset_ids != ["low", "balanced", "high"]: errors.append("Performance preset ordering must be deterministic.")
    if Profiles.normalize_id("unknown") != Profiles.DEFAULT: errors.append("Unknown performance presets must safely fall back to Balanced.")
    if Profiles.validate_profile({"preset_id": "unknown"}).is_empty(): errors.append("Malformed performance profiles must be rejected.")

    var fixtures: Array[Dictionary] = Benchmarks.fixtures()
    if fixtures.size() != 4: errors.append("Phase 14 must define Small, Medium, Large, and Stress benchmark fixtures.")
    var last_entities := -1
    var signatures: Dictionary = {}
    for fixture in fixtures:
        var fixture_errors: Array[String] = Benchmarks.validate_fixture(fixture)
        if not fixture_errors.is_empty(): errors.append("Valid benchmark fixture failed validation: %s" % str(fixture_errors))
        var entities: int = int(fixture.get("entity_count", -1))
        if entities <= last_entities: errors.append("Benchmark entity counts must increase from Small through Stress.")
        last_entities = entities
        var signature: String = Benchmarks.stable_fixture_signature(fixture.get("fixture_id", ""))
        if signature.is_empty() or signatures.has(signature): errors.append("Benchmark fixture signatures must be stable and unique.")
        signatures[signature] = true
        var budgets: Dictionary = fixture.get("budgets", {})
        var sample: Dictionary = {}
        for metric in Benchmarks.METRIC_KEYS: sample[metric] = float(budgets.get(metric, 1.0)) * 0.5
        if not Benchmarks.evaluate_sample(fixture.get("fixture_id", ""), sample).get("ok", false): errors.append("Within-budget benchmark sample must pass.")
        sample["frame_time_ms"] = float(budgets.get("frame_time_ms", 1.0)) * 2.0
        if Benchmarks.evaluate_sample(fixture.get("fixture_id", ""), sample).get("ok", true): errors.append("Over-budget benchmark sample must fail.")

    var normalized: Dictionary = Preferences.normalize({"performance_preset": "invalid", "ui_scale": 1.22, "density": "invalid", "controller_glyphs": "invalid"})
    if str(normalized.get("performance_preset", "")) != "balanced": errors.append("Invalid stored preset must normalize to Balanced.")
    if not is_equal_approx(float(normalized.get("ui_scale", 0.0)), 1.25): errors.append("UI scale must normalize to the nearest supported scale.")
    if str(normalized.get("density", "")) != "comfortable": errors.append("Invalid density must normalize to Comfortable.")
    if not Glyphs.action_hint(&"confirm", &"gamepad").begins_with("A"): errors.append("Gamepad confirm hint must use the canonical A glyph.")
    if not Glyphs.action_hint(&"back", &"keyboard_mouse").begins_with("Esc"): errors.append("Keyboard back hint must use the canonical Escape glyph.")

    var play_session = PlaySession.new()
    var low_result: Dictionary = play_session.configure_performance_profile(Profiles.get_profile(Profiles.LOW))
    if not low_result.get("ok", false): errors.append("PlaySession must accept a validated Phase 14 performance profile.")
    elif str(play_session.get_performance_profile().get("preset_id", "")) != "low": errors.append("PlaySession must retain the selected performance policy without changing authored state.")
    if play_session.configure_performance_profile({"preset_id": "invalid"}).get("ok", true): errors.append("PlaySession must reject malformed performance policy.")
    play_session.free()
    return errors
