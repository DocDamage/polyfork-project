class_name PlayWorldRuntimeQuestService
extends RefCounted

var _runtime
var _states: Dictionary = {}
var _event_callable := Callable()


func bind_runtime(runtime) -> Dictionary:
    clear()
    if runtime == null or not runtime.has_method("is_loaded") or not runtime.is_loaded():
        return _failure("Quest runtime requires loaded gameplay state.")
    _runtime = runtime
    _event_callable = Callable(self, "_on_gameplay_event")
    if not _runtime.gameplay_event.is_connected(_event_callable):
        _runtime.gameplay_event.connect(_event_callable)
    return {"ok": true, "errors": []}


func clear() -> void:
    if _runtime != null and _event_callable.is_valid() and _runtime.gameplay_event.is_connected(_event_callable):
        _runtime.gameplay_event.disconnect(_event_callable)
    _runtime = null
    _states.clear()
    _event_callable = Callable()


func start_quest(quest_id: String) -> Dictionary:
    if _runtime == null:
        return _failure("Quest service is not bound.")
    var quest: Dictionary = _runtime.get_quest(quest_id)
    if quest.is_empty():
        return _failure("Quest reference does not resolve.")
    var current: Dictionary = _states.get(quest_id, {})
    if str(current.get("status", "inactive")) == "active":
        return _failure("Quest is already active.")
    if str(current.get("status", "inactive")) == "completed":
        return _failure("Quest is already completed.")
    for prerequisite_value in quest.get("prerequisite_quest_ids", []):
        var prerequisite_id := str(prerequisite_value)
        var prerequisite_state: Dictionary = _states.get(prerequisite_id, {})
        if str(prerequisite_state.get("status", "inactive")) != "completed":
            return _failure("Quest prerequisite is not completed.")
    var progress: Dictionary = {}
    for objective_value in quest.get("objectives", []):
        if objective_value is Dictionary:
            progress[str(objective_value.get("objective_id", ""))] = 0
    _states[quest_id] = {"status": "active", "objective_progress": progress}
    var event_result: Dictionary = _runtime.emit_event("quest.started", "", "", {"quest_id": quest_id})
    if not event_result.get("ok", false):
        _states.erase(quest_id)
        return event_result
    return {"ok": true, "errors": [], "quest_id": quest_id, "state": get_quest_state(quest_id).get("state", {})}


func fail_quest(quest_id: String, reason: String = "") -> Dictionary:
    if _runtime == null:
        return _failure("Quest service is not bound.")
    var state: Dictionary = _states.get(quest_id, {})
    if str(state.get("status", "inactive")) != "active":
        return _failure("Only an active quest can fail.")
    state["status"] = "failed"
    _states[quest_id] = state
    var event_result: Dictionary = _runtime.emit_event("quest.failed", "", "", {"quest_id": quest_id, "reason": reason})
    if not event_result.get("ok", false):
        return event_result
    return {"ok": true, "errors": [], "quest_id": quest_id, "state": state.duplicate(true)}


func get_quest_state(quest_id: String) -> Dictionary:
    if _runtime == null:
        return _failure("Quest service is not bound.")
    if not _runtime.has_quest(quest_id):
        return _failure("Quest reference does not resolve.")
    var state: Dictionary = _states.get(quest_id, {"status": "inactive", "objective_progress": {}}).duplicate(true)
    state["quest_id"] = quest_id
    return {"ok": true, "errors": [], "state": state}


func get_runtime_snapshot() -> Dictionary:
    var states: Dictionary = {}
    for quest_id in _states.keys():
        states[str(quest_id)] = _states[quest_id].duplicate(true)
    return {"quest_states": states}


