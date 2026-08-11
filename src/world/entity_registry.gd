class_name PlayWorldEntityRegistry
extends RefCounted

const WorldEntity = preload("res://src/world/world_entity.gd")

var _entities: Dictionary = {}


func add(entity) -> Dictionary:
    if entity == null:
        return _failure("Entity is required.")

    var errors: Array[String] = entity.validate()
    if not errors.is_empty():
        return {"ok": false, "errors": errors, "entity": null}
    if _entities.has(entity.entity_id):
        return _failure("Entity ID is already registered.")

    _entities[entity.entity_id] = entity
    return {"ok": true, "errors": [], "entity": entity}


func remove(entity_id: String) -> Dictionary:
    if not _entities.has(entity_id):
        return _failure("Entity ID is not registered.")
    var entity = _entities[entity_id]
    _entities.erase(entity_id)
    return {"ok": true, "errors": [], "entity": entity}


func load_dictionaries(records: Array) -> Dictionary:
    var staged: Dictionary = {}
    for record in records:
        if not record is Dictionary:
            return _failure("Entity registry records must be dictionaries.")
        var entity = WorldEntity.new()
        var errors: Array[String] = entity.load_dictionary(record)
        if not errors.is_empty():
            return {"ok": false, "errors": errors, "entity": null}
        if staged.has(entity.entity_id):
            return _failure("Entity registry records contain a duplicate entity ID.")
        staged[entity.entity_id] = entity

    for entity in staged.values():
        if entity.parent_entity_id.is_empty():
            continue
        if entity.parent_entity_id == entity.entity_id:
            return _failure("Entity cannot parent itself.")
        if not staged.has(entity.parent_entity_id):
            return _failure("Entity parent reference does not resolve in the registry.")

    _entities = staged
    return {"ok": true, "errors": [], "entity": null}


func to_dictionaries() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for entity_id in ids():
        result.append(_entities[entity_id].to_dictionary())
    return result


func get_entity(entity_id: String):
    return _entities.get(entity_id)


func has_entity(entity_id: String) -> bool:
    return _entities.has(entity_id)


func size() -> int:
    return _entities.size()


func ids() -> Array[String]:
    var result: Array[String] = []
    for entity_id in _entities.keys():
        result.append(str(entity_id))
    result.sort()
    return result


func entities() -> Array:
    var result: Array = []
    for entity_id in ids():
        result.append(_entities[entity_id])
    return result


func clear() -> void:
    _entities.clear()


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message], "entity": null}
