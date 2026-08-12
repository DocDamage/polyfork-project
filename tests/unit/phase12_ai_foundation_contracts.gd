extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/ai/ai_contracts.gd")
const ProviderRegistry = preload("res://src/ai/ai_provider_registry.gd")
const ProviderSettingsRepository = preload("res://src/ai/ai_provider_settings_repository.gd")
const HistoryRepository = preload("res://src/ai/ai_history_repository.gd")
const OpenAiCompatibleProvider = preload("res://src/ai/openai_compatible_provider.gd")
const QueryService = preload("res://src/ai/ai_query_service.gd")
const ActionRegistry = preload("res://src/ai/ai_action_registry.gd")
const PreviewService = preload("res://src/ai/ai_preview_service.gd")
const GraphBuilder = preload("res://src/ai/ai_graph_builder.gd")
const StagingService = preload("res://src/ai/ai_staging_service.gd")
const ExecutionService = preload("res://src/ai/ai_execution_service.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var local: Dictionary = {"provider_id": "local-test", "display_name": "Local Test", "protocol": "openai_compatible_chat_v1", "scope": "local", "endpoint": "http://127.0.0.1:11434/v1/chat/completions", "model": "test-model", "credential_env": "", "timeout_seconds": 30.0, "enabled": true}
    if not Contracts.validate_provider_descriptor(local).is_empty(): errors.append("Valid loopback OpenAI-compatible provider descriptor must pass validation.")
    var secret_descriptor: Dictionary = local.duplicate(true); secret_descriptor["api_key"] = "must-not-persist"
    if Contracts.validate_provider_descriptor(secret_descriptor).is_empty(): errors.append("Provider descriptors must reject persisted API keys.")
    var remote_local: Dictionary = local.duplicate(true); remote_local["endpoint"] = "http://example.com/v1/chat/completions"
    if Contracts.validate_provider_descriptor(remote_local).is_empty(): errors.append("Local providers must reject non-loopback endpoints.")
    var cloud: Dictionary = local.duplicate(true); cloud["provider_id"] = "cloud-test"; cloud["scope"] = "cloud"; cloud["endpoint"] = "https://example.com/v1/chat/completions"; cloud["credential_env"] = "POLYFORK_TEST_AI_KEY"
    if not Contracts.validate_provider_descriptor(cloud).is_empty(): errors.append("Valid HTTPS cloud provider descriptor with credential env name must pass validation.")

    var settings_path: String = "user://tests/phase12/providers-%s.json" % StableId.generate()
    var registry = ProviderRegistry.new(settings_path)
    var load_result: Dictionary = registry.load_settings()
    if not load_result.get("ok", false): errors.append("AI provider registry must create user-scoped settings.")
    elif not registry.upsert_provider(local).get("ok", false): errors.append("AI provider registry must persist sanitized local provider metadata.")
    elif not registry.upsert_provider(cloud).get("ok", false): errors.append("AI provider registry must persist sanitized cloud provider metadata.")
    else:
        registry.set_active_provider("cloud-test")
        var blocked: Dictionary = registry.resolve_active_provider()
        if blocked.get("ok", false): errors.append("Default local-only policy must block a cloud provider.")
        registry.set_privacy_policy({"local_only": false}); blocked = registry.resolve_active_provider()
        if blocked.get("ok", false): errors.append("Cloud provider must remain blocked without explicit cloud consent.")
        registry.set_privacy_policy({"cloud_consent": true})
        if not registry.resolve_active_provider().get("ok", false): errors.append("Cloud provider must resolve only after explicit consent.")
        var saved: Dictionary = ProviderSettingsRepository.new(settings_path).load_or_create()
        if not saved.get("ok", false): errors.append("Saved AI provider settings must reopen.")
        elif JSON.stringify(saved.get("settings", {})).contains("must-not-persist"): errors.append("AI provider settings must never persist credential values.")
    registry.free()

    var malformed: Dictionary = OpenAiCompatibleProvider.parse_http_response(HTTPRequest.RESULT_SUCCESS, 200, "not json")
    if malformed.get("ok", true): errors.append("Malformed provider JSON must fail locally before orchestration.")
    var remote_error: Dictionary = OpenAiCompatibleProvider.parse_http_response(HTTPRequest.RESULT_SUCCESS, 429, "rate limited")
    if remote_error.get("ok", true) or int(remote_error.get("response_code", 0)) != 429: errors.append("Non-2xx provider responses must preserve the HTTP failure code.")
    var tool_body := JSON.stringify({"choices": [{"message": {"role": "assistant", "content": "", "tool_calls": [{"id": "call-1", "type": "function", "function": {"name": "asset_search", "arguments": "{\"query\":\"tree\",\"limit\":4}"}}]}}]})
    var tool_response: Dictionary = OpenAiCompatibleProvider.parse_http_response(HTTPRequest.RESULT_SUCCESS, 200, tool_body)
    if not tool_response.get("ok", false) or tool_response.get("tool_calls", []).size() != 1 or str(tool_response.get("tool_calls", [])[0].get("tool", "")) != "asset_search": errors.append("OpenAI-compatible tool calls must parse into bounded query requests.")
    var fenced_body := JSON.stringify({"choices": [{"message": {"role": "assistant", "content": "```json\n{\"summary\":\"ok\",\"actions\":[]}\n```"}}]})
    var fenced: Dictionary = OpenAiCompatibleProvider.parse_http_response(HTTPRequest.RESULT_SUCCESS, 200, fenced_body)
    if not fenced.get("ok", false) or not fenced.get("structured") is Dictionary or str(fenced.get("structured", {}).get("summary", "")) != "ok": errors.append("Fenced structured provider output must parse deterministically.")

    var project_id: String = StableId.generate()
    var history = HistoryRepository.new("user://tests/phase12/history-%s" % StableId.generate())
    if not history.open_or_create(project_id).get("ok", false): errors.append("AI history repository must create crash-safe project history.")
    var entry: Dictionary = {"execution_id": StableId.generate(), "provider_id": "local-test", "source_asset_ids": [], "active": true, "status": "applied"}
    if not history.append(entry).get("ok", false): errors.append("AI execution history must accept credential-free entries.")
    else:
        entry["active"] = false; entry["status"] = "undone"
        if not history.upsert(entry).get("ok", false): errors.append("AI execution history must support transactional status updates.")
        elif history.get_entry(str(entry["execution_id"])).get("status") != "undone": errors.append("AI execution history status update must persist in memory.")

    var proposal: Dictionary = Contracts.new_proposal(StableId.generate(), "Test", [])
    if not Contracts.validate_proposal(proposal).is_empty(): errors.append("Locally generated empty proposal contract must validate.")
    if QueryService == null or ActionRegistry == null or PreviewService == null or GraphBuilder == null or StagingService == null or ExecutionService == null or OpenAiCompatibleProvider == null: errors.append("Phase 12 AI foundation modules must preload successfully.")
    return errors
