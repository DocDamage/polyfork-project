class_name PlayWorldRuntimeEntityBridge
extends Node3D

const StableId = preload("res://src/world/stable_id.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const RuntimeEntityNode = preload("res://src/editor/runtime_entity_node.gd")

var _runtime_nodes: Dictionary = {}
var _records: Dictionary = {}


func rebuild(records: Array) -> Dictionary:
    var staged_nodes: Dictionary = {}
    var staged_records: Dictionary = {}
    var parent_ids: Dictionary = {}

    for item in records:
        if not item is Dictionary:
            _free_staged(staged_nodes)
            return _failure("Runtime entity bridge records must be dictionaries.")

        var record: Dictionary = item
        var errors: Array[String] = WorldEntity.validate_dictionary(record)
        if not errors.is_empty():
            _free_staged(staged_nodes)
            return {"ok": false, "errors": errors}

        var entity_id := str(record.get("entity_id", ""))
        if staged_nodes.has(entity_id):
            _free_staged(staged_nodes)
            return _failure("Runtime entity bridge received a duplicate entity ID.")

        var runtime_node = RuntimeEntityNode.new()
        var node_errors: Array[String] = runtime_node.apply_record(record)
        if not node_errors.is_empty():
            runtime_node.free()
            _free_staged(staged_nodes)
            return {"ok": false, "errors": node_errors}

        staged_nodes[entity_id] = runtime_node
        staged_records[entity_id] = record.duplicate(true)
        parent_ids[entity_id] = _optional_id(record.get("parent_entity_id"))

    for entity_id in staged_nodes.keys():
        var parent_id: String = str(parent_ids[entity_id])
        if parent_id.is_empty():
            continue
        if parent_id == entity_id:
            _free_staged(staged_nodes)
            return _failure("Runtime entity cannot parent itself.")
        if not staged_nodes.has(parent_id):
            _free_staged(staged_nodes)
            return _failure("Runtime entity parent reference does not resolve in the bridge.")

    if _contains_parent_cycle(parent_ids):
        _free_staged(staged_nodes)
        return _failure("Runtime entity hierarchy contains a parent cycle.")

    _clear_runtime_nodes()
    _runtime_nodes = staged_nodes
    _records = staged_records

    var children_by_parent: Dictionary = {}
    for entity_id in parent_ids.keys():
        var parent_id: String = str(parent_ids[entity_id])
        if parent_id.is_empty():
            continue
        if not children_by_parent.has(parent_id):
            children_by_parent[parent_id] = []
        children_by_parent[parent_id].append(str(entity_id))

    for child_ids in children_by_parent.values():
        child_ids.sort()

    for entity_id in entity_ids():
        if str(parent_ids[entity_id]).is_empty():
            _attach_subtree(entity_id, self, children_by_parent)

    return {"ok": true, "errors": [], "count": _runtime_nodes.size()}


func clear_entities() -> void:
    _clear_runtime_nodes()


func entity_count() -> int:
    return _runtime_nodes.size()


func entity_ids() -> Array[String]:
    var result: Array[String] = []
    for entity_id in _runtime_nodes.keys():
        result.append(str(entity_id))
    result.sort()
    return result


func has_entity(entity_id: String) -> bool:
    return _runtime_nodes.has(entity_id)


func get_entity_node(entity_id: String):
    return _runtime_nodes.get(entity_id)


func get_entity_record(entity_id: String) -> Dictionary:
    if not _records.has(entity_id):
        return {}
    return _records[entity_id].duplicate(true)


func resolve_entity_id(node: Node) -> String:
    var current := node
    while current != null and current != self:
        if current.has_meta(RuntimeEntityNode.ENTITY_ID_META):
            var candidate := str(current.get_meta(RuntimeEntityNode.ENTITY_ID_META))
            if StableId.is_valid(candidate) and _runtime_nodes.has(candidate):
                return candidate
        current = current.get_parent()
    return ""


func _attach_subtree(entity_id: String, parent: Node, children_by_parent: Dictionary) -> void:
    var runtime_node: Node = _runtime_nodes[entity_id]
    parent.add_child(runtime_node)
    for child_id in children_by_parent.get(entity_id, []):
        _attach_subtree(str(child_id), runtime_node, children_by_parent)


func _contains_parent_cycle(parent_ids: Dictionary) -> bool:
    for entity_id in parent_ids.keys():
        var seen: Dictionary = {}
        var current := str(entity_id)
        while not current.is_empty():
            if seen.has(current):
                return true
            seen[current] = true
            current = str(parent_ids.get(current, ""))
    return false


func _clear_runtime_nodes() -> void:
    for child in get_children():
        remove_child(child)
        child.free()
    _runtime_nodes.clear()
    _records.clear()


func _free_staged(staged_nodes: Dictionary) -> void:
    for runtime_node in staged_nodes.values():
        if is_instance_valid(runtime_node):
            runtime_node.free()


func _optional_id(value: Variant) -> String:
    return "" if value == null else str(value)


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
