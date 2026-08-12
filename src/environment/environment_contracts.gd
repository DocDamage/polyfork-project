class_name PlayWorldEnvironmentContracts
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")

const DOCUMENT_TYPE := "environment_registry"
const SCHEMA_VERSION := 1


static func empty_document(project_id: String) -> Dictionary:
    var clear_id: String = StableId.generate()
    return {
        "document_type": DOCUMENT_TYPE,
        "schema_version": SCHEMA_VERSION,
        "project_id": project_id,
        "authored_state": {
            "time_of_day_hours": 10.0,
            "day_length_seconds": 1200.0,
            "progress_time_in_play": true,
            "default_weather_profile_id": clear_id,
            "default_transition_seconds": 5.0,
            "fog_enabled": true,
            "wind_enabled": true,
        },
        "weather_profiles": [_default_clear_profile(clear_id)],
        "biome_overrides": [],
        "water_hooks": [],
    }


static func validate_document(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if data.get("document_type") != DOCUMENT_TYPE:
        errors.append("Environment document_type is invalid.")
    if int(data.get("schema_version", 0)) != SCHEMA_VERSION:
        errors.append("Environment schema_version is unsupported.")
    if not StableId.is_valid(str(data.get("project_id", ""))):
        errors.append("Environment project_id must be a stable UUID.")

    var profiles_value: Variant = data.get("weather_profiles", [])
    if not profiles_value is Array:
        errors.append("Environment weather_profiles must be an array.")
        return errors
    var profile_ids: Array[String] = []
    var seen_profiles: Dictionary = {}
    for value in profiles_value:
        if not value is Dictionary:
            errors.append("Environment weather_profiles must contain dictionaries.")
            continue
        var record: Dictionary = value
        errors.append_array(validate_weather_profile(record))
        var profile_id: String = str(record.get("weather_profile_id", ""))
        if StableId.is_valid(profile_id):
            if seen_profiles.has(profile_id):
                errors.append("Environment contains a duplicate weather_profile_id.")
            else:
                seen_profiles[profile_id] = true
                profile_ids.append(profile_id)
    if profile_ids.is_empty():
        errors.append("Environment must contain at least one weather profile.")

    var hooks_value: Variant = data.get("water_hooks", [])
    var hook_ids: Array[String] = []
    var seen_hooks: Dictionary = {}
    if not hooks_value is Array:
        errors.append("Environment water_hooks must be an array.")
    else:
        for value in hooks_value:
            if not value is Dictionary:
                errors.append("Environment water_hooks must contain dictionaries.")
                continue
            var hook: Dictionary = value
            errors.append_array(validate_water_hook(hook))
            var hook_id: String = str(hook.get("water_hook_id", ""))
            if StableId.is_valid(hook_id):
                if seen_hooks.has(hook_id):
                    errors.append("Environment contains a duplicate water_hook_id.")
                else:
                    seen_hooks[hook_id] = true
                    hook_ids.append(hook_id)

    errors.append_array(validate_authored_state(data.get("authored_state", {}), profile_ids))

    var overrides_value: Variant = data.get("biome_overrides", [])
    var seen_overrides: Dictionary = {}
    var seen_biomes: Dictionary = {}
    if not overrides_value is Array:
        errors.append("Environment biome_overrides must be an array.")
    else:
        for value in overrides_value:
            if not value is Dictionary:
                errors.append("Environment biome_overrides must contain dictionaries.")
                continue
            var override_record: Dictionary = value
            errors.append_array(validate_biome_override(override_record, profile_ids, hook_ids))
            var override_id: String = str(override_record.get("override_id", ""))
            var biome_id: String = str(override_record.get("biome_id", ""))
            if StableId.is_valid(override_id):
                if seen_overrides.has(override_id):
                    errors.append("Environment contains a duplicate biome override ID.")
                seen_overrides[override_id] = true
            if StableId.is_valid(biome_id):
                if seen_biomes.has(biome_id):
                    errors.append("Environment contains multiple overrides for the same biome.")
                seen_biomes[biome_id] = true
    return errors


static func validate_authored_state(value: Variant, profile_ids: Array[String]) -> Array[String]:
    var errors: Array[String] = []
    if not value is Dictionary:
        return ["Environment authored_state must be a dictionary."]
    var state: Dictionary = value
    var time_value: float = float(state.get("time_of_day_hours", -1.0))
    if time_value < 0.0 or time_value >= 24.0:
        errors.append("Environment time_of_day_hours must be in [0, 24).")
    if float(state.get("day_length_seconds", 0.0)) <= 0.0:
        errors.append("Environment day_length_seconds must be positive.")
    if float(state.get("default_transition_seconds", -1.0)) < 0.0:
        errors.append("Environment default_transition_seconds must be non-negative.")
    var default_id: String = str(state.get("default_weather_profile_id", ""))
    if not StableId.is_valid(default_id) or not profile_ids.has(default_id):
        errors.append("Environment default_weather_profile_id must reference an existing profile.")
    if not state.has("progress_time_in_play"):
        errors.append("Environment progress_time_in_play is required.")
    if not state.has("fog_enabled"):
        errors.append("Environment fog_enabled is required.")
    if not state.has("wind_enabled"):
        errors.append("Environment wind_enabled is required.")
    return errors


static func validate_weather_profile(record: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if not StableId.is_valid(str(record.get("weather_profile_id", ""))):
        errors.append("Weather profile ID must be a stable UUID.")
    if str(record.get("display_name", "")).strip_edges().is_empty():
        errors.append("Weather profile display_name is required.")
    for key in ["sky_top_color", "sky_horizon_color", "ambient_color", "sun_color", "fog_color"]:
        if not _valid_color(record.get(key, [])):
            errors.append("Weather profile %s must contain four numeric channels." % key)
    for key in ["sun_energy", "ambient_energy", "fog_density", "wind_speed_mps", "wind_gust_strength", "precipitation", "cloud_coverage"]:
        if float(record.get(key, -1.0)) < 0.0:
            errors.append("Weather profile %s must be non-negative." % key)
    if float(record.get("fog_density", 0.0)) > 1.0:
        errors.append("Weather profile fog_density must not exceed 1.0.")
    if float(record.get("precipitation", 0.0)) > 1.0:
        errors.append("Weather profile precipitation must not exceed 1.0.")
    if float(record.get("cloud_coverage", 0.0)) > 1.0:
        errors.append("Weather profile cloud_coverage must not exceed 1.0.")
    var wind_direction: Variant = record.get("wind_direction", [])
    if not wind_direction is Array or wind_direction.size() != 3:
        errors.append("Weather profile wind_direction must contain three channels.")
    if not record.get("water_modifiers", {}) is Dictionary:
        errors.append("Weather profile water_modifiers must be a dictionary.")
    return errors


static func validate_water_hook(record: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if not StableId.is_valid(str(record.get("water_hook_id", ""))):
        errors.append("Water hook ID must be a stable UUID.")
    if str(record.get("display_name", "")).strip_edges().is_empty():
        errors.append("Water hook display_name is required.")
    if str(record.get("provider_key", "")).strip_edges().is_empty():
        errors.append("Water hook provider_key is required.")
    if not record.get("settings", {}) is Dictionary:
        errors.append("Water hook settings must be a dictionary.")
    if not record.get("tags", []) is Array:
        errors.append("Water hook tags must be an array.")
    return errors


static func validate_biome_override(record: Dictionary, profile_ids: Array[String], water_hook_ids: Array[String]) -> Array[String]:
    var errors: Array[String] = []
    if not StableId.is_valid(str(record.get("override_id", ""))):
        errors.append("Biome override ID must be a stable UUID.")
    if not StableId.is_valid(str(record.get("biome_id", ""))):
        errors.append("Biome override biome_id must be a stable UUID.")
    var profile_id: String = str(record.get("weather_profile_id", ""))
    if not profile_id.is_empty() and (not StableId.is_valid(profile_id) or not profile_ids.has(profile_id)):
        errors.append("Biome override weather_profile_id must reference an existing profile.")
    if float(record.get("wind_multiplier", 1.0)) < 0.0:
        errors.append("Biome override wind_multiplier must be non-negative.")
    if float(record.get("fog_density_multiplier", 1.0)) < 0.0:
        errors.append("Biome override fog_density_multiplier must be non-negative.")
    var hooks: Variant = record.get("water_hook_ids", [])
    if not hooks is Array:
        errors.append("Biome override water_hook_ids must be an array.")
    else:
        for hook_id in hooks:
            if not water_hook_ids.has(str(hook_id)):
                errors.append("Biome override references a missing water hook.")
    return errors


static func _default_clear_profile(profile_id: String) -> Dictionary:
    return {
        "weather_profile_id": profile_id,
        "display_name": "Clear",
        "sky_top_color": [0.11, 0.32, 0.62, 1.0],
        "sky_horizon_color": [0.58, 0.76, 0.92, 1.0],
        "ambient_color": [0.72, 0.80, 0.92, 1.0],
        "ambient_energy": 0.65,
        "sun_color": [1.0, 0.94, 0.82, 1.0],
        "sun_energy": 1.15,
        "fog_color": [0.68, 0.78, 0.86, 1.0],
        "fog_density": 0.002,
        "wind_direction": [1.0, 0.0, 0.25],
        "wind_speed_mps": 2.5,
        "wind_gust_strength": 0.2,
        "precipitation": 0.0,
        "cloud_coverage": 0.15,
        "water_modifiers": {},
    }


static func _valid_color(value: Variant) -> bool:
    if not value is Array or value.size() != 4:
        return false
    for channel in value:
        var numeric: float = float(channel)
        if numeric < 0.0 or numeric > 1.0:
            return false
    return true
