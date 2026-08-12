class_name PlayWorldTemplateManifest
extends RefCounted

const MultiplayerTemplate = preload("res://src/network/multiplayer_template_contract.gd")

const DOCUMENT_TYPE := "playworld_template_manifest"
const SCHEMA_VERSION := 1
const CONTROLLERS := ["none", "third_person", "first_person"]


static func validate_dictionary(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if data.get("document_type") != DOCUMENT_TYPE: errors.append("Template manifest document_type is invalid.")
    if int(data.get("schema_version", -1)) != SCHEMA_VERSION: errors.append("Template manifest schema_version is unsupported.")
    var template_id := str(data.get("template_id", ""))
    if template_id.is_empty() or not _is_template_id(template_id): errors.append("Template manifest template_id must use lowercase snake_case.")
    var display = data.get("display")
    if not display is Dictionary: errors.append("Template manifest display metadata must be a dictionary.")
    elif str(display.get("name", "")).strip_edges().is_empty(): errors.append("Template manifest display.name is required.")
    _validate_string_array(data.get("required_runtime_modules"), "required_runtime_modules", errors, false)
    _validate_starter_entities(data.get("starter_entities"), errors)
    var input_mapping = data.get("input_mapping")
    if not input_mapping is Dictionary: errors.append("Template manifest input_mapping must be a dictionary.")
    elif str(input_mapping.get("profile", "")).strip_edges().is_empty(): errors.append("Template manifest input_mapping.profile is required.")
    var player_archetype = data.get("default_player_archetype")
    if player_archetype != null and str(player_archetype).strip_edges().is_empty(): errors.append("Template manifest default_player_archetype must be null or a non-empty reference.")
    var camera = data.get("camera_configuration")
    if not camera is Dictionary: errors.append("Template manifest camera_configuration must be a dictionary.")
    else:
        var controller := str(camera.get("controller", ""))
        if not CONTROLLERS.has(controller): errors.append("Template manifest camera_configuration.controller is unsupported.")
        _validate_vector3(camera.get("spawn_position", [0.0, 2.0, 0.0]), "camera_configuration.spawn_position", errors)
    _validate_string_array(data.get("example_graph_references"), "example_graph_references", errors, true)
    _validate_string_array(data.get("ui_hud_packages"), "ui_hud_packages", errors, true)
    if not data.get("export_settings") is Dictionary: errors.append("Template manifest export_settings must be a dictionary.")
    _validate_tutorial_steps(data.get("tutorial_steps"), errors)
    _validate_string_array(data.get("planned_modules", []), "planned_modules", errors, true)
    if data.has("multiplayer"):
        errors.append_array(MultiplayerTemplate.validate(data.get("multiplayer")))
        if MultiplayerTemplate.supports_multiplayer(data) and not data.get("required_runtime_modules", []).has("phase15.multiplayer"):
            errors.append("Multiplayer-enabled templates must require phase15.multiplayer runtime support.")
    return errors


static func _validate_starter_entities(value: Variant, errors: Array[String]) -> void:
    if not value is Array:
        errors.append("Template manifest starter_entities must be an array.")
        return
    var seen: Dictionary = {}
    for item in value:
        if not item is Dictionary:
            errors.append("Template manifest starter_entities must contain only dictionaries.")
            continue
        var starter: Dictionary = item
        var starter_key := str(starter.get("starter_key", "")).strip_edges()
        if starter_key.is_empty() or not _is_template_id(starter_key): errors.append("Template starter_entity starter_key must use lowercase snake_case.")
        elif seen.has(starter_key): errors.append("Template starter_entity starter_key values must be unique.")
        else: seen[starter_key] = true
        if str(starter.get("display_name", "")).strip_edges().is_empty(): errors.append("Template starter_entity display_name is required.")
        if str(starter.get("role", "")).strip_edges().is_empty(): errors.append("Template starter_entity role is required.")
        if starter.has("archetype_key") and str(starter.get("archetype_key", "")).strip_edges().is_empty(): errors.append("Template starter_entity archetype_key cannot be blank.")
        var transform = starter.get("transform")
        if not transform is Dictionary:
            errors.append("Template starter_entity transform must be a dictionary.")
        else:
            _validate_vector3(transform.get("position"), "starter_entity.transform.position", errors)
            _validate_vector3(transform.get("rotation_degrees"), "starter_entity.transform.rotation_degrees", errors)
            _validate_vector3(transform.get("scale"), "starter_entity.transform.scale", errors)


static func _validate_tutorial_steps(value: Variant, errors: Array[String]) -> void:
    if not value is Array:
        errors.append("Template manifest tutorial_steps must be an array.")
        return
    for item in value:
        if not item is Dictionary: errors.append("Template tutorial_steps must contain only dictionaries."); continue
        if str(item.get("id", "")).strip_edges().is_empty(): errors.append("Template tutorial step id is required.")
        if str(item.get("title", "")).strip_edges().is_empty(): errors.append("Template tutorial step title is required.")
        if str(item.get("body", "")).strip_edges().is_empty(): errors.append("Template tutorial step body is required.")


static func _validate_string_array(value: Variant, field_name: String, errors: Array[String], allow_empty: bool) -> void:
    if not value is Array: errors.append("Template manifest %s must be an array." % field_name); return
    if not allow_empty and value.is_empty(): errors.append("Template manifest %s must contain at least one value." % field_name)
    var seen: Dictionary = {}
    for item in value:
        var text := str(item).strip_edges()
        if text.is_empty(): errors.append("Template manifest %s contains an empty value." % field_name); continue
        if seen.has(text): errors.append("Template manifest %s contains a duplicate value." % field_name)
        seen[text] = true


static func _validate_vector3(value: Variant, field_name: String, errors: Array[String]) -> void:
    if not value is Array or value.size() != 3: errors.append("Template manifest %s must contain exactly three numbers." % field_name); return
    for item in value:
        if not item is int and not item is float: errors.append("Template manifest %s must contain only numbers." % field_name); return


static func _is_template_id(value: String) -> bool:
    if value.is_empty() or value.begins_with("_") or value.ends_with("_"): return false
    for character in value:
        if not (character >= "a" and character <= "z") and not (character >= "0" and character <= "9") and character != "_": return false
    return true
