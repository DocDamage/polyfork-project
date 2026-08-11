class_name PlayWorldProject
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProfile = preload("res://src/world/world_profile.gd")

const DOCUMENT_TYPE := "world_project"
const SCHEMA_VERSION := 1

var project_id: String = ""
var title: String = ""
var world_profile: StringName = &"medium"
var template_id: String = "blank_sandbox"
var cell_ids: Array[String] = []
var environment: Dictionary = {"time_of_day": 12.75, "weather_profile_id": null}
var registries: Dictionary = {
    "prefab_ids": [],
    "archetype_ids": [],
    "visual_graph_ids": []
}
var editor: Dictionary = {"last_mode": "build"}
var export_settings: Dictionary = {"preset_id": null}
var dependencies: Array = []
var created_at_unix: int = 0
var updated_at_unix: int = 0
var created_at_msec: int = 0
var updated_at_msec: int = 0


func initialize_new(project_title: String, profile_id: StringName, starting_template_id: String) -> void:
    project_id = StableId.generate()
    title = project_title.strip_edges()
    world_profile = profile_id
    template_id = starting_template_id.strip_edges()
    var now_msec := int(Time.get_unix_time_from_system() * 1000.0)
    var now_unix := int(now_msec / 1000)
    created_at_unix = now_unix
    updated_at_unix = now_unix
    created_at_msec = now_msec
    updated_at_msec = now_msec


func load_dictionary(data: Dictionary) -> Array[String]:
    var errors := validate_dictionary(data)
    if not errors.is_empty():
        return errors

    project_id = str(data["project_id"])
    title = str(data["title"])
    world_profile = StringName(str(data["world_profile"]))
    template_id = str(data["template_id"])
    cell_ids = _string_array(data.get("cell_ids", []))
    environment = data.get("environment", {}).duplicate(true)
    registries = data.get("registries", {}).duplicate(true)
    editor = data.get("editor", {}).duplicate(true)
    export_settings = data.get("export", {}).duplicate(true)
    dependencies = data.get("dependencies", []).duplicate(true)
    created_at_unix = int(data.get("created_at_unix", 0))
    updated_at_unix = int(data.get("updated_at_unix", created_at_unix))
    created_at_msec = int(data.get("created_at_msec", created_at_unix * 1000))
    updated_at_msec = int(data.get("updated_at_msec", updated_at_unix * 1000))
    return []


static func validate_dictionary(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if data.get("document_type") != DOCUMENT_TYPE:
        errors.append("World project document_type is invalid.")
    if data.get("schema_version") != SCHEMA_VERSION:
        errors.append("World project schema_version is unsupported.")

    var id := str(data.get("project_id", ""))
    if not StableId.is_valid(id):
        errors.append("World project project_id must be a valid stable UUID.")

    if str(data.get("title", "")).strip_edges().is_empty():
        errors.append("World project title is required.")

    var profile_id := StringName(str(data.get("world_profile", "")))
    if not WorldProfile.is_valid(profile_id):
        errors.append("World project world_profile is invalid.")

    if str(data.get("template_id", "")).strip_edges().is_empty():
        errors.append("World project template_id is required.")

    _validate_id_array(data.get("cell_ids", []), "cell_ids", errors)
    var registry_data = data.get("registries", {})
    if not registry_data is Dictionary:
        errors.append("World project registries must be a dictionary.")
    else:
        for key in ["prefab_ids", "archetype_ids", "visual_graph_ids"]:
            _validate_id_array(registry_data.get(key, []), "registries.%s" % key, errors)

    for timestamp_key in ["created_at_unix", "updated_at_unix"]:
        if int(data.get(timestamp_key, 0)) <= 0:
            errors.append("World project %s must be a positive Unix timestamp." % timestamp_key)
    for timestamp_key in ["created_at_msec", "updated_at_msec"]:
        if data.has(timestamp_key) and int(data.get(timestamp_key, 0)) <= 0:
            errors.append("World project %s must be a positive millisecond timestamp." % timestamp_key)
    return errors


func validate() -> Array[String]:
    return validate_dictionary(to_dictionary())


func touch_updated() -> void:
    var now_msec := int(Time.get_unix_time_from_system() * 1000.0)
    updated_at_msec = max(now_msec, max(created_at_msec, updated_at_msec + 1))
    updated_at_unix = max(int(updated_at_msec / 1000), created_at_unix)


func to_dictionary() -> Dictionary:
    return {
        "document_type": DOCUMENT_TYPE,
        "schema_version": SCHEMA_VERSION,
        "project_id": project_id,
        "title": title,
        "world_profile": str(world_profile),
        "template_id": template_id,
        "cell_ids": cell_ids.duplicate(),
        "environment": environment.duplicate(true),
        "registries": registries.duplicate(true),
        "editor": editor.duplicate(true),
        "export": export_settings.duplicate(true),
        "dependencies": dependencies.duplicate(true),
        "created_at_unix": created_at_unix,
        "updated_at_unix": updated_at_unix,
        "created_at_msec": created_at_msec,
        "updated_at_msec": updated_at_msec
    }


static func _validate_id_array(value: Variant, field_name: String, errors: Array[String]) -> void:
    if not value is Array:
        errors.append("World project %s must be an array." % field_name)
        return
    for item in value:
        if not StableId.is_valid(str(item)):
            errors.append("World project %s contains an invalid stable ID." % field_name)


static func _string_array(value: Array) -> Array[String]:
    var result: Array[String] = []
    for item in value:
        result.append(str(item))
    return result
