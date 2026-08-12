class_name PlayWorldEnvironmentEvaluator
extends RefCounted

static func evaluate(profile: Dictionary, time_hours: float, authored_state: Dictionary = {}, biome_override: Dictionary = {}) -> Dictionary:
    if profile.is_empty():
        return {"ok": false, "errors": ["Environment evaluation requires a weather profile."]}
    var local_time: float = fposmod(time_hours + float(biome_override.get("time_offset_hours", 0.0)), 24.0)
    var solar_angle: float = TAU * ((local_time - 6.0) / 24.0)
    var sun_height: float = sin(solar_angle)
    var daylight: float = clampf((sun_height + 0.12) / 0.72, 0.0, 1.0)
    var night_factor: float = 1.0 - daylight
    var fog_multiplier: float = maxf(0.0, float(biome_override.get("fog_density_multiplier", 1.0)))
    var wind_multiplier: float = maxf(0.0, float(biome_override.get("wind_multiplier", 1.0)))
    var fog_enabled: bool = bool(authored_state.get("fog_enabled", true))
    var wind_enabled: bool = bool(authored_state.get("wind_enabled", true))
    var direction: Vector3 = _normalized_direction(profile.get("wind_direction", [1.0, 0.0, 0.0]))
    var sun_energy: float = float(profile.get("sun_energy", 1.0)) * lerpf(0.04, 1.0, daylight)
    var ambient_energy: float = float(profile.get("ambient_energy", 0.5)) * lerpf(0.24, 1.0, daylight)
    return {
        "ok": true,
        "errors": [],
        "weather_profile_id": str(profile.get("weather_profile_id", "")),
        "weather_display_name": str(profile.get("display_name", "Weather")),
        "time_of_day_hours": local_time,
        "daylight": daylight,
        "night_factor": night_factor,
        "sun_rotation_degrees": Vector3(rad_to_deg(-solar_angle), 145.0, 0.0),
        "sun_color": _color(profile.get("sun_color", [1.0, 1.0, 1.0, 1.0])),
        "sun_energy": sun_energy,
        "ambient_color": _color(profile.get("ambient_color", [0.7, 0.8, 0.9, 1.0])).darkened(night_factor * 0.55),
        "ambient_energy": ambient_energy,
        "sky_top_color": _color(profile.get("sky_top_color", [0.1, 0.3, 0.6, 1.0])).darkened(night_factor * 0.82),
        "sky_horizon_color": _color(profile.get("sky_horizon_color", [0.5, 0.7, 0.9, 1.0])).darkened(night_factor * 0.72),
        "fog_enabled": fog_enabled and float(profile.get("fog_density", 0.0)) > 0.0,
        "fog_color": _color(profile.get("fog_color", [0.7, 0.8, 0.9, 1.0])).darkened(night_factor * 0.6),
        "fog_density": float(profile.get("fog_density", 0.0)) * fog_multiplier if fog_enabled else 0.0,
        "wind": {
            "enabled": wind_enabled,
            "direction": direction,
            "speed_mps": float(profile.get("wind_speed_mps", 0.0)) * wind_multiplier if wind_enabled else 0.0,
            "gust_strength": float(profile.get("wind_gust_strength", 0.0)) * wind_multiplier if wind_enabled else 0.0,
        },
        "precipitation": float(profile.get("precipitation", 0.0)),
        "cloud_coverage": float(profile.get("cloud_coverage", 0.0)),
        "water_modifiers": profile.get("water_modifiers", {}).duplicate(true),
    }

static func blend(a: Dictionary, b: Dictionary, weight: float) -> Dictionary:
    if a.is_empty(): return b.duplicate(true)
    if b.is_empty(): return a.duplicate(true)
    var t: float = clampf(weight, 0.0, 1.0)
    var result: Dictionary = a.duplicate(true)
    for key in ["sun_energy", "ambient_energy", "fog_density", "precipitation", "cloud_coverage", "daylight", "night_factor"]:
        result[key] = lerpf(float(a.get(key, 0.0)), float(b.get(key, 0.0)), t)
    for key in ["sun_color", "ambient_color", "sky_top_color", "sky_horizon_color", "fog_color"]:
        var left: Color = a.get(key, Color.WHITE)
        var right: Color = b.get(key, Color.WHITE)
        result[key] = left.lerp(right, t)
    var aw: Dictionary = a.get("wind", {})
    var bw: Dictionary = b.get("wind", {})
    var left_direction: Vector3 = aw.get("direction", Vector3.RIGHT)
    var right_direction: Vector3 = bw.get("direction", Vector3.RIGHT)
    var direction: Vector3 = left_direction.lerp(right_direction, t)
    if direction.length_squared() > 0.000001: direction = direction.normalized()
    result["wind"] = {
        "enabled": bool(aw.get("enabled", true)) or bool(bw.get("enabled", true)),
        "direction": direction,
        "speed_mps": lerpf(float(aw.get("speed_mps", 0.0)), float(bw.get("speed_mps", 0.0)), t),
        "gust_strength": lerpf(float(aw.get("gust_strength", 0.0)), float(bw.get("gust_strength", 0.0)), t),
    }
    result["weather_profile_id"] = str(b.get("weather_profile_id", "")) if t >= 0.5 else str(a.get("weather_profile_id", ""))
    result["weather_display_name"] = str(b.get("weather_display_name", "Weather")) if t >= 0.5 else str(a.get("weather_display_name", "Weather"))
    result["water_modifiers"] = b.get("water_modifiers", {}).duplicate(true) if t >= 0.5 else a.get("water_modifiers", {}).duplicate(true)
    return result

static func _color(value: Variant) -> Color:
    if value is Color: return value
    if value is Array and value.size() == 4:
        return Color(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
    return Color.WHITE

static func _normalized_direction(value: Variant) -> Vector3:
    if value is Array and value.size() == 3:
        var direction: Vector3 = Vector3(float(value[0]), float(value[1]), float(value[2]))
        if direction.length_squared() > 0.000001: return direction.normalized()
    return Vector3.RIGHT
