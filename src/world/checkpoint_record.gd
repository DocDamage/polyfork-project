class_name PlayWorldCheckpointRecord
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")

const DOCUMENT_TYPE := "world_checkpoint"
const SCHEMA_VERSION := 1

var checkpoint_id: String = ""
var project_id: String = ""
var created_at_msec: int = 0
var project_state: Dictionary = {}


func initialize_from_project(project, timestamp_msec: int) -> void:
    checkpoint_id = StableId.generate()
    project_id = project.project_id
    created_at_msec = timestamp_msec
    project_state = project.to_dictionary().duplicate(true)


func load_dictionary(data: Dictionary) -> Array[String]:
    var errors := validate_dictionary(data)
    if not errors.is_empty():
        return errors
    checkpoint_id = str(data["id"])
    project_id = str(data["project_id"])
    created_at_msec = int(data["created_at_msec"])
    project_state = data["project_state"].duplicate(true)
    return []


func to_dictionary() -> Dictionary:
    return {
        "document_type": DOCUMENT_TYPE,
        "schema_version": SCHEMA_VERSION,
        "id": checkpoint_id,
        "project_id": project_id,
        "created_at_msec": created_at_msec,
        "project_state": project_state.duplicate(true)
    }


static func validate_dictionary(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if data.get("document_type") != DOCUMENT_TYPE:
        errors.append("Checkpoint document_type is invalid.")
    if data.get("schema_version") != SCHEMA_VERSION:
        errors.append("Checkpoint schema_version is unsupported.")

    var checkpoint_id_value := str(data.get("id", ""))
    if not StableId.is_valid(checkpoint_id_value):
        errors.append("Checkpoint id must be a valid stable UUID.")

    var project_id_value := str(data.get("project_id", ""))
    if not StableId.is_valid(project_id_value):
        errors.append("Checkpoint project_id must be a valid stable UUID.")

    if int(data.get("created_at_msec", 0)) <= 0:
        errors.append("Checkpoint created_at_msec must be positive.")

    var state: Variant = data.get("project_state")
    if not state is Dictionary:
        errors.append("Checkpoint project_state must be a dictionary.")
        return errors

    var state_errors: Array[String] = WorldProject.validate_dictionary(state)
    for error in state_errors:
        errors.append("Checkpoint project_state: %s" % error)
    if str(state.get("project_id", "")) != project_id_value:
        errors.append("Checkpoint project_state project_id does not match checkpoint ownership.")
    return errors
