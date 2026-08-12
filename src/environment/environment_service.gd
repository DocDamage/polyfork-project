class_name PlayWorldEnvironmentService
extends RefCounted

signal environment_changed
signal status_changed(message: String, is_error: bool)

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/environment/environment_contracts.gd")
const Repository = preload("res://src/environment/environment_repository.gd")
const SnapshotCommand = preload("res://src/environment/environment_snapshot_command.gd")

var _project
var _editor_session
var _dirty_callback := Callable()
var _repository
var _state
var _history
var _terrain_state
var _runtime

func bind_project(project, project_directory: String, editor_session, dirty_callback: Callable, terrain_state = null, runtime = null) -> Dictionary:
    if project == null or editor_session == null or not dirty_callback.is_valid(): return _failure("Environment service requires project, editor session, and dirty callback.")
    _project = project
    _editor_session = editor_session
    _dirty_callback = dirty_callback
    _terrain_state = terrain_state
    _runtime = runtime
    _history = editor_session.get_history()
    if _history == null or not _history.has_method("execute_command"): return _failure("Environment service could not bind universal command history.")
    _repository = Repository.new(project_directory)
    var open_result: Dictionary = _repository.open_or_create(project)
    if not open_result.get("ok", false):
        _clear()
        return open_result
    _state = open_result.get("state")
    if _runtime != null:
        var runtime_result: Dictionary = _runtime.initialize(_state.to_document(), _terrain_state, null, false)
        if not runtime_result.get("ok", false): return runtime_result
    if bool(open_result.get("registry_changed", false)):
        var dirty_result: Variant = _dirty_callback.call()
        if dirty_result is Dictionary and not dirty_result.get("ok", false): return _failure("Environment registries initialized but project dirty-state signaling failed.")
    return {"ok": true, "errors": [], "created": open_result.get("created", false), "weather_profile_count": _state.weather_profiles.size(), "biome_override_count": _state.biome_overrides.size(), "water_hook_count": _state.water_hooks.size()}

func get_state(): return _state
func get_repository(): return _repository
func get_runtime(): return _runtime
func get_weather_profiles() -> Array[Dictionary]: return [] if _state == null else _state.weather_profiles.duplicate(true)
func get_biome_overrides() -> Array[Dictionary]: return [] if _state == null else _state.biome_overrides.duplicate(true)
func get_water_hooks() -> Array[Dictionary]: return [] if _state == null else _state.water_hooks.duplicate(true)

func configure_authored_state(patch: Dictionary) -> Dictionary:
    if not _is_bound(): return _failure("Environment service is not bound.")
    var allowed: Array[String] = ["time_of_day_hours", "day_length_seconds", "progress_time_in_play", "default_weather_profile_id", "default_transition_seconds", "fog_enabled", "wind_enabled"]
    for key_value in patch.keys():
        if not allowed.has(str(key_value)): return _failure("Unsupported environment property: %s" % str(key_value))
    var after: Dictionary = _state.to_document()
    var authored: Dictionary = after.get("authored_state", {}).duplicate(true)
    for key_value in patch.keys(): authored[key_value] = patch[key_value]
    after["authored_state"] = authored
    return _commit(after, "Configure environment")

func create_weather_profile(display_name: String, patch: Dictionary = {}) -> Dictionary:
    if not _is_bound(): return _failure("Environment service is not bound.")
    if display_name.strip_edges().is_empty(): return _failure("Weather profile display name is required.")
    var template: Dictionary = _state.get_weather_profile(str(_state.authored_state.get("default_weather_profile_id", "")))
    if template.is_empty() and not _state.weather_profiles.is_empty(): template = _state.weather_profiles[0].duplicate(true)
    if template.is_empty(): return _failure("Environment has no weather profile template.")
    var profile_id: String = StableId.generate()
    template["weather_profile_id"] = profile_id
    template["display_name"] = display_name.strip_edges()
    for key_value in patch.keys():
        if str(key_value) == "weather_profile_id": return _failure("Weather profile identity cannot be supplied by callers.")
        template[key_value] = patch[key_value]
    var after: Dictionary = _state.to_document()
    var profiles: Array = after.get("weather_profiles", []).duplicate(true)
    profiles.append(template)
    after["weather_profiles"] = profiles
    var result: Dictionary = _commit(after, "Create weather profile")
    if result.get("ok", false): result["weather_profile_id"] = profile_id
    return result

