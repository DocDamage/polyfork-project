class_name PlayWorldAutosaveService
extends RefCounted

const DEFAULT_INTERVAL_SECONDS := 30.0

var interval_seconds: float
var _repository
var _project
var _dirty := false
var _elapsed_seconds := 0.0


func _init(repository, autosave_interval_seconds: float = DEFAULT_INTERVAL_SECONDS) -> void:
    _repository = repository
    interval_seconds = max(0.1, autosave_interval_seconds)


func attach_project(project) -> Dictionary:
    if project == null:
        return _failure("Autosave requires an active project.")
    var errors: Array[String] = project.validate()
    if not errors.is_empty():
        return {"ok": false, "errors": errors}
    _project = project
    _dirty = false
    _elapsed_seconds = 0.0
    return {"ok": true, "errors": []}


func detach_project() -> void:
    _project = null
    _dirty = false
    _elapsed_seconds = 0.0


func mark_dirty() -> Dictionary:
    if _project == null:
        return _failure("Cannot mark autosave dirty without an active project.")
    _dirty = true
    return {"ok": true, "errors": []}


func mark_clean() -> void:
    _dirty = false
    _elapsed_seconds = 0.0


func is_dirty() -> bool:
    return _dirty


func advance(delta_seconds: float) -> Dictionary:
    if _project == null:
        return {"ok": true, "attempted": false, "reason": "no_project"}
    if not _dirty:
        return {"ok": true, "attempted": false, "reason": "clean"}

    _elapsed_seconds += max(0.0, delta_seconds)
    if _elapsed_seconds < interval_seconds:
        return {"ok": true, "attempted": false, "reason": "interval_pending"}
    return checkpoint_now()


func checkpoint_now() -> Dictionary:
    if _project == null:
        return _failure_attempt("Autosave requires an active project.")
    if not _dirty:
        return {"ok": true, "attempted": false, "reason": "clean"}

    _elapsed_seconds = 0.0
    var result: Dictionary = _repository.create_checkpoint(_project)
    result["attempted"] = true
    if result.get("ok", false):
        _dirty = false
    return result


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}


func _failure_attempt(message: String) -> Dictionary:
    return {"ok": false, "attempted": true, "errors": [message]}
