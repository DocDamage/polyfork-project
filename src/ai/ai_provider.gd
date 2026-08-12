class_name PlayWorldAiProvider
extends Node

signal response_completed(request_id: String, response: Dictionary)
signal status_changed(message: String, is_error: bool)

var _descriptor: Dictionary = {}


func configure(descriptor: Dictionary) -> Dictionary:
    _descriptor = descriptor.duplicate(true)
    return {"ok": true, "errors": []}


func get_descriptor() -> Dictionary:
    return _descriptor.duplicate(true)


func submit(_request: Dictionary) -> Dictionary:
    return _failure("AI provider does not implement submit().")


func cancel(_request_id: String = "") -> Dictionary:
    return {"ok": true, "errors": [], "cancelled": false}


func is_busy() -> bool:
    return false


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