func configure_weather_profile(profile_id: String, patch: Dictionary) -> Dictionary:
    if not _is_bound(): return _failure("Environment service is not bound.")
    var allowed: Array[String] = ["display_name", "sky_top_color", "sky_horizon_color", "ambient_color", "ambient_energy", "sun_color", "sun_energy", "fog_color", "fog_density", "wind_direction", "wind_speed_mps", "wind_gust_strength", "precipitation", "cloud_coverage", "water_modifiers"]
    for key_value in patch.keys():
        if not allowed.has(str(key_value)): return _failure("Unsupported weather profile property: %s" % str(key_value))
    var after: Dictionary = _state.to_document()
    var profiles: Array = after.get("weather_profiles", []).duplicate(true)
    var found: bool = false
    for index in range(profiles.size()):
        if str(profiles[index].get("weather_profile_id", "")) != profile_id: continue
        var staged: Dictionary = profiles[index].duplicate(true)
        for key_value in patch.keys(): staged[key_value] = patch[key_value]
        profiles[index] = staged
        found = true
        break
    if not found: return _failure("Weather profile does not exist.")
    after["weather_profiles"] = profiles
    return _commit(after, "Configure weather profile")

func delete_weather_profile(profile_id: String) -> Dictionary:
    if not _is_bound(): return _failure("Environment service is not bound.")
    if str(_state.authored_state.get("default_weather_profile_id", "")) == profile_id: return _failure("The authored default weather profile cannot be deleted.")
    for override_record in _state.biome_overrides:
        if str(override_record.get("weather_profile_id", "")) == profile_id: return _failure("Weather profile is referenced by a biome override.")
    if _terrain_state != null and _terrain_state.has_method("biome_ids"):
        for biome_id in _terrain_state.biome_ids():
            var biome: Dictionary = _terrain_state.get_biome(biome_id)
            if str(biome.get("future_defaults", {}).get("environment_profile_id", "")) == profile_id: return _failure("Weather profile is referenced by a terrain biome default.")
    var after: Dictionary = _state.to_document()
    var profiles: Array = after.get("weather_profiles", []).duplicate(true)
    var removed: bool = false
    for index in range(profiles.size() - 1, -1, -1):
        if str(profiles[index].get("weather_profile_id", "")) == profile_id:
            profiles.remove_at(index)
            removed = true
            break
    if not removed: return _failure("Weather profile does not exist.")
    after["weather_profiles"] = profiles
    return _commit(after, "Delete weather profile")

func set_biome_override(biome_id: String, patch: Dictionary) -> Dictionary:
    if not _is_bound(): return _failure("Environment service is not bound.")
    if _terrain_state != null and _terrain_state.has_method("get_biome") and _terrain_state.get_biome(biome_id).is_empty(): return _failure("Environment biome override requires an existing terrain biome.")
    var allowed: Array[String] = ["weather_profile_id", "time_offset_hours", "wind_multiplier", "fog_density_multiplier", "water_hook_ids"]
    for key_value in patch.keys():
        if not allowed.has(str(key_value)): return _failure("Unsupported biome override property: %s" % str(key_value))
    var after: Dictionary = _state.to_document()
    var records: Array = after.get("biome_overrides", []).duplicate(true)
    var found: bool = false
    var override_id: String = ""
    for index in range(records.size()):
        if str(records[index].get("biome_id", "")) != biome_id: continue
        var staged: Dictionary = records[index].duplicate(true)
        override_id = str(staged.get("override_id", ""))
        for key_value in patch.keys(): staged[key_value] = patch[key_value]
        records[index] = staged
        found = true
        break
    if not found:
        override_id = StableId.generate()
        var record: Dictionary = {"override_id": override_id, "biome_id": biome_id, "weather_profile_id": "", "time_offset_hours": 0.0, "wind_multiplier": 1.0, "fog_density_multiplier": 1.0, "water_hook_ids": []}
        for key_value in patch.keys(): record[key_value] = patch[key_value]
        records.append(record)
    after["biome_overrides"] = records
    var result: Dictionary = _commit(after, "Configure biome environment")
    if result.get("ok", false): result["override_id"] = override_id
    return result

func clear_biome_override(biome_id: String) -> Dictionary:
    if not _is_bound(): return _failure("Environment service is not bound.")
    var after: Dictionary = _state.to_document()
    var records: Array = after.get("biome_overrides", []).duplicate(true)
    var removed: bool = false
    for index in range(records.size() - 1, -1, -1):
        if str(records[index].get("biome_id", "")) == biome_id:
            records.remove_at(index)
            removed = true
            break
    if not removed: return _failure("Biome environment override does not exist.")
    after["biome_overrides"] = records
    return _commit(after, "Clear biome environment")

