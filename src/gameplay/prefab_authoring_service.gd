class_name PlayWorldPrefabAuthoringService
extends RefCounted

signal prefab_changed(prefab_id: String)

const StableId = preload("res://src/world/stable_id.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const GameplayState = preload("res://src/gameplay/gameplay_state.gd")
const PrefabResolver = preload("res://src/gameplay/prefab_resolver.gd")
const SnapshotCommand = preload("res://src/gameplay/gameplay_snapshot_command.gd")

var _project
var _state
var _repository
var _editor_session
var _dirty_callback := Callable()
var _cell_resolver := Callable()


func bind(project, gameplay_state, repository, editor_session, dirty_callback: Callable, cell_resolver: Callable = Callable()) -> Dictionary:
    if project == null or gameplay_state == null or repository == null or editor_session == null: return _failure("Prefab authoring requires project, gameplay state, repository, and editor session.")
    if not dirty_callback.is_valid(): return _failure("Prefab authoring requires a valid dirty callback.")
    _project = project; _state = gameplay_state; _repository = repository; _editor_session = editor_session; _dirty_callback = dirty_callback; _cell_resolver = cell_resolver
    return {"ok": true, "errors": []}


func save_prefab(root_entity_id: String, display_name: String) -> Dictionary:
    if not _is_bound(): return _failure("Prefab authoring is not bound.")
    var subtree := _entity_subtree(root_entity_id)
    if subtree.is_empty(): return _failure("Prefab root entity does not exist.")
    var stage = _clone_state(); var project_after := _project_snapshot()
    var prefab_id := StableId.generate(); var entity_node_ids: Dictionary = {}
    for entity in subtree: entity_node_ids[str(entity.get("entity_id", ""))] = StableId.generate()
    var nodes: Array[Dictionary] = []; var new_sockets: Array[Dictionary] = []
    for entity in subtree:
        var entity_id := str(entity.get("entity_id", "")); var node_id := str(entity_node_ids[entity_id])
        var parent = entity.get("parent_entity_id"); var parent_node = null
        if parent != null and entity_node_ids.has(str(parent)): parent_node = entity_node_ids[str(parent)]
        var transform: Dictionary = entity.get("transform", {}).duplicate(true)
        if entity_id == root_entity_id: transform["position"] = [0.0, 0.0, 0.0]
        var components: Dictionary = {}
        for instance in stage.instances_for_entity(entity_id): components[str(instance.get("definition_id", ""))] = instance.get("values", {}).duplicate(true)
        nodes.append({"node_id": node_id, "parent_node_id": parent_node, "display_name": entity.get("display_name", "Entity"), "asset_id": entity.get("asset_id"), "transform": transform, "components": components})
        for socket in stage.sockets_for_owner("entity", entity_id):
            var copy: Dictionary = socket.duplicate(true); copy["socket_id"] = StableId.generate(); copy["owner_kind"] = "prefab_node"; copy["owner_id"] = node_id
            new_sockets.append(copy)
    var prefab := {"document_type": Contracts.PREFAB, "schema_version": Contracts.SCHEMA_VERSION, "prefab_id": prefab_id, "display_name": display_name.strip_edges() if not display_name.strip_edges().is_empty() else str(subtree[0].get("display_name", "Prefab")), "base_prefab_id": null, "nodes": nodes, "node_overrides": {}, "removed_node_ids": [], "socket_ids": [], "socket_overrides": {}, "removed_socket_ids": []}
    for socket in new_sockets: prefab["socket_ids"].append(socket["socket_id"]); stage.sockets.append(socket)
    var put: Dictionary = stage.put_prefab(prefab)
    if not put.get("ok", false): return put
    _ensure_registry_id(project_after, "prefab_ids", prefab_id)
    var verify: Dictionary = PrefabResolver.new(stage).resolve(prefab_id)
    if not verify.get("ok", false): return verify
    var result := _execute(stage, project_after, ["prefabs", "sockets"], "Save prefab")
    if result.get("ok", false): result["prefab_id"] = prefab_id; prefab_changed.emit(prefab_id)
    return result


func create_derived_prefab(base_prefab_id: String, display_name: String, node_overrides: Dictionary = {}, removed_node_ids: Array = [], added_nodes: Array = [], socket_overrides: Dictionary = {}, removed_socket_ids: Array = []) -> Dictionary:
    if not _is_bound(): return _failure("Prefab authoring is not bound.")
    if _state.get_prefab(base_prefab_id).is_empty(): return _failure("Base prefab does not exist.")
    var stage = _clone_state(); var project_after := _project_snapshot(); var prefab_id := StableId.generate()
    var prefab := {"document_type": Contracts.PREFAB, "schema_version": Contracts.SCHEMA_VERSION, "prefab_id": prefab_id, "display_name": display_name.strip_edges() if not display_name.strip_edges().is_empty() else "Derived Prefab", "base_prefab_id": base_prefab_id, "nodes": _copy_array(added_nodes), "node_overrides": node_overrides.duplicate(true), "removed_node_ids": removed_node_ids.duplicate(), "socket_ids": [], "socket_overrides": socket_overrides.duplicate(true), "removed_socket_ids": removed_socket_ids.duplicate()}
    var put: Dictionary = stage.put_prefab(prefab)
    if not put.get("ok", false): return put
    var resolved: Dictionary = PrefabResolver.new(stage).resolve(prefab_id)
    if not resolved.get("ok", false): return resolved
    _ensure_registry_id(project_after, "prefab_ids", prefab_id)
    var result := _execute(stage, project_after, ["prefabs"], "Create derived prefab")
    if result.get("ok", false): result["prefab_id"] = prefab_id; prefab_changed.emit(prefab_id)
    return result


func instantiate_prefab(prefab_id: String, position: Vector3) -> Dictionary:
    if not _is_bound(): return _failure("Prefab authoring is not bound.")
    var stage = _clone_state(); var resolved: Dictionary = PrefabResolver.new(stage).resolve(prefab_id)
    if not resolved.get("ok", false): return resolved
    var project_after := _project_snapshot(); var node_entity_ids: Dictionary = {}
    for node in resolved.get("nodes", []): node_entity_ids[str(node.get("node_id", ""))] = StableId.generate()
    var root_entity_id := ""; var cell_id := _resolve_cell(position)
    if cell_id.is_empty(): return _failure("Prefab placement position is outside the authored world partition.")
    for node in resolved.get("nodes", []):
        var node_id := str(node.get("node_id", "")); var entity_id := str(node_entity_ids[node_id])
        var parent_node = node.get("parent_node_id"); var parent_entity := "" if parent_node == null else str(node_entity_ids.get(str(parent_node), ""))
        if parent_entity.is_empty(): root_entity_id = entity_id
        var world_entity = WorldEntity.new(); world_entity.initialize_new(str(node.get("display_name", "Prefab Entity")), cell_id)
        world_entity.entity_id = entity_id; world_entity.asset_id = "" if node.get("asset_id") == null else str(node.get("asset_id")); world_entity.prefab_id = prefab_id; world_entity.parent_entity_id = parent_entity
        var transform: Dictionary = node.get("transform", {}).duplicate(true)
        if parent_entity.is_empty(): transform["position"] = [position.x, position.y, position.z]
        world_entity.transform = transform
        for definition_id in node.get("components", {}).keys():
            var definition: Dictionary = stage.get_definition(str(definition_id))
            if definition.is_empty(): return _failure("Prefab references an unavailable component definition.")
            var values: Dictionary = node["components"][definition_id].duplicate(true)
            var value_errors: Array[String] = Contracts.validate_values(values, definition)
            if not value_errors.is_empty(): return {"ok": false, "errors": value_errors}
            var component_id := StableId.generate(); var component := {"document_type": Contracts.COMPONENT_INSTANCE, "schema_version": Contracts.SCHEMA_VERSION, "instance_id": component_id, "definition_id": str(definition_id), "owner_entity_id": entity_id, "values": values}
            var add: Dictionary = stage.add_instance(component)
            if not add.get("ok", false): return add
            world_entity.component_instance_ids.append(component_id)
        project_after["entities"].append(world_entity.to_dictionary())
    if root_entity_id.is_empty(): return _failure("Resolved prefab has no root node.")

    # Prefab-node sockets are definition data. Every world instance receives fresh entity-owned
    # socket identities so attachments never alias another prefab instance or depend on node paths.
    var entity_socket_ids: Array[String] = []
    for prefab_socket in resolved.get("sockets", []):
        var owner_node_id := str(prefab_socket.get("owner_id", ""))
        var owner_entity_id := str(node_entity_ids.get(owner_node_id, ""))
        if owner_entity_id.is_empty(): return _failure("Resolved prefab socket owner node is unavailable during instantiation.")
        var entity_socket: Dictionary = prefab_socket.duplicate(true)
        entity_socket["socket_id"] = StableId.generate(); entity_socket["owner_kind"] = "entity"; entity_socket["owner_id"] = owner_entity_id
        var put_socket: Dictionary = stage.put_socket(entity_socket)
        if not put_socket.get("ok", false): return put_socket
        entity_socket_ids.append(str(entity_socket["socket_id"]))

    var instance_id := StableId.generate(); var instance := {"document_type": Contracts.PREFAB_INSTANCE, "schema_version": Contracts.SCHEMA_VERSION, "instance_id": instance_id, "prefab_id": prefab_id, "root_entity_id": root_entity_id, "node_entity_ids": node_entity_ids.duplicate(true), "overrides": {}}
    var put_instance: Dictionary = stage.put_prefab_instance(instance)
    if not put_instance.get("ok", false): return put_instance
    _ensure_registry_id(project_after, "prefab_ids", prefab_id)
    var result := _execute(stage, project_after, ["instances", "sockets", "prefab_instances"], "Instantiate prefab")
    if result.get("ok", false):
        _editor_session.select_entity(root_entity_id); result["prefab_instance_id"] = instance_id; result["root_entity_id"] = root_entity_id; result["node_entity_ids"] = node_entity_ids; result["socket_ids"] = entity_socket_ids
    return result


func set_instance_override(instance_id: String, node_id: String, patch: Dictionary) -> Dictionary:
    if not _is_bound(): return _failure("Prefab authoring is not bound.")
    var stage = _clone_state(); var record: Dictionary = stage.get_prefab_instance(instance_id)
    if record.is_empty(): return _failure("Prefab instance does not exist.")
    var overrides: Dictionary = record.get("overrides", {}).duplicate(true); var existing: Dictionary = overrides.get(node_id, {}).duplicate(true)
    for key in patch.keys(): existing[key] = patch[key] if not patch[key] is Dictionary else patch[key].duplicate(true)
    overrides[node_id] = existing; record["overrides"] = overrides
    var put: Dictionary = stage.put_prefab_instance(record)
    if not put.get("ok", false): return put
    var resolved: Dictionary = PrefabResolver.new(stage).resolve_instance(record)
    if not resolved.get("ok", false): return resolved
    return _execute(stage, _project_snapshot(), ["prefab_instances"], "Edit prefab instance override")


func _execute(stage, project_after: Dictionary, sections: Array[String], label: String) -> Dictionary:
    var command = SnapshotCommand.new(_project, _state, _repository, _project_snapshot(), project_after, _state_snapshot(_state), _state_snapshot(stage), sections)
    var history_result: Dictionary = _editor_session.get_history().execute_command(command, label)
    if not history_result.get("ok", false): return _failure(str(history_result.get("error", "Prefab command failed.")))
    var refresh: Dictionary = _editor_session.refresh_runtime(true)
    if not refresh.get("ok", false): return refresh
    var dirty: Variant = _dirty_callback.call()
    if dirty is Dictionary and not dirty.get("ok", false): return _failure("Prefab edit succeeded but project dirty-state signaling failed.")
    _editor_session.emit_signal("project_changed", _project.to_dictionary())
    return {"ok": true, "errors": [], "project_data": _project.to_dictionary()}


func _entity_subtree(root_entity_id: String) -> Array[Dictionary]:
    var root := _entity(root_entity_id)
    if root.is_empty(): return []
    var result: Array[Dictionary] = []; _collect_subtree(root, result)
    return result


func _collect_subtree(entity: Dictionary, result: Array[Dictionary]) -> void:
    result.append(entity.duplicate(true)); var entity_id := str(entity.get("entity_id", "")); var children: Array[Dictionary] = []
    for candidate in _project.entity_records:
        var parent = candidate.get("parent_entity_id")
        if parent != null and str(parent) == entity_id: children.append(candidate)
    children.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("entity_id", "")) < str(b.get("entity_id", "")))
    for child in children: _collect_subtree(child, result)


