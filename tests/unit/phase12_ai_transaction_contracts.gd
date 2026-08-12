extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const Command = preload("res://src/commands/command.gd")
const CommandHistory = preload("res://src/commands/command_history.gd")
const CompositeCommand = preload("res://src/ai/ai_composite_command.gd")

class MarkerCommand extends Command:
    var marker: Dictionary
    func _init(value: Dictionary) -> void: marker = value
    func execute() -> bool: marker["value"] = int(marker.get("value", 0)) + 1; return true
    func undo() -> bool: marker["value"] = int(marker.get("value", 0)) - 1; return true

class FailingCommand extends Command:
    func execute() -> bool: _set_error("Intentional Phase 12 subcommand failure."); return false
    func undo() -> bool: return true

static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var marker := {"value": 0}
    var history = CommandHistory.new()
    var failed = CompositeCommand.new("AI rollback", Callable(), null, {"execution_id": StableId.generate()})
    failed.add_command(MarkerCommand.new(marker)); failed.add_command(FailingCommand.new())
    var failed_result: Dictionary = history.execute_command(failed, "AI rollback")
    if failed_result.get("ok", false): errors.append("AI composite execution must fail when any staged subcommand fails.")
    if int(marker["value"]) != 0: errors.append("AI composite execution must roll back already-applied subcommands after a later failure.")
    if history.undo_count() != 0: errors.append("Failed AI Execute must not leave a universal Undo entry.")

    var refresh_marker := {"value": 0}
    var refresh_history = CommandHistory.new()
    var refresh_fail := CompositeCommand.new("AI refresh rollback", func() -> Dictionary: return {"ok": false, "errors": ["intentional refresh failure"]}, null, {"execution_id": StableId.generate()})
    refresh_fail.add_command(MarkerCommand.new(refresh_marker))
    var refresh_result: Dictionary = refresh_history.execute_command(refresh_fail, "AI refresh rollback")
    if refresh_result.get("ok", false): errors.append("AI composite execution must fail if authored-runtime refresh fails.")
    if int(refresh_marker["value"]) != 0: errors.append("Runtime-refresh failure must roll back the staged AI transaction.")
    if refresh_history.undo_count() != 0: errors.append("Refresh-rolled-back AI Execute must not enter universal history.")

    var success_marker := {"value": 0}
    var success_history = CommandHistory.new()
    var success := CompositeCommand.new("AI success", func() -> Dictionary: return {"ok": true, "errors": []}, null, {"execution_id": StableId.generate()})
    success.add_command(MarkerCommand.new(success_marker)); success.add_command(MarkerCommand.new(success_marker))
    if not success_history.execute_command(success, "AI success").get("ok", false): errors.append("Valid multi-command AI composite must execute through universal history.")
    elif int(success_marker["value"]) != 2 or success_history.undo_count() != 1: errors.append("Successful AI composite must expose exactly one Undo entry regardless of subcommand count.")
    elif not success_history.undo().get("ok", false) or int(success_marker["value"]) != 0: errors.append("One universal Undo must revert all successful AI subcommands.")
    elif not success_history.redo().get("ok", false) or int(success_marker["value"]) != 2: errors.append("One universal Redo must reapply all successful AI subcommands.")
    return errors
