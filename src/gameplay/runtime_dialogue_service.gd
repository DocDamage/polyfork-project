class_name PlayWorldRuntimeDialogueService
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")

var _runtime
var _conversations: Dictionary = {}


func bind_runtime(runtime) -> Dictionary:
    clear()
    if runtime == null or not runtime.has_method("is_loaded") or not runtime.is_loaded():
        return _failure("Dialogue runtime requires loaded gameplay state.")
    _runtime = runtime
    return {"ok": true, "errors": []}


func clear() -> void:
    _runtime = null
    _conversations.clear()


func start_dialogue(dialogue_id: String, initiator_entity_id: String = "") -> Dictionary:
    if _runtime == null:
        return _failure("Dialogue service is not bound.")
    if not _runtime.has_dialogue(dialogue_id):
        return _failure("Dialogue reference does not resolve.")
    if not initiator_entity_id.is_empty() and not _runtime.has_entity(initiator_entity_id):
        return _failure("Dialogue initiator entity reference does not resolve.")
    var dialogue: Dictionary = _runtime.get_dialogue(dialogue_id)
    var start_line_id := str(dialogue.get("start_line_id", ""))
    var line: Dictionary = _find_line(dialogue, start_line_id)
    if line.is_empty():
        return _failure("Dialogue start line does not resolve.")
    var conversation_id: String = StableId.generate()
    _conversations[conversation_id] = {
        "conversation_id": conversation_id,
        "dialogue_id": dialogue_id,
        "initiator_entity_id": initiator_entity_id,
        "current_line_id": start_line_id,
        "completed": false,
    }
    var emit_result: Dictionary = _runtime.emit_event("dialogue.started", initiator_entity_id, _line_speaker(line), {"conversation_id": conversation_id, "dialogue_id": dialogue_id, "line_id": start_line_id})
    if not emit_result.get("ok", false):
        _conversations.erase(conversation_id)
        return emit_result
    _emit_line_event(conversation_id, dialogue, line)
    return {"ok": true, "errors": [], "conversation_id": conversation_id, "line": _present_line(line)}


func get_conversation(conversation_id: String) -> Dictionary:
    if not _conversations.has(conversation_id):
        return _failure("Dialogue conversation does not exist.")
    var conversation: Dictionary = _conversations[conversation_id].duplicate(true)
    var dialogue: Dictionary = _runtime.get_dialogue(str(conversation.get("dialogue_id", "")))
    var line: Dictionary = _find_line(dialogue, str(conversation.get("current_line_id", "")))
    conversation["line"] = _present_line(line) if not line.is_empty() else {}
    return {"ok": true, "errors": [], "conversation": conversation}


func get_current_line(conversation_id: String) -> Dictionary:
    var result: Dictionary = get_conversation(conversation_id)
    if not result.get("ok", false):
        return result
    var conversation: Dictionary = result.get("conversation", {})
    if bool(conversation.get("completed", false)):
        return _failure("Dialogue conversation is complete.")
    var line: Dictionary = conversation.get("line", {})
    if line.is_empty():
        return _failure("Dialogue current line does not resolve.")
    return {"ok": true, "errors": [], "conversation_id": conversation_id, "line": line}


func advance(conversation_id: String, choice_id: String = "") -> Dictionary:
    if not _conversations.has(conversation_id):
        return _failure("Dialogue conversation does not exist.")
    var conversation: Dictionary = _conversations[conversation_id].duplicate(true)
    if bool(conversation.get("completed", false)):
        return _failure("Dialogue conversation is already complete.")
    var dialogue: Dictionary = _runtime.get_dialogue(str(conversation.get("dialogue_id", "")))
    if dialogue.is_empty():
        return _failure("Dialogue definition no longer resolves.")
    var current_line: Dictionary = _find_line(dialogue, str(conversation.get("current_line_id", "")))
    if current_line.is_empty():
        return _failure("Dialogue current line no longer resolves.")

    var next_line_id := ""
    var choices: Array = current_line.get("choices", [])
    if not choices.is_empty():
        if choice_id.is_empty():
            return _failure("Dialogue choice is required for the current line.")
        var choice: Dictionary = _find_choice(choices, choice_id)
        if choice.is_empty():
            return _failure("Dialogue choice does not resolve on the current line.")
        next_line_id = _optional_string(choice.get("next_line_id"))
        var choice_event: Dictionary = _runtime.emit_event("dialogue.choice", _line_speaker(current_line), str(conversation.get("initiator_entity_id", "")), {
            "conversation_id": conversation_id,
            "dialogue_id": conversation.get("dialogue_id"),
            "line_id": current_line.get("line_id"),
            "choice_id": choice_id,
        })
        if not choice_event.get("ok", false):
            return choice_event
    else:
        if not choice_id.is_empty():
            return _failure("Dialogue choice was supplied for a line without choices.")
        next_line_id = _optional_string(current_line.get("next_line_id"))

    var event_key := str(current_line.get("event_key", "")).strip_edges()
    if not event_key.is_empty():
        var custom_event: Dictionary = _runtime.emit_event(event_key, _line_speaker(current_line), str(conversation.get("initiator_entity_id", "")), {
            "conversation_id": conversation_id,
            "dialogue_id": conversation.get("dialogue_id"),
            "line_id": current_line.get("line_id"),
        })
        if not custom_event.get("ok", false):
            return custom_event

    if next_line_id.is_empty():
        conversation["completed"] = true
        _conversations[conversation_id] = conversation
        var complete_event: Dictionary = _runtime.emit_event("dialogue.completed", str(conversation.get("initiator_entity_id", "")), "", {
            "conversation_id": conversation_id,
            "dialogue_id": conversation.get("dialogue_id"),
        })
        if not complete_event.get("ok", false):
            return complete_event
        return {"ok": true, "errors": [], "conversation_id": conversation_id, "completed": true, "line": {}}

    var next_line: Dictionary = _find_line(dialogue, next_line_id)
    if next_line.is_empty():
        return _failure("Dialogue next line does not resolve.")
    conversation["current_line_id"] = next_line_id
    _conversations[conversation_id] = conversation
    var line_event_result: Dictionary = _emit_line_event(conversation_id, dialogue, next_line)
    if not line_event_result.get("ok", false):
        return line_event_result
    return {"ok": true, "errors": [], "conversation_id": conversation_id, "completed": false, "line": _present_line(next_line)}


