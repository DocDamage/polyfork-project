class_name PlayWorldRuntimeGameplayState
extends RefCounted

signal gameplay_event(event: Dictionary)

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")

var _loaded := false
var _project_data: Dictionary = {}
var _definitions_by_id: Dictionary = {}
var _definition_ids_by_key: Dictionary = {}
var _instances_by_id: Dictionary = {}
var _entity_instance_ids: Dictionary = {}
var _runtime_values: Dictionary = {}
var _sockets: Array[Dictionary] = []
var _attachments: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _next_event_sequence := 1


func initialize(project_data: Dictionary, gameplay_snapshot: Dictionary) -> Dictionary:
    clear()
    var errors := _validate_and_index(project_data, gameplay_snapshot)
    if not errors.is_empty():
        clear()
        return {"ok": false, "errors": errors}
    _project_data = project_data.duplicate(true)
    _loaded = true
    return {
        "ok": true,
        "errors": [],
        "entity_count": _entity_instance_ids.size(),
        "component_count": _instances_by_id.size(),
    }


func clear() -> void:
    _loaded = false
    _project_data.clear()
    _definitions_by_id.clear()
    _definition_ids_by_key.clear()
    _instances_by_id.clear()
    _entity_instance_ids.clear()
    _runtime_values.clear()
    _sockets.clear()
    _attachments.clear()
    _events.clear()
    _next_event_sequence = 1


func is_loaded() -> bool:
    return _loaded


func has_entity(entity_id: String) -> bool:
    return _entity_instance_ids.has(entity_id)


func has_component(entity_id: String, component_key: String) -> bool:
    return not get_component(entity_id, component_key).is_empty()


func get_component(entity_id: String, component_key: String) -> Dictionary:
    var definition_id := str(_definition_ids_by_key.get(component_key, ""))
    if definition_id.is_empty():
        return {}
    for instance_id_value in _entity_instance_ids.get(entity_id, []):
        var instance_id := str(instance_id_value)
        var instance: Dictionary = _instances_by_id.get(instance_id, {})
        if str(instance.get("definition_id", "")) != definition_id:
            continue
        return {
            "instance_id": instance_id,
            "definition_id": definition_id,
            "key": component_key,
            "owner_entity_id": entity_id,
            "values": _runtime_values.get(instance_id, {}).duplicate(true),
        }
    return {}


func get_component_values(entity_id: String, component_key: String) -> Dictionary:
    return get_component(entity_id, component_key).get("values", {}).duplicate(true)


func component_keys_for_entity(entity_id: String) -> Array[String]:
    var result: Array[String] = []
    for instance_id_value in _entity_instance_ids.get(entity_id, []):
        var instance: Dictionary = _instances_by_id.get(str(instance_id_value), {})
        var definition: Dictionary = _definitions_by_id.get(str(instance.get("definition_id", "")), {})
        var key := str(definition.get("key", ""))
        if not key.is_empty():
            result.append(key)
    result.sort()
    return result


func set_component_value(entity_id: String, component_key: String, property_name: String, value: Variant) -> Dictionary:
    var component := get_component(entity_id, component_key)
    if component.is_empty():
        return _failure("Runtime component does not exist: %s/%s" % [entity_id, component_key])
    var definition: Dictionary = _definitions_by_id.get(str(component.get("definition_id", "")), {})
    var values: Dictionary = component.get("values", {}).duplicate(true)
    values[property_name] = value
    var validation_errors := Contracts.validate_values(values, definition)
    if not validation_errors.is_empty():
        return {"ok": false, "errors": validation_errors}
    _runtime_values[str(component.get("instance_id", ""))] = values
    return {"ok": true, "errors": [], "entity_id": entity_id, "component_key": component_key, "values": values.duplicate(true)}


func patch_component_values(entity_id: String, component_key: String, patch: Dictionary) -> Dictionary:
    var component := get_component(entity_id, component_key)
    if component.is_empty():
        return _failure("Runtime component does not exist: %s/%s" % [entity_id, component_key])
    var values: Dictionary = component.get("values", {}).duplicate(true)
    for key in patch.keys():
        values[key] = patch[key]
    var definition: Dictionary = _definitions_by_id.get(str(component.get("definition_id", "")), {})
    var validation_errors := Contracts.validate_values(values, definition)
    if not validation_errors.is_empty():
        return {"ok": false, "errors": validation_errors}
    _runtime_values[str(component.get("instance_id", ""))] = values
    return {"ok": true, "errors": [], "entity_id": entity_id, "component_key": component_key, "values": values.duplicate(true)}


