class_name PlayWorldUserPreferences
extends RefCounted

const Profiles = preload("res://src/scale/performance_profiles.gd")
const DEFAULT_PATH := "user://scale_polish.cfg"
const UI_SCALES := [0.90, 1.0, 1.10, 1.25, 1.50]
const DENSITIES := ["comfortable", "compact"]

var _path: String

func _init(path: String = DEFAULT_PATH) -> void:
    _path = path

static func defaults() -> Dictionary:
    return {
        "performance_preset": str(Profiles.DEFAULT),
        "ui_scale": 1.0,
        "reduced_motion": false,
        "density": "comfortable",
        "controller_glyphs": "auto",
    }

func load_preferences() -> Dictionary:
    var result: Dictionary = defaults()
    var config := ConfigFile.new()
    var load_error: Error = config.load(_path)
    if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
        return {"ok": false, "errors": ["Could not load user scale/polish preferences."], "settings": result}
    if load_error == OK:
        for key in result.keys(): result[key] = config.get_value("preferences", key, result[key])
    result = normalize(result)
    return {"ok": true, "errors": [], "settings": result}

func save_preferences(settings: Dictionary) -> Dictionary:
    var normalized: Dictionary = normalize(settings)
    var config := ConfigFile.new()
    for key in normalized.keys(): config.set_value("preferences", key, normalized[key])
    var save_error: Error = config.save(_path)
    if save_error != OK:
        return {"ok": false, "errors": ["Could not save user scale/polish preferences."], "settings": normalized}
    return {"ok": true, "errors": [], "settings": normalized}

static func normalize(settings: Dictionary) -> Dictionary:
    var result: Dictionary = defaults()
    result["performance_preset"] = str(Profiles.normalize_id(settings.get("performance_preset", result["performance_preset"])))
    result["ui_scale"] = _nearest_scale(float(settings.get("ui_scale", result["ui_scale"])))
    result["reduced_motion"] = bool(settings.get("reduced_motion", result["reduced_motion"]))
    var density: String = str(settings.get("density", result["density"]))
    result["density"] = density if DENSITIES.has(density) else "comfortable"
    var glyphs: String = str(settings.get("controller_glyphs", "auto"))
    result["controller_glyphs"] = glyphs if ["auto", "generic"].has(glyphs) else "auto"
    return result

static func _nearest_scale(value: float) -> float:
    var selected: float = float(UI_SCALES[0])
    var best_distance: float = absf(value - selected)
    for candidate in UI_SCALES:
        var distance: float = absf(value - float(candidate))
        if distance < best_distance:
            selected = float(candidate)
            best_distance = distance
    return selected
