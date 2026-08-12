class_name PlayWorldRuntimeEntityBridge
extends Node3D

const StableId = preload("res://src/world/stable_id.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const RuntimeEntityNode = preload("res://src/editor/runtime_entity_node.gd")

var _runtime_nodes: Dictionary = {}
var _records: Dictionary = {}
var _all_records: Array[Dictionary] = []
var _asset_resolver := Callable()
var _cell_filter_enabled = false
var _active_cell_ids: Dictionary = {}
var _excluded_entity_ids: Dictionary = {}


func bind_asset_resolver(resolver: Callable) -> void:
    _asset_resolver = resolver


func rebuild(records: Array) -> Dictionary:
    var record_map: Dictionary = {}
    var parent_ids: Dictionary = {}
    var validated_records: Array[Dictionary] = []
    for item in records:
        if not item is Dictionary: return _failure("Runtime entity bridge records must be dictionaries.")
        var record: Dictionary = item
        var errors: Array[String] = WorldEntity.validate_dictionary(record)
        if not errors.is_empty(): return {"ok": false, "errors": errors}
        var entity_id: String = str(record.get("entity_id", ""))
        if record_map.has(entity_id): return _failure("Runtime entity bridge received a duplicate entity ID.")
        record_map[entity_id] = record.duplicate(true)
        parent_ids[entity_id] = _optional_id(record.get("parent_entity_id"))
        validated_records.append(record.duplicate(true))

    for entity_id in record_map.keys():
        var parent_id: String = str(parent_ids[entity_id])
        if parent_id.is_empty(): continue
        if parent_id == entity_id: return _failure("Runtime entity cannot parent itself.")
        if not record_map.has(parent_id): return _failure("Runtime entity parent reference does not resolve in the project record set.")
    if _contains_parent_cycle(parent_ids): return _failure("Runtime entity hierarchy contains a parent cycle.")

    var staged_nodes: Dictionary = {}
    var staged_records: Dictionary = {}
    var ordered_ids: Array[String] = []
    for entity_id in record_map.keys(): ordered_ids.append(str(entity_id))
    ordered_ids.sort()
    for entity_id in ordered_ids:
        var record: Dictionary = record_map[entity_id]
        if not _record_is_active(record): continue
        var runtime_node = RuntimeEntityNode.new()
        var node_errors: Array[String] = runtime_node.apply_record(record)
        if not node_errors.is_empty():
            runtime_node.free(); _free_staged(staged_nodes); return {"ok": false, "errors": node_errors}
        _apply_asset_visual(runtime_node, record)
        staged_nodes[entity_id] = runtime_node
        staged_records[entity_id] = record.duplicate(true)

    _clear_runtime_nodes()
    _runtime_nodes = staged_nodes
    _records = staged_records
    _all_records = validated_records

    var children_by_parent: Dictionary = {}
    var root_ids: Array[String] = []
    for entity_id in entity_ids():
        var parent_id: String = str(parent_ids.get(entity_id, ""))
        if parent_id.is_empty() or not _runtime_nodes.has(parent_id):
            root_ids.append(entity_id); continue
        if not children_by_parent.has(parent_id): children_by_parent[parent_id] = []
        children_by_parent[parent_id].append(entity_id)
    for child_ids in children_by_parent.values(): child_ids.sort()
    root_ids.sort()
    for entity_id in root_ids: _attach_subtree(entity_id, self, children_by_parent)
    return {"ok": true, "errors": [], "count": _runtime_nodes.size(), "total_count": _all_records.size(), "filtered": _cell_filter_enabled, "excluded_count": _excluded_entity_ids.size()}


func set_active_cell_ids(cell_ids: Array) -> Dictionary:
    var staged_filter: Dictionary = {}
    for value in cell_ids:
        var cell_id: String = str(value)
        if not StableId.is_valid(cell_id): return _failure("Runtime entity cell filter contains an invalid stable cell ID.")
        staged_filter[cell_id] = true
    if _cell_filter_enabled and _same_key_set(_active_cell_ids, staged_filter):
        return {"ok": true, "errors": [], "changed": false, "count": _runtime_nodes.size()}
    var previous_enabled: bool = _cell_filter_enabled
    var previous_filter: Dictionary = _active_cell_ids.duplicate()
    _cell_filter_enabled = true; _active_cell_ids = staged_filter
    var result: Dictionary = rebuild(_all_records)
    if not result.get("ok", false):
        _cell_filter_enabled = previous_enabled; _active_cell_ids = previous_filter; rebuild(_all_records)
    else: result["changed"] = true
    return result


func clear_cell_filter() -> Dictionary:
    if not _cell_filter_enabled:
        return {"ok": true, "errors": [], "changed": false, "count": _runtime_nodes.size()}
    var previous_filter: Dictionary = _active_cell_ids.duplicate()
    _cell_filter_enabled = false; _active_cell_ids.clear()
    var result: Dictionary = rebuild(_all_records)
    if not result.get("ok", false):
        _cell_filter_enabled = true; _active_cell_ids = previous_filter; rebuild(_all_records)
    else: result["changed"] = true
    return result


func set_excluded_entity_ids(entity_ids: Array) -> Dictionary:
    var staged: Dictionary = {}
    for value in entity_ids:
        var entity_id := str(value)
        if not StableId.is_valid(entity_id): return _failure("Runtime entity exclusion contains an invalid stable entity ID.")
        staged[entity_id] = true
    if _same_key_set(_excluded_entity_ids, staged):
        return {"ok": true, "errors": [], "changed": false, "count": _runtime_nodes.size()}
    var previous: Dictionary = _excluded_entity_ids.duplicate()
    _excluded_entity_ids = staged
    var result: Dictionary = rebuild(_all_records)
    if not result.get("ok", false):
        _excluded_entity_ids = previous; rebuild(_all_records)
    else: result["changed"] = true
    return result


func clear_excluded_entity_ids() -> Dictionary:
    if _excluded_entity_ids.is_empty(): return {"ok": true, "errors": [], "changed": false, "count": _runtime_nodes.size()}
    var previous: Dictionary = _excluded_entity_ids.duplicate()
    _excluded_entity_ids.clear()
    var result: Dictionary = rebuild(_all_records)
    if not result.get("ok", false):
        _excluded_entity_ids = previous; rebuild(_all_records)
    else: result["changed"] = true
    return result


func get_active_cell_ids() -> Array[String]:
    var result: Array[String] = []
    for cell_id in _active_cell_ids.keys(): result.append(str(cell_id))
    result.sort(); return result


func get_excluded_entity_ids() -> Array[String]:
    var result: Array[String] = []
    for entity_id in _excluded_entity_ids.keys(): result.append(str(entity_id))
    result.sort(); return result


func is_cell_filter_enabled() -> bool: return _cell_filter_enabled
func all_record_count() -> int: return _all_records.size()


func clear_entities() -> void:
    _clear_runtime_nodes(); _all_records.clear()


func entity_count() -> int: return _runtime_nodes.size()
func entity_ids() -> Array[String]:
    var result: Array[String] = []
    for entity_id in _runtime_nodes.keys(): result.append(str(entity_id))
    result.sort(); return result
func has_entity(entity_id: String) -> bool: return _runtime_nodes.has(entity_id)
func get_entity_node(entity_id: String): return _runtime_nodes.get(entity_id)
func get_entity_record(entity_id: String) -> Dictionary: return {} if not _records.has(entity_id) else _records[entity_id].duplicate(true)


func resolve_entity_id(node: Node) -> String:
    var current := node
    while current != null and current != self:
        if current.has_meta(RuntimeEntityNode.ENTITY_ID_META):
            var candidate: String = str(current.get_meta(RuntimeEntityNode.ENTITY_ID_META))
            if StableId.is_valid(candidate) and _runtime_nodes.has(candidate): return candidate
        current = current.get_parent()
    return ""


func _record_is_active(record: Dictionary) -> bool:
    var entity_id := str(record.get("entity_id", ""))
    if _excluded_entity_ids.has(entity_id): return false
    if not _cell_filter_enabled: return true
    return _active_cell_ids.has(str(record.get("cell_id", "")))


func _apply_asset_visual(runtime_node, record: Dictionary) -> void:
    var asset_value = record.get("asset_id")
    if asset_value == null or not _asset_resolver.is_valid(): return
    var result: Variant = _asset_resolver.call(str(asset_value))
    if not result is Dictionary or not result.get("ok", false): runtime_node.set_meta(&"playworld_asset_load_failed", true); return
    var node_value = result.get("node")
    if node_value is Node3D: runtime_node.set_asset_visual(node_value)
    elif node_value is Node: node_value.free(); runtime_node.set_meta(&"playworld_asset_load_failed", true)


func _attach_subtree(entity_id: String, parent: Node, children_by_parent: Dictionary) -> void:
    var runtime_node: Node = _runtime_nodes[entity_id]
    parent.add_child(runtime_node)
    for child_id in children_by_parent.get(entity_id, []): _attach_subtree(str(child_id), runtime_node, children_by_parent)


func _contains_parent_cycle(parent_ids: Dictionary) -> bool:
    for entity_id in parent_ids.keys():
        var seen: Dictionary = {}
        var current: String = str(entity_id)
        while not current.is_empty():
            if seen.has(current): return true
            seen[current] = true; current = str(parent_ids.get(current, ""))
    return false


func _same_key_set(a: Dictionary, b: Dictionary) -> bool:
    if a.size() != b.size(): return false
    for key in a.keys():
        if not b.has(key): return false
    return true


func _clear_runtime_nodes() -> void:
    for child in get_children(): remove_child(child); child.free()
    _runtime_nodes.clear(); _records.clear()


func _free_staged(staged_nodes: Dictionary) -> void:
    for runtime_node in staged_nodes.values():
        if is_instance_valid(runtime_node): runtime_node.free()


func _optional_id(value: Variant) -> String: return "" if value == null else str(value)
func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
