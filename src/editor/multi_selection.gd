class_name PlayWorldMultiSelection
extends RefCounted

signal selection_changed(entity_ids: Array, primary_entity_id: String, runtime_node: Node3D)

var _bridge
var _selected_ids: Array[String] = []
var _primary_entity_id: String = ""


func bind_bridge(bridge) -> Dictionary:
    clear()
    if bridge == null:
        _bridge = null
        return _failure("Multi-selection requires a runtime entity bridge.")
    _bridge = bridge
    return {"ok": true, "errors": []}


func select_single(entity_id: String) -> Dictionary:
    return set_selected([entity_id], entity_id)


func toggle_entity(entity_id: String) -> Dictionary:
    if _bridge == null or not _bridge.has_entity(entity_id):
        return _failure("Selection entity ID is not present in the runtime entity bridge.")
    var next := _selected_ids.duplicate()
    if next.has(entity_id):
        next.erase(entity_id)
        var primary := _primary_entity_id
        if primary == entity_id:
            primary = "" if next.is_empty() else next.back()
        return set_selected(next, primary)
    next.append(entity_id)
    return set_selected(next, entity_id)


func select_node(node: Node, additive: bool = false) -> Dictionary:
    if _bridge == null:
        return _failure("Multi-selection is not bound to a runtime entity bridge.")
    var entity_id: String = _bridge.resolve_entity_id(node)
    if entity_id.is_empty():
        return _failure("Runtime node does not resolve to a bridged entity.")
    return toggle_entity(entity_id) if additive else select_single(entity_id)


func set_selected(entity_ids: Array, primary_entity_id: String = "") -> Dictionary:
    if _bridge == null:
        return _failure("Multi-selection is not bound to a runtime entity bridge.")

    var normalized: Array[String] = []
    for value in entity_ids:
        var entity_id := str(value)
        if entity_id.is_empty() or not _bridge.has_entity(entity_id):
            return _failure("Selection contains an entity ID not present in the runtime entity bridge.")
        if not normalized.has(entity_id):
            normalized.append(entity_id)
    normalized.sort()

    var primary := primary_entity_id
    if normalized.is_empty():
        primary = ""
    elif primary.is_empty() or not normalized.has(primary):
        primary = normalized.back()

    if normalized == _selected_ids and primary == _primary_entity_id:
        return _result(false)

    for entity_id in _selected_ids:
        _set_runtime_selected(entity_id, false)
    _selected_ids = normalized
    _primary_entity_id = primary
    for entity_id in _selected_ids:
        _set_runtime_selected(entity_id, true)

    var runtime_node: Node3D = null
    if not _primary_entity_id.is_empty():
        runtime_node = _bridge.get_entity_node(_primary_entity_id)
    selection_changed.emit(_selected_ids.duplicate(), _primary_entity_id, runtime_node)
    return _result(true)


func clear() -> Dictionary:
    if _selected_ids.is_empty():
        return _result(false)
    for entity_id in _selected_ids:
        _set_runtime_selected(entity_id, false)
    _selected_ids.clear()
    _primary_entity_id = ""
    selection_changed.emit([], "", null)
    return _result(true)


func get_selected_ids() -> Array[String]:
    return _selected_ids.duplicate()


func get_primary_entity_id() -> String:
    return _primary_entity_id


func get_primary_node():
    if _bridge == null or _primary_entity_id.is_empty():
        return null
    return _bridge.get_entity_node(_primary_entity_id)


func has_selection() -> bool:
    return not _selected_ids.is_empty()


func size() -> int:
    return _selected_ids.size()


func _set_runtime_selected(entity_id: String, value: bool) -> void:
    if _bridge == null or not _bridge.has_entity(entity_id):
        return
    var runtime_node = _bridge.get_entity_node(entity_id)
    if runtime_node != null and runtime_node.has_method("set_selected"):
        runtime_node.set_selected(value)


func _result(changed: bool) -> Dictionary:
    return {
        "ok": true,
        "errors": [],
        "changed": changed,
        "entity_ids": _selected_ids.duplicate(),
        "primary_entity_id": _primary_entity_id
    }


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message], "changed": false}
