class_name PlayWorldAiExecutionService
extends RefCounted

signal executed(result: Dictionary)
signal status_changed(message: String, is_error: bool)

const StableId = preload("res://src/world/stable_id.gd")
const StagingService = preload("res://src/ai/ai_staging_service.gd")
const HistoryRepository = preload("res://src/ai/ai_history_repository.gd")
const CompositeCommand = preload("res://src/ai/ai_composite_command.gd")
const ProjectSnapshotCommand = preload("res://src/ai/ai_project_snapshot_command.gd")
const GameplaySnapshotCommand = preload("res://src/gameplay/gameplay_snapshot_command.gd")
const VisualSnapshotCommand = preload("res://src/visual_scripting/visual_graph_snapshot_command.gd")
const ProceduralSnapshotCommand = preload("res://src/procedural/procedural_snapshot_command.gd")
const EnvironmentSnapshotCommand = preload("res://src/environment/environment_snapshot_command.gd")

var _project
var _editor_session
var _dirty_callback := Callable()
var _action_registry
var _staging
var _history_repository
var _gameplay_service
var _visual_service
var _procedural_service
var _procedural_runtime
var _environment_service
var _last_execution: Dictionary = {}


func bind(project, project_directory: String, editor_session, dirty_callback: Callable, action_registry, terrain_controller = null, gameplay_service = null, visual_service = null, procedural_service = null, procedural_runtime = null, environment_service = null) -> Dictionary:
    if project == null or editor_session == null or action_registry == null or not dirty_callback.is_valid():
        return _failure("AI execution service requires project, editor session, action registry, and dirty callback.")
    _project = project
    _editor_session = editor_session
    _dirty_callback = dirty_callback
    _action_registry = action_registry
    _gameplay_service = gameplay_service
    _visual_service = visual_service
    _procedural_service = procedural_service
    _procedural_runtime = procedural_runtime
    _environment_service = environment_service
    _staging = StagingService.new()
    var stage_bind: Dictionary = _staging.bind(project, terrain_controller, gameplay_service, visual_service, procedural_service, environment_service)
    if not stage_bind.get("ok", false): return stage_bind
    _history_repository = HistoryRepository.new(project_directory)
    var history_open: Dictionary = _history_repository.open_or_create(str(project.project_id))
    if not history_open.get("ok", false): return history_open
    return {"ok": true, "errors": [], "history_entries": history_open.get("entries", []).size()}


func execute(proposal: Dictionary, provider_id: String, prompt: String = "", record_prompt: bool = true) -> Dictionary:
    if not _is_bound(): return _failure("AI execution service is not bound.")
    var proposal_errors: Array[String] = _action_registry.validate_proposal(proposal)
    if not proposal_errors.is_empty(): return {"ok": false, "errors": proposal_errors}
    if proposal.get("actions", []).is_empty(): return _failure("AI Execute requires a proposal containing at least one action.")
    var staged: Dictionary = _staging.stage(proposal)
    if not staged.get("ok", false): return staged
    var execution_id: String = StableId.generate()
    var entry: Dictionary = {
        "execution_id": execution_id,
        "request_id": str(proposal.get("request_id", "")),
        "proposal_id": str(proposal.get("proposal_id", "")),
        "provider_id": provider_id,
        "mode": "execute",
        "summary": str(proposal.get("summary", "")),
        "source_asset_ids": _action_registry.source_asset_ids(proposal),
        "action_count": proposal.get("actions", []).size(),
        "timestamp_unix": int(Time.get_unix_time_from_system()),
        "active": true,
        "status": "applied",
    }
    if record_prompt: entry["prompt"] = prompt.left(12000)
    var command = CompositeCommand.new("AI Execute", Callable(self, "_refresh_authored_runtime"), _history_repository, entry)
    var build_result: Dictionary = _add_staged_commands(command, staged)
    if not build_result.get("ok", false): return build_result
    if command.size() == 0: return _failure("AI Execute produced no authored commands.")
    var history_result: Dictionary = _editor_session.get_history().execute_command(command, "AI Execute")
    if not history_result.get("ok", false):
        return _failure(str(history_result.get("error", history_result.get("errors", ["AI Execute failed."]))))
    _last_execution = {
        "execution_id": execution_id,
        "transaction_id": str(history_result.get("transaction_id", "")),
        "generated": staged.get("generated", {}).duplicate(true),
        "source_asset_ids": entry["source_asset_ids"].duplicate(),
    }
    var result: Dictionary = {"ok": true, "errors": [], "execution_id": execution_id, "transaction_id": _last_execution["transaction_id"], "generated": _last_execution["generated"], "source_asset_ids": _last_execution["source_asset_ids"]}
    executed.emit(result.duplicate(true))
    status_changed.emit("AI proposal executed as one Undo step", false)
    return result


