extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const NarrativeContracts = preload("res://src/gameplay/gameplay_narrative_contracts.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const RuntimeGameplay = preload("res://src/gameplay/runtime_gameplay_state.gd")
const Dialogue = preload("res://src/gameplay/runtime_dialogue_service.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new()
    project.initialize_new("Phase 10 Dialogue", &"small", "blank_sandbox")
    var cell_id: String = StableId.generate()
    var cell_ids: Array[String] = [cell_id]
    project.cell_ids = cell_ids

    var actor = WorldEntity.new()
    actor.initialize_new("Actor", cell_id)
    var speaker = WorldEntity.new()
    speaker.initialize_new("Speaker", cell_id)
    var instances: Array[Dictionary] = []
    _attach(speaker, instances, "dialogue_participant", {"speaker_name": "Guide"})
    var entity_records: Array[Dictionary] = [actor.to_dictionary(), speaker.to_dictionary()]
    project.entity_records = entity_records

    var line_one_id: String = StableId.generate()
    var line_two_id: String = StableId.generate()
    var choice_id: String = StableId.generate()
    var dialogue_id: String = StableId.generate()
    var dialogue: Dictionary = {
        "document_type": NarrativeContracts.DIALOGUE,
        "schema_version": NarrativeContracts.SCHEMA_VERSION,
        "dialogue_id": dialogue_id,
        "display_name": "Guide Greeting",
        "participant_entity_ids": [actor.entity_id, speaker.entity_id],
        "start_line_id": line_one_id,
        "lines": [
            {
                "line_id": line_one_id,
                "speaker_entity_id": speaker.entity_id,
                "text": "Ready to begin?",
                "next_line_id": null,
                "event_key": "dialogue.prompted",
                "choices": [{"choice_id": choice_id, "text": "Yes", "next_line_id": line_two_id}],
            },
            {
                "line_id": line_two_id,
                "speaker_entity_id": speaker.entity_id,
                "text": "Then move out.",
                "next_line_id": null,
                "event_key": "",
                "choices": [],
            },
        ],
    }
    var contract_errors: Array[String] = NarrativeContracts.validate_dialogue(dialogue)
    if not contract_errors.is_empty():
        return ["Valid Phase 10 dialogue fixture failed validation: %s" % str(contract_errors)]

    var runtime = RuntimeGameplay.new()
    var snapshot: Dictionary = {
        "definitions": Components.definitions(),
        "instances": instances,
        "sockets": [],
        "attachments": [],
        "dialogues": [dialogue],
        "quests": [],
    }
    var load_result: Dictionary = runtime.initialize(project.to_dictionary(), snapshot)
    if not load_result.get("ok", false):
        return ["Phase 10 dialogue runtime fixture failed: %s" % str(load_result.get("errors", []))]
    var service = Dialogue.new()
    var bind_result: Dictionary = service.bind_runtime(runtime)
    if not bind_result.get("ok", false):
        return ["Dialogue service must bind to loaded runtime gameplay state."]

    var start_result: Dictionary = service.start_dialogue(dialogue_id, actor.entity_id)
    if not start_result.get("ok", false):
        errors.append("A valid dialogue must start from its stable dialogue ID.")
        return errors
    var conversation_id := str(start_result.get("conversation_id", ""))
    if not StableId.is_valid(conversation_id):
        errors.append("Dialogue conversations require stable runtime IDs.")
    var first_line: Dictionary = start_result.get("line", {})
    if str(first_line.get("speaker_name", "")) != "Guide" or str(first_line.get("text", "")) != "Ready to begin?":
        errors.append("Dialogue presentation must resolve speaker metadata from the authored Dialogue Participant component.")

    var missing_choice: Dictionary = service.advance(conversation_id)
    if missing_choice.get("ok", false):
        errors.append("Dialogue lines with choices must require a valid choice ID.")
    var invalid_choice: Dictionary = service.advance(conversation_id, StableId.generate())
    if invalid_choice.get("ok", false):
        errors.append("Dialogue must fail safely for a choice ID not present on the current line.")
    var choice_result: Dictionary = service.advance(conversation_id, choice_id)
    if not choice_result.get("ok", false) or str(choice_result.get("line", {}).get("text", "")) != "Then move out.":
        errors.append("Dialogue choices must advance deterministically to their stable next line.")
    var complete_result: Dictionary = service.advance(conversation_id)
    if not complete_result.get("ok", false) or not bool(complete_result.get("completed", false)):
        errors.append("Dialogue must complete when the current line has no next line.")

    var kinds: Dictionary = {}
    for event in runtime.events_after(0):
        kinds[str(event.get("kind", ""))] = true
    for expected in ["dialogue.started", "dialogue.line", "dialogue.choice", "dialogue.prompted", "dialogue.completed"]:
        if not kinds.has(expected):
            errors.append("Dialogue runtime event bus is missing event: %s" % expected)

    var corrupt_dialogue: Dictionary = dialogue.duplicate(true)
    corrupt_dialogue["dialogue_id"] = StableId.generate()
    corrupt_dialogue["participant_entity_ids"] = [StableId.generate()]
    var corrupt_runtime = RuntimeGameplay.new()
    var corrupt_snapshot: Dictionary = snapshot.duplicate(true)
    corrupt_snapshot["dialogues"] = [corrupt_dialogue]
    var corrupt_result: Dictionary = corrupt_runtime.initialize(project.to_dictionary(), corrupt_snapshot)
    if corrupt_result.get("ok", false):
        errors.append("Runtime dialogue initialization must fail closed for missing stable participant references.")
    return errors


static func _attach(entity, instances: Array[Dictionary], component_key: String, patch: Dictionary) -> void:
    var definition: Dictionary = _definition(component_key)
    var values: Dictionary = Contracts.defaults_for(definition)
    for key in patch.keys():
        values[key] = patch[key]
    var record: Dictionary = {
        "document_type": Contracts.COMPONENT_INSTANCE,
        "schema_version": Contracts.SCHEMA_VERSION,
        "instance_id": StableId.generate(),
        "definition_id": str(definition.get("definition_id", "")),
        "owner_entity_id": entity.entity_id,
        "values": values,
    }
    instances.append(record)
    entity.component_instance_ids.append(str(record["instance_id"]))


static func _definition(key: String) -> Dictionary:
    for definition in Components.definitions():
        if str(definition.get("key", "")) == key:
            return definition.duplicate(true)
    return {}
