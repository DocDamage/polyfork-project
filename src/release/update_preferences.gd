class_name PlayWorldUpdatePreferences
extends RefCounted

const ReleasePaths = preload("res://src/release/release_paths.gd")
const PREFERENCES_PATH := "user://release/update_preferences.cfg"
const CHANNEL_CONFIG_PATH := "res://config/release/update_channels.json"
const CHANNELS := ["stable", "beta", "development"]
const DEFAULT_CHANNEL := "stable"
const DEFAULT_BACKOFF_SECONDS := 900
const MAX_BACKOFF_SECONDS := 86400

var _path: String
var _channels: Dictionary = {}

func _init(path: String = PREFERENCES_PATH) -> void:
    _path = path
    _channels = _load_channel_config()

func defaults() -> Dictionary:
    return {
        "schema_version": 1,
        "channel": DEFAULT_CHANNEL,
        "auto_check": true,
        "last_check_unix": 0,
        "last_success_unix": 0,
        "last_result": "never",
        "last_error": "",
        "consecutive_failures": 0,
        "next_allowed_check_unix": 0,
        "cached_manifest_path": "",
        "last_verified_artifact": "",
        "last_verified_sha256": "",
        "last_verified_size": 0,
        "last_verified_version": "",
        "last_verified_kind": "",
    }

func load_preferences() -> Dictionary:
    var settings := defaults()
    if not FileAccess.file_exists(_path):
        var created := save_preferences(settings)
        if not created.get("ok", false): return created
        return {"ok": true, "errors": [], "settings": settings, "created": true}
    var config := ConfigFile.new()
    var error := config.load(_path)
    if error != OK:
        var backup := "%s.malformed-%d.bak" % [_path, Time.get_unix_time_from_system()]
        ReleasePaths.copy_file(_path, backup)
        var fallback := save_preferences(settings)
        if not fallback.get("ok", false): return fallback
        return {"ok": false, "errors": ["Update preferences were malformed and reset to safe defaults."], "settings": settings, "recovery_backup": backup}
    settings["schema_version"] = int(config.get_value("update", "schema_version", 1))
    settings["channel"] = str(config.get_value("update", "channel", DEFAULT_CHANNEL))
    settings["auto_check"] = bool(config.get_value("update", "auto_check", true))
    settings["last_check_unix"] = int(config.get_value("health", "last_check_unix", 0))
    settings["last_success_unix"] = int(config.get_value("health", "last_success_unix", 0))
    settings["last_result"] = str(config.get_value("health", "last_result", "never"))
    settings["last_error"] = str(config.get_value("health", "last_error", ""))
    settings["consecutive_failures"] = maxi(0, int(config.get_value("health", "consecutive_failures", 0)))
    settings["next_allowed_check_unix"] = maxi(0, int(config.get_value("health", "next_allowed_check_unix", 0)))
    settings["cached_manifest_path"] = str(config.get_value("cache", "manifest_path", ""))
    settings["last_verified_artifact"] = str(config.get_value("cache", "last_verified_artifact", ""))
    settings["last_verified_sha256"] = str(config.get_value("cache", "last_verified_sha256", ""))
    settings["last_verified_size"] = int(config.get_value("cache", "last_verified_size", 0))
    settings["last_verified_version"] = str(config.get_value("cache", "last_verified_version", ""))
    settings["last_verified_kind"] = str(config.get_value("cache", "last_verified_kind", ""))
    var validation := validate(settings)
    if not validation.get("ok", false):
        var backup := "%s.invalid-%d.bak" % [_path, Time.get_unix_time_from_system()]
        ReleasePaths.copy_file(_path, backup)
        settings = defaults()
        save_preferences(settings)
        return {"ok": false, "errors": validation.get("errors", []), "settings": settings, "recovery_backup": backup}
    return {"ok": true, "errors": [], "settings": settings}

func save_preferences(settings: Dictionary) -> Dictionary:
    var validation := validate(settings)
    if not validation.get("ok", false): return validation
    var directory := ReleasePaths.ensure_directory(ProjectSettings.globalize_path(_path).get_base_dir())
    if not directory.get("ok", false): return directory
    var config := ConfigFile.new()
    config.set_value("update", "schema_version", int(settings.get("schema_version", 1)))
    config.set_value("update", "channel", str(settings.get("channel", DEFAULT_CHANNEL)))
    config.set_value("update", "auto_check", bool(settings.get("auto_check", true)))
    config.set_value("health", "last_check_unix", int(settings.get("last_check_unix", 0)))
    config.set_value("health", "last_success_unix", int(settings.get("last_success_unix", 0)))
    config.set_value("health", "last_result", str(settings.get("last_result", "never")))
    config.set_value("health", "last_error", str(settings.get("last_error", "")))
    config.set_value("health", "consecutive_failures", int(settings.get("consecutive_failures", 0)))
    config.set_value("health", "next_allowed_check_unix", int(settings.get("next_allowed_check_unix", 0)))
    config.set_value("cache", "manifest_path", str(settings.get("cached_manifest_path", "")))
    config.set_value("cache", "last_verified_artifact", str(settings.get("last_verified_artifact", "")))
    config.set_value("cache", "last_verified_sha256", str(settings.get("last_verified_sha256", "")))
    config.set_value("cache", "last_verified_size", int(settings.get("last_verified_size", 0)))
    config.set_value("cache", "last_verified_version", str(settings.get("last_verified_version", "")))
    config.set_value("cache", "last_verified_kind", str(settings.get("last_verified_kind", "")))
    var error := config.save(_path)
    if error != OK: return ReleasePaths.failure("Update preferences could not be saved.")
    return {"ok": true, "errors": [], "settings": settings.duplicate(true)}

