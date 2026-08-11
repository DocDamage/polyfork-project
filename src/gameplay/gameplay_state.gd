class_name PlayWorldGameplayState
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")

var definitions: Array[Dictionary] = []
var instances: Array[Dictionary] = []
var archetypes: Array[Dictionary] = []
var prefabs: Array[Dictionary] = []
var sockets: Array[Dictionary] = []
var attachments: Array[Dictionary] = []
var prefab_instances: Array[Dictionary] = []


func validate(project = null) -> Array[String]:
    var errors: Array[String] = []
    _validate_unique(definitions, "definition_id", Callable(Contracts, "validate_component_definition"), errors)
    _validate_unique(instances, "instance_id", Callable(Contracts, "validate_component_instance"), errors)
    _validate_unique(archetypes, "archetype_id", Callable(Contracts, "validate_archetype"), errors)
    _validate_unique(prefabs, "prefab_id", Callable(Contracts, "validate_prefab"), errors)
    _validate_unique(sockets, "socket_id", Callable(Contracts, "validate_socket"), errors)
    _validate_unique(attachments, "attachment_id", Callable(Contracts, "validate_attachment"), errors)
    _validate_unique(prefab_instances, "instance_id", Callable(Contracts, "validate_prefab_instance"), errors)
    _validate_definition_links(errors)
    _validate_instance_links(project, errors)
    _validate_archetype_links(errors)
    _validate_prefab_links(errors)
    _validate_socket_links(project, errors)
    _validate_attachment_links(project, errors)
    _validate_prefab_instance_links(project, errors)
    return errors


func get_definition(definition_id: String) -> Dictionary: return _find(definitions, "definition_id", definition_id)
func get_definition_by_key(key: String) -> Dictionary: return _find(definitions, "key", key)
func get_instance(instance_id: String) -> Dictionary: return _find(instances, "instance_id", instance_id)
func get_archetype(archetype_id: String) -> Dictionary: return _find(archetypes, "archetype_id", archetype_id)
func get_prefab(prefab_id: String) -> Dictionary: return _find(prefabs, "prefab_id", prefab_id)
func get_socket(socket_id: String) -> Dictionary: return _find(sockets, "socket_id", socket_id)
func get_attachment(attachment_id: String) -> Dictionary: return _find(attachments, "attachment_id", attachment_id)
func get_prefab_instance(instance_id: String) -> Dictionary: return _find(prefab_instances, "instance_id", instance_id)


func instances_for_entity(entity_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for record in instances:
        if str(record.get("owner_entity_id", "")) == entity_id: result.append(record.duplicate(true))
    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("definition_id", "")) < str(b.get("definition_id", "")))
    return result


func sockets_for_owner(owner_kind: String, owner_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for record in sockets:
        if str(record.get("owner_kind", "")) == owner_kind and str(record.get("owner_id", "")) == owner_id: result.append(record.duplicate(true))
    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("name", "")) < str(b.get("name", "")))
    return result


