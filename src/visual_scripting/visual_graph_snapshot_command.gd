class_name PlayWorldVisualGraphSnapshotCommand
extends "res://src/commands/command.gd"

var _project
var _state
var _repository
var _before_records: Array[Dictionary] = []
var _after_records: Array[Dictionary] = []
var _before_registries: Dictionary = {}
var _after_registries: Dictionary = {}

func _init(project, state, repository, before_records: Array[Dictionary], after_records: Array[Dictionary], before_registries: Dictionary, after_registries: Dictionary) -> void:
    _project = project; _state = state; _repository = repository
    _before_records = before_records.duplicate(true); _after_records = after_records.duplicate(true)
    _before_registries = before_registries.duplicate(true); _after_registries = after_registries.duplicate(true)

func execute() -> bool: _clear_error(); return _apply(_after_records, _after_registries, _before_records, _before_registries, "Visual graph edit")
func undo() -> bool: _clear_error(); return _apply(_before_records, _before_registries, _after_records, _after_registries, "Visual graph undo")

func _apply(records: Array[Dictionary], registries: Dictionary, rollback_records: Array[Dictionary], rollback_registries: Dictionary, label: String) -> bool:
    if _project == null or _state == null or _repository == null:
        _set_error("%s requires a bound project, graph state, and repository." % label); return false
    var load_errors: Array[String] = _state.replace_records(records)
    if not load_errors.is_empty(): _set_error("%s produced invalid graph state: %s" % [label, load_errors]); return false
    _project.registries = registries.duplicate(true)
    var persist: Dictionary = _repository.flush(_state, _project)
    if persist.get("ok", false): return true
    _state.replace_records(rollback_records); _project.registries = rollback_registries.duplicate(true)
    var restore: Dictionary = _repository.flush(_state, _project); var suffix := ""
    if not restore.get("ok", false): suffix = " Recovery persistence also failed: %s" % str(restore.get("errors", []))
    _set_error("%s persistence failed: %s.%s" % [label, str(persist.get("errors", [])), suffix]); return false
