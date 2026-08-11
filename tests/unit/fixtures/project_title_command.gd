extends "res://src/commands/command.gd"

var _project
var _next_title: String
var _previous_title: String
var _fail_execute: bool
var _fail_undo: bool


func _init(
    project,
    next_title: String,
    fail_execute: bool = false,
    fail_undo: bool = false
) -> void:
    _project = project
    _next_title = next_title
    _previous_title = str(project.title) if project != null else ""
    _fail_execute = fail_execute
    _fail_undo = fail_undo


func execute() -> bool:
    _clear_error()
    if _fail_execute:
        _set_error("Injected project-title execute failure.")
        return false
    if _project == null:
        _set_error("Project-title command requires a project.")
        return false
    _project.title = _next_title
    return true


func undo() -> bool:
    _clear_error()
    if _fail_undo:
        _set_error("Injected project-title undo failure.")
        return false
    if _project == null:
        _set_error("Project-title command requires a project.")
        return false
    _project.title = _previous_title
    return true