func attachments_for_entity(entity_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for record in attachments:
        if str(record.get("parent_entity_id", "")) == entity_id or str(record.get("child_entity_id", "")) == entity_id: result.append(record.duplicate(true))
    return result


func prefab_instance_for_root(entity_id: String) -> Dictionary: return _find(prefab_instances, "root_entity_id", entity_id)


func definition_ids_for_entity(entity_id: String) -> Array[String]:
    var result: Array[String] = []
    for record in instances_for_entity(entity_id): result.append(str(record.get("definition_id", "")))
    result.sort()
    return result


func dependency_plan(definition_id: String, existing: Array[String] = []) -> Dictionary:
    if get_definition(definition_id).is_empty(): return _failure("Component definition is not registered.")
    var existing_set: Dictionary = {}
    for item in existing: existing_set[item] = true
    var visiting: Dictionary = {}
    var visited: Dictionary = {}
    var ordered: Array[String] = []
    var error := _visit_dependency(definition_id, existing_set, visiting, visited, ordered)
    if not error.is_empty(): return _failure(error)
    return {"ok": true, "errors": [], "definition_ids": ordered}


func conflict_for(definition_id: String, existing: Array[String]) -> Dictionary:
    var definition := get_definition(definition_id)
    if definition.is_empty(): return _failure("Component definition is not registered.")
    for existing_id in existing:
        var existing_definition := get_definition(existing_id)
        if existing_definition.is_empty(): continue
        if definition.get("conflicts", []).has(existing_id) or existing_definition.get("conflicts", []).has(definition_id):
            return {"ok": true, "errors": [], "conflict": true, "definition_id": definition_id, "with_definition_id": existing_id}
    return {"ok": true, "errors": [], "conflict": false}


func add_instance(record: Dictionary) -> Dictionary:
    var errors := Contracts.validate_component_instance(record)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    if not get_instance(str(record.get("instance_id", ""))).is_empty(): return _failure("Component instance ID already exists.")
    var definition := get_definition(str(record.get("definition_id", "")))
    if definition.is_empty(): return _failure("Component instance definition does not resolve.")
    var value_errors := Contracts.validate_values(record.get("values", {}), definition)
    if not value_errors.is_empty(): return {"ok": false, "errors": value_errors}
    for existing in instances_for_entity(str(record.get("owner_entity_id", ""))):
        if existing.get("definition_id") == record.get("definition_id"): return _failure("Entity already has this component definition.")
    instances.append(record.duplicate(true))
    return {"ok": true, "errors": []}


func replace_instance(record: Dictionary) -> Dictionary:
    var index := _index(instances, "instance_id", str(record.get("instance_id", "")))
    if index < 0: return _failure("Component instance does not exist.")
    var definition := get_definition(str(record.get("definition_id", "")))
    var errors := Contracts.validate_component_instance(record)
    if definition.is_empty(): errors.append("Component instance definition does not resolve.")
    else: errors.append_array(Contracts.validate_values(record.get("values", {}), definition))
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    instances[index] = record.duplicate(true)
    return {"ok": true, "errors": []}


func remove_instance(instance_id: String) -> Dictionary:
    var index := _index(instances, "instance_id", instance_id)
    if index < 0: return _failure("Component instance does not exist.")
    var removed: Dictionary = instances[index].duplicate(true)
    instances.remove_at(index)
    return {"ok": true, "errors": [], "record": removed}


func put_prefab(record: Dictionary) -> Dictionary: return _put(prefabs, "prefab_id", record, Callable(Contracts, "validate_prefab"))
func put_socket(record: Dictionary) -> Dictionary: return _put(sockets, "socket_id", record, Callable(Contracts, "validate_socket"))
func put_attachment(record: Dictionary) -> Dictionary: return _put(attachments, "attachment_id", record, Callable(Contracts, "validate_attachment"))
func put_prefab_instance(record: Dictionary) -> Dictionary: return _put(prefab_instances, "instance_id", record, Callable(Contracts, "validate_prefab_instance"))
func remove_socket(socket_id: String) -> Dictionary: return _remove(sockets, "socket_id", socket_id)
func remove_attachment(attachment_id: String) -> Dictionary: return _remove(attachments, "attachment_id", attachment_id)
func remove_prefab_instance(instance_id: String) -> Dictionary: return _remove(prefab_instances, "instance_id", instance_id)


func _validate_definition_links(errors: Array[String]) -> void:
    var keys: Dictionary = {}
    for definition in definitions:
        var key := str(definition.get("key", ""))
        if keys.has(key): errors.append("Component definitions contain duplicate keys.")
        keys[key] = true
        for linked_id in definition.get("dependencies", []) + definition.get("conflicts", []):
            if get_definition(str(linked_id)).is_empty(): errors.append("Component definition references an unknown dependency/conflict ID.")
    for definition in definitions:
        var plan := dependency_plan(str(definition.get("definition_id", "")))
        if not plan.get("ok", false): errors.append_array(plan.get("errors", []))


func _validate_instance_links(project, errors: Array[String]) -> void:
    var owner_defs: Dictionary = {}
    for record in instances:
        var definition := get_definition(str(record.get("definition_id", "")))
        if definition.is_empty(): errors.append("Component instance references an unknown definition."); continue
        errors.append_array(Contracts.validate_values(record.get("values", {}), definition))
        var owner_id := str(record.get("owner_entity_id", ""))
        if project != null and not _project_has_entity(project, owner_id): errors.append("Component instance owner_entity_id does not resolve in the world project.")
        var key := "%s:%s" % [owner_id, record.get("definition_id")]
        if owner_defs.has(key): errors.append("An entity cannot contain duplicate instances of the same component definition.")
        owner_defs[key] = true


func _validate_archetype_links(errors: Array[String]) -> void:
    var keys: Dictionary = {}
    for archetype in archetypes:
        var key := str(archetype.get("key", ""))
        if keys.has(key): errors.append("Archetypes contain duplicate keys.")
        keys[key] = true
        for definition_id in archetype.get("required_definition_ids", []):
            if get_definition(str(definition_id)).is_empty(): errors.append("Archetype references an unknown component definition.")
        for definition_id in archetype.get("component_defaults", {}).keys():
            var definition := get_definition(str(definition_id))
            if definition.is_empty(): errors.append("Archetype defaults reference an unknown component definition.")
            else: errors.append_array(Contracts.validate_values(archetype["component_defaults"][definition_id], definition, true))


func _validate_prefab_links(errors: Array[String]) -> void:
    for prefab in prefabs:
        var base = prefab.get("base_prefab_id")
        if base != null and not str(base).is_empty() and get_prefab(str(base)).is_empty(): errors.append("Prefab base_prefab_id does not resolve.")
        for node in prefab.get("nodes", []):
            if node is Dictionary:
                for definition_id in node.get("components", {}).keys():
                    var definition := get_definition(str(definition_id))
                    if definition.is_empty(): errors.append("Prefab node references an unknown component definition.")
                    else: errors.append_array(Contracts.validate_values(node["components"][definition_id], definition))
        var cycle := _prefab_cycle(str(prefab.get("prefab_id", "")))
        if not cycle.is_empty(): errors.append(cycle)


func _validate_socket_links(project, errors: Array[String]) -> void:
    var owner_names: Dictionary = {}
    for socket in sockets:
        var owner_kind := str(socket.get("owner_kind", "")); var owner_id := str(socket.get("owner_id", ""))
        if owner_kind == "entity" and project != null and not _project_has_entity(project, owner_id): errors.append("Entity socket owner does not resolve in the world project.")
        if owner_kind == "prefab_node" and not _prefab_node_exists(owner_id): errors.append("Prefab socket owner node does not resolve.")
        var unique_key := "%s:%s:%s" % [owner_kind, owner_id, str(socket.get("name", "")).to_lower()]
        if owner_names.has(unique_key): errors.append("Socket names must be unique per owner.")
        owner_names[unique_key] = true


func _validate_attachment_links(project, errors: Array[String]) -> void:
    var child_owner: Dictionary = {}
    for attachment in attachments:
        var parent_id := str(attachment.get("parent_entity_id", "")); var child_id := str(attachment.get("child_entity_id", ""))
        if project != null and (not _project_has_entity(project, parent_id) or not _project_has_entity(project, child_id)): errors.append("Attachment entity reference does not resolve.")
        var socket := get_socket(str(attachment.get("parent_socket_id", "")))
        if socket.is_empty() or str(socket.get("owner_kind", "")) != "entity" or str(socket.get("owner_id", "")) != parent_id: errors.append("Attachment parent_socket_id must belong to parent_entity_id.")
        var child_socket = attachment.get("child_socket_id")
        if child_socket != null and not str(child_socket).is_empty():
            var resolved := get_socket(str(child_socket))
            if resolved.is_empty() or str(resolved.get("owner_kind", "")) != "entity" or str(resolved.get("owner_id", "")) != child_id: errors.append("Attachment child_socket_id must belong to child_entity_id.")
        if child_owner.has(child_id): errors.append("An entity may have only one active socket attachment parent.")
        child_owner[child_id] = true


func _validate_prefab_instance_links(project, errors: Array[String]) -> void:
    for record in prefab_instances:
        if get_prefab(str(record.get("prefab_id", ""))).is_empty(): errors.append("Prefab instance references an unknown prefab.")
        if project != null:
            if not _project_has_entity(project, str(record.get("root_entity_id", ""))): errors.append("Prefab instance root entity does not resolve.")
            for entity_id in record.get("node_entity_ids", {}).values():
                if not _project_has_entity(project, str(entity_id)): errors.append("Prefab instance node entity does not resolve.")


func _visit_dependency(definition_id: String, existing: Dictionary, visiting: Dictionary, visited: Dictionary, ordered: Array[String]) -> String:
    if existing.has(definition_id) or visited.has(definition_id): return ""
    if visiting.has(definition_id): return "Component dependency cycle detected."
    var definition := get_definition(definition_id)
    if definition.is_empty(): return "Component dependency does not resolve."
    visiting[definition_id] = true
    var dependencies: Array = definition.get("dependencies", []).duplicate(); dependencies.sort()
    for dependency_id in dependencies:
        var error := _visit_dependency(str(dependency_id), existing, visiting, visited, ordered)
        if not error.is_empty(): return error
    visiting.erase(definition_id); visited[definition_id] = true; ordered.append(definition_id)
    return ""


func _prefab_cycle(prefab_id: String) -> String:
    var seen: Dictionary = {}; var current := prefab_id
    while not current.is_empty():
        if seen.has(current): return "Prefab inheritance cycle detected."
        seen[current] = true
        var prefab := get_prefab(current)
        if prefab.is_empty(): return ""
        var base = prefab.get("base_prefab_id")
        current = "" if base == null else str(base)
    return ""


func _prefab_node_exists(node_id: String) -> bool:
    for prefab in prefabs:
        for node in prefab.get("nodes", []):
            if node is Dictionary and str(node.get("node_id", "")) == node_id: return true
    return false


static func _project_has_entity(project, entity_id: String) -> bool:
    for record in project.entity_records:
        if str(record.get("entity_id", "")) == entity_id: return true
    return false


static func _validate_unique(records: Array[Dictionary], id_field: String, validator: Callable, errors: Array[String]) -> void:
    var seen: Dictionary = {}
    for record in records:
        errors.append_array(validator.call(record))
        var id := str(record.get(id_field, ""))
        if seen.has(id): errors.append("Gameplay registry contains duplicate %s." % id_field)
        seen[id] = true


static func _find(records: Array[Dictionary], key: String, value: String) -> Dictionary:
    for record in records:
        if str(record.get(key, "")) == value: return record.duplicate(true)
    return {}


static func _index(records: Array[Dictionary], key: String, value: String) -> int:
    for index in range(records.size()):
        if str(records[index].get(key, "")) == value: return index
    return -1


static func _put(records: Array[Dictionary], id_field: String, record: Dictionary, validator: Callable) -> Dictionary:
    var errors: Array = validator.call(record)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    var index := _index(records, id_field, str(record.get(id_field, "")))
    if index < 0: records.append(record.duplicate(true))
    else: records[index] = record.duplicate(true)
    return {"ok": true, "errors": []}


static func _remove(records: Array[Dictionary], id_field: String, id: String) -> Dictionary:
    var index := _index(records, id_field, id)
    if index < 0: return _failure("Gameplay record does not exist.")
    var record: Dictionary = records[index].duplicate(true); records.remove_at(index)
    return {"ok": true, "errors": [], "record": record}


static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