func get_runtime_snapshot() -> Dictionary:
    var conversations: Dictionary = {}
    for conversation_id in _conversations.keys():
        conversations[str(conversation_id)] = _conversations[conversation_id].duplicate(true)
    return {"conversations": conversations}


func restore_runtime_snapshot(snapshot: Dictionary) -> Dictionary:
    if _runtime == null:
        return _failure("Dialogue service is not bound.")
    var incoming = snapshot.get("conversations", {})
    if not incoming is Dictionary:
        return _failure("Dialogue runtime snapshot conversations must be a dictionary.")
    var restored: Dictionary = {}
    for conversation_id_value in incoming.keys():
        var conversation_id := str(conversation_id_value)
        if not StableId.is_valid(conversation_id):
            return _failure("Dialogue runtime snapshot contains an invalid conversation ID.")
        var value = incoming[conversation_id_value]
        if not value is Dictionary:
            return _failure("Dialogue runtime snapshot conversation must be a dictionary.")
        var record: Dictionary = value
        var dialogue_id := str(record.get("dialogue_id", ""))
        if not _runtime.has_dialogue(dialogue_id):
            return _failure("Dialogue runtime snapshot references a missing dialogue.")
        var current_line_id := str(record.get("current_line_id", ""))
        var dialogue: Dictionary = _runtime.get_dialogue(dialogue_id)
        if not bool(record.get("completed", false)) and _find_line(dialogue, current_line_id).is_empty():
            return _failure("Dialogue runtime snapshot current line does not resolve.")
        var initiator_id := str(record.get("initiator_entity_id", ""))
        if not initiator_id.is_empty() and not _runtime.has_entity(initiator_id):
            return _failure("Dialogue runtime snapshot initiator entity does not resolve.")
        restored[conversation_id] = record.duplicate(true)
    _conversations = restored
    return {"ok": true, "errors": [], "restored": restored.size()}


func _emit_line_event(conversation_id: String, dialogue: Dictionary, line: Dictionary) -> Dictionary:
    return _runtime.emit_event("dialogue.line", _line_speaker(line), "", {
        "conversation_id": conversation_id,
        "dialogue_id": dialogue.get("dialogue_id"),
        "line_id": line.get("line_id"),
    })


func _present_line(line: Dictionary) -> Dictionary:
    var speaker_id := _line_speaker(line)
    var speaker_name := ""
    if not speaker_id.is_empty():
        var participant: Dictionary = _runtime.get_component_values(speaker_id, "dialogue_participant")
        speaker_name = str(participant.get("speaker_name", "")) if not participant.is_empty() else ""
    return {
        "line_id": str(line.get("line_id", "")),
        "speaker_entity_id": speaker_id if not speaker_id.is_empty() else null,
        "speaker_name": speaker_name,
        "text": str(line.get("text", "")),
        "choices": _copy_dictionary_array(line.get("choices", [])),
    }


static func _find_line(dialogue: Dictionary, line_id: String) -> Dictionary:
    for value in dialogue.get("lines", []):
        if value is Dictionary and str(value.get("line_id", "")) == line_id:
            return value.duplicate(true)
    return {}


static func _find_choice(choices: Array, choice_id: String) -> Dictionary:
    for value in choices:
        if value is Dictionary and str(value.get("choice_id", "")) == choice_id:
            return value.duplicate(true)
    return {}


static func _line_speaker(line: Dictionary) -> String:
    return _optional_string(line.get("speaker_entity_id"))


static func _optional_string(value: Variant) -> String:
    if value == null:
        return ""
    return str(value)


static func _copy_dictionary_array(value: Variant) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not value is Array:
        return result
    for item in value:
        if item is Dictionary:
            result.append(item.duplicate(true))
    return result


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
