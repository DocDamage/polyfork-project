class_name PlayWorldEnvironmentRuntime
extends Node3D

signal environment_changed(state: Dictionary)
signal environment_event(event_name: String, payload: Dictionary)

const Contracts = preload("res://src/environment/environment_contracts.gd")
const Evaluator = preload("res://src/environment/environment_evaluator.gd")
const RenderBridge = preload("res://src/environment/environment_render_bridge.gd")

var _document: Dictionary = {}
var _terrain_state
var _procedural_runtime
var _render_bridge
var _play_mode := false
var _time_hours := 10.0
var _explicit_weather_id := ""
var _active_profile_id := ""
var _evaluated: Dictionary = {}
var _transition_from: Dictionary = {}
var _transition_elapsed := 0.0
var _transition_duration := 0.0
var _last_focus := Vector3.ZERO
var _last_warning := ""

func _init() -> void:
    name = "EnvironmentRuntime"
    _render_bridge = RenderBridge.new()
    add_child(_render_bridge)

func initialize(document: Dictionary, terrain_state = null, procedural_runtime = null, play_mode: bool = false) -> Dictionary:
    var errors: Array[String] = Contracts.validate_document(document)
    if not errors.is_empty():
        return {"ok": false, "errors": errors}
    _document = document.duplicate(true)
    _terrain_state = terrain_state
    _procedural_runtime = procedural_runtime
    _play_mode = play_mode
    _time_hours = float(_document.get("authored_state", {}).get("time_of_day_hours", 10.0))
    _explicit_weather_id = ""
    _active_profile_id = ""
    _evaluated.clear()
    _transition_from.clear()
    _transition_elapsed = 0.0
    _transition_duration = 0.0
    _last_warning = ""
    return _evaluate(Vector3.ZERO, 0.0, true)

func refresh_authored(document: Dictionary) -> Dictionary:
    var errors: Array[String] = Contracts.validate_document(document)
    if not errors.is_empty():
        return {"ok": false, "errors": errors}
    _document = document.duplicate(true)
    if not _play_mode:
        _time_hours = float(_document.get("authored_state", {}).get("time_of_day_hours", 10.0))
    if not _explicit_weather_id.is_empty() and _get_profile(_explicit_weather_id).is_empty():
        _explicit_weather_id = ""
    return _evaluate(_last_focus, 0.0, true)

func advance(delta: float, focus_position: Vector3 = Vector3.ZERO) -> Dictionary:
    if _document.is_empty():
        return _failure("Environment runtime is not initialized.")
    var authored: Dictionary = _document.get("authored_state", {})
    if _play_mode and bool(authored.get("progress_time_in_play", true)):
        var day_length := max(0.001, float(authored.get("day_length_seconds", 1200.0)))
        _time_hours = fposmod(_time_hours + max(0.0, delta) * 24.0 / day_length, 24.0)
    return _evaluate(focus_position, max(0.0, delta), false)

func set_time_of_day(hours: float) -> Dictionary:
    if _document.is_empty(): return _failure("Environment runtime is not initialized.")
    if hours < 0.0 or hours >= 24.0: return _failure("Environment runtime time must be in [0, 24).")
    _time_hours = hours
    var result := _evaluate(_last_focus, 0.0, true)
    if result.get("ok", false):
        environment_event.emit("environment.time_changed", {"time_of_day_hours": _time_hours})
    return result

func set_weather_profile(profile_id: String, transition_seconds: float = -1.0) -> Dictionary:
    if _get_profile(profile_id).is_empty():
        return _failure("Environment weather profile does not resolve: %s" % profile_id)
    _explicit_weather_id = profile_id
    _transition_duration = _default_transition_seconds() if transition_seconds < 0.0 else max(0.0, transition_seconds)
    var result := _evaluate(_last_focus, 0.0, false, true)
    if result.get("ok", false):
        environment_event.emit("environment.weather_changed", {"weather_profile_id": profile_id})
    return result

