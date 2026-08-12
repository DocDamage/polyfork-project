extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const NarrativeContracts = preload("res://src/gameplay/gameplay_narrative_contracts.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const RuntimeGameplay = preload("res://src/gameplay/runtime_gameplay_state.gd")
const Quest = preload("res://src/gameplay/runtime_quest_service.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new()
    project.initialize_new("Phase 10 Quest", &"small", "blank_sandbox")
    var cell_id: String = StableId.generate()
    var cell_ids: Array[String] = [cell_id]
    project.cell_ids = cell_ids

    var actor = WorldEntity.new()
    actor.initialize_new("Actor", cell_id)
    var quest_giver = WorldEntity.new()
    quest_giver.initialize_new("Quest Giver", cell_id)
    var item = WorldEntity.new()
    item.initialize_new("Quest Item", cell_id)
    var instances: Array[Dictionary] = []
    _attach(quest_giver, instances, "quest_participant", {"quest_tag": "guide"})
    var entity_records: Array[Dictionary] = [actor.to_dictionary(), quest_giver.to_dictionary(), item.to_dictionary()]
    project.entity_records = entity_records

    var first_quest_id: String = StableId.generate()
    var first_objective_id: String = StableId.generate()
    var first_quest: Dictionary = {
        "document_type": NarrativeContracts.QUEST,
        "schema_version": NarrativeContracts.SCHEMA_VERSION,
        "quest_id": first_quest_id,
        "display_name": "Collect Supplies",
        "description": "Collect two supplies.",
        "participant_entity_ids": [quest_giver.entity_id],
        "prerequisite_quest_ids": [],
        "objectives": [{
            "objective_id": first_objective_id,
            "display_name": "Collect two",
            "kind": "pickup",
            "event_key": "pickup.collected",
            "target_entity_id": item.entity_id,
            "required_count": 2,
            "optional": false,
        }],
    }
    var second_quest_id: String = StableId.generate()
    var second_objective_id: String = StableId.generate()
    var second_quest: Dictionary = {
        "document_type": NarrativeContracts.QUEST,
        "schema_version": NarrativeContracts.SCHEMA_VERSION,
        "quest_id": second_quest_id,
        "display_name": "Report Back",
        "description": "Finish the conversation.",
        "participant_entity_ids": [quest_giver.entity_id],
        "prerequisite_quest_ids": [first_quest_id],
        "objectives": [{
            "objective_id": second_objective_id,
            "display_name": "Report",
            "kind": "dialogue",
            "event_key": "dialogue.completed",
            "target_entity_id": null,
            "required_count": 1,
            "optional": false,
        }],
    }
    if not NarrativeContracts.validate_quest(first_quest).is_empty() or not NarrativeContracts.validate_quest(second_quest).is_empty():
        return ["Valid Phase 10 quest fixtures must satisfy narrative contracts."]

    var runtime = RuntimeGameplay.new()
    var snapshot: Dictionary = {
        "definitions": Components.definitions(),
        "instances": instances,
        "sockets": [],
        "attachments": [],
        "dialogues": [],
        "quests": [first_quest, second_quest],
    }
    var load_result: Dictionary = runtime.initialize(project.to_dictionary(), snapshot)
    if not load_result.get("ok", false):
        return ["Phase 10 quest runtime fixture failed: %s" % str(load_result.get("errors", []))]
    var service = Quest.new()
    var bind_result: Dictionary = service.bind_runtime(runtime)
    if not bind_result.get("ok", false):
        return ["Quest service must bind to loaded runtime gameplay state."]

    var blocked_prerequisite: Dictionary = service.start_quest(second_quest_id)
    if blocked_prerequisite.get("ok", false):
        errors.append("A quest must not start before all stable prerequisite quest IDs are completed.")
    var start_first: Dictionary = service.start_quest(first_quest_id)
    if not start_first.get("ok", false):
        errors.append("A valid quest must start from its stable quest ID.")
    runtime.emit_event("pickup.collected", actor.entity_id, item.entity_id, {"count": 1})
    var midway: Dictionary = service.get_quest_state(first_quest_id).get("state", {})
    if str(midway.get("status", "")) != "active" or int(midway.get("objective_progress", {}).get(first_objective_id, 0)) != 1:
        errors.append("Quest objectives must consume matching gameplay events deterministically.")
    runtime.emit_event("pickup.collected", actor.entity_id, item.entity_id, {"count": 1})
    var completed: Dictionary = service.get_quest_state(first_quest_id).get("state", {})
    if str(completed.get("status", "")) != "completed" or int(completed.get("objective_progress", {}).get(first_objective_id, 0)) != 2:
        errors.append("Required quest objectives must complete the quest at their required count.")

    var start_second: Dictionary = service.start_quest(second_quest_id)
    if not start_second.get("ok", false):
        errors.append("Completed prerequisites must unlock dependent quests.")
    runtime.emit_event("dialogue.completed", actor.entity_id, quest_giver.entity_id, {"conversation_id": StableId.generate()})
    var second_state: Dictionary = service.get_quest_state(second_quest_id).get("state", {})
    if str(second_state.get("status", "")) != "completed":
        errors.append("Quest objectives must support dialogue and other reusable event keys.")

    var kinds: Dictionary = {}
    for event in runtime.events_after(0):
        kinds[str(event.get("kind", ""))] = true
    for expected in ["quest.started", "quest.objective_progress", "quest.completed"]:
        if not kinds.has(expected):
            errors.append("Quest runtime event bus is missing event: %s" % expected)

    var bad_quest: Dictionary = first_quest.duplicate(true)
    bad_quest["quest_id"] = StableId.generate()
    var bad_objectives: Array = bad_quest.get("objectives", []).duplicate(true)
    var bad_objective: Dictionary = bad_objectives[0].duplicate(true)
    bad_objective["target_entity_id"] = StableId.generate()
    bad_objectives[0] = bad_objective
    bad_quest["objectives"] = bad_objectives
    var bad_runtime = RuntimeGameplay.new()
    var bad_snapshot: Dictionary = snapshot.duplicate(true)
    bad_snapshot["quests"] = [bad_quest]
    var bad_result: Dictionary = bad_runtime.initialize(project.to_dictionary(), bad_snapshot)
    if bad_result.get("ok", false):
        errors.append("Runtime quest initialization must fail closed for missing stable objective target references.")

    service.clear()
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
