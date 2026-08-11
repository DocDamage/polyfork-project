class_name PlayWorldEntityRegistry
extends RefCounted

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