func clear_weather_override(transition_seconds: float = -1.0) -> Dictionary:
    _explicit_weather_id = ""
    _transition_duration = _default_transition_seconds() if transition_seconds < 0.0 else max(0.0, transition_seconds)
    var result := _evaluate(_last_focus, 0.0, false, true)
    if result.get("ok", false):
        environment_event.emit("environment.weather_override_cleared", {})
    return result

func set_rendering_enabled(value: bool) -> void:
    _render_bridge.set_rendering_enabled(value)

func is_rendering_enabled() -> bool:
    return _render_bridge.is_rendering_enabled()

func get_evaluated_state() -> Dictionary:
    return _evaluated.duplicate(true)

func get_wind_state() -> Dictionary:
    return _evaluated.get("wind", {}).duplicate(true)

func get_water_state() -> Dictionary:
    return {
        "water_modifiers": _evaluated.get("water_modifiers", {}).duplicate(true),
        "water_hooks": _evaluated.get("water_hooks", []).duplicate(true),
    }

func get_time_of_day() -> float:
    return _time_hours

func get_active_weather_profile_id() -> String:
    return _active_profile_id

func get_last_warning() -> String:
    return _last_warning

func get_render_snapshot() -> Dictionary:
    return _render_bridge.get_snapshot()

func clear() -> void:
    _document.clear()
    _terrain_state = null
    _procedural_runtime = null
    _play_mode = false
    _time_hours = 10.0
    _explicit_weather_id = ""
    _active_profile_id = ""
    _evaluated.clear()
    _transition_from.clear()
    _transition_elapsed = 0.0
    _transition_duration = 0.0
    _last_warning = ""
    _render_bridge.set_rendering_enabled(false)

func _evaluate(focus_position: Vector3, delta: float, force_immediate: bool, force_transition: bool = false) -> Dictionary:
    _last_focus = focus_position
    var resolved: Dictionary = _resolve_profile_context(focus_position)
    if not resolved.get("ok", false): return resolved
    var profile: Dictionary = resolved.get("profile", {})
    var profile_id := str(profile.get("weather_profile_id", ""))
    var target: Dictionary = Evaluator.evaluate(profile, _time_hours, _document.get("authored_state", {}), resolved.get("biome_override", {}))
    if not target.get("ok", false): return target
    target["cell_id"] = str(resolved.get("cell_id", ""))
    target["biome_id"] = str(resolved.get("biome_id", ""))
    target["weather_source"] = str(resolved.get("weather_source", "default"))
    target["water_hooks"] = resolved.get("water_hooks", []).duplicate(true)
    target["warning"] = _last_warning

    var profile_changed := profile_id != _active_profile_id
    if (profile_changed or force_transition) and not _evaluated.is_empty() and not force_immediate:
        _transition_from = _evaluated.duplicate(true)
        _transition_elapsed = 0.0
        if _transition_duration <= 0.0:
            _transition_duration = _default_transition_seconds()
    elif force_immediate or _evaluated.is_empty():
        _transition_from.clear()
        _transition_elapsed = 0.0
        _transition_duration = 0.0

    _active_profile_id = profile_id
    if not _transition_from.is_empty() and _transition_duration > 0.0:
        _transition_elapsed = min(_transition_duration, _transition_elapsed + delta)
        var weight := _transition_elapsed / _transition_duration
        _evaluated = Evaluator.blend(_transition_from, target, weight)
        for key in ["cell_id", "biome_id", "weather_source", "water_hooks", "warning", "time_of_day_hours", "sun_rotation_degrees"]:
            _evaluated[key] = target.get(key)
        if weight >= 1.0:
            _transition_from.clear()
            _transition_duration = 0.0
    else:
        _evaluated = target

    var render_result: Dictionary = _render_bridge.apply_state(_evaluated)
    if not render_result.get("ok", false): return render_result
    var wind_result := _push_wind()
    if not wind_result.get("ok", false): return wind_result
    environment_changed.emit(_evaluated.duplicate(true))
    return {"ok": true, "errors": [], "state": _evaluated.duplicate(true), "warning": _last_warning}

