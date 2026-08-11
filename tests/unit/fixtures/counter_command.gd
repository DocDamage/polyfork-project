extends "res://src/commands/command.gd"

var _target: Dictionary
var _delta: int
var _fail_execute: bool
var _fail_undo: bool


func _init(
    target: Dictionary,
    delta: int = 1,
    fail_execute: bool = false,
    fail_undo: bool = false
) -> void:
    _target = target
    _delta = delta
    _fail_execute = fail_execute
    _fail_undo = fail_undo


func execute() -> bool:
    _clear_error()
    if _fail_execute:
        _set_error("Intentional execute failure.")
        return false
    _target["value"] = int(_target.get("value", 0)) + _delta
    return true


func undo() -> bool:
    _clear_error()
    if _fail_undo:
        _set_error("Intentional undo failure.")
        return false
    _target["value"] = int(_target.get("value", 0)) - _delta
    return true
