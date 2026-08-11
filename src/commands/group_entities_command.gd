class_name PlayWorldGroupEntitiesCommand
extends "res://src/commands/command.gd"

const StableId = preload("res://src/world/stable_id.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")

var _project
var _entity_ids: Array[String] = []
var _group_id := StableId.generate()
var _before_parents: Dictionary = {}
var _group_record: Dictionary = {}
var _prepared := false


func _init(project, entity_ids: Array[String]) -> void:
    _project = project
    _entity_ids = entity_ids.duplicate()


func execute() -> bool:
    _clear_error()
    if _project == null or _entity_ids.size() < 2:
        _set_error("Grouping requires at least two project entities.")
        return false
    if not _prepared:
        if not _prepare():
            return false
        _prepared = true
    if _find_index(_group_id) >= 0:
        _set_error("Group entity ID already exists in the project.")
        return false

    var original := _copy_records(_project.entity_records)
    _project.entity_records.append(_group_record.duplicate(true))
    for entity_id in _entity_ids:
        var index := _find_index(entity_id)
        if index < 0:
            _project.entity_records = original
            _set_error("Grouping target is no longer present in the project.")
            return false
        var record: Dictionary = _project.entity_records[index].duplicate(true)
        record["parent_entity_id"] = _group_id
        _project.entity_records[index] = record

    var errors: Array[String] = _project.validate()
    if not errors.is_empty():
        _project.entity_records = original
        _set_error("Grouping would invalidate the project: %s" % "; ".join(errors))
        return false
    return true


func undo() -> bool:
    _clear_error()
    var original := _copy_records(_project.entity_records)
    var group_index := _find_index(_group_id)
    if group_index < 0:
        _set_error("Group entity is no longer present in the project.")
        return false
    _project.entity_records.remove_at(group_index)

    for entity_id in _entity_ids:
        var index := _find_index(entity_id)
        if index < 0:
            _project.entity_records = original
            _set_error("Grouped entity is no longer present in the project.")
            return false
        var record: Dictionary = _project.entity_records[index].duplicate(true)
        var old_parent: String = str(_before_parents.get(entity_id, ""))
        record["parent_entity_id"] = old_parent if not old_parent.is_empty() else null
        _project.entity_records[index] = record

    var errors: Array[String] = _project.validate()
    if not errors.is_empty():
        _project.entity_records = original
        _set_error("Group undo would invalidate the project: %s" % "; ".join(errors))
        return false
    return true


func group_id() -> String:
    return _group_id


func _prepare() -> bool:
    var cell_id := ""
    var common_parent: Variant = null
    var first := true
    _before_parents.clear()

    for entity_id in _entity_ids:
        var index := _find_index(entity_id)
        if index < 0:
            _set_error("Grouping target is not present in the project.")
            return false
        var record: Dictionary = _project.entity_records[index]
        var record_cell := str(record.get("cell_id", ""))
        if cell_id.is_empty():
            cell_id = record_cell
        elif cell_id != record_cell:
            _set_error("Grouping currently requires all entities to share one owning cell.")
            return false
        var parent = record.get("parent_entity_id")
        var parent_id := "" if parent == null else str(parent)
        _before_parents[entity_id] = parent_id
        if first:
            common_parent = parent
            first = false
        elif (common_parent == null and parent != null) or (common_parent != null and str(common_parent) != parent_id):
            common_parent = null

    _group_record = {
        "document_type": WorldEntity.DOCUMENT_TYPE,
        "schema_version": WorldEntity.SCHEMA_VERSION,
        "entity_id": _group_id,
        "display_name": "Group",
        "cell_id": cell_id,
        "asset_id": null,
        "prefab_id": null,
        "parent_entity_id": common_parent,
        "component_instance_ids": [],
        "transform": {
            "position": [0.0, 0.0, 0.0],
            "rotation_degrees": [0.0, 0.0, 0.0],
            "scale": [1.0, 1.0, 1.0]
        }
    }
    var errors: Array[String] = WorldEntity.validate_dictionary(_group_record)
    if not errors.is_empty():
        _set_error("Generated group entity is invalid: %s" % "; ".join(errors))
        return false
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