func set_channel(channel: String) -> Dictionary:
    var current := load_preferences().get("settings", defaults()) as Dictionary
    if not is_channel_allowed(channel):
        return ReleasePaths.failure("The selected update channel is not available in this build.")
    current["channel"] = channel
    current["next_allowed_check_unix"] = 0
    current["last_result"] = "channel_changed"
    return save_preferences(current)

func set_auto_check(enabled: bool) -> Dictionary:
    var current := load_preferences().get("settings", defaults()) as Dictionary
    current["auto_check"] = enabled
    return save_preferences(current)

func record_check(success: bool, result: String, error_message: String = "", cached_manifest_path: String = "") -> Dictionary:
    var current := load_preferences().get("settings", defaults()) as Dictionary
    var now := int(Time.get_unix_time_from_system())
    current["last_check_unix"] = now
    current["last_result"] = result
    current["last_error"] = error_message.left(512)
    if not cached_manifest_path.is_empty(): current["cached_manifest_path"] = cached_manifest_path
    if success:
        current["last_success_unix"] = now
        current["consecutive_failures"] = 0
        current["next_allowed_check_unix"] = now + DEFAULT_BACKOFF_SECONDS
    else:
        var failures := mini(int(current.get("consecutive_failures", 0)) + 1, 16)
        current["consecutive_failures"] = failures
        var backoff := mini(DEFAULT_BACKOFF_SECONDS * int(pow(2.0, float(failures - 1))), MAX_BACKOFF_SECONDS)
        current["next_allowed_check_unix"] = now + backoff
    return save_preferences(current)

func record_verified_artifact(path: String, metadata: Dictionary = {}) -> Dictionary:
    var current := load_preferences().get("settings", defaults()) as Dictionary
    current["last_verified_artifact"] = path
    current["last_verified_sha256"] = str(metadata.get("sha256", ""))
    current["last_verified_size"] = int(metadata.get("size", 0))
    current["last_verified_version"] = str(metadata.get("version", ""))
    current["last_verified_kind"] = str(metadata.get("kind", ""))
    return save_preferences(current)

func check_allowed_now(manual: bool = false) -> bool:
    if manual: return true
    var settings := load_preferences().get("settings", defaults()) as Dictionary
    return int(Time.get_unix_time_from_system()) >= int(settings.get("next_allowed_check_unix", 0))

func selected_channel() -> String:
    return str(load_preferences().get("settings", defaults()).get("channel", DEFAULT_CHANNEL))

func manifest_url(channel: String = "") -> String:
    var selected := selected_channel() if channel.is_empty() else channel
    var record: Dictionary = _channels.get(selected, {})
    return str(record.get("manifest_url", ""))

func allowed_hosts(channel: String = "") -> Array[String]:
    var selected := selected_channel() if channel.is_empty() else channel
    var result: Array[String] = []
    var record: Dictionary = _channels.get(selected, {})
    for value in record.get("allowed_hosts", []): result.append(str(value).to_lower())
    return result

func is_channel_allowed(channel: String) -> bool:
    if not CHANNELS.has(channel) or not _channels.has(channel): return false
    var enabled := bool((_channels[channel] as Dictionary).get("enabled", false))
    if channel == "development":
        enabled = enabled and bool(ProjectSettings.get_setting("playworld/release/allow_development_channel", false))
    return enabled

func is_url_allowed(url: String, channel: String = "") -> bool:
    var selected := selected_channel() if channel.is_empty() else channel
    if not url.begins_with("https://") or url.contains("\\") or url.contains("\r") or url.contains("\n") or url.contains("\t") or url.contains(" "):
        return false
    var tail := url.substr(8)
    var slash := tail.find("/")
    var authority := tail if slash < 0 else tail.substr(0, slash)
    if authority.contains("@"): return false
    var host := authority.split(":", false, 2)[0].to_lower()
    return allowed_hosts(selected).has(host)

func channel_records() -> Dictionary:
    return _channels.duplicate(true)

func validate(settings: Dictionary) -> Dictionary:
    if int(settings.get("schema_version", -1)) != 1:
        return ReleasePaths.failure("Update preference schema is unsupported.")
    var channel := str(settings.get("channel", ""))
    if not is_channel_allowed(channel):
        return ReleasePaths.failure("Saved update channel is unavailable.")
    if int(settings.get("consecutive_failures", 0)) < 0:
        return ReleasePaths.failure("Update failure count is invalid.")
    return {"ok": true, "errors": []}

func _load_channel_config() -> Dictionary:
    if not FileAccess.file_exists(CHANNEL_CONFIG_PATH):
        return {"stable": {"enabled": true, "manifest_url": "", "allowed_hosts": []}}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CHANNEL_CONFIG_PATH))
    if not parsed is Dictionary or int(parsed.get("schema_version", -1)) != 1:
        return {"stable": {"enabled": true, "manifest_url": "", "allowed_hosts": []}}
    var channels_value: Variant = parsed.get("channels", {})
    return channels_value.duplicate(true) if channels_value is Dictionary else {}
