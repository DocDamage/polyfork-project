class_name PlayWorldPrefabResolver
extends RefCounted

const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")

var state


func _init(gameplay_state) -> void: state = gameplay_state


func resolve(prefab_id: String) -> Dictionary:
    if state == null: return _failure("Prefab resolver requires gameplay state.")
    return _resolve(prefab_id, {})


func resolve_instance(record: Dictionary) -> Dictionary:
    var errors := Contracts.validate_prefab_instance(record)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    var base := resolve(str(record.get("prefab_id", "")))
    if not base.get("ok", false): return base
    var nodes: Array[Dictionary] = _copy_array(base.get("nodes", []))
    var overrides: Dictionary = record.get("overrides", {})
    for node_id in overrides.keys():
        var index := _node_index(nodes, str(node_id))
        if index < 0: return _failure("Prefab instance override targets an unknown node.")
        nodes[index] = _merge_node(nodes[index], overrides[node_id])
    var validate := _validate_effective(nodes, base.get("sockets", []))
    if not validate.is_empty(): return {"ok": false, "errors": validate}
    base["nodes"] = nodes
    base["instance_id"] = record.get("instance_id")
    base["node_entity_ids"] = record.get("node_entity_ids", {}).duplicate(true)
    return base


func _resolve(prefab_id: String, visiting: Dictionary) -> Dictionary:
    if visiting.has(prefab_id): return _failure("Prefab inheritance cycle detected during resolution.")
    var prefab: Dictionary = state.get_prefab(prefab_id)
    if prefab.is_empty(): return _failure("Prefab does not exist.")
    visiting[prefab_id] = true
    var nodes: Array[Dictionary] = []
    var sockets: Array[Dictionary] = []
    var base = prefab.get("base_prefab_id")
    if base != null and not str(base).is_empty():
        var resolved_base := _resolve(str(base), visiting)
        if not resolved_base.get("ok", false): return resolved_base
        nodes = _copy_array(resolved_base.get("nodes", []))
        sockets = _copy_array(resolved_base.get("sockets", []))
        _remove_nodes(nodes, prefab.get("removed_node_ids", []))
        for node_id in prefab.get("node_overrides", {}).keys():
            var index := _node_index(nodes, str(node_id))
            if index < 0: return _failure("Derived prefab override targets an unknown inherited node.")
            nodes[index] = _merge_node(nodes[index], prefab["node_overrides"][node_id])
        _remove_sockets(sockets, prefab.get("removed_socket_ids", []))
        for socket_id in prefab.get("socket_overrides", {}).keys():
            var socket_index := _socket_index(sockets, str(socket_id))
            if socket_index < 0: return _failure("Derived prefab socket override targets an unknown inherited socket.")
            sockets[socket_index] = _merge_dictionary(sockets[socket_index], prefab["socket_overrides"][socket_id])
    nodes.append_array(_copy_array(prefab.get("nodes", [])))
    for socket_id in prefab.get("socket_ids", []):
        var socket := state.get_socket(str(socket_id))
        if socket.is_empty(): return _failure("Prefab references an unknown socket record.")
        sockets.append(socket)
    visiting.erase(prefab_id)
    var errors := _validate_effective(nodes, sockets)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    return {"ok": true, "errors": [], "prefab_id": prefab_id, "display_name": prefab.get("display_name", "Prefab"), "nodes": nodes, "sockets": sockets}


func _validate_effective(nodes: Array, sockets: Array) -> Array[String]:
    var errors: Array[String] = []
    var known: Dictionary = {}; var roots := 0
    for node in nodes:
        if not node is Dictionary: errors.append("Effective prefab nodes must be dictionaries."); continue
        var id := str(node.get("node_id", ""))
        if known.has(id): errors.append("Effective prefab contains duplicate node IDs.")
        known[id] = true
        var parent = node.get("parent_node_id")
        if parent == null or str(parent).is_empty(): roots += 1
    for node in nodes:
        if node is Dictionary:
            var parent = node.get("parent_node_id")
            if parent != null and not str(parent).is_empty() and not known.has(str(parent)): errors.append("Effective prefab node parent does not resolve.")
    if roots != 1: errors.append("Effective prefab must have exactly one root node.")
    var socket_ids: Dictionary = {}; var socket_names: Dictionary = {}
    for socket in sockets:
        if not socket is Dictionary: errors.append("Effective prefab sockets must be dictionaries."); continue
        var socket_errors := Contracts.validate_socket(socket); errors.append_array(socket_errors)
        var socket_id := str(socket.get("socket_id", ""))
        if socket_ids.has(socket_id): errors.append("Effective prefab contains duplicate socket IDs.")
        socket_ids[socket_id] = true
        var owner_id := str(socket.get("owner_id", ""))
        if str(socket.get("owner_kind", "")) != "prefab_node" or not known.has(owner_id): errors.append("Effective prefab socket owner must resolve to a prefab node.")
        var name_key := "%s:%s" % [owner_id, str(socket.get("name", "")).to_lower()]
        if socket_names.has(name_key): errors.append("Effective prefab socket names must be unique per node.")
        socket_names[name_key] = true
    return errors


func _remove_nodes(nodes: Array[Dictionary], removed_ids: Array) -> void:
    var removed: Dictionary = {}
    for id in removed_ids: removed[str(id)] = true
    var changed := true
    while changed:
        changed = false
        for node in nodes:
            var parent = node.get("parent_node_id")
            if parent != null and removed.has(str(parent)) and not removed.has(str(node.get("node_id", ""))): removed[str(node.get("node_id", ""))] = true; changed = true
    for index in range(nodes.size() - 1, -1, -1):
        if removed.has(str(nodes[index].get("node_id", ""))): nodes.remove_at(index)


func _remove_sockets(sockets: Array[Dictionary], removed_ids: Array) -> void:
    var removed: Dictionary = {}
    for id in removed_ids: removed[str(id)] = true
    for index in range(sockets.size() - 1, -1, -1):
        if removed.has(str(sockets[index].get("socket_id", ""))): sockets.remove_at(index)


func _merge_node(base: Dictionary, patch: Dictionary) -> Dictionary:
    var result := base.duplicate(true)
    for key in patch.keys():
        if key == "components" and patch[key] is Dictionary:
            var components: Dictionary = result.get("components", {}).duplicate(true)
            for definition_id in patch[key].keys():
                var values: Dictionary = components.get(definition_id, {}).duplicate(true)
                if patch[key][definition_id] is Dictionary:
                    for property_name in patch[key][definition_id].keys(): values[property_name] = patch[key][definition_id][property_name]
                components[definition_id] = values
            result["components"] = components
        elif ["display_name", "asset_id", "transform", "parent_node_id"].has(key): result[key] = patch[key] if not patch[key] is Dictionary else patch[key].duplicate(true)
    return result


static func _merge_dictionary(base: Dictionary, patch: Dictionary) -> Dictionary:
    var result := base.duplicate(true)
    for key in patch.keys():
        if ["name", "category", "custom_category", "local_transform"].has(key): result[key] = patch[key] if not patch[key] is Dictionary else patch[key].duplicate(true)
    return result


static func _node_index(nodes: Array, node_id: String) -> int:
    for index in range(nodes.size()):
        if str(nodes[index].get("node_id", "")) == node_id: return index
    return -1


static func _socket_index(sockets: Array, socket_id: String) -> int:
    for index in range(sockets.size()):
        if str(sockets[index].get("socket_id", "")) == socket_id: return index
    return -1


static func _copy_array(records: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for record in records: result.append(record.duplicate(true))
    return result


static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