func restore_runtime_snapshot(snapshot: Dictionary) -> Dictionary:
    if _runtime == null:
        return _failure("Quest service is not bound.")
    var incoming = snapshot.get("quest_states", {})
    if not incoming is Dictionary:
        return _failure("Quest runtime snapshot quest_states must be a dictionary.")
    var restored: Dictionary = {}
    for quest_id_value in incoming.keys():
        var quest_id := str(quest_id_value)
        if not _runtime.has_quest(quest_id):
            return _failure("Quest runtime snapshot references a missing quest.")
        var value = incoming[quest_id_value]
        if not value is Dictionary:
            return _failure("Quest runtime snapshot state must be a dictionary.")
        var record: Dictionary = value
        var status := str(record.get("status", ""))
        if not ["active", "completed", "failed"].has(status):
            return _failure("Quest runtime snapshot contains an invalid status.")
        var progress = record.get("objective_progress", {})
        if not progress is Dictionary:
            return _failure("Quest runtime snapshot objective_progress must be a dictionary.")
        var quest: Dictionary = _runtime.get_quest(quest_id)
        var objective_ids: Dictionary = {}
        for objective_value in quest.get("objectives", []):
            if objective_value is Dictionary:
                objective_ids[str(objective_value.get("objective_id", ""))] = int(objective_value.get("required_count", 1))
        for objective_id_value in progress.keys():
            var objective_id := str(objective_id_value)
            if not objective_ids.has(objective_id):
                return _failure("Quest runtime snapshot objective reference does not resolve.")
            var count := int(progress[objective_id_value])
            if count < 0 or count > int(objective_ids[objective_id]):
                return _failure("Quest runtime snapshot objective progress is out of range.")
        restored[quest_id] = record.duplicate(true)
    _states = restored
    return {"ok": true, "errors": [], "restored": restored.size()}


func _on_gameplay_event(event: Dictionary) -> void:
    var kind := str(event.get("kind", ""))
    if kind.begins_with("quest."):
        return
    var quest_ids: Array[String] = []
    for quest_id_value in _states.keys():
        quest_ids.append(str(quest_id_value))
    quest_ids.sort()
    for quest_id in quest_ids:
        var state: Dictionary = _states.get(quest_id, {})
        if str(state.get("status", "")) != "active":
            continue
        var quest: Dictionary = _runtime.get_quest(quest_id)
        if quest.is_empty():
            continue
        _apply_event_to_quest(quest_id, quest, state, event)


func _apply_event_to_quest(quest_id: String, quest: Dictionary, state: Dictionary, event: Dictionary) -> void:
    var progress: Dictionary = state.get("objective_progress", {}).duplicate(true)
    var changed := false
    for objective_value in quest.get("objectives", []):
        if not objective_value is Dictionary:
            continue
        var objective: Dictionary = objective_value
        if str(objective.get("event_key", "")) != str(event.get("kind", "")):
            continue
        if not _event_matches_target(objective, event):
            continue
        var objective_id := str(objective.get("objective_id", ""))
        var required := int(objective.get("required_count", 1))
        var current := int(progress.get(objective_id, 0))
        if current >= required:
            continue
        var payload: Dictionary = event.get("payload", {}) if event.get("payload", {}) is Dictionary else {}
        var increment := maxi(1, int(payload.get("count", 1)))
        var next := mini(required, current + increment)
        progress[objective_id] = next
        changed = true
        _runtime.emit_event("quest.objective_progress", "", "", {"quest_id": quest_id, "objective_id": objective_id, "current": next, "required": required})
    if not changed:
        return
    state["objective_progress"] = progress
    if _required_objectives_complete(quest, progress):
        state["status"] = "completed"
        _states[quest_id] = state
        _runtime.emit_event("quest.completed", "", "", {"quest_id": quest_id})
        return
    _states[quest_id] = state


static func _event_matches_target(objective: Dictionary, event: Dictionary) -> bool:
    var target = objective.get("target_entity_id")
    if target == null or str(target).is_empty():
        return true
    var target_id := str(target)
    var event_target := "" if event.get("target_entity_id") == null else str(event.get("target_entity_id"))
    var event_source := "" if event.get("source_entity_id") == null else str(event.get("source_entity_id"))
    return target_id == event_target or target_id == event_source


static func _required_objectives_complete(quest: Dictionary, progress: Dictionary) -> bool:
    for objective_value in quest.get("objectives", []):
        if not objective_value is Dictionary:
            continue
        var objective: Dictionary = objective_value
        if bool(objective.get("optional", false)):
            continue
        var objective_id := str(objective.get("objective_id", ""))
        if int(progress.get(objective_id, 0)) < int(objective.get("required_count", 1)):
            return false
    return true


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
