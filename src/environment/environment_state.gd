class_name PlayWorldEnvironmentState
extends RefCounted

const Contracts = preload("res://src/environment/environment_contracts.gd")

var project_id: String = ""
var authored_state: Dictionary = {}
var weather_profiles: Array[Dictionary] = []
var biome_overrides: Array[Dictionary] = []
var water_hooks: Array[Dictionary] = []

func load_document(data: Dictionary) -> Array[String]:
    var errors: Array[String] = Contracts.validate_document(data)
    if not errors.is_empty():
        return errors
    project_id = str(data.get("project_id", ""))
    authored_state = data.get("authored_state", {}).duplicate(true)
    weather_profiles = _records(data.get("weather_profiles", []))
    biome_overrides = _records(data.get("biome_overrides", []))
    water_hooks = _records(data.get("water_hooks", []))
    _normalize_types()
    return []

func replace_document(data: Dictionary) -> Array[String]:
    return load_document(data)

func validate() -> Array[String]:
    return Contracts.validate_document(to_document())

func to_document() -> Dictionary:
    return {
        "document_type": Contracts.DOCUMENT_TYPE,
        "schema_version": Contracts.SCHEMA_VERSION,
        "project_id": project_id,
        "authored_state": authored_state.duplicate(true),
        "weather_profiles": weather_profiles.duplicate(true),
        "biome_overrides": biome_overrides.duplicate(true),
        "water_hooks": water_hooks.duplicate(true),
    }

func get_weather_profile(profile_id: String) -> Dictionary:
    return _find(weather_profiles, "weather_profile_id", profile_id)

func get_biome_override(biome_id: String) -> Dictionary:
    return _find(biome_overrides, "biome_id", biome_id)

func get_water_hook(hook_id: String) -> Dictionary:
    return _find(water_hooks, "water_hook_id", hook_id)

func weather_profile_ids() -> Array[String]:
    return _ids(weather_profiles, "weather_profile_id")

func biome_override_ids() -> Array[String]:
    return _ids(biome_overrides, "override_id")

func water_hook_ids() -> Array[String]:
    return _ids(water_hooks, "water_hook_id")

func _normalize_types() -> void:
    authored_state["time_of_day_hours"] = float(authored_state.get("time_of_day_hours", 10.0))
    authored_state["day_length_seconds"] = float(authored_state.get("day_length_seconds", 1200.0))
    authored_state["default_transition_seconds"] = float(authored_state.get("default_transition_seconds", 5.0))
    for index in range(weather_profiles.size()):
        var profile: Dictionary = weather_profiles[index]
        for key in ["ambient_energy", "sun_energy", "fog_density", "wind_speed_mps", "wind_gust_strength", "precipitation", "cloud_coverage"]:
            profile[key] = float(profile.get(key, 0.0))
        weather_profiles[index] = profile
    for index in range(biome_overrides.size()):
        var item: Dictionary = biome_overrides[index]
        item["time_offset_hours"] = float(item.get("time_offset_hours", 0.0))
        item["wind_multiplier"] = float(item.get("wind_multiplier", 1.0))
        item["fog_density_multiplier"] = float(item.get("fog_density_multiplier", 1.0))
        biome_overrides[index] = item

static func _records(value: Variant) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if value is Array:
        for item in value:
            if item is Dictionary:
                result.append(item.duplicate(true))
    return result

static func _find(records: Array[Dictionary], key: String, expected: String) -> Dictionary:
    for record in records:
        if str(record.get(key, "")) == expected:
            return record.duplicate(true)
    return {}

static func _ids(records: Array[Dictionary], key: String) -> Array[String]:
    var result: Array[String] = []
    for record in records:
        result.append(str(record.get(key, "")))
    result.sort()
    return result
