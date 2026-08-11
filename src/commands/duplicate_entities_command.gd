class_name PlayWorldDuplicateEntitiesCommand
extends "res://src/commands/command.gd"

const StableId = preload("res://src/world/stable_id.gd")

var _project
var _source_ids: Array[String] = []
var _created_records: Array[Dictionary] = []
var _created_ids: Array[String] = []
var _prepared := false
var _offset := Vector3(1.0, 0.0, 1.0)


func _init(project, entity_ids: Array[String], offset: Vector3 = Vector3(1.0, 0.0, 1.0)) -> void:
    _project = project
    _source_ids = entity_ids.duplicate()
    _offset = offset


func execute() -> bool:
    _clear_error()
    if _project == null or _source_ids.is_empty():
        _set_error("Duplicate requires an active project and at least one entity.")
        return false
    if not _prepared:
        if not _prepare_records():
            return false
        _prepared = true

    for record in _created_records:
        if _find_index(str(record.get("entity_id", ""))) >= 0:
            _set_error("Duplicate target ID already exists in the project.")
            return false

    var original := _copy_records(_project.entity_records)
    for record in _created_records:
        _project.entity_records.append(record.duplicate(true))
    var errors: Array[String] = _project.validate()
    if not errors.is_empty():
        _project.entity_records = original
        _set_error("Duplicate would invalidate the project: %s" % "; ".join(errors))
        return false
    return true


func undo() -> bool:
    _clear_error()
    var original := _copy_records(_project.entity_records)
    for entity_id in _created_ids:
        var index := _find_index(entity_id)
        if index < 0:
            _project.entity_records = original
            _set_error("Duplicated entity is no longer present in the project.")
            return false
        _project.entity_records.remove_at(index)
    var errors: Array[String] = _project.validate()
    if not errors.is_empty():
        _project.entity_records = original
        _set_error("Duplicate undo would invalidate the project: %s" % "; ".join(errors))
        return false
    return true


func created_ids() -> Array[String]:
    return _created_ids.duplicate()


func _prepare_records() -> bool:
    var source_records: Dictionary = {}
    for entity_id in _source_ids:
        var index := _find_index(entity_id)
        if index < 0:
            _set_error("Duplicate source is not present in the project.")
            return false
        source_records[entity_id] = _project.entity_records[index].duplicate(true)

    var id_map: Dictionary = {}
    for entity_id in _source_ids:
        id_map[entity_id] = StableId.generate()

    _created_records.clear()
    _created_ids.clear()
    for source_id in _source_ids:
        var record: Dictionary = source_records[source_id].duplicate(true)
        var new_id: String = id_map[source_id]
        record["entity_id"] = new_id
        record["display_name"] = "%s Copy" % str(record.get("display_name", "Entity"))
        var parent = record.get("parent_entity_id")
        if parent != null and id_map.has(str(parent)):
            record["parent_entity_id"] = id_map[str(parent)]
        var transform_data: Dictionary = record.get("transform", {}).duplicate(true)
        var position: Array = transform_data.get("position", [0.0, 0.0, 0.0])
        transform_data["position"] = [
            float(position[0]) + _offset.x,
            float(position[1]) + _offset.y,
            float(position[2]) + _offset.z
        ]
        record["transform"] = transform_data
        _created_records.append(record)
        _created_ids.append(new_id)
    return true


func _find_index(entity_id: String) -> int:
    for index in range(_project.entity_records.size()):
        if str(_project.entity_records[index].get("entity_id", "")) == entity_id:
            return index
    return -1


func _copy_records(records: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for record in records:
        result.append(record.duplicate(true))
    return result
