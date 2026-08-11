extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const CommandHistory = preload("res://src/commands/command_history.gd")
const CommandTransaction = preload("res://src/commands/command_transaction.gd")
const CounterCommand = preload("res://tests/unit/fixtures/counter_command.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    _check_execute_undo_redo(errors)
    _check_grouped_transaction(errors)
    _check_failed_transaction_rollback(errors)
    _check_divergent_edit_clears_redo(errors)
    _check_bounded_history(errors)
    return errors


static func _check_execute_undo_redo(errors: Array[String]) -> void:
    var state := {"value": 0}
    var history = CommandHistory.new(8)
    var execute_result: Dictionary = history.execute_command(CounterCommand.new(state, 3), "Increment")

    _expect(errors, execute_result.get("ok", false), "A valid command must execute successfully.")
    _expect(errors, state["value"] == 3, "Command execution must mutate authored state.")
    _expect(errors, history.undo_count() == 1, "Successful command execution must create one undo entry.")

    _expect(errors, history.undo().get("ok", false), "Committed command must undo successfully.")
    _expect(errors, state["value"] == 0, "Undo must reverse the committed command.")
    _expect(errors, history.redo_count() == 1, "Undo must move the transaction to redo history.")

    _expect(errors, history.redo().get("ok", false), "Undone command must redo successfully.")
    _expect(errors, state["value"] == 3, "Redo must reapply the committed command.")


static func _check_grouped_transaction(errors: Array[String]) -> void:
    var state := {"value": 0}
    var history = CommandHistory.new(8)
    var transaction = CommandTransaction.new("Grouped edit")
    transaction.add_command(CounterCommand.new(state, 2))
    transaction.add_command(CounterCommand.new(state, 5))

    _expect(errors, StableId.is_valid(transaction.transaction_id), "History transactions must use stable UUID identities.")
    _expect(errors, history.execute_transaction(transaction).get("ok", false), "A valid grouped transaction must execute.")
    _expect(errors, state["value"] == 7, "All commands in a successful transaction must apply.")
    _expect(errors, history.undo_count() == 1, "A grouped transaction must create exactly one history entry.")

    _expect(errors, history.undo().get("ok", false), "Grouped transaction must undo as one entry.")
    _expect(errors, state["value"] == 0, "Grouped undo must reverse every command in reverse order.")
    _expect(errors, history.redo().get("ok", false), "Grouped transaction must redo as one entry.")
    _expect(errors, state["value"] == 7, "Grouped redo must reapply every command.")


static func _check_failed_transaction_rollback(errors: Array[String]) -> void:
    var state := {"value": 0}
    var history = CommandHistory.new(8)
    var transaction = CommandTransaction.new("Failing edit")
    transaction.add_command(CounterCommand.new(state, 4))
    transaction.add_command(CounterCommand.new(state, 99, true))

    var result: Dictionary = history.execute_transaction(transaction)
    _expect(errors, not result.get("ok", false), "A transaction must fail when any command fails.")
    _expect(errors, state["value"] == 0, "Failed transaction must roll back already-applied commands.")
    _expect(errors, history.undo_count() == 0, "Failed transaction must not enter undo history.")
    _expect(errors, history.redo_count() == 0, "Failed transaction must not create redo history.")


static func _check_divergent_edit_clears_redo(errors: Array[String]) -> void:
    var state := {"value": 0}
    var history = CommandHistory.new(8)
    history.execute_command(CounterCommand.new(state, 1), "First")
    history.undo()
    _expect(errors, history.redo_count() == 1, "Undo must make one redo entry available.")

    history.execute_command(CounterCommand.new(state, 10), "Divergent")
    _expect(errors, state["value"] == 10, "Divergent edit must apply from the undone state.")
    _expect(errors, history.redo_count() == 0, "A new divergent edit must clear redo history.")
    _expect(errors, not history.redo().get("ok", false), "Cleared redo history must not be replayable.")


static func _check_bounded_history(errors: Array[String]) -> void:
    var state := {"value": 0}
    var history = CommandHistory.new(2)
    history.execute_command(CounterCommand.new(state, 1), "Oldest")
    history.execute_command(CounterCommand.new(state, 10), "Middle")
    history.execute_command(CounterCommand.new(state, 100), "Newest")

    _expect(errors, history.undo_count() == 2, "Undo history must not exceed its configured bound.")
    history.undo()
    history.undo()
    _expect(errors, state["value"] == 1, "Bounded history must discard the oldest history entry, not its applied state.")
    _expect(errors, not history.undo().get("ok", false), "Discarded history entries must no longer be undoable.")


static func _expect(errors: Array[String], condition: bool, message: String) -> void:
    if not condition:
        errors.append(message)