func create_water_hook(display_name: String, provider_key: String, settings: Dictionary = {}, tags: Array = []) -> Dictionary:
    if not _is_bound(): return _failure("Environment service is not bound.")
    var hook_id: String = StableId.generate()
    var hook: Dictionary = {"water_hook_id": hook_id, "display_name": display_name.strip_edges(), "provider_key": provider_key.strip_edges(), "settings": settings.duplicate(true), "tags": tags.duplicate(true)}
    var hook_errors: Array[String] = Contracts.validate_water_hook(hook)
    if not hook_errors.is_empty(): return {"ok": false, "errors": hook_errors}
    var after: Dictionary = _state.to_document()
    var hooks: Array = after.get("water_hooks", []).duplicate(true)
    hooks.append(hook)
    after["water_hooks"] = hooks
    var result: Dictionary = _commit(after, "Create water hook")
    if result.get("ok", false): result["water_hook_id"] = hook_id
    return result

func configure_water_hook(hook_id: String, patch: Dictionary) -> Dictionary:
    if not _is_bound(): return _failure("Environment service is not bound.")
    var allowed: Array[String] = ["display_name", "provider_key", "settings", "tags"]
    for key_value in patch.keys():
        if not allowed.has(str(key_value)): return _failure("Unsupported water hook property: %s" % str(key_value))
    var after: Dictionary = _state.to_document()
    var hooks: Array = after.get("water_hooks", []).duplicate(true)
    var found: bool = false
    for index in range(hooks.size()):
        if str(hooks[index].get("water_hook_id", "")) != hook_id: continue
        var staged: Dictionary = hooks[index].duplicate(true)
        for key_value in patch.keys(): staged[key_value] = patch[key_value]
        hooks[index] = staged
        found = true
        break
    if not found: return _failure("Water hook does not exist.")
    after["water_hooks"] = hooks
    return _commit(after, "Configure water hook")

func delete_water_hook(hook_id: String) -> Dictionary:
    if not _is_bound(): return _failure("Environment service is not bound.")
    for override_record in _state.biome_overrides:
        for referenced in override_record.get("water_hook_ids", []):
            if str(referenced) == hook_id: return _failure("Water hook is referenced by a biome override.")
    var after: Dictionary = _state.to_document()
    var hooks: Array = after.get("water_hooks", []).duplicate(true)
    var removed: bool = false
    for index in range(hooks.size() - 1, -1, -1):
        if str(hooks[index].get("water_hook_id", "")) == hook_id:
            hooks.remove_at(index)
            removed = true
            break
    if not removed: return _failure("Water hook does not exist.")
    after["water_hooks"] = hooks
    return _commit(after, "Delete water hook")

func _commit(after: Dictionary, label: String) -> Dictionary:
    var validation: Array[String] = Contracts.validate_document(after)
    if not validation.is_empty(): return {"ok": false, "errors": validation}
    var refresh: Callable = Callable(self, "_refresh_runtime") if _runtime != null else Callable()
    var command = SnapshotCommand.new(_project, _state, _repository, _state.to_document(), after, refresh)
    var history_result: Dictionary = _history.execute_command(command, label)
    if not history_result.get("ok", false): return _failure(str(history_result.get("error", history_result.get("errors", ["Environment command failed."]))))
    var dirty_result: Variant = _dirty_callback.call()
    if dirty_result is Dictionary and not dirty_result.get("ok", false): return _failure("Environment edit succeeded but project dirty-state signaling failed.")
    if _editor_session.has_signal("project_changed"): _editor_session.emit_signal("project_changed", _project.to_dictionary())
    environment_changed.emit()
    status_changed.emit(label, false)
    return {"ok": true, "errors": [], "project_data": _project.to_dictionary()}

func _refresh_runtime() -> Dictionary:
    if _runtime == null: return {"ok": true, "errors": []}
    return _runtime.refresh_authored(_state.to_document())

func _is_bound() -> bool: return _project != null and _editor_session != null and _state != null and _repository != null and _history != null

func _clear() -> void:
    _project = null
    _editor_session = null
    _repository = null
    _state = null
    _history = null
    _terrain_state = null
    _runtime = null
    _dirty_callback = Callable()

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
