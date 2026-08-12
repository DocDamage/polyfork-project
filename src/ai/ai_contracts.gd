class_name PlayWorldAiContracts
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")

const SCHEMA_VERSION := 1
const PROPOSAL_TYPE := "polyfork_ai_proposal"
const HISTORY_TYPE := "polyfork_ai_history"
const PROVIDER_SETTINGS_TYPE := "polyfork_ai_provider_settings"
const MODES := ["suggest", "preview", "execute"]
const PROVIDER_SCOPES := ["local", "cloud"]
const MAX_ACTIONS := 64
const MAX_PROMPT_CHARS := 12000
const DEFAULT_CONTEXT_ITEMS := 200
const DEFAULT_CONTEXT_CHARS := 48000


static func default_privacy_policy() -> Dictionary:
    return {
        "local_only": true,
        "cloud_consent": false,
        "record_prompts": true,
        "max_context_items": DEFAULT_CONTEXT_ITEMS,
        "max_context_chars": DEFAULT_CONTEXT_CHARS,
    }


static func empty_provider_settings() -> Dictionary:
    return {
        "document_type": PROVIDER_SETTINGS_TYPE,
        "schema_version": SCHEMA_VERSION,
        "active_provider_id": "",
        "privacy": default_privacy_policy(),
        "providers": [],
    }


static func empty_history(project_id: String) -> Dictionary:
    return {
        "document_type": HISTORY_TYPE,
        "schema_version": SCHEMA_VERSION,
        "project_id": project_id,
        "entries": [],
    }


static func new_proposal(request_id: String, summary: String, actions: Array, notes: Array = []) -> Dictionary:
    return {
        "document_type": PROPOSAL_TYPE,
        "schema_version": SCHEMA_VERSION,
        "proposal_id": StableId.generate(),
        "request_id": request_id,
        "summary": summary.strip_edges(),
        "actions": actions.duplicate(true),
        "notes": notes.duplicate(true),
    }


