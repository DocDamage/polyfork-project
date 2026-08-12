class_name PlayWorldAiProjectSnapshotCommand
extends "res://src/commands/command.gd"

var _project
var _before_entities: Array[Dictionary] = []
var _after_entities: Array[Dictionary] = []
var _before_registries: Dictionary = {}
var _after_registries: Dictionary = {}


func _init(project, before_entities: Array[Dictionary], after_entities: Array[Dictionary], before_registries: Dictionary, after_registries: Dictionary) -> void:
    _project = project
    _before_entities = before_entities.duplicate(true)
    _after_entities = after_entities.duplicate(true)
    _before_registries = before_registries.duplicate(true)
    _after_registries = after_registries.duplicate(true)


func execute() -> bool:
    _clear_error()
    return _apply(_after_entities, _after_registries, _before_entities, _before_registries, "AI project edit")


func undo() -> bool:
    _clear_error()
    return _apply(_before_entities, _before_registries, _after_entities, _after_registries, "AI project undo")


func _apply(entities: Array[Dictionary], registries: Dictionary, rollback_entities: Array[Dictionary], rollback_registries: Dictionary, label: String) -> bool:
    if _project == null:
        _set_error("%s requires an active project." % label)
        return false
    _project.entity_records = entities.duplicate(true)
    _project.registries = registries.duplicate(true)
    var errors: Array[String] = _project.validate()
    if errors.is_empty(): return true
    _project.entity_records = rollback_entities.duplicate(true)
    _project.registries = rollback_registries.duplicate(true)
    _set_error("%s produced invalid project state: %s" % [label, "; ".join(errors)])
    return false
