class_name PlayWorldSingleSelection
extends RefCounted

signal selection_changed(entity_id: String, runtime_node: Node3D)

var _bridge
var _selected_entity_id: String = ""


func bind_bridge(bridge) -> Dictionary:
    clear()
    if bridge == null:
        _bridge = null
        return _failure("Single selection requires a runtime entity bridge.")
    _bridge = bridge
    return {"ok": true, "errors": []}


func select_entity(entity_id: String) -> Dictionary:
    if _bridge == null:
        return _failure("Single selection is not bound to a runtime entity bridge.")
    if entity_id.is_empty() or not _bridge.has_entity(entity_id):
        return _failure("Selected entity ID is not present in the runtime entity bridge.")

    if entity_id == _selected_entity_id:
        return {
            "ok": true,
            "errors": [],
            "changed": false,
            "entity_id": entity_id,
            "runtime_node": _bridge.get_entity_node(entity_id)
        }

    _set_runtime_selected(_selected_entity_id, false)
    _selected_entity_id = entity_id
    var runtime_node = _bridge.get_entity_node(entity_id)
    if runtime_node.has_method("set_selected"):
        runtime_node.set_selected(true)
    selection_changed.emit(_selected_entity_id, runtime_node)
    return {
        "ok": true,
        "errors": [],
        "changed": true,
        "entity_id": _selected_entity_id,
        "runtime_node": runtime_node
    }


func select_node(node: Node) -> Dictionary:
    if _bridge == null:
        return _failure("Single selection is not bound to a runtime entity bridge.")
    var entity_id: String = _bridge.resolve_entity_id(node)
    if entity_id.is_empty():
        return _failure("Runtime node does not resolve to a bridged entity.")
    return select_entity(entity_id)


func clear() -> Dictionary:
    if _selected_entity_id.is_empty():
        return {"ok": true, "errors": [], "changed": false}

    _set_runtime_selected(_selected_entity_id, false)
    _selected_entity_id = ""
    selection_changed.emit("", null)
    return {"ok": true, "errors": [], "changed": true}


func get_selected_entity_id() -> String:
    return _selected_entity_id


func get_selected_node():
    if _bridge == null or _selected_entity_id.is_empty():
        return null
    return _bridge.get_entity_node(_selected_entity_id)


func has_selection() -> bool:
    return not _selected_entity_id.is_empty()


func _set_runtime_selected(entity_id: String, value: bool) -> void:
    if _bridge == null or entity_id.is_empty() or not _bridge.has_entity(entity_id):
        return
    var runtime_node = _bridge.get_entity_node(entity_id)
    if runtime_node != null and runtime_node.has_method("set_selected"):
        runtime_node.set_selected(value)


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message], "changed": false}