func emit_event(kind: String, source_entity_id: String = "", target_entity_id: String = "", payload: Dictionary = {}) -> Dictionary:
    if kind.strip_edges().is_empty():
        return _failure("Gameplay event kind is required.")
    if not source_entity_id.is_empty() and not has_entity(source_entity_id):
        return _failure("Gameplay event source entity does not exist.")
    if not target_entity_id.is_empty() and not has_entity(target_entity_id):
        return _failure("Gameplay event target entity does not exist.")
    var event := {
        "event_id": StableId.generate(),
        "sequence": _next_event_sequence,
        "kind": kind,
        "source_entity_id": source_entity_id if not source_entity_id.is_empty() else null,
        "target_entity_id": target_entity_id if not target_entity_id.is_empty() else null,
        "payload": payload.duplicate(true),
    }
    _next_event_sequence += 1
    _events.append(event)
    gameplay_event.emit(event.duplicate(true))
    return {"ok": true, "errors": [], "event": event.duplicate(true)}


func events_after(sequence: int = 0) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for event in _events:
        if int(event.get("sequence", 0)) > sequence:
            result.append(event.duplicate(true))
    return result


func get_runtime_snapshot() -> Dictionary:
    var values: Dictionary = {}
    for instance_id in _runtime_values.keys():
        values[str(instance_id)] = _runtime_values[instance_id].duplicate(true)
    return {
        "runtime_values": values,
        "events": events_after(0),
    }


func get_authored_project_copy() -> Dictionary:
    return _project_data.duplicate(true)


func _validate_and_index(project_data: Dictionary, gameplay_snapshot: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    var entity_ids: Dictionary = {}
    var entities = project_data.get("entities", [])
    if not entities is Array:
        return ["Runtime gameplay initialization requires project entities."]
    for entity in entities:
        if not entity is Dictionary:
            errors.append("Runtime gameplay project entity must be a dictionary.")
            continue
        var entity_id := str(entity.get("entity_id", ""))
        if not StableId.is_valid(entity_id):
            errors.append("Runtime gameplay project entity has an invalid stable ID.")
            continue
        if entity_ids.has(entity_id):
            errors.append("Runtime gameplay project contains duplicate entity IDs.")
            continue
        entity_ids[entity_id] = true
        _entity_instance_ids[entity_id] = []

    var definitions = gameplay_snapshot.get("definitions", [])
    if not definitions is Array:
        errors.append("Runtime gameplay snapshot definitions must be an array.")
        definitions = []
    for definition in definitions:
        if not definition is Dictionary:
            errors.append("Runtime gameplay component definition must be a dictionary.")
            continue
        var definition_errors := Contracts.validate_component_definition(definition)
        errors.append_array(definition_errors)
        var definition_id := str(definition.get("definition_id", ""))
        var key := str(definition.get("key", ""))
        if _definitions_by_id.has(definition_id) or _definition_ids_by_key.has(key):
            errors.append("Runtime gameplay snapshot contains duplicate component definitions.")
            continue
        _definitions_by_id[definition_id] = definition.duplicate(true)
        _definition_ids_by_key[key] = definition_id

    var instances = gameplay_snapshot.get("instances", [])
    if not instances is Array:
        errors.append("Runtime gameplay snapshot instances must be an array.")
        instances = []
    for instance in instances:
        if not instance is Dictionary:
            errors.append("Runtime gameplay component instance must be a dictionary.")
            continue
        var instance_errors := Contracts.validate_component_instance(instance)
        errors.append_array(instance_errors)
        var instance_id := str(instance.get("instance_id", ""))
        var definition_id := str(instance.get("definition_id", ""))
        var owner_entity_id := str(instance.get("owner_entity_id", ""))
        if _instances_by_id.has(instance_id):
            errors.append("Runtime gameplay snapshot contains duplicate component instance IDs.")
            continue
        if not _definitions_by_id.has(definition_id):
            errors.append("Runtime gameplay component definition reference does not resolve.")
            continue
        if not entity_ids.has(owner_entity_id):
            errors.append("Runtime gameplay component owner entity does not resolve.")
            continue
        var definition: Dictionary = _definitions_by_id[definition_id]
        var values: Dictionary = instance.get("values", {}).duplicate(true)
        var value_errors := Contracts.validate_values(values, definition)
        if not value_errors.is_empty():
            errors.append_array(value_errors)
            continue
        _instances_by_id[instance_id] = instance.duplicate(true)
        _runtime_values[instance_id] = values
        var owner_instances: Array = _entity_instance_ids.get(owner_entity_id, []).duplicate()
        owner_instances.append(instance_id)
        _entity_instance_ids[owner_entity_id] = owner_instances

    _sockets = _copy_dictionary_array(gameplay_snapshot.get("sockets", []))
    _attachments = _copy_dictionary_array(gameplay_snapshot.get("attachments", []))
    return errors


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
