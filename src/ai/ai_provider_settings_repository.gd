class_name PlayWorldAiProviderSettingsRepository
extends RefCounted

const SafeJsonWriter = preload("res://src/world/safe_json_writer.gd")
const Contracts = preload("res://src/ai/ai_contracts.gd")

var settings_path: String
var writer


func _init(path_override: String = "", safe_writer = null) -> void:
    settings_path = path_override if not path_override.is_empty() else "user://polyfork/ai/providers.json"
    writer = safe_writer if safe_writer != null else SafeJsonWriter.new()


func load_or_create() -> Dictionary:
    var parent: String = settings_path.get_base_dir()
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(parent))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS:
        return _failure("Unable to create user-scoped AI settings directory.")
    if not FileAccess.file_exists(settings_path):
        var initial: Dictionary = Contracts.empty_provider_settings()
        var save_result: Dictionary = save(initial)
        if not save_result.get("ok", false): return save_result
        return {"ok": true, "errors": [], "settings": initial, "created": true}
    var read: Dictionary = writer.read_dictionary(settings_path)
    if not read.get("ok", false): return _failure("AI provider settings are corrupt or unreadable.")
    var data: Dictionary = read.get("data", {})
    var errors: Array[String] = Contracts.validate_provider_settings(data)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    return {"ok": true, "errors": [], "settings": data.duplicate(true), "created": false}


func save(settings: Dictionary) -> Dictionary:
    var validator := func(value: Dictionary) -> Array[String]:
        return Contracts.validate_provider_settings(value)
    return writer.write_validated_dictionary(settings_path, settings.duplicate(true), validator)


func get_path() -> String:
    return settings_path


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
