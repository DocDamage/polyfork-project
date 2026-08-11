class_name PlayWorldCommandHistory
extends RefCounted

const DEFAULT_HISTORY_LIMIT := 100

var _history_limit: int
var _undo_stack: Array[PlayWorldCommandTransaction] = []
var _redo_stack: Array[PlayWorldCommandTransaction] = []


func _init(history_limit: int = DEFAULT_HISTORY_LIMIT) -> void:
    _history_limit = max(1, history_limit)


func execute_command(command: PlayWorldCommand, label: String = "Edit") -> Dictionary:
    var transaction := PlayWorldCommandTransaction.new(label)
    var add_result := transaction.add_command(command)
    if not add_result.get("ok", false):
        return add_result
    return execute_transaction(transaction)


func execute_transaction(transaction: PlayWorldCommandTransaction) -> Dictionary:
    if transaction == null:
        return _failure("Cannot execute a null transaction.")

    var result := transaction.execute()
    if not result.get("ok", false):
        return result

    _redo_stack.clear()
    _undo_stack.append(transaction)
    _trim_undo_history()
    return {
        "ok": true,
        "transaction_id": transaction.transaction_id,
        "label": transaction.label
    }


func undo() -> Dictionary:
    if _undo_stack.is_empty():
        return _failure("Nothing to undo.")

    var transaction := _undo_stack.back()
    var result := transaction.undo()
    if not result.get("ok", false):
        return result

    _undo_stack.pop_back()
    _redo_stack.append(transaction)
    return {
        "ok": true,
        "transaction_id": transaction.transaction_id,
        "label": transaction.label
    }


func redo() -> Dictionary:
    if _redo_stack.is_empty():
        return _failure("Nothing to redo.")

    var transaction := _redo_stack.back()
    var result := transaction.execute()
    if not result.get("ok", false):
        return result

    _redo_stack.pop_back()
    _undo_stack.append(transaction)
    _trim_undo_history()
    return {
        "ok": true,
        "transaction_id": transaction.transaction_id,
        "label": transaction.label
    }


func undo_count() -> int:
    return _undo_stack.size()


func redo_count() -> int:
    return _redo_stack.size()


func history_limit() -> int:
    return _history_limit


func set_history_limit(value: int) -> Dictionary:
    if value < 1:
        return _failure("History limit must be at least 1.")
    _history_limit = value
    _trim_undo_history()
    while _redo_stack.size() > _history_limit:
        _redo_stack.pop_front()
    return {"ok": true}


func clear() -> void:
    _undo_stack.clear()
    _redo_stack.clear()


func _trim_undo_history() -> void:
    while _undo_stack.size() > _history_limit:
        _undo_stack.pop_front()


func _failure(message: String) -> Dictionary:
    return {"ok": false, "error": message}
