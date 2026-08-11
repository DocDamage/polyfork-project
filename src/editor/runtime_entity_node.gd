class_name PlayWorldRuntimeEntityNode
extends Node3D

const WorldEntity = preload("res://src/world/world_entity.gd")
const ENTITY_ID_META := &"playworld_entity_id"

var entity_id: String = ""
var entity_record: Dictionary = {}
var _selected := false


func apply_record(record: Dictionary) -> Array[String]:
    var errors: Array[String] = WorldEntity.validate_dictionary(record)
    if not errors.is_empty():
        return errors

    entity_id = str(record["entity_id"])
    entity_record = record.duplicate(true)
    set_meta(ENTITY_ID_META, entity_id)
    name = "Entity_%s" % entity_id.substr(0, 8)

    var transform_data: Dictionary = record.get("transform", {})
    position = _vector3(transform_data.get("position", [0.0, 0.0, 0.0]))
    rotation_degrees = _vector3(transform_data.get("rotation_degrees", [0.0, 0.0, 0.0]))
    scale = _vector3(transform_data.get("scale", [1.0, 1.0, 1.0]))
    return []


func set_selected(value: bool) -> void:
    _selected = value


func is_selected() -> bool:
    return _selected


func get_record() -> Dictionary:
    return entity_record.duplicate(true)


static func _vector3(value: Array) -> Vector3:
    return Vector3(float(value[0]), float(value[1]), float(value[2]))
