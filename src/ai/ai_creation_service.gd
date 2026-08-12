class_name PlayWorldAiCreationService
extends Node

signal result_ready(result: Dictionary)
signal status_changed(message: String, is_error: bool)
signal busy_changed(busy: bool)

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/ai/ai_contracts.gd")
const ProviderRegistry = preload("res://src/ai/ai_provider_registry.gd")
const QueryService = preload("res://src/ai/ai_query_service.gd")
const ActionRegistry = preload("res://src/ai/ai_action_registry.gd")
const PreviewService = preload("res://src/ai/ai_preview_service.gd")
const ExecutionService = preload("res://src/ai/ai_execution_service.gd")

const MAX_TOOL_ROUNDS := 6

var _provider_registry
var _query_service = QueryService.new()
var _action_registry = ActionRegistry.new()
var _preview_service = PreviewService.new()
var _execution_service = ExecutionService.new()
var _provider
var _project
var _mode_provider := Callable()
var _busy := false
var _request: Dictionary = {}
var _messages: Array[Dictionary] = []
var _tool_rounds := 0
var _last_preview: Dictionary = {}

func _init(settings_path_override: String = "", provider_registry_override = null) -> void:
    name = "AiCreationService"
    _provider_registry = provider_registry_override if provider_registry_override != null else ProviderRegistry.new(settings_path_override)
    if _provider_registry.get_parent() == null: add_child(_provider_registry)
    if _provider_registry.has_signal("status_changed"): _provider_registry.status_changed.connect(func(message: String, is_error: bool) -> void: status_changed.emit(message, is_error))

func bind(project, project_directory: String, editor_session, dirty_callback: Callable, asset_library, terrain_controller = null, gameplay_service = null, visual_service = null, procedural_service = null, procedural_runtime = null, environment_service = null, mode_provider: Callable = Callable()) -> Dictionary:
    if project == null or editor_session == null or asset_library == null: return _failure("AI Creation requires project, editor session, and Asset Library.")
    _project = project; _mode_provider = mode_provider
    var provider_settings: Dictionary = _provider_registry.load_settings()
    if not provider_settings.get("ok", false): return provider_settings
    var query_bind: Dictionary = _query_service.bind(project, editor_session, asset_library, terrain_controller, gameplay_service, visual_service, procedural_service, environment_service)
    if not query_bind.get("ok", false): return query_bind
    var action_bind: Dictionary = _action_registry.bind(_query_service, gameplay_service)
    if not action_bind.get("ok", false): return action_bind
    var preview_bind: Dictionary = _preview_service.bind(_query_service, _action_registry)
    if not preview_bind.get("ok", false): return preview_bind
    var execute_bind: Dictionary = _execution_service.bind(project, project_directory, editor_session, dirty_callback, _action_registry, terrain_controller, gameplay_service, visual_service, procedural_service, procedural_runtime, environment_service)
    if not execute_bind.get("ok", false): return execute_bind
    return {"ok": true, "errors": [], "provider_settings": _provider_registry.get_settings(), "history_entries": execute_bind.get("history_entries", 0)}

func request(mode: String, prompt: String) -> Dictionary:
    if _busy: return _failure("An AI request is already active.")
    if mode == "execute": return _failure("Execute is available only for the last validated Preview. Use execute_last_preview().")
    if not ["suggest", "preview"].has(mode): return _failure("AI request mode must be suggest or preview.")
    if not _is_build_mode(): return _failure("AI authoring is available only in Build mode.")
    var request_id: String = StableId.generate()
    var request_data: Dictionary = {"request_id": request_id, "project_id": str(_project.project_id), "mode": mode, "prompt": prompt.strip_edges()}
    var request_errors: Array[String] = Contracts.validate_request(request_data)
    if not request_errors.is_empty(): return {"ok": false, "errors": request_errors}
    var provider_result: Dictionary = _provider_registry.create_active_provider()
    if not provider_result.get("ok", false): return provider_result
    _provider = provider_result.get("provider")
    if _provider == null: return _failure("AI provider could not be created.")
    if not _provider.response_completed.is_connected(_on_provider_response): _provider.response_completed.connect(_on_provider_response)
    _request = request_data
    _request["provider_id"] = str(provider_result.get("descriptor", {}).get("provider_id", "")); _request["provider_scope"] = str(provider_result.get("descriptor", {}).get("scope", "")); _request["privacy"] = provider_result.get("privacy", {}).duplicate(true)
    _tool_rounds = 0; _last_preview.clear(); _messages = _initial_messages(prompt, mode, _request["privacy"]); _set_busy(true)
    var submit_result: Dictionary = _submit_provider()
    if not submit_result.get("ok", false): _set_busy(false); _request.clear(); return submit_result
    status_changed.emit(_disclosure_text(_request), false)
    return {"ok": true, "errors": [], "pending": true, "request_id": request_id, "provider_id": _request["provider_id"], "provider_scope": _request["provider_scope"]}

