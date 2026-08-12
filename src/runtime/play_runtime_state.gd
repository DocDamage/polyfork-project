class_name PlayWorldRuntimeState
extends RefCounted

const WorldProject = preload("res://src/world/world_project.gd")

var _project_data: Dictionary = {}


func load_authored_project(project_data: Dictionary) -> Dictionary:
    var errors: Array[String] = WorldProject.validate_dictionary(project_data)
    if not errors.is_empty():
        return {"ok": false, "errors": errors}
    _project_data = project_data.duplicate(true)
    return {"ok": true, "errors": [], "entity_count": _project_data.get("entities", []).size()}


func clear() -> void:
    _project_data.clear()


func is_loaded() -> bool:
    return not _project_data.is_empty()


func get_project_data() -> Dictionary:
    return _project_data.duplicate(true)


func get_entity(entity_id: String) -> Dictionary:
    for item in _project_data.get("entities", []):
        if item is Dictionary and str(item.get("entity_id", "")) == entity_id:
            return item.duplicate(true)
    return {}


func set_entity_position(entity_id: String, position_value: Vector3) -> Dictionary:
    var entities: Array = _project_data.get("entities", [])
    for index in range(entities.size()):
        if not entities[index] is Dictionary:
            continue
        var record: Dictionary = entities[index]
        if str(record.get("entity_id", "")) != entity_id:
            continue
        var transform_data: Dictionary = record.get("transform", {}).duplicate(true)
        transform_data["position"] = [position_value.x, position_value.y, position_value.z]
        record["transform"] = transform_data
        entities[index] = record
        _project_data["entities"] = entities
        return {"ok": true, "errors": [], "entity_id": entity_id}
    return {"ok": false, "errors": ["Runtime entity does not exist: %s" % entity_id]}
