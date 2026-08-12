class_name PlayWorldGameplaySnapshotCommand
extends "res://src/commands/command.gd"

var _project
var _state
var _repository
var _before_project: Dictionary
var _after_project: Dictionary
var _before_state: Dictionary
var _after_state: Dictionary
var _sections: Array[String] = []


func _init(project, gameplay_state, repository, before_project: Dictionary, after_project: Dictionary, before_state: Dictionary, after_state: Dictionary, sections: Array[String]) -> void:
    _project = project; _state = gameplay_state; _repository = repository
    _before_project = before_project.duplicate(true); _after_project = after_project.duplicate(true)
    _before_state = before_state.duplicate(true); _after_state = after_state.duplicate(true); _sections = sections.duplicate()


func execute() -> bool: _clear_error(); return _apply(_after_project, _after_state, _before_project, _before_state, "Gameplay edit")
func undo() -> bool: _clear_error(); return _apply(_before_project, _before_state, _after_project, _after_state, "Gameplay undo")


func _apply(project_snapshot: Dictionary, state_snapshot: Dictionary, rollback_project: Dictionary, rollback_state: Dictionary, label: String) -> bool:
    if _project == null or _state == null or _repository == null:
        _set_error("%s requires a bound project, gameplay state, and repository." % label); return false
    _assign_project(project_snapshot); _assign_state(state_snapshot)
    var project_errors: Array[String] = _project.validate()
    # World entity availability is recoverable and may change because of Delete/Undo or
    # streaming. Internal gameplay identity/dependency/socket/prefab/narrative relationships remain strict.
    var gameplay_errors: Array[String] = _state.validate(null)
    if not project_errors.is_empty() or not gameplay_errors.is_empty():
        _assign_project(rollback_project); _assign_state(rollback_state)
        _set_error("%s produced invalid authored state: %s %s" % [label, project_errors, gameplay_errors]); return false
    var persist: Dictionary = _repository.flush_sections(_state, _sections)
    if not persist.get("ok", false):
        _assign_project(rollback_project); _assign_state(rollback_state)
        var restore: Dictionary = _repository.flush_sections(_state, _sections); var suffix := ""
        if not restore.get("ok", false): suffix = " Recovery persistence also failed: %s" % [restore.get("errors", [])]
        _set_error("%s persistence failed: %s.%s" % [label, persist.get("errors", []), suffix]); return false
    return true


func _assign_project(snapshot: Dictionary) -> void:
    _project.entity_records = _dictionary_array(snapshot.get("entities", []))
    _project.registries = snapshot.get("registries", {}).duplicate(true)


func _assign_state(snapshot: Dictionary) -> void:
    _state.definitions = _dictionary_array(snapshot.get("definitions", []))
    _state.instances = _dictionary_array(snapshot.get("instances", []))
    _state.archetypes = _dictionary_array(snapshot.get("archetypes", []))
    _state.prefabs = _dictionary_array(snapshot.get("prefabs", []))
    _state.sockets = _dictionary_array(snapshot.get("sockets", []))
    _state.attachments = _dictionary_array(snapshot.get("attachments", []))
    _state.prefab_instances = _dictionary_array(snapshot.get("prefab_instances", []))
    _state.dialogues = _dictionary_array(snapshot.get("dialogues", []))
    _state.quests = _dictionary_array(snapshot.get("quests", []))


static func _dictionary_array(value: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for record in value:
        if record is Dictionary: result.append(record.duplicate(true))
    return result
