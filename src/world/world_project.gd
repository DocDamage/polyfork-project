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


static func create_new(project_title: String, profile_id: StringName, starting_template_id: String) -> PlayWorldProject:
    var project := PlayWorldProject.new()
    project.project_id = StableId.generate()
    project.title = project_title.strip_edges()
    project.world_profile = profile_id
    project.template_id = starting_template_id.strip_edges()
    var now := int(Time.get_unix_time_from_system())
    project.created_at_unix = now
    project.updated_at_unix = now
    return project


static func from_dictionary(data: Dictionary) -> Dictionary:
    var errors := validate_dictionary(data)
    if not errors.is_empty():
        return {"ok": false, "errors": errors, "project": null}

    var project := PlayWorldProject.new()
    project.project_id = str(data["project_id"])
    project.title = str(data["title"])
    project.world_profile = StringName(str(data["world_profile"]))
    project.template_id = str(data["template_id"])
    project.cell_ids = _string_array(data.get("cell_ids", []))
    project.environment = data.get("environment", {}).duplicate(true)
    project.registries = data.get("registries", {}).duplicate(true)
    project.editor = data.get("editor", {}).duplicate(true)
    project.export_settings = data.get("export", {}).duplicate(true)
    project.dependencies = data.get("dependencies", []).duplicate(true)
    project.created_at_unix = int(data.get("created_at_unix", 0))
    project.updated_at_unix = int(data.get("updated_at_unix", project.created_at_unix))
    return {"ok": true, "errors": [], "project": project}


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
    return errors


func validate() -> Array[String]:
    return validate_dictionary(to_dictionary())


func touch_updated() -> void:
    updated_at_unix = int(Time.get_unix_time_from_system())
    if updated_at_unix < created_at_unix:
        updated_at_unix = created_at_unix


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
        "updated_at_unix": updated_at_unix
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
