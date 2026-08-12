class_name PlayWorldPerformanceProfiles
extends RefCounted

const LOW: StringName = &"low"
const BALANCED: StringName = &"balanced"
const HIGH: StringName = &"high"
const DEFAULT: StringName = BALANCED

const REQUIRED_KEYS := [
    "preset_id",
    "display_name",
    "target_fps",
    "frame_time_budget_ms",
    "memory_budget_mb",
    "streaming_focus_interval_ms",
    "environment_update_interval_ms",
    "foliage_visibility_range_m",
    "foliage_shadow_enabled",
    "procedural_preview_instance_limit",
    "ui_refresh_hz",
    "render_scale",
    "export_worker_limit",
]

const PROFILE_DATA := {
    "low": {
        "preset_id": "low",
        "display_name": "Low",
        "target_fps": 30,
        "frame_time_budget_ms": 33.34,
        "memory_budget_mb": 1536,
        "streaming_focus_interval_ms": 100,
        "environment_update_interval_ms": 100,
        "foliage_visibility_range_m": 650.0,
        "foliage_shadow_enabled": false,
        "procedural_preview_instance_limit": 5000,
        "ui_refresh_hz": 20,
        "render_scale": 0.75,
        "export_worker_limit": 2,
    },
    "balanced": {
        "preset_id": "balanced",
        "display_name": "Balanced",
        "target_fps": 60,
        "frame_time_budget_ms": 16.67,
        "memory_budget_mb": 2560,
        "streaming_focus_interval_ms": 50,
        "environment_update_interval_ms": 50,
        "foliage_visibility_range_m": 1200.0,
        "foliage_shadow_enabled": false,
        "procedural_preview_instance_limit": 12000,
        "ui_refresh_hz": 30,
        "render_scale": 0.90,
        "export_worker_limit": 4,
    },
    "high": {
        "preset_id": "high",
        "display_name": "High",
        "target_fps": 60,
        "frame_time_budget_ms": 16.67,
        "memory_budget_mb": 4096,
        "streaming_focus_interval_ms": 25,
        "environment_update_interval_ms": 0,
        "foliage_visibility_range_m": 2200.0,
        "foliage_shadow_enabled": true,
        "procedural_preview_instance_limit": 24000,
        "ui_refresh_hz": 60,
        "render_scale": 1.0,
        "export_worker_limit": 8,
    },
}


static func normalize_id(value: Variant) -> StringName:
    var normalized := str(value).strip_edges().to_lower()
    if PROFILE_DATA.has(normalized):
        return StringName(normalized)
    return DEFAULT


static func get_profile(value: Variant = DEFAULT) -> Dictionary:
    var preset_id := normalize_id(value)
    return PROFILE_DATA[str(preset_id)].duplicate(true)


static func all_profiles() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for preset_id in [LOW, BALANCED, HIGH]:
        result.append(get_profile(preset_id))
    return result


static func validate_profile(profile: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    for key in REQUIRED_KEYS:
        if not profile.has(key):
            errors.append("Performance profile is missing required key '%s'." % key)
    if not errors.is_empty():
        return errors
    if normalize_id(profile.get("preset_id", "")) != StringName(str(profile.get("preset_id", ""))):
        errors.append("Performance profile preset_id must be one of low, balanced, or high.")
    if int(profile.get("target_fps", 0)) <= 0:
        errors.append("Performance profile target_fps must be positive.")
    if float(profile.get("frame_time_budget_ms", 0.0)) <= 0.0:
        errors.append("Performance profile frame-time budget must be positive.")
    if int(profile.get("memory_budget_mb", 0)) <= 0:
        errors.append("Performance profile memory budget must be positive.")
    if float(profile.get("render_scale", 0.0)) <= 0.0 or float(profile.get("render_scale", 0.0)) > 1.0:
        errors.append("Performance profile render_scale must be greater than zero and at most one.")
    return errors


static func effective_summary(value: Variant = DEFAULT) -> Dictionary:
    var profile := get_profile(value)
    return {
        "preset_id": profile["preset_id"],
        "display_name": profile["display_name"],
        "target_fps": profile["target_fps"],
        "frame_time_budget_ms": profile["frame_time_budget_ms"],
        "memory_budget_mb": profile["memory_budget_mb"],
        "render_scale": profile["render_scale"],
        "streaming_focus_interval_ms": profile["streaming_focus_interval_ms"],
        "environment_update_interval_ms": profile["environment_update_interval_ms"],
        "foliage_visibility_range_m": profile["foliage_visibility_range_m"],
        "procedural_preview_instance_limit": profile["procedural_preview_instance_limit"],
    }
