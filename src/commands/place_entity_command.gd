class_name PlayWorldPlaceEntityCommand
extends "res://src/commands/command.gd"

const StableId = preload("res://src/world/stable_id.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")

var _project
var _record: Dictionary
var _created_cell_id: String = ""


func _init(project, record: Dictionary) -> void:
    _project = project
    _record = record.duplicate(true)


func execute() -> bool:
    _clear_error()
    if _project == null:
        _set_error("Placement requires an active world project.")
        return false

    var errors: Array[String] = WorldEntity.validate_dictionary(_record)
    if not errors.is_empty():
        _set_error("Placement entity is invalid: %s" % "; ".join(errors))
        return false

    var entity_id := str(_record.get("entity_id", ""))
    if _find_index(entity_id) >= 0:
        _set_error("Placement entity ID is already present in the project.")
        return false

    var cell_id := str(_record.get("cell_id", ""))
    _created_cell_id = ""
    if not _project.cell_ids.has(cell_id):
        if not _project.cell_ids.is_empty():
            _set_error("Placement entity references a cell not owned by the project.")
            return false
        if not StableId.is_valid(cell_id):
            _set_error("Placement requires a valid owning cell ID.")
            return false
        _project.cell_ids.append(cell_id)
        _created_cell_id = cell_id

    _project.entity_records.append(_record.duplicate(true))
    var project_errors: Array[String] = _project.validate()
    if not project_errors.is_empty():
        _project.entity_records.pop_back()
        _remove_created_cell_if_unused()
        _set_error("Placement would invalidate the project: %s" % "; ".join(project_errors))
        return false
    return true


func undo() -> bool:
    _clear_error()
    if _project == null:
        _set_error("Placement undo requires an active world project.")
        return false

    var index := _find_index(str(_record.get("entity_id", "")))
    if index < 0:
        _set_error("Placed entity is no longer present in the project.")
        return false

    var removed: Dictionary = _project.entity_records[index].duplicate(true)
    _project.entity_records.remove_at(index)
    var removed_cell := _remove_created_cell_if_unused()
    var project_errors: Array[String] = _project.validate()
    if not project_errors.is_empty():
        if removed_cell:
            _project.cell_ids.append(_created_cell_id)
        _project.entity_records.insert(index, removed)
        _set_error("Placement undo would invalidate the project: %s" % "; ".join(project_errors))
        return false
    return true


func get_entity_id() -> String:
    return str(_record.get("entity_id", ""))


func get_record() -> Dictionary:
    return _record.duplicate(true)


func _find_index(entity_id: String) -> int:
    for index in range(_project.entity_records.size()):
        if str(_project.entity_records[index].get("entity_id", "")) == entity_id:
            return index
    return -1


func _remove_created_cell_if_unused() -> bool:
    if _created_cell_id.is_empty():
        return false
    for record in _project.entity_records:
        if str(record.get("cell_id", "")) == _created_cell_id:
            return false
    var index := _project.cell_ids.find(_created_cell_id)
    if index >= 0:
        _project.cell_ids.remove_at(index)
        return true
    return false
