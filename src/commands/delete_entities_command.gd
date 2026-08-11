class_name PlayWorldDeleteEntitiesCommand
extends "res://src/commands/command.gd"

var _project
var _requested_ids: Array[String] = []
var _deleted_ids: Array[String] = []
var _captured_records: Array[Dictionary] = []
var _captured := false


func _init(project, entity_ids: Array[String]) -> void:
    _project = project
    _requested_ids = entity_ids.duplicate()


func execute() -> bool:
    _clear_error()
    if _project == null or _requested_ids.is_empty():
        _set_error("Delete requires an active project and at least one entity.")
        return false

    if not _captured:
        if not _capture_delete_closure():
            return false
        _captured = true

    var staged: Array[Dictionary] = []
    for record in _project.entity_records:
        if not _deleted_ids.has(str(record.get("entity_id", ""))):
            staged.append(record.duplicate(true))

    var original := _copy_records(_project.entity_records)
    _project.entity_records = staged
    var errors: Array[String] = _project.validate()
    if not errors.is_empty():
        _project.entity_records = original
        _set_error("Delete would invalidate the project: %s" % "; ".join(errors))
        return false
    return true


func undo() -> bool:
    _clear_error()
    if not _captured:
        _set_error("Delete has no captured state to undo.")
        return false
    var original := _copy_records(_project.entity_records)
    var restored := _copy_records(_project.entity_records)
    for entry in _captured_records:
        var index := min(int(entry["index"]), restored.size())
        restored.insert(index, entry["record"].duplicate(true))
    _project.entity_records = restored
    var errors: Array[String] = _project.validate()
    if not errors.is_empty():
        _project.entity_records = original
        _set_error("Delete undo would invalidate the project: %s" % "; ".join(errors))
        return false
    return true


func deleted_ids() -> Array[String]:
    return _deleted_ids.duplicate()


func _capture_delete_closure() -> bool:
    var known: Dictionary = {}
    for record in _project.entity_records:
        known[str(record.get("entity_id", ""))] = record

    for entity_id in _requested_ids:
        if not known.has(entity_id):
            _set_error("Delete target is not present in the project.")
            return false

    var delete_set: Dictionary = {}
    for entity_id in _requested_ids:
        delete_set[entity_id] = true

    var changed := true
    while changed:
        changed = false
        for record in _project.entity_records:
            var parent = record.get("parent_entity_id")
            if parent == null:
                continue
            var parent_id := str(parent)
            var entity_id := str(record.get("entity_id", ""))
            if delete_set.has(parent_id) and not delete_set.has(entity_id):
                delete_set[entity_id] = true
                changed = true

    _deleted_ids.clear()
    _captured_records.clear()
    for index in range(_project.entity_records.size()):
        var record: Dictionary = _project.entity_records[index]
        var entity_id := str(record.get("entity_id", ""))
        if delete_set.has(entity_id):
            _deleted_ids.append(entity_id)
            _captured_records.append({"index": index, "record": record.duplicate(true)})
    _deleted_ids.sort()
    return true


func _copy_records(records: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for record in records:
        result.append(record.duplicate(true))
    return result