func _entity(entity_id: String) -> Dictionary:
    for record in _project.entity_records:
        if str(record.get("entity_id", "")) == entity_id: return record
    return {}


func _resolve_cell(position: Vector3) -> String:
    if _cell_resolver.is_valid():
        var value: Variant = _cell_resolver.call(position)
        if value != null and not str(value).is_empty(): return str(value)
    return str(_project.cell_ids[0]) if not _project.cell_ids.is_empty() else ""


func _clone_state():
    var clone = GameplayState.new()
    clone.definitions = _copy_array(_state.definitions); clone.instances = _copy_array(_state.instances); clone.archetypes = _copy_array(_state.archetypes)
    clone.prefabs = _copy_array(_state.prefabs); clone.sockets = _copy_array(_state.sockets); clone.attachments = _copy_array(_state.attachments); clone.prefab_instances = _copy_array(_state.prefab_instances)
    return clone


func _state_snapshot(value) -> Dictionary:
    return {"definitions": _copy_array(value.definitions), "instances": _copy_array(value.instances), "archetypes": _copy_array(value.archetypes), "prefabs": _copy_array(value.prefabs), "sockets": _copy_array(value.sockets), "attachments": _copy_array(value.attachments), "prefab_instances": _copy_array(value.prefab_instances)}


func _project_snapshot() -> Dictionary: return {"entities": _copy_array(_project.entity_records), "registries": _project.registries.duplicate(true)}


static func _ensure_registry_id(project_snapshot: Dictionary, key: String, id: String) -> void:
    var registries: Dictionary = project_snapshot.get("registries", {}).duplicate(true); var ids: Array = registries.get(key, []).duplicate()
    if not ids.has(id): ids.append(id); ids.sort()
    registries[key] = ids; project_snapshot["registries"] = registries


static func _copy_array(records: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for record in records: result.append(record.duplicate(true))
    return result


func _is_bound() -> bool: return _project != null and _state != null and _repository != null and _editor_session != null
static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
