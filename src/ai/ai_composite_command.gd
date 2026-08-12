class_name PlayWorldAiCompositeCommand
extends "res://src/commands/command.gd"

const CommandTransaction = preload("res://src/commands/command_transaction.gd")

var _transaction
var _refresh_callback := Callable()
var _history_repository
var _history_entry: Dictionary = {}


func _init(label: String, refresh_callback: Callable, history_repository, history_entry: Dictionary) -> void:
    _transaction = CommandTransaction.new(label)
    _refresh_callback = refresh_callback
    _history_repository = history_repository
    _history_entry = history_entry.duplicate(true)


func add_command(command: RefCounted) -> Dictionary:
    return _transaction.add_command(command)


func size() -> int:
    return _transaction.size()


func get_execution_id() -> String:
    return str(_history_entry.get("execution_id", ""))


func get_history_entry() -> Dictionary:
    return _history_entry.duplicate(true)


func execute() -> bool:
    _clear_error()
    if _transaction.is_empty():
        _set_error("AI Execute requires at least one authored action.")
        return false
    var apply_result: Dictionary = _transaction.execute()
    if not apply_result.get("ok", false):
        _set_error(str(apply_result.get("error", "AI transaction execution failed.")))
        return false
    var refresh_result: Dictionary = _refresh("apply")
    if not refresh_result.get("ok", false):
        _transaction.undo()
        _refresh("rollback")
        _set_error("AI transaction runtime refresh failed: %s" % str(refresh_result.get("errors", [])))
        return false
    var entry: Dictionary = _history_entry.duplicate(true)
    entry["active"] = true
    entry["status"] = "applied"
    var history_result: Dictionary = _history_repository.upsert(entry) if _history_repository != null else {"ok": true}
    if not history_result.get("ok", false):
        _transaction.undo()
        _refresh("rollback")
        _set_error("AI transaction history persistence failed: %s" % str(history_result.get("errors", [])))
        return false
    _history_entry = entry
    return true


func undo() -> bool:
    _clear_error()
    var undo_result: Dictionary = _transaction.undo()
    if not undo_result.get("ok", false):
        _set_error(str(undo_result.get("error", "AI transaction undo failed.")))
        return false
    var refresh_result: Dictionary = _refresh("undo")
    if not refresh_result.get("ok", false):
        _transaction.execute()
        _refresh("restore")
        _set_error("AI transaction undo refresh failed: %s" % str(refresh_result.get("errors", [])))
        return false
    var entry: Dictionary = _history_entry.duplicate(true)
    entry["active"] = false
    entry["status"] = "undone"
    var history_result: Dictionary = _history_repository.upsert(entry) if _history_repository != null else {"ok": true}
    if not history_result.get("ok", false):
        _transaction.execute()
        _refresh("restore")
        var restored: Dictionary = _history_entry.duplicate(true)
        restored["active"] = true
        restored["status"] = "applied"
        if _history_repository != null: _history_repository.upsert(restored)
        _set_error("AI transaction undo history persistence failed: %s" % str(history_result.get("errors", [])))
        return false
    _history_entry = entry
    return true


func _refresh(_reason: String) -> Dictionary:
    if not _refresh_callback.is_valid(): return {"ok": true, "errors": []}
    var value: Variant = _refresh_callback.call()
    if value is Dictionary: return value
    return {"ok": true, "errors": []}
