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
    if not FileAccess.file_exists(_path):
        return {"ok": true, "errors": [], "settings": result}
    var parsed: Dictionary = _parse_preferences_text(FileAccess.get_file_as_string(_path))
    if not parsed.get("ok", false):
        var backup := _preserve_malformed_file()
        var errors: Array[String] = ["Could not load user scale/polish preferences. Safe defaults are active."]
        if not backup.is_empty(): errors.append("Malformed preferences were preserved at %s" % backup)
        return {"ok": false, "errors": errors, "settings": result, "recovery_backup": backup}
    var values: Dictionary = parsed.get("values", {})
    for key in result.keys():
        if values.has(key): result[key] = values[key]
    result = normalize(result)
    return {"ok": true, "errors": [], "settings": result}

func save_preferences(settings: Dictionary) -> Dictionary:
    var normalized: Dictionary = normalize(settings)
    var absolute := ProjectSettings.globalize_path(_path)
    var parent := absolute.get_base_dir()
    var make_error := DirAccess.make_dir_recursive_absolute(parent)
    if make_error not in [OK, ERR_ALREADY_EXISTS]:
        return {"ok": false, "errors": ["Could not create the user preferences directory."], "settings": normalized}
    var temp_path := "%s.phase18-tmp" % _path
    var config := ConfigFile.new()
    for key in normalized.keys(): config.set_value("preferences", key, normalized[key])
    var save_error: Error = config.save(temp_path)
    if save_error != OK:
        return {"ok": false, "errors": ["Could not stage user scale/polish preferences."], "settings": normalized}
    var temp_absolute := ProjectSettings.globalize_path(temp_path)
    if FileAccess.file_exists(_path):
        var previous := "%s.previous" % _path
        _copy_file(_path, previous)
    var rename_error := DirAccess.rename_absolute(temp_absolute, absolute)
    if rename_error != OK:
        DirAccess.remove_absolute(temp_absolute)
        return {"ok": false, "errors": ["Could not atomically replace user scale/polish preferences."], "settings": normalized}
    return {"ok": true, "errors": [], "settings": normalized}

func _preserve_malformed_file() -> String:
    if not FileAccess.file_exists(_path): return ""
    var backup := "%s.recovery-%d.bak" % [_path, Time.get_unix_time_from_system()]
    return backup if _copy_file(_path, backup) else ""

func _copy_file(source: String, target: String) -> bool:
    var data := FileAccess.get_file_as_bytes(source)
    var handle := FileAccess.open(target, FileAccess.WRITE)
    if handle == null: return false
    handle.store_buffer(data); handle.close(); return true

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

static func _parse_preferences_text(text: String) -> Dictionary:
    var values: Dictionary = {}
    var in_preferences := false
    for raw_line in text.split("\n"):
        var line := str(raw_line).strip_edges()
        if line.is_empty() or line.begins_with(";") or line.begins_with("#"): continue
        if line.begins_with("["):
            if not line.ends_with("]") or line.length() < 3: return {"ok": false, "values": {}}
            in_preferences = line == "[preferences]"; continue
        if not in_preferences or not line.contains("="): return {"ok": false, "values": {}}
        var separator := line.find("=")
        var key := line.substr(0, separator).strip_edges()
        var value_text := line.substr(separator + 1).strip_edges()
        if key.is_empty() or value_text.is_empty(): return {"ok": false, "values": {}}
        var parsed_value: Variant = _parse_scalar(value_text)
        if parsed_value == null: return {"ok": false, "values": {}}
        values[key] = parsed_value
    return {"ok": true, "values": values}

static func _parse_scalar(value_text: String) -> Variant:
    if value_text == "true": return true
    if value_text == "false": return false
    if value_text.begins_with("\""):
        if not value_text.ends_with("\"") or value_text.length() < 2: return null
        return value_text.substr(1, value_text.length() - 2).replace("\\\"", "\"").replace("\\\\", "\\")
    if value_text.is_valid_float(): return value_text.to_float()
    if value_text.is_valid_int(): return value_text.to_int()
    return null

static func _nearest_scale(value: float) -> float:
    var selected: float = float(UI_SCALES[0])
    var best_distance: float = absf(value - selected)
    for candidate in UI_SCALES:
        var distance: float = absf(value - float(candidate))
        if distance < best_distance:
            selected = float(candidate); best_distance = distance
    return selected