static func validate_request(value: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if not StableId.is_valid(str(value.get("request_id", ""))): errors.append("AI request requires a stable request_id.")
    if not StableId.is_valid(str(value.get("project_id", ""))): errors.append("AI request requires a stable project_id.")
    var mode: String = str(value.get("mode", ""))
    if not MODES.has(mode): errors.append("AI request mode must be suggest, preview, or execute.")
    var prompt: String = str(value.get("prompt", "")).strip_edges()
    if prompt.is_empty(): errors.append("AI request prompt is required.")
    if prompt.length() > MAX_PROMPT_CHARS: errors.append("AI request prompt exceeds the maximum length.")
    return errors


static func validate_provider_descriptor(value: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    var provider_id: String = str(value.get("provider_id", "")).strip_edges()
    if provider_id.is_empty(): errors.append("AI provider requires provider_id.")
    if str(value.get("display_name", "")).strip_edges().is_empty(): errors.append("AI provider requires display_name.")
    if str(value.get("protocol", "")) != "openai_compatible_chat_v1": errors.append("Unsupported AI provider protocol.")
    var scope: String = str(value.get("scope", ""))
    if not PROVIDER_SCOPES.has(scope): errors.append("AI provider scope must be local or cloud.")
    var endpoint: String = str(value.get("endpoint", "")).strip_edges()
    if not endpoint.begins_with("http://") and not endpoint.begins_with("https://"): errors.append("AI provider endpoint must be HTTP or HTTPS.")
    if scope == "cloud" and not endpoint.begins_with("https://"): errors.append("Cloud AI providers require HTTPS endpoints.")
    if scope == "local" and not _is_local_endpoint(endpoint): errors.append("Local AI provider endpoints must resolve to localhost/loopback.")
    if str(value.get("model", "")).strip_edges().is_empty(): errors.append("AI provider requires a model identifier.")
    var credential_env: String = str(value.get("credential_env", "")).strip_edges()
    if credential_env.contains("=") or credential_env.contains(" "): errors.append("AI credential_env must be an environment-variable name, not a credential value.")
    var timeout_seconds: float = float(value.get("timeout_seconds", 45.0))
    if timeout_seconds < 1.0 or timeout_seconds > 300.0: errors.append("AI provider timeout_seconds must be between 1 and 300.")
    for forbidden in ["api_key", "token", "credential", "secret"]:
        if value.has(forbidden): errors.append("AI provider descriptors may not persist credential fields.")
    return errors


static func validate_provider_settings(value: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if str(value.get("document_type", "")) != PROVIDER_SETTINGS_TYPE: errors.append("AI provider settings document_type is invalid.")
    if int(value.get("schema_version", 0)) != SCHEMA_VERSION: errors.append("AI provider settings schema_version is unsupported.")
    var privacy_value: Variant = value.get("privacy", {})
    if not privacy_value is Dictionary: errors.append("AI provider settings privacy must be a dictionary.")
    else: errors.append_array(validate_privacy_policy(privacy_value))
    var providers_value: Variant = value.get("providers", [])
    if not providers_value is Array: errors.append("AI provider settings providers must be an array.")
    else:
        var seen: Dictionary = {}
        for provider_value in providers_value:
            if not provider_value is Dictionary:
                errors.append("AI provider entries must be dictionaries.")
                continue
            errors.append_array(validate_provider_descriptor(provider_value))
            var provider_id: String = str(provider_value.get("provider_id", ""))
            if seen.has(provider_id): errors.append("AI provider settings contain duplicate provider_id values.")
            seen[provider_id] = true
        var active_id: String = str(value.get("active_provider_id", ""))
        if not active_id.is_empty() and not seen.has(active_id): errors.append("Active AI provider does not exist in provider settings.")
    return errors


static func validate_privacy_policy(value: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    var max_items: int = int(value.get("max_context_items", DEFAULT_CONTEXT_ITEMS))
    var max_chars: int = int(value.get("max_context_chars", DEFAULT_CONTEXT_CHARS))
    if max_items < 1 or max_items > 5000: errors.append("AI max_context_items must be between 1 and 5000.")
    if max_chars < 1024 or max_chars > 500000: errors.append("AI max_context_chars must be between 1024 and 500000.")
    return errors


static func validate_proposal(value: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if str(value.get("document_type", "")) != PROPOSAL_TYPE: errors.append("AI proposal document_type is invalid.")
    if int(value.get("schema_version", 0)) != SCHEMA_VERSION: errors.append("AI proposal schema_version is unsupported.")
    if not StableId.is_valid(str(value.get("proposal_id", ""))): errors.append("AI proposal requires a stable proposal_id.")
    if not StableId.is_valid(str(value.get("request_id", ""))): errors.append("AI proposal requires a stable request_id.")
    if str(value.get("summary", "")).strip_edges().is_empty(): errors.append("AI proposal summary is required.")
    var actions_value: Variant = value.get("actions", [])
    if not actions_value is Array:
        errors.append("AI proposal actions must be an array.")
        return errors
    if actions_value.size() > MAX_ACTIONS: errors.append("AI proposal exceeds the maximum action count.")
    var seen: Dictionary = {}
    for action_value in actions_value:
        if not action_value is Dictionary:
            errors.append("AI proposal actions must be dictionaries.")
            continue
        errors.append_array(validate_action(action_value))
        var action_id: String = str(action_value.get("action_id", ""))
        if seen.has(action_id): errors.append("AI proposal contains duplicate action_id values.")
        seen[action_id] = true
    return errors


static func validate_action(value: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if not StableId.is_valid(str(value.get("action_id", ""))): errors.append("AI action requires a stable action_id.")
    if str(value.get("type", "")).strip_edges().is_empty(): errors.append("AI action requires type.")
    if not value.get("arguments", {}) is Dictionary: errors.append("AI action arguments must be a dictionary.")
    if str(value.get("reason", "")).length() > 1000: errors.append("AI action reason is too long.")
    return errors


static func validate_history(value: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if str(value.get("document_type", "")) != HISTORY_TYPE: errors.append("AI history document_type is invalid.")
    if int(value.get("schema_version", 0)) != SCHEMA_VERSION: errors.append("AI history schema_version is unsupported.")
    if not StableId.is_valid(str(value.get("project_id", ""))): errors.append("AI history requires stable project_id.")
    var entries_value: Variant = value.get("entries", [])
    if not entries_value is Array:
        errors.append("AI history entries must be an array.")
        return errors
    var seen: Dictionary = {}
    for entry_value in entries_value:
        if not entry_value is Dictionary:
            errors.append("AI history entries must be dictionaries.")
            continue
        var execution_id: String = str(entry_value.get("execution_id", ""))
        if not StableId.is_valid(execution_id): errors.append("AI history entry requires stable execution_id.")
        if seen.has(execution_id): errors.append("AI history contains duplicate execution_id values.")
        seen[execution_id] = true
        if str(entry_value.get("provider_id", "")).strip_edges().is_empty(): errors.append("AI history entry requires provider_id.")
        for asset_id in entry_value.get("source_asset_ids", []):
            if not StableId.is_valid(str(asset_id)): errors.append("AI history source_asset_ids must contain stable IDs.")
        for forbidden in ["api_key", "token", "credential", "secret"]:
            if entry_value.has(forbidden): errors.append("AI history may not persist credentials.")
    return errors


static func sanitized_provider_descriptor(value: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for key in ["provider_id", "display_name", "protocol", "scope", "endpoint", "model", "credential_env", "timeout_seconds", "enabled"]:
        if value.has(key): result[key] = value[key]
    return result


static func _is_local_endpoint(endpoint: String) -> bool:
    var lower: String = endpoint.to_lower()
    return lower.begins_with("http://127.0.0.1") or lower.begins_with("https://127.0.0.1") or lower.begins_with("http://localhost") or lower.begins_with("https://localhost") or lower.begins_with("http://[::1]") or lower.begins_with("https://[::1]")
