class_name PlayWorldEntity
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")

const DOCUMENT_TYPE := "world_entity"
const SCHEMA_VERSION := 1

var entity_id: String = ""
var display_name: String = "Entity"
var cell_id: String = ""
var asset_id: String = ""
var prefab_id: String = ""
var parent_entity_id: String = ""
var component_instance_ids: Array[String] = []
var transform: Dictionary = {
    "position": [0.0, 0.0, 0.0],
    "rotation_degrees": [0.0, 0.0, 0.0],
    "scale": [1.0, 1.0, 1.0]
}


func initialize_new(name: String, owning_cell_id: String) -> void:
    entity_id = StableId.generate()
    display_name = name.strip_edges() if not name.strip_edges().is_empty() else "Entity"
    cell_id = owning_cell_id


func load_dictionary(data: Dictionary) -> Array[String]:
    var errors := validate_dictionary(data)
    if not errors.is_empty():
        return errors

    entity_id = str(data["entity_id"])
    display_name = str(data["display_name"])
    cell_id = str(data["cell_id"])
    asset_id = _optional_id(data.get("asset_id"))
    prefab_id = _optional_id(data.get("prefab_id"))
    parent_entity_id = _optional_id(data.get("parent_entity_id"))
    component_instance_ids = _string_array(data.get("component_instance_ids", []))
    transform = data.get("transform", {}).duplicate(true)
    return []


func validate() -> Array[String]:
    return validate_dictionary(to_dictionary())


func to_dictionary() -> Dictionary:
    return {
        "document_type": DOCUMENT_TYPE,
        "schema_version": SCHEMA_VERSION,
        "entity_id": entity_id,
        "display_name": display_name,
        "cell_id": cell_id,
        "asset_id": asset_id if not asset_id.is_empty() else null,
        "prefab_id": prefab_id if not prefab_id.is_empty() else null,
        "parent_entity_id": parent_entity_id if not parent_entity_id.is_empty() else null,
        "component_instance_ids": component_instance_ids.duplicate(),
        "transform": transform.duplicate(true)
    }


static func validate_dictionary(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if data.get("document_type") != DOCUMENT_TYPE:
        errors.append("World entity document_type is invalid.")
    if data.get("schema_version") != SCHEMA_VERSION:
        errors.append("World entity schema_version is unsupported.")

    if not StableId.is_valid(str(data.get("entity_id", ""))):
        errors.append("World entity entity_id must be a stable UUID.")
    if str(data.get("display_name", "")).strip_edges().is_empty():
        errors.append("World entity display_name is required.")
    if not StableId.is_valid(str(data.get("cell_id", ""))):
        errors.append("World entity cell_id must be a stable UUID.")

    for field_name in ["asset_id", "prefab_id", "parent_entity_id"]:
        var value = data.get(field_name)
        if value != null and not str(value).is_empty() and not StableId.is_valid(str(value)):
            errors.append("World entity %s must be null or a stable UUID." % field_name)

    var component_ids = data.get("component_instance_ids", [])
    if not component_ids is Array:
        errors.append("World entity component_instance_ids must be an array.")
    else:
        for component_id in component_ids:
            if not StableId.is_valid(str(component_id)):
                errors.append("World entity component_instance_ids contains an invalid UUID.")

    _validate_transform(data.get("transform"), errors)
    return errors


static func _validate_transform(value: Variant, errors: Array[String]) -> void:
    if not value is Dictionary:
        errors.append("World entity transform must be a dictionary.")
        return

    for field_name in ["position", "rotation_degrees", "scale"]:
        var vector_value = value.get(field_name)
        if not vector_value is Array or vector_value.size() != 3:
            errors.append("World entity transform.%s must contain exactly three numbers." % field_name)
            continue
        for component in vector_value:
            if not component is float and not component is int:
                errors.append("World entity transform.%s must contain only numbers." % field_name)
                break


static func _string_array(value: Array) -> Array[String]:
    var result: Array[String] = []
    for item in value:
        result.append(str(item))
    return result


static func _optional_id(value: Variant) -> String:
    return "" if value == null else str(value)