func get_history_entries() -> Array[Dictionary]:
    return [] if _history_repository == null else _history_repository.get_entries()


func get_last_execution() -> Dictionary:
    return _last_execution.duplicate(true)


func _add_staged_commands(command, staged: Dictionary) -> Dictionary:
    var changed: Dictionary = staged.get("changed", {})
    var before_project: Dictionary = staged.get("before_project", {})
    var after_project: Dictionary = staged.get("after_project", {})
    if bool(changed.get("gameplay", false)):
        if _gameplay_service == null: return _failure("AI staged gameplay edits without a Gameplay service.")
        var gameplay_command = GameplaySnapshotCommand.new(
            _project,
            _gameplay_service.get_state(),
            _gameplay_service.get_repository(),
            before_project,
            after_project,
            staged.get("gameplay_before", {}),
            staged.get("gameplay_after", {}),
            ["instances"]
        )
        var add_gameplay: Dictionary = command.add_command(gameplay_command)
        if not add_gameplay.get("ok", false): return add_gameplay
    if bool(changed.get("visual", false)):
        if _visual_service == null: return _failure("AI staged visual edits without a Visual Scripting service.")
        var visual_command = VisualSnapshotCommand.new(
            _project,
            _visual_service.get_state(),
            _visual_service.get_repository(),
            staged.get("visual_before", []),
            staged.get("visual_after", []),
            before_project.get("registries", {}),
            after_project.get("registries", {})
        )
        var add_visual: Dictionary = command.add_command(visual_command)
        if not add_visual.get("ok", false): return add_visual
    if bool(changed.get("procedural", false)):
        if _procedural_service == null: return _failure("AI staged procedural edits without a Procedural service.")
        var procedural_refresh := Callable()
        if _procedural_runtime != null and _procedural_runtime.has_method("refresh_all"): procedural_refresh = Callable(_procedural_runtime, "refresh_all")
        var procedural_command = ProceduralSnapshotCommand.new(_project, _procedural_service.get_state(), _procedural_service.get_repository(), staged.get("procedural_before", {}), staged.get("procedural_after", {}), procedural_refresh)
        var add_procedural: Dictionary = command.add_command(procedural_command)
        if not add_procedural.get("ok", false): return add_procedural
    if bool(changed.get("environment", false)):
        if _environment_service == null: return _failure("AI staged environment edits without an Environment service.")
        var environment_refresh := Callable(_environment_service, "_refresh_runtime")
        var environment_command = EnvironmentSnapshotCommand.new(_project, _environment_service.get_state(), _environment_service.get_repository(), staged.get("environment_before", {}), staged.get("environment_after", {}), environment_refresh)
        var add_environment: Dictionary = command.add_command(environment_command)
        if not add_environment.get("ok", false): return add_environment
    if bool(changed.get("project", false)):
        var project_command = ProjectSnapshotCommand.new(
            _project,
            before_project.get("entities", []),
            after_project.get("entities", []),
            before_project.get("registries", {}),
            after_project.get("registries", {})
        )
        var add_project: Dictionary = command.add_command(project_command)
        if not add_project.get("ok", false): return add_project
    return {"ok": true, "errors": []}


func _refresh_authored_runtime() -> Dictionary:
    var refresh_result: Dictionary = _editor_session.refresh_runtime(true)
    if not refresh_result.get("ok", false): return refresh_result
    if _gameplay_service != null and _gameplay_service.has_signal("gameplay_changed"): _gameplay_service.emit_signal("gameplay_changed")
    if _visual_service != null and _visual_service.has_signal("graphs_changed"): _visual_service.emit_signal("graphs_changed")
    if _procedural_service != null and _procedural_service.has_signal("procedural_changed"): _procedural_service.emit_signal("procedural_changed")
    if _environment_service != null and _environment_service.has_signal("environment_changed"): _environment_service.emit_signal("environment_changed")
    var dirty_result: Variant = _dirty_callback.call()
    if dirty_result is Dictionary and not dirty_result.get("ok", false): return _failure("AI authored state changed but project dirty-state signaling failed.")
    if _editor_session.has_signal("project_changed"): _editor_session.emit_signal("project_changed", _project.to_dictionary())
    return {"ok": true, "errors": []}


func _is_bound() -> bool:
    return _project != null and _editor_session != null and _action_registry != null and _staging != null and _history_repository != null


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
