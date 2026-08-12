class_name PlayWorldOpenAiCompatibleProvider
extends "res://src/ai/ai_provider.gd"

const Contracts = preload("res://src/ai/ai_contracts.gd")

var _http: HTTPRequest
var _busy := false
var _request_id := ""


func _ready() -> void:
    _ensure_http()


func configure(descriptor: Dictionary) -> Dictionary:
    var errors: Array[String] = Contracts.validate_provider_descriptor(descriptor)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    _descriptor = Contracts.sanitized_provider_descriptor(descriptor)
    _ensure_http()
    _http.timeout = float(_descriptor.get("timeout_seconds", 45.0))
    return {"ok": true, "errors": []}


func submit(request: Dictionary) -> Dictionary:
    if _busy: return _failure("AI provider already has an active request.")
    if _descriptor.is_empty(): return _failure("AI provider is not configured.")
    var request_id: String = str(request.get("request_id", ""))
    if request_id.is_empty(): return _failure("AI provider request requires request_id.")
    var messages_value: Variant = request.get("messages", [])
    if not messages_value is Array or messages_value.is_empty(): return _failure("AI provider request requires messages.")
    var credential_env: String = str(_descriptor.get("credential_env", ""))
    var credential: String = ""
    if not credential_env.is_empty(): credential = OS.get_environment(credential_env)
    if str(_descriptor.get("scope", "")) == "cloud" and not credential_env.is_empty() and credential.is_empty():
        return _failure("Cloud AI provider credential environment variable is not set.")

    var payload: Dictionary = {
        "model": str(_descriptor.get("model", "")),
        "messages": messages_value.duplicate(true),
        "temperature": float(request.get("temperature", 0.2)),
    }
    var tools_value: Variant = request.get("tools", [])
    if tools_value is Array and not tools_value.is_empty():
        payload["tools"] = tools_value.duplicate(true)
        payload["tool_choice"] = "auto"
    var headers := PackedStringArray(["Content-Type: application/json"])
    if not credential.is_empty(): headers.append("Authorization: Bearer %s" % credential)
    for header_value in request.get("headers", []):
        var header: String = str(header_value)
        if not header.strip_edges().is_empty(): headers.append(header)

    _ensure_http()
    _request_id = request_id
    _busy = true
    var error: Error = _http.request(
        str(_descriptor.get("endpoint", "")),
        headers,
        HTTPClient.METHOD_POST,
        JSON.stringify(payload)
    )
    if error != OK:
        _busy = false
        _request_id = ""
        return _failure("Unable to start AI provider HTTP request: %s" % error_string(error))
    status_changed.emit("AI provider request started", false)
    return {"ok": true, "errors": [], "pending": true, "request_id": request_id}


func cancel(request_id: String = "") -> Dictionary:
    if not _busy: return {"ok": true, "errors": [], "cancelled": false}
    if not request_id.is_empty() and request_id != _request_id: return _failure("AI provider cancellation request_id does not match the active request.")
    _http.cancel_request()
    var cancelled_id: String = _request_id
    _busy = false
    _request_id = ""
    status_changed.emit("AI provider request cancelled", false)
    return {"ok": true, "errors": [], "cancelled": true, "request_id": cancelled_id}


func is_busy() -> bool:
    return _busy


func _ensure_http() -> void:
    if _http != null and is_instance_valid(_http): return
    _http = HTTPRequest.new()
    _http.name = "AiHttpRequest"
    add_child(_http)
    _http.request_completed.connect(_on_request_completed)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if not _busy: return
    var completed_id: String = _request_id
    _busy = false
    _request_id = ""
    if result != HTTPRequest.RESULT_SUCCESS:
        _emit_failure(completed_id, "AI provider transport failed with result %d." % result, response_code)
        return
    var body_text: String = body.get_string_from_utf8()
    if response_code < 200 or response_code >= 300:
        _emit_failure(completed_id, "AI provider returned HTTP %d." % response_code, response_code, body_text)
        return
    var parsed: Variant = JSON.parse_string(body_text)
    if not parsed is Dictionary:
        _emit_failure(completed_id, "AI provider returned malformed JSON.", response_code)
        return
    var root: Dictionary = parsed
    var choices_value: Variant = root.get("choices", [])
    if not choices_value is Array or choices_value.is_empty() or not choices_value[0] is Dictionary:
        _emit_failure(completed_id, "AI provider response did not contain a message choice.", response_code)
        return
    var message_value: Variant = choices_value[0].get("message", {})
    if not message_value is Dictionary:
        _emit_failure(completed_id, "AI provider response message is invalid.", response_code)
        return
    var message: Dictionary = message_value
    var content_text: String = _content_text(message.get("content", ""))
    var structured: Variant = null
    if not content_text.strip_edges().is_empty(): structured = JSON.parse_string(_strip_json_fence(content_text))
    var tool_calls: Array[Dictionary] = _tool_calls(message.get("tool_calls", []))
    var usage: Dictionary = root.get("usage", {}).duplicate(true) if root.get("usage", {}) is Dictionary else {}
    response_completed.emit(completed_id, {
        "ok": true,
        "errors": [],
        "response_code": response_code,
        "message": message.duplicate(true),
        "content_text": content_text,
        "structured": structured,
        "tool_calls": tool_calls,
        "usage": usage,
    })
    status_changed.emit("AI provider response received", false)


func _emit_failure(request_id: String, message: String, response_code: int = 0, response_body: String = "") -> void:
    var response: Dictionary = {"ok": false, "errors": [message], "response_code": response_code}
    if not response_body.is_empty(): response["response_body"] = response_body.left(2000)
    response_completed.emit(request_id, response)
    status_changed.emit(message, true)


static func _tool_calls(value: Variant) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not value is Array: return result
    for call_value in value:
        if not call_value is Dictionary: continue
        var function_value: Variant = call_value.get("function", {})
        if not function_value is Dictionary: continue
        var arguments_text: String = str(function_value.get("arguments", "{}"))
        var arguments_value: Variant = JSON.parse_string(arguments_text)
        if not arguments_value is Dictionary: arguments_value = {}
        result.append({
            "call_id": str(call_value.get("id", "")),
            "tool": str(function_value.get("name", "")),
            "arguments": arguments_value,
        })
    return result


static func _content_text(value: Variant) -> String:
    if value is String: return value
    if value is Array:
        var parts: Array[String] = []
        for item in value:
            if item is Dictionary and str(item.get("type", "")) == "text": parts.append(str(item.get("text", "")))
        return "\n".join(parts)
    return ""


static func _strip_json_fence(value: String) -> String:
    var text: String = value.strip_edges()
    if not text.begins_with("```"): return text
    var lines: PackedStringArray = text.split("\n")
    if lines.size() >= 3:
        lines.remove_at(0)
        if lines[lines.size() - 1].strip_edges() == "```": lines.remove_at(lines.size() - 1)
    return "\n".join(lines).strip_edges()
