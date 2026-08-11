class_name PlayWorldSetEntityTransformsCommand
extends "res://src/commands/command.gd"

const WorldEntity = preload("res://src/world/world_entity.gd")

var _project
var _updates: Dictionary = {}
var _before: Dictionary = {}
var _captured := false


func _init(project, updates: Dictionary) -> void:
    _project = project
    _updates = updates.duplicate(true)


func execute() -> bool:
    _clear_error()
    if _project == null or _updates.is_empty():
        _set_error("Transform edit requires a project and at least one entity update.")
        return false
    if not _captured:
        if not _capture_before(): return false
        _captured = true
    return _apply(_updates, "Transform edit")


func undo() -> bool:
    _clear_error()
    if not _captured:
        _set_error("Transform edit has no captured state to undo.")
        return false
    return _apply(_before, "Transform undo")


func entity_ids() -> Array[String]:
    var result: Array[String] = []
    for entity_id in _updates.keys(): result.append(str(entity_id))
    result.sort()
    return result


func _capture_before() -> bool:
    _before.clear()
    for entity_id in _updates.keys():
        var index: int = _find_index(str(entity_id))
        if index < 0:
            _set_error("Transform target is not present in the project.")
            return false
        var record: Dictionary = _project.entity_records[index]
        _before[str(entity_id)] = {
            "transform": record.get("transform", {}).duplicate(true),
            "cell_id": str(record.get("cell_id", ""))
        }
    return true


func _apply(updates: Dictionary, label: String) -> bool:
    var staged: Array[Dictionary] = _copy_records(_project.entity_records)
    for entity_id in updates.keys():
        var index: int = _find_index_in(staged, str(entity_id))
        if index < 0:
            _set_error("%s target is not present in the project." % label)
            return false
        var record: Dictionary = staged[index].duplicate(true)
        var normalized: Dictionary = _normalize_update(updates[entity_id], record)
        if normalized.is_empty():
            _set_error("%s contains an invalid transform update payload." % label)
            return false
        record["transform"] = normalized["transform"].duplicate(true)
        if normalized.has("cell_id"): record["cell_id"] = str(normalized["cell_id"])
        var record_errors: Array[String] = WorldEntity.validate_dictionary(record)
        if not record_errors.is_empty():
            _set_error("%s contains invalid entity state: %s" % [label, "; ".join(record_errors)])
            return false
        staged[index] = record

    var original: Array[Dictionary] = _copy_records(_project.entity_records)
    _project.entity_records = staged
    var project_errors: Array[String] = _project.validate()
    if not project_errors.is_empty():
        _project.entity_records = original
        _set_error("%s would invalidate the project: %s" % [label, "; ".join(project_errors)])
        return false
    return true


func _normalize_update(value: Variant, current_record: Dictionary) -> Dictionary:
    if not value is Dictionary: return {}
    var payload: Dictionary = value
    if payload.has("transform"):
        var transform_value: Variant = payload.get("transform")
        if not transform_value is Dictionary: return {}
        var result: Dictionary = {"transform": transform_value.duplicate(true)}
        if payload.has("cell_id"): result["cell_id"] = str(payload.get("cell_id", ""))
        return result
    if payload.has("position") and payload.has("rotation_degrees") and payload.has("scale"):
        return {"transform": payload.duplicate(true), "cell_id": str(current_record.get("cell_id", ""))}
    return {}


func _find_index(entity_id: String) -> int: return _find_index_in(_project.entity_records, entity_id)


func _find_index_in(records: Array, entity_id: String) -> int:
    for index in range(records.size()):
        if str(records[index].get("entity_id", "")) == entity_id: return index
    return -1


func _copy_records(records: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for record in records: result.append(record.duplicate(true))
    return result
