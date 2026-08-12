class_name PlayWorldGameplayNarrativeContracts
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const SCHEMA_VERSION := 1
const DIALOGUE := "dialogue_definition"
const QUEST := "quest_definition"
const OBJECTIVE_KINDS := ["event_count", "interaction", "pickup", "dialogue", "custom"]


static func validate_dialogue(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    _base(data, DIALOGUE, "dialogue_id", errors)
    if str(data.get("display_name", "")).strip_edges().is_empty(): errors.append("Dialogue display_name is required.")
    _validate_id_array(data.get("participant_entity_ids", []), "Dialogue participant_entity_ids", errors)
    var lines = data.get("lines", [])
    if not lines is Array or lines.is_empty():
        errors.append("Dialogue lines must be a non-empty array.")
        return errors
    var line_ids: Dictionary = {}
    var choice_ids: Dictionary = {}
    for item in lines:
        if not item is Dictionary:
            errors.append("Dialogue lines must contain dictionaries only.")
            continue
        var line: Dictionary = item
        var line_id := str(line.get("line_id", ""))
        _require_id(line_id, "Dialogue line_id", errors)
        if line_ids.has(line_id): errors.append("Dialogue contains duplicate line_id.")
        line_ids[line_id] = true
        _optional_id(line.get("speaker_entity_id"), "Dialogue speaker_entity_id", errors)
        if str(line.get("text", "")).strip_edges().is_empty(): errors.append("Dialogue line text is required.")
        _optional_id(line.get("next_line_id"), "Dialogue next_line_id", errors)
        if not line.get("event_key", "") is String: errors.append("Dialogue line event_key must be a string.")
        var choices = line.get("choices", [])
        if not choices is Array:
            errors.append("Dialogue choices must be an array.")
            continue
        for choice_value in choices:
            if not choice_value is Dictionary:
                errors.append("Dialogue choices must contain dictionaries only.")
                continue
            var choice: Dictionary = choice_value
            var choice_id := str(choice.get("choice_id", ""))
            _require_id(choice_id, "Dialogue choice_id", errors)
            if choice_ids.has(choice_id): errors.append("Dialogue contains duplicate choice_id.")
            choice_ids[choice_id] = true
            if str(choice.get("text", "")).strip_edges().is_empty(): errors.append("Dialogue choice text is required.")
            _optional_id(choice.get("next_line_id"), "Dialogue choice next_line_id", errors)
    var start_line_id := str(data.get("start_line_id", ""))
    _require_id(start_line_id, "Dialogue start_line_id", errors)
    if not start_line_id.is_empty() and not line_ids.has(start_line_id): errors.append("Dialogue start_line_id does not resolve.")
    for item in lines:
        if not item is Dictionary: continue
        var line: Dictionary = item
        var next_value = line.get("next_line_id")
        if next_value != null and not str(next_value).is_empty() and not line_ids.has(str(next_value)): errors.append("Dialogue next_line_id does not resolve.")
        for choice_value in line.get("choices", []):
            if not choice_value is Dictionary: continue
            var next_choice = choice_value.get("next_line_id")
            if next_choice != null and not str(next_choice).is_empty() and not line_ids.has(str(next_choice)): errors.append("Dialogue choice next_line_id does not resolve.")
    return errors


static func validate_quest(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    _base(data, QUEST, "quest_id", errors)
    if str(data.get("display_name", "")).strip_edges().is_empty(): errors.append("Quest display_name is required.")
    if not data.get("description", "") is String: errors.append("Quest description must be a string.")
    _validate_id_array(data.get("participant_entity_ids", []), "Quest participant_entity_ids", errors)
    _validate_id_array(data.get("prerequisite_quest_ids", []), "Quest prerequisite_quest_ids", errors)
    var objectives = data.get("objectives", [])
    if not objectives is Array or objectives.is_empty():
        errors.append("Quest objectives must be a non-empty array.")
        return errors
    var objective_ids: Dictionary = {}
    for item in objectives:
        if not item is Dictionary:
            errors.append("Quest objectives must contain dictionaries only.")
            continue
        var objective: Dictionary = item
        var objective_id := str(objective.get("objective_id", ""))
        _require_id(objective_id, "Quest objective_id", errors)
        if objective_ids.has(objective_id): errors.append("Quest contains duplicate objective_id.")
        objective_ids[objective_id] = true
        if str(objective.get("display_name", "")).strip_edges().is_empty(): errors.append("Quest objective display_name is required.")
        var kind := str(objective.get("kind", ""))
        if not OBJECTIVE_KINDS.has(kind): errors.append("Quest objective kind is unsupported.")
        if str(objective.get("event_key", "")).strip_edges().is_empty(): errors.append("Quest objective event_key is required.")
        _optional_id(objective.get("target_entity_id"), "Quest objective target_entity_id", errors)
        if int(objective.get("required_count", 0)) < 1: errors.append("Quest objective required_count must be at least one.")
        if not objective.get("optional", false) is bool: errors.append("Quest objective optional must be bool.")
    return errors


static func new_dialogue(display_name: String, participant_entity_ids: Array[String], lines: Array[Dictionary], start_line_id: String) -> Dictionary:
    return {
        "document_type": DIALOGUE,
        "schema_version": SCHEMA_VERSION,
        "dialogue_id": StableId.generate(),
        "display_name": display_name,
        "participant_entity_ids": participant_entity_ids.duplicate(),
        "start_line_id": start_line_id,
        "lines": _copy_array(lines),
    }


static func new_quest(display_name: String, description: String, participant_entity_ids: Array[String], objectives: Array[Dictionary]) -> Dictionary:
    return {
        "document_type": QUEST,
        "schema_version": SCHEMA_VERSION,
        "quest_id": StableId.generate(),
        "display_name": display_name,
        "description": description,
        "participant_entity_ids": participant_entity_ids.duplicate(),
        "prerequisite_quest_ids": [],
        "objectives": _copy_array(objectives),
    }


static func _base(data: Dictionary, expected_type: String, id_field: String, errors: Array[String]) -> void:
    if data.get("document_type") != expected_type: errors.append("%s document_type is invalid." % expected_type)
    if int(data.get("schema_version", 0)) != SCHEMA_VERSION: errors.append("%s schema_version is unsupported." % expected_type)
    _require_id(data.get(id_field), "%s %s" % [expected_type, id_field], errors)

static func _validate_id_array(value: Variant, label: String, errors: Array[String]) -> void:
    if not value is Array: errors.append("%s must be an array." % label); return
    var seen: Dictionary = {}
    for item in value:
        var item_id := str(item); _require_id(item_id, label, errors)
        if seen.has(item_id): errors.append("%s contains duplicate IDs." % label)
        seen[item_id] = true

static func _require_id(value: Variant, label: String, errors: Array[String]) -> void:
    if not StableId.is_valid(str(value)): errors.append("%s must be a stable UUID." % label)

static func _optional_id(value: Variant, label: String, errors: Array[String]) -> void:
    if value != null and not str(value).is_empty() and not StableId.is_valid(str(value)): errors.append("%s must be null or a stable UUID." % label)

static func _copy_array(records: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for record in records:
        if record is Dictionary: result.append(record.duplicate(true))
    return result
