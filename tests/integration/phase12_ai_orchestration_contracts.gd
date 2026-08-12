extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const AssetLibrary = preload("res://src/assets/asset_library_service.gd")
const AiCreationService = preload("res://src/ai/ai_creation_service.gd")
const Contracts = preload("res://src/ai/ai_contracts.gd")

class FakeProvider extends Node:
    signal response_completed(request_id: String, response: Dictionary)
    signal status_changed(message: String, is_error: bool)
    var _last_request_id := ""
    var _step := 0
    var submissions := 0
    func submit(request: Dictionary) -> Dictionary:
        var request_id: String = str(request.get("request_id", ""))
        if request_id != _last_request_id: _last_request_id = request_id; _step = 0
        else: _step += 1
        submissions += 1
        call_deferred("_respond", request_id, _step)
        return {"ok": true, "errors": [], "pending": true, "request_id": request_id}
    func cancel(_request_id: String = "") -> Dictionary: return {"ok": true, "errors": [], "cancelled": true}
    func _respond(request_id: String, step: int) -> void:
        if step == 0:
            response_completed.emit(request_id, {"ok": true, "errors": [], "message": {"role": "assistant", "content": "", "tool_calls": [{"id": "tool-1", "type": "function", "function": {"name": "project_summary", "arguments": "{}"}}]}, "tool_calls": [{"call_id": "tool-1", "tool": "project_summary", "arguments": {}}], "structured": null})
        else:
            response_completed.emit(request_id, {"ok": true, "errors": [], "message": {"role": "assistant", "content": "structured"}, "tool_calls": [], "structured": {"summary": "Place one local proxy", "actions": [{"type": "entity.place_proxy", "arguments": {"display_name": "AI Planned Object", "position": [1.0, 0.5, 1.0], "result_ref": "planned"}, "reason": "Use a safe proxy without inventing an asset."}], "notes": ["Queried project summary first."]}})

class FakeRegistry extends Node:
    signal status_changed(message: String, is_error: bool)
    signal settings_changed(settings: Dictionary)
    var provider
    var settings: Dictionary
    func _init(provider_value) -> void:
        provider = provider_value; add_child(provider)
        settings = {"document_type": Contracts.PROVIDER_SETTINGS_TYPE, "schema_version": Contracts.SCHEMA_VERSION, "active_provider_id": "fake", "privacy": Contracts.default_privacy_policy(), "providers": [{"provider_id": "fake", "display_name": "Fake Local", "protocol": "openai_compatible_chat_v1", "scope": "local", "endpoint": "http://127.0.0.1:1/v1/chat/completions", "model": "fake", "credential_env": "", "timeout_seconds": 5.0, "enabled": true}]}
    func load_settings() -> Dictionary: return {"ok": true, "errors": [], "settings": settings.duplicate(true), "created": false}
    func get_settings() -> Dictionary: return settings.duplicate(true)
    func create_active_provider() -> Dictionary: return {"ok": true, "errors": [], "provider": provider, "descriptor": settings["providers"][0].duplicate(true), "privacy": settings["privacy"].duplicate(true)}

static func run_checks(tree_root: Node) -> Array[String]:
    var errors: Array[String] = []
    var project_dir: String = "user://tests/phase12/orchestration-%s" % StableId.generate()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(project_dir))
    var project = WorldProject.new(); project.initialize_new("Phase 12 Orchestration", &"small", "blank_sandbox")
    var cells: Array[String] = [StableId.generate()]; project.cell_ids = cells
    var fixture := Node3D.new(); tree_root.add_child(fixture)
    var editor = EditorSession.new(); fixture.add_child(editor)
    var dirty := {"count": 0}
    var bind_editor: Dictionary = editor.bind_project(project, func() -> Dictionary: dirty["count"] = int(dirty["count"]) + 1; return {"ok": true, "errors": []})
    if not bind_editor.get("ok", false): fixture.queue_free(); return ["Orchestration fixture could not bind editor."]
    var assets = AssetLibrary.new(project_dir); var load_assets: Dictionary = assets.load_library()
    if not load_assets.get("ok", false): fixture.queue_free(); return ["Orchestration fixture could not load Asset Library."]
    var provider = FakeProvider.new(); var registry = FakeRegistry.new(provider)
    var service = AiCreationService.new("", registry); fixture.add_child(service)
    var mode := {"value": &"build"}
    var bind: Dictionary = service.bind(project, project_dir, editor, func() -> Dictionary: dirty["count"] = int(dirty["count"]) + 1; return {"ok": true, "errors": []}, assets, null, null, null, null, null, null, func(): return mode["value"])
    if not bind.get("ok", false): fixture.queue_free(); return ["AI Creation orchestration fixture could not bind: %s" % bind.get("errors", [])]
    var results: Array[Dictionary] = []
    service.result_ready.connect(func(result: Dictionary) -> void: results.append(result.duplicate(true)))
    var authored_before: Dictionary = project.to_dictionary()

    var suggest: Dictionary = service.request("suggest", "Suggest one safe object")
    if not suggest.get("ok", false): errors.append("Suggest orchestration must start through the provider interface.")
    await tree_root.get_tree().process_frame; await tree_root.get_tree().process_frame; await tree_root.get_tree().process_frame
    if results.is_empty() or not results[-1].get("ok", false) or str(results[-1].get("mode", "")) != "suggest": errors.append("Suggest orchestration must complete with structured validated output.")
    elif int(results[-1].get("tool_rounds", 0)) != 1 or provider.submissions < 2: errors.append("Suggest orchestration must execute bounded read-only query-tool continuation rounds.")
    if project.to_dictionary() != authored_before or not editor.get_history_counts().is_empty() and int(editor.get_history_counts().get("undo", 0)) != 0: errors.append("Suggest mode must never mutate authored project state or history.")

    results.clear(); var preview_request: Dictionary = service.request("preview", "Preview one safe object")
    if not preview_request.get("ok", false): errors.append("Preview orchestration must start through the provider interface.")
    await tree_root.get_tree().process_frame; await tree_root.get_tree().process_frame; await tree_root.get_tree().process_frame
    if results.is_empty() or not results[-1].get("ok", false) or str(results[-1].get("mode", "")) != "preview" or not bool(results[-1].get("executable", false)): errors.append("Preview orchestration must produce an executable validated preview.")
    if project.to_dictionary() != authored_before or not service.has_executable_preview(): errors.append("Preview must cache a proposal without mutating authored state.")
    var execute: Dictionary = service.execute_last_preview()
    if not execute.get("ok", false) or project.entity_records.size() != 1: errors.append("Execute must consume the last validated Preview and author through the transaction layer.")
    if int(editor.get_history_counts().get("undo", 0)) != 1: errors.append("Preview-to-Execute orchestration must still produce one universal Undo step.")

    mode["value"] = &"play"
    if service.request("suggest", "Blocked in play").get("ok", false): errors.append("AI provider authoring requests must be blocked during Play.")
    if service.execute_last_preview().get("ok", false): errors.append("AI Execute must be blocked during Play.")
    fixture.queue_free()
    return errors
