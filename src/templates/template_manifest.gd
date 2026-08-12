class_name PlayWorldTemplateManifest
extends RefCounted

const DOCUMENT_TYPE := "playworld_template_manifest"
const SCHEMA_VERSION := 1
const CONTROLLERS := ["none", "third_person", "first_person"]


static func validate_dictionary(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if data.get("document_type") != DOCUMENT_TYPE:
        errors.append("Template manifest document_type is invalid.")
    if int(data.get("schema_version", -1)) != SCHEMA_VERSION:
        errors.append("Template manifest schema_version is unsupported.")

    var template_id := str(data.get("template_id", ""))
    if template_id.is_empty() or not _is_template_id(template_id):
        errors.append("Template manifest template_id must use lowercase snake_case.")

    var display = data.get("display")
    if not display is Dictionary:
        errors.append("Template manifest display metadata must be a dictionary.")
    elif str(display.get("name", "")).strip_edges().is_empty():
        errors.append("Template manifest display.name is required.")

    _validate_string_array(data.get("required_runtime_modules"), "required_runtime_modules", errors, false)
    _validate_dictionary_array(data.get("starter_entities"), "starter_entities", errors)

    var input_mapping = data.get("input_mapping")
    if not input_mapping is Dictionary:
        errors.append("Template manifest input_mapping must be a dictionary.")
    elif str(input_mapping.get("profile", "")).strip_edges().is_empty():
        errors.append("Template manifest input_mapping.profile is required.")

    var player_archetype = data.get("default_player_archetype")
    if player_archetype != null and str(player_archetype).strip_edges().is_empty():
        errors.append("Template manifest default_player_archetype must be null or a non-empty reference.")

    var camera = data.get("camera_configuration")
    if not camera is Dictionary:
        errors.append("Template manifest camera_configuration must be a dictionary.")
    else:
        var controller := str(camera.get("controller", ""))
        if not CONTROLLERS.has(controller):
            errors.append("Template manifest camera_configuration.controller is unsupported.")
        _validate_vector3(camera.get("spawn_position", [0.0, 2.0, 0.0]), "camera_configuration.spawn_position", errors)

    _validate_string_array(data.get("example_graph_references"), "example_graph_references", errors, true)
    _validate_string_array(data.get("ui_hud_packages"), "ui_hud_packages", errors, true)

    if not data.get("export_settings") is Dictionary:
        errors.append("Template manifest export_settings must be a dictionary.")
    if not data.get("tutorial_steps") is Array:
        errors.append("Template manifest tutorial_steps must be an array.")
    _validate_string_array(data.get("planned_modules", []), "planned_modules", errors, true)
    return errors


static func _validate_string_array(value: Variant, field_name: String, errors: Array[String], allow_empty: bool) -> void:
    if not value is Array:
        errors.append("Template manifest %s must be an array." % field_name)
        return
    if not allow_empty and value.is_empty():
        errors.append("Template manifest %s must contain at least one value." % field_name)
    for item in value:
        if str(item).strip_edges().is_empty():
            errors.append("Template manifest %s contains an empty value." % field_name)


static func _validate_dictionary_array(value: Variant, field_name: String, errors: Array[String]) -> void:
    if not value is Array:
        errors.append("Template manifest %s must be an array." % field_name)
        return
    for item in value:
        if not item is Dictionary:
            errors.append("Template manifest %s must contain only dictionaries." % field_name)


static func _validate_vector3(value: Variant, field_name: String, errors: Array[String]) -> void:
    if not value is Array or value.size() != 3:
        errors.append("Template manifest %s must contain exactly three numbers." % field_name)
        return
    for item in value:
        if not item is int and not item is float:
            errors.append("Template manifest %s must contain only numbers." % field_name)
            return


static func _is_template_id(value: String) -> bool:
    if value.is_empty() or value.begins_with("_") or value.ends_with("_"):
        return false
    for character in value:
        if not (character >= "a" and character <= "z") and not (character >= "0" and character <= "9") and character != "_":
            return false
    return true