func execute_last_preview() -> Dictionary:
    if _busy: return _failure("Cannot Execute while an AI request is active.")
    if not _is_build_mode(): return _failure("AI Execute is available only in Build mode.")
    if _last_preview.is_empty(): return _failure("AI Execute requires a completed validated Preview.")
    var proposal: Dictionary = _last_preview.get("proposal", {}); var preview: Dictionary = _last_preview.get("preview", {})
    if proposal.is_empty() or not preview.get("ok", false) or bool(preview.get("mutates_authored_state", true)): return _failure("The cached AI Preview is not executable.")
    var privacy: Dictionary = _last_preview.get("privacy", Contracts.default_privacy_policy())
    var result: Dictionary = _execution_service.execute(proposal, str(_last_preview.get("provider_id", "")), str(_last_preview.get("prompt", "")), bool(privacy.get("record_prompts", true)))
    if not result.get("ok", false): status_changed.emit(str(result.get("errors", ["AI Execute failed."])[0]), true); return result
    result["mode"] = "execute"; result["proposal"] = proposal.duplicate(true); result["preview"] = preview.duplicate(true); _last_preview.clear(); result_ready.emit(result.duplicate(true)); return result

func cancel() -> Dictionary:
    if not _busy or _provider == null: return {"ok": true, "errors": [], "cancelled": false}
    var result: Dictionary = _provider.cancel(str(_request.get("request_id", ""))); _set_busy(false); _request.clear(); _messages.clear(); _tool_rounds = 0; return result

func is_busy() -> bool: return _busy
func has_executable_preview() -> bool: return not _last_preview.is_empty()
func get_last_preview() -> Dictionary: return _last_preview.duplicate(true)
func get_provider_registry(): return _provider_registry
func get_query_service(): return _query_service
func get_action_registry(): return _action_registry
func get_execution_history() -> Array[Dictionary]: return _execution_service.get_history_entries()

func _submit_provider() -> Dictionary:
    return _provider.submit({"request_id": str(_request.get("request_id", "")), "messages": _messages.duplicate(true), "tools": _query_service.tool_definitions(), "temperature": 0.2})

