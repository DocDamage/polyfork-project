class_name PlayWorldAiProviderRegistry
extends Node

signal settings_changed(settings: Dictionary)
signal status_changed(message: String, is_error: bool)

const Contracts = preload("res://src/ai/ai_contracts.gd")
const SettingsRepository = preload("res://src/ai/ai_provider_settings_repository.gd")
const OpenAiCompatibleProvider = preload("res://src/ai/openai_compatible_provider.gd")

var _repository
var _settings: Dictionary = {}
var _provider


func _init(settings_path_override: String = "") -> void:
    _repository = SettingsRepository.new(settings_path_override)


func load_settings() -> Dictionary:
    var result: Dictionary = _repository.load_or_create()
    if not result.get("ok", false): return result
    _settings = result.get("settings", {}).duplicate(true)
    return {"ok": true, "errors": [], "created": result.get("created", false), "settings": get_settings()}


func get_settings() -> Dictionary:
    return _settings.duplicate(true)


func get_privacy_policy() -> Dictionary:
    return _settings.get("privacy", Contracts.default_privacy_policy()).duplicate(true)


func get_providers() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for value in _settings.get("providers", []):
        if value is Dictionary: result.append(value.duplicate(true))
    return result


func get_active_provider_descriptor() -> Dictionary:
    var active_id: String = str(_settings.get("active_provider_id", ""))
    for descriptor in get_providers():
        if str(descriptor.get("provider_id", "")) == active_id: return descriptor
    return {}


func upsert_provider(descriptor: Dictionary) -> Dictionary:
    if _settings.is_empty(): return _failure("AI provider settings are not loaded.")
    var errors: Array[String] = Contracts.validate_provider_descriptor(descriptor)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    var staged: Dictionary = _settings.duplicate(true)
    var providers: Array = staged.get("providers", []).duplicate(true)
    var provider_id: String = str(descriptor.get("provider_id", ""))
    var replaced := false
    for index in range(providers.size()):
        if str(providers[index].get("provider_id", "")) == provider_id:
            providers[index] = Contracts.sanitized_provider_descriptor(descriptor)
            replaced = true
            break
    if not replaced: providers.append(Contracts.sanitized_provider_descriptor(descriptor))
    staged["providers"] = providers
    if str(staged.get("active_provider_id", "")).is_empty(): staged["active_provider_id"] = provider_id
    return _save(staged, "AI provider saved")


func remove_provider(provider_id: String) -> Dictionary:
    if _settings.is_empty(): return _failure("AI provider settings are not loaded.")
    var staged: Dictionary = _settings.duplicate(true)
    var providers: Array = staged.get("providers", []).duplicate(true)
    var removed := false
    for index in range(providers.size() - 1, -1, -1):
        if str(providers[index].get("provider_id", "")) == provider_id:
            providers.remove_at(index)
            removed = true
            break
    if not removed: return _failure("AI provider does not exist.")
    staged["providers"] = providers
    if str(staged.get("active_provider_id", "")) == provider_id:
        staged["active_provider_id"] = str(providers[0].get("provider_id", "")) if not providers.is_empty() else ""
    return _save(staged, "AI provider removed")


func set_active_provider(provider_id: String) -> Dictionary:
    var found := false
    for descriptor in get_providers():
        if str(descriptor.get("provider_id", "")) == provider_id:
            found = true
            break
    if not found: return _failure("AI provider does not exist.")
    var staged: Dictionary = _settings.duplicate(true)
    staged["active_provider_id"] = provider_id
    return _save(staged, "Active AI provider changed")


func set_privacy_policy(patch: Dictionary) -> Dictionary:
    if _settings.is_empty(): return _failure("AI provider settings are not loaded.")
    var staged: Dictionary = _settings.duplicate(true)
    var privacy: Dictionary = staged.get("privacy", Contracts.default_privacy_policy()).duplicate(true)
    var allowed: Array[String] = ["local_only", "cloud_consent", "record_prompts", "max_context_items", "max_context_chars"]
    for key_value in patch.keys():
        var key: String = str(key_value)
        if not allowed.has(key): return _failure("Unsupported AI privacy property: %s" % key)
        privacy[key] = patch[key_value]
    var errors: Array[String] = Contracts.validate_privacy_policy(privacy)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    staged["privacy"] = privacy
    return _save(staged, "AI privacy settings changed")


func resolve_active_provider() -> Dictionary:
    var descriptor: Dictionary = get_active_provider_descriptor()
    if descriptor.is_empty(): return _failure("No active AI provider is configured.")
    if not bool(descriptor.get("enabled", true)): return _failure("The active AI provider is disabled.")
    var privacy: Dictionary = get_privacy_policy()
    var scope: String = str(descriptor.get("scope", ""))
    if scope == "cloud" and bool(privacy.get("local_only", true)): return _failure("Local-only AI mode blocks cloud providers.")
    if scope == "cloud" and not bool(privacy.get("cloud_consent", false)): return _failure("Cloud AI provider use requires explicit consent.")
    return {"ok": true, "errors": [], "descriptor": descriptor, "privacy": privacy}


func create_active_provider() -> Dictionary:
    var resolved: Dictionary = resolve_active_provider()
    if not resolved.get("ok", false): return resolved
    if _provider != null and is_instance_valid(_provider):
        _provider.queue_free()
        _provider = null
    var descriptor: Dictionary = resolved.get("descriptor", {})
    match str(descriptor.get("protocol", "")):
        "openai_compatible_chat_v1": _provider = OpenAiCompatibleProvider.new()
        _: return _failure("Unsupported AI provider protocol.")
    add_child(_provider)
    var configure_result: Dictionary = _provider.configure(descriptor)
    if not configure_result.get("ok", false):
        _provider.queue_free()
        _provider = null
        return configure_result
    return {"ok": true, "errors": [], "provider": _provider, "descriptor": descriptor, "privacy": resolved.get("privacy", {})}


func get_provider():
    return _provider


func _save(staged: Dictionary, message: String) -> Dictionary:
    var errors: Array[String] = Contracts.validate_provider_settings(staged)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    var save_result: Dictionary = _repository.save(staged)
    if not save_result.get("ok", false): return save_result
    _settings = staged.duplicate(true)
    settings_changed.emit(get_settings())
    status_changed.emit(message, false)
    return {"ok": true, "errors": [], "settings": get_settings()}


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
