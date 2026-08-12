class_name PlayWorldProceduralSnapshotCommand
extends "res://src/commands/command.gd"

var _project
var _state
var _repository
var _before: Dictionary = {}
var _after: Dictionary = {}
var _refresh_callback := Callable()


func _init(project, state, repository, before_document: Dictionary, after_document: Dictionary, refresh_callback: Callable = Callable()) -> void:
    _project = project
    _state = state
    _repository = repository
    _before = before_document.duplicate(true)
    _after = after_document.duplicate(true)
    _refresh_callback = refresh_callback


func execute() -> bool:
    _clear_error()
    return _apply(_after, _before, "Procedural edit")


func undo() -> bool:
    _clear_error()
    return _apply(_before, _after, "Procedural undo")


func _apply(target: Dictionary, rollback: Dictionary, label: String) -> bool:
    if _project == null or _state == null or _repository == null:
        _set_error("%s requires project, procedural state, and repository." % label)
        return false
    var load_errors: Array[String] = _state.replace_document(target)
    if not load_errors.is_empty():
        _set_error("%s produced invalid procedural state: %s" % [label, str(load_errors)])
        return false
    var persist: Dictionary = _repository.flush(_state, _project)
    if not persist.get("ok", false):
        _state.replace_document(rollback)
        var restore: Dictionary = _repository.flush(_state, _project)
        var suffix: String = ""
        if not restore.get("ok", false):
            suffix = " Recovery persistence also failed: %s" % str(restore.get("errors", []))
        _set_error("%s persistence failed: %s.%s" % [label, str(persist.get("errors", [])), suffix])
        return false
    if _refresh_callback.is_valid():
        var refresh_value: Variant = _refresh_callback.call()
        if refresh_value is Dictionary and not refresh_value.get("ok", false):
            _state.replace_document(rollback)
            _repository.flush(_state, _project)
            _refresh_callback.call()
            _set_error("%s runtime refresh failed: %s" % [label, str(refresh_value.get("errors", []))])
            return false
    return true