func _on_provider_response(request_id: String, response: Dictionary) -> void:
    if not _busy or request_id != str(_request.get("request_id", "")): return
    if not response.get("ok", false): _finish_failure(str(response.get("errors", ["AI provider request failed."])[0])); return
    var tool_calls: Array = response.get("tool_calls", [])
    if not tool_calls.is_empty():
        if _tool_rounds >= MAX_TOOL_ROUNDS: _finish_failure("AI provider exceeded the bounded project-query round limit."); return
        _tool_rounds += 1
        var assistant_message: Variant = response.get("message", {})
        if assistant_message is Dictionary: _messages.append(assistant_message.duplicate(true))
        for call_value in tool_calls:
            if not call_value is Dictionary: continue
            var tool_result: Dictionary = _query_service.execute_tool(str(call_value.get("tool", "")), call_value.get("arguments", {}), int(_request.get("privacy", {}).get("max_context_items", Contracts.DEFAULT_CONTEXT_ITEMS)))
            if not tool_result.get("ok", false): _finish_failure(str(tool_result.get("errors", ["AI query tool failed."])[0])); return
            _messages.append({"role": "tool", "tool_call_id": str(call_value.get("call_id", "")), "content": _bounded_tool_content(tool_result.get("result"), int(_request.get("privacy", {}).get("max_context_chars", Contracts.DEFAULT_CONTEXT_CHARS)))})
        var submit_result: Dictionary = _submit_provider()
        if not submit_result.get("ok", false): _finish_failure(str(submit_result.get("errors", ["AI provider continuation failed."])[0]))
        return
    var structured: Variant = response.get("structured", null)
    if not structured is Dictionary: _finish_failure("AI provider must return a structured JSON proposal after project queries are complete."); return
    var proposal: Dictionary = _action_registry.normalize_provider_proposal(str(_request.get("request_id", "")), structured)
    var validation: Array[String] = _action_registry.validate_proposal(proposal)
    if not validation.is_empty(): _finish_failure("AI provider proposal was rejected: %s" % "; ".join(validation)); return
    var mode: String = str(_request.get("mode", "suggest"))
    if mode == "suggest": _finish_success({"ok": true, "errors": [], "mode": "suggest", "proposal": proposal, "provider_id": _request.get("provider_id", ""), "provider_scope": _request.get("provider_scope", ""), "tool_rounds": _tool_rounds, "mutates_authored_state": false}); return
    var preview: Dictionary = _preview_service.preview(proposal)
    if not preview.get("ok", false): _finish_failure(str(preview.get("errors", ["AI Preview validation failed."])[0])); return
    _last_preview = {"proposal": proposal.duplicate(true), "preview": preview.duplicate(true), "provider_id": str(_request.get("provider_id", "")), "provider_scope": str(_request.get("provider_scope", "")), "prompt": str(_request.get("prompt", "")), "privacy": _request.get("privacy", {}).duplicate(true)}
    _finish_success({"ok": true, "errors": [], "mode": "preview", "proposal": proposal, "preview": preview, "provider_id": _request.get("provider_id", ""), "provider_scope": _request.get("provider_scope", ""), "tool_rounds": _tool_rounds, "mutates_authored_state": false, "executable": true})

func _initial_messages(prompt: String, mode: String, privacy: Dictionary) -> Array[Dictionary]:
    var max_items: int = int(privacy.get("max_context_items", Contracts.DEFAULT_CONTEXT_ITEMS)); var max_chars: int = int(privacy.get("max_context_chars", Contracts.DEFAULT_CONTEXT_CHARS)); var context: Dictionary = _query_service.context_snapshot(prompt, max_items); var context_text: String = _bounded_text(JSON.stringify(context), max_chars); var action_text: String = JSON.stringify(_action_registry.action_catalog())
    var system_text := "You are Polyfork's bounded AI authoring planner. You have read-only query tools. Never invent asset, entity, component, biome, graph, weather, prefab, or other persisted IDs. Query the project when an exact ID is needed. You cannot write files or mutate the project. Return one JSON object only after queries are complete: {\"summary\":string,\"actions\":[{\"type\":string,\"arguments\":object,\"reason\":string}],\"notes\":[string]}. Use only this action catalog: %s. Keep actions minimal and deterministic. If the request cannot be fulfilled using existing assets/references, return no unsafe action and explain it in notes." % action_text
    var user_text := "Mode: %s\nUser request: %s\nBounded current project context:\n%s" % [mode, prompt, context_text]
    return [{"role": "system", "content": system_text}, {"role": "user", "content": user_text}]

func _finish_success(result: Dictionary) -> void:
    _set_busy(false); _request.clear(); _messages.clear(); _tool_rounds = 0; result_ready.emit(result.duplicate(true))
func _finish_failure(message: String) -> void:
    _set_busy(false); _request.clear(); _messages.clear(); _tool_rounds = 0; status_changed.emit(message, true); result_ready.emit({"ok": false, "errors": [message]})
func _set_busy(value: bool) -> void:
    if _busy == value: return
    _busy = value; busy_changed.emit(value)
func _is_build_mode() -> bool:
    if not _mode_provider.is_valid(): return true
    return str(_mode_provider.call()) == "build"
static func _disclosure_text(request: Dictionary) -> String: return "Using local AI provider; project context stays on this machine." if str(request.get("provider_scope", "")) == "local" else "Using cloud AI provider with explicit consent; bounded project/catalog metadata will be sent to the configured endpoint."
static func _bounded_tool_content(value: Variant, max_chars: int) -> String: return _bounded_text(JSON.stringify(value), max_chars)
static func _bounded_text(value: String, max_chars: int) -> String: return value if value.length() <= max_chars else value.left(max_chars) + "\n[context truncated by Polyfork privacy limits]"
static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