func _resolve_profile_context(position_value: Vector3) -> Dictionary:
    _last_warning = ""
    var authored: Dictionary = _document.get("authored_state", {})
    var profile_id := _explicit_weather_id
    var source := "runtime_override" if not profile_id.is_empty() else "default"
    var cell_id := ""
    var biome_id := ""
    var biome_override: Dictionary = {}
    var water_hooks: Array[Dictionary] = []
    if _terrain_state != null and _terrain_state.has_method("get_cell_at_position"):
        var cell: Dictionary = _terrain_state.get_cell_at_position(position_value)
        if not cell.is_empty():
            cell_id = str(cell.get("cell_id", ""))
            biome_id = str(cell.get("biome_id", ""))
            biome_override = _get_biome_override(biome_id)
            if profile_id.is_empty():
                var override_profile := str(biome_override.get("weather_profile_id", ""))
                if not override_profile.is_empty():
                    if _get_profile(override_profile).is_empty():
                        _last_warning = "Biome environment override references a missing weather profile; using authored default."
                    else:
                        profile_id = override_profile
                        source = "environment_biome_override"
                if profile_id.is_empty() and _terrain_state.has_method("get_biome"):
                    var biome: Dictionary = _terrain_state.get_biome(biome_id)
                    var future_defaults: Dictionary = biome.get("future_defaults", {})
                    var terrain_profile := str(future_defaults.get("environment_profile_id", ""))
                    if not terrain_profile.is_empty() and terrain_profile != "<null>":
                        if _get_profile(terrain_profile).is_empty():
                            _last_warning = "Terrain biome references a missing environment profile; using authored default."
                        else:
                            profile_id = terrain_profile
                            source = "terrain_biome_default"
            for hook_id in biome_override.get("water_hook_ids", []):
                var hook := _get_water_hook(str(hook_id))
                if not hook.is_empty(): water_hooks.append(hook)
    if profile_id.is_empty():
        profile_id = str(authored.get("default_weather_profile_id", ""))
        source = "default"
    var profile := _get_profile(profile_id)
    if profile.is_empty():
        var fallback_id := str(authored.get("default_weather_profile_id", ""))
        profile = _get_profile(fallback_id)
        profile_id = fallback_id
        source = "default_fallback"
        _last_warning = "Environment profile reference did not resolve; using authored default."
    if profile.is_empty(): return _failure("Environment authored default weather profile is missing.")
    return {"ok": true, "errors": [], "profile": profile, "biome_override": biome_override, "cell_id": cell_id, "biome_id": biome_id, "weather_source": source, "water_hooks": water_hooks}

func _push_wind() -> Dictionary:
    if _procedural_runtime == null or not _procedural_runtime.has_method("set_environment_wind"):
        return {"ok": true, "errors": [], "consumed": false}
    var result: Variant = _procedural_runtime.call("set_environment_wind", get_wind_state())
    if result is Dictionary: return result
    return _failure("Procedural wind consumer returned an invalid result.")

func _get_profile(profile_id: String) -> Dictionary:
    for record in _document.get("weather_profiles", []):
        if record is Dictionary and str(record.get("weather_profile_id", "")) == profile_id:
            return record.duplicate(true)
    return {}

func _get_biome_override(biome_id: String) -> Dictionary:
    for record in _document.get("biome_overrides", []):
        if record is Dictionary and str(record.get("biome_id", "")) == biome_id:
            return record.duplicate(true)
    return {}

func _get_water_hook(hook_id: String) -> Dictionary:
    for record in _document.get("water_hooks", []):
        if record is Dictionary and str(record.get("water_hook_id", "")) == hook_id:
            return record.duplicate(true)
    return {}

func _default_transition_seconds() -> float:
    return max(0.0, float(_document.get("authored_state", {}).get("default_transition_seconds", 5.0)))

static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
