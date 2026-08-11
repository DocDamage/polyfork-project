extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const EntityRegistry = preload("res://src/world/entity_registry.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var cell_id := StableId.generate()
    var entity = WorldEntity.new()
    entity.initialize_new("Tree", cell_id)

    if not StableId.is_valid(entity.entity_id):
        errors.append("New entity must receive a stable UUID.")
    if not entity.validate().is_empty():
        errors.append("New entity record must validate.")

    entity.asset_id = StableId.generate()
    entity.prefab_id = StableId.generate()
    entity.parent_entity_id = StableId.generate()
    entity.component_instance_ids = [StableId.generate(), StableId.generate()]
    entity.transform = {
        "position": [1.0, 2.0, 3.0],
        "rotation_degrees": [0.0, 90.0, 0.0],
        "scale": [1.0, 1.0, 1.0]
    }
    if not entity.validate().is_empty():
        errors.append("Entity stable-reference fields and transform must validate.")

    var dictionary := entity.to_dictionary()
    var reloaded = WorldEntity.new()
    var load_errors: Array[String] = reloaded.load_dictionary(dictionary)
    if not load_errors.is_empty():
        errors.append("Serialized entity record must reload cleanly: " + str(load_errors))
    elif reloaded.entity_id != entity.entity_id or reloaded.parent_entity_id != entity.parent_entity_id:
        errors.append("Reloaded entity must preserve stable identity references.")

    var invalid := dictionary.duplicate(true)
    invalid["parent_entity_id"] = "../SomeNode"
    if WorldEntity.validate_dictionary(invalid).is_empty():
        errors.append("Scene-tree-style parent references must not validate as stable IDs.")

    var registry = EntityRegistry.new()
    var add_result: Dictionary = registry.add(entity)
    if not add_result.get("ok", false):
        errors.append("Valid entity must register successfully.")
    if registry.get_entity(entity.entity_id) != entity:
        errors.append("Registry lookup must return the registered entity by stable ID.")
    if registry.size() != 1 or not registry.has_entity(entity.entity_id):
        errors.append("Registry size/contains state must track additions.")

    var duplicate_result: Dictionary = registry.add(entity)
    if duplicate_result.get("ok", false):
        errors.append("Registry must reject duplicate stable entity IDs.")

    var second = WorldEntity.new()
    second.initialize_new("Rock", cell_id)
    if not registry.add(second).get("ok", false):
        errors.append("Registry must accept a second unique entity.")
    if registry.ids().size() != 2:
        errors.append("Registry IDs must enumerate both unique entities.")

    var remove_result: Dictionary = registry.remove(entity.entity_id)
    if not remove_result.get("ok", false) or registry.has_entity(entity.entity_id):
        errors.append("Registry removal must remove the entity by stable ID.")
    if registry.remove(entity.entity_id).get("ok", false):
        errors.append("Registry must reject removing an entity that is no longer registered.")

    return errors
