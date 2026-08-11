class_name PlayWorldCommandTransaction
extends RefCounted

const Command = preload("res://src/commands/command.gd")
const StableId = preload("res://src/world/stable_id.gd")

var transaction_id: String
var label: String
var _commands: Array[RefCounted] = []
var _error_message := ""


func _init(transaction_label: String = "Edit") -> void:
    transaction_id = StableId.generate()
    label = transaction_label.strip_edges()
    if label.is_empty():
        label = "Edit"


func add_command(command: RefCounted) -> Dictionary:
    if command == null:
        return _failure("Transaction commands cannot be null.")
    if not command is Command:
        return _failure("Transaction entries must implement the PlayWorldCommand contract.")
    _commands.append(command)
    return {"ok": true}


func size() -> int:
    return _commands.size()


func is_empty() -> bool:
    return _commands.is_empty()


func get_error_message() -> String:
    return _error_message


func execute() -> Dictionary:
    _error_message = ""
    if _commands.is_empty():
        return _failure("Cannot execute an empty transaction.")

    var applied_count := 0
    for command in _commands:
        if not command.execute():
            var command_error := _command_error(command, "Command execution failed.")
            var rollback_errors := _rollback_applied(applied_count)
            var message := command_error
            if not rollback_errors.is_empty():
                message += " Rollback also failed: %s" % _format_errors(rollback_errors)
            return _failure(message, rollback_errors)
        applied_count += 1

    return {"ok": true}


func undo() -> Dictionary:
    _error_message = ""
    if _commands.is_empty():
        return _failure("Cannot undo an empty transaction.")

    var undone_commands: Array[RefCounted] = []
    for index in range(_commands.size() - 1, -1, -1):
        var command := _commands[index]
        if not command.undo():
            var command_error := _command_error(command, "Command undo failed.")
            var restore_errors := _restore_undone(undone_commands)
            var message := command_error
            if not restore_errors.is_empty():
                message += " Restore also failed: %s" % _format_errors(restore_errors)
            return _failure(message, restore_errors)
        undone_commands.append(command)

    return {"ok": true}


func _rollback_applied(applied_count: int) -> Array[String]:
    var errors: Array[String] = []
    for index in range(applied_count - 1, -1, -1):
        var command := _commands[index]
        if not command.undo():
            errors.append(_command_error(command, "Rollback undo failed."))
    return errors


func _restore_undone(undone_commands: Array[RefCounted]) -> Array[String]:
    var errors: Array[String] = []
    for index in range(undone_commands.size() - 1, -1, -1):
        var command := undone_commands[index]
        if not command.execute():
            errors.append(_command_error(command, "Undo compensation failed."))
    return errors


func _command_error(command: RefCounted, fallback: String) -> String:
    var message := str(command.get_error_message()).strip_edges()
    return fallback if message.is_empty() else message


func _format_errors(errors: Array[String]) -> String:
    var result := ""
    for error in errors:
        if not result.is_empty():
            result += "; "
        result += error
    return result


func _failure(message: String, secondary_errors: Array[String] = []) -> Dictionary:
    _error_message = message
    return {
        "ok": false,
        "error": message,
        "secondary_errors": secondary_errors.duplicate()
    }
