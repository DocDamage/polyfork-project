@abstract
class_name PlayWorldCommand
extends RefCounted

var _error_message := ""


@abstract func execute() -> bool


@abstract func undo() -> bool


func get_error_message() -> String:
    return _error_message


func _set_error(message: String) -> void:
    _error_message = message


func _clear_error() -> void:
    _error_message = ""
