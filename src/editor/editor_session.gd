class_name PlayWorldEditorSession
extends Node

signal project_changed(project_data: Dictionary)
signal selection_changed(entity_ids: Array, primary_entity_id: String, runtime_node: Node3D)
signal placement_changed(active: bool, preview_record: Dictionary)

const StableId = preload("res://src/world/stable_id.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const CommandHistory = preload("res://src/commands/command_history.gd")
const PlaceEntityCommand = preload("res://src/commands/place_entity_command.gd")
const SetTransformsCommand = preload("res://src/commands/set_entity_transforms_command.gd")
const DuplicateEntitiesCommand = preload("res://src/commands/duplicate_entities_command.gd")
const DeleteEntitiesCommand = preload("res://src/commands/delete_entities_command.gd")
const GroupEntitiesCommand = preload("res://src/commands/group_entities_command.gd")
const RuntimeEntityBridge = preload("res://src/editor/runtime_entity_bridge.gd")
const MultiSelection = preload("res://src/editor/multi_selection.gd")
const PlacementGhost = preload("res://src/editor/placement_ghost.gd")
const SnappingService = preload("res://src/editor/snapping_service.gd")
const GizmoState = preload("res://src/editor/transform_gizmo_state.gd")

var _project
var _dirty_callback := Callable()
var _cell_resolver := Callable()
var _history = CommandHistory.new()
var _bridge = RuntimeEntityBridge.new()
var _selection = MultiSelection.new()
var _ghost = PlacementGhost.new()
var _snapping = SnappingService.new()
var _gizmo = GizmoState.new()


func _init() -> void:
    name = "EditorSession"
    _bridge.name = "RuntimeEntityBridge"
    add_child(_bridge)
    add_child(_ghost)
    _selection.bind_bridge(_bridge)
    _selection.selection_changed.connect(_on_selection_changed)


func bind_project(project, dirty_callback: Callable) -> Dictionary:
    if project == null: return _failure("Editor session requires an active project.")
    var errors: Array[String] = project.validate()
    if not errors.is_empty(): return _failure("Editor session project is invalid: %s" % str(errors))
    if not dirty_callback.is_valid(): return _failure("Editor session requires a valid dirty-state callback.")
    _selection.clear(); _ghost.hide_preview(); _history.clear()
    _project = project; _dirty_callback = dirty_callback; _cell_resolver = Callable()
    var result: Dictionary = _bridge.rebuild(_project.entity_records)
    if not result.get("ok", false):
        _project = null; _dirty_callback = Callable(); return result
    return {"ok": true, "errors": [], "entity_count": _bridge.entity_count()}


func bind_cell_resolver(resolver: Callable) -> Dictionary:
    if not resolver.is_valid(): return _failure("Editor cell resolver must be callable.")
    _cell_resolver = resolver
    return {"ok": true, "errors": []}


func clear_cell_resolver() -> void: _cell_resolver = Callable()
func get_history(): return _history
func load_preview_records(records: Array) -> Dictionary: _selection.clear(); return _bridge.rebuild(records)


func refresh_runtime(preserve_selection: bool = true) -> Dictionary:
    if _project == null: return _failure("Editor session has no bound project.")
    var selected: Array[String] = []
    var primary: String = ""
    if preserve_selection:
        selected = _selection.get_selected_ids(); primary = _selection.get_primary_entity_id()
    _selection.clear()
    var result: Dictionary = _bridge.rebuild(_project.entity_records)
    if not result.get("ok", false): return result
    if preserve_selection and not selected.is_empty():
        restore_selection(selected, primary)
    return result


func restore_selection(entity_ids: Array[String], primary_entity_id: String = "") -> Dictionary:
    var surviving: Array[String] = []
    for entity_id in entity_ids:
        if _bridge.has_entity(entity_id):
            surviving.append(entity_id)
    if surviving.is_empty():
        return _selection.clear()
    var resolved_primary := primary_entity_id
    if resolved_primary.is_empty() or not surviving.has(resolved_primary):
        resolved_primary = surviving[0]
    return _selection.set_selected(surviving, resolved_primary)


func begin_proxy_placement(display_name: String = "Proxy Object") -> Dictionary:
    if not _can_mutate(): return _failure("Placement requires a bound editable project.")
    if _ghost.is_active(): return _failure("A placement preview is already active.")
    var cell_id: String = str(_project.cell_ids[0]) if not _project.cell_ids.is_empty() else StableId.generate()
    var record: Dictionary = _new_entity_record(display_name, cell_id)
    _ghost.show_record(record); _sync_ghost_cell()
    placement_changed.emit(true, _ghost.get_record())
    return {"ok": true, "errors": [], "record": _ghost.get_record()}


func update_placement_preview(position_value: Vector3, context: Dictionary = {}) -> Dictionary:
    if not _ghost.is_active(): return _failure("No placement preview is active.")
    var resolved_context: Dictionary = context.duplicate(true)
    if not resolved_context.has("object_candidates"): resolved_context["object_candidates"] = _runtime_snap_candidates(false)
    if not resolved_context.has("socket_candidates"): resolved_context["socket_candidates"] = _runtime_snap_candidates(true)
    var snap_result: Dictionary = _snapping.resolve_position(position_value, resolved_context)
    var record: Dictionary = _ghost.get_record()
    var transform_data: Dictionary = record.get("transform", {}).duplicate(true)
    var rotation_value: Vector3 = _vector3(transform_data.get("rotation_degrees", [0.0, 0.0, 0.0]))
    var scale_value: Vector3 = _vector3(transform_data.get("scale", [1.0, 1.0, 1.0]))
    _ghost.update_transform(snap_result["position"], rotation_value, scale_value)
    var cell_result: Dictionary = _sync_ghost_cell()
    if not cell_result.get("ok", false): return cell_result
    placement_changed.emit(true, _ghost.get_record())
    return {"ok": true, "errors": [], "record": _ghost.get_record(), "snap_mode": snap_result["mode"]}


func cancel_placement() -> Dictionary:
    var changed := _ghost.is_active(); _ghost.hide_preview()
    if changed: placement_changed.emit(false, {})
    return {"ok": true, "errors": [], "changed": changed}


func commit_placement() -> Dictionary:
    if not _ghost.is_active(): return _failure("No placement preview is active.")
    var command = PlaceEntityCommand.new(_project, _ghost.get_record())
    var result: Dictionary = _history.execute_command(command, "Place object")
    if not result.get("ok", false): return _history_failure(result)
    var entity_id: String = command.get_entity_id()
    _ghost.hide_preview(); placement_changed.emit(false, {})
    var finish: Dictionary = _finish_mutation(false)
    if not finish.get("ok", false): return finish
    _selection.select_single(entity_id); finish["entity_id"] = entity_id
    return finish


func nudge_selected(mode: StringName, delta: Vector3) -> Dictionary:
    if not _selection.has_selection(): return _failure("Transform editing requires a selection.")
    if not [&"move", &"rotate", &"scale"].has(mode): return _failure("Unsupported transform edit mode: %s" % mode)
    var constrained: Vector3 = _gizmo.constrain(delta)
    var updates: Dictionary = {}
    for entity_id in _selection.get_selected_ids():
        var record: Dictionary = _find_record(entity_id)
        if record.is_empty(): return _failure("Selected entity no longer exists in the project.")
        var transform_data: Dictionary = record.get("transform", {}).duplicate(true)
        var position_value: Vector3 = _vector3(transform_data.get("position", [0.0, 0.0, 0.0]))
        var rotation_value: Vector3 = _vector3(transform_data.get("rotation_degrees", [0.0, 0.0, 0.0]))
        var scale_value: Vector3 = _vector3(transform_data.get("scale", [1.0, 1.0, 1.0]))
        match mode:
            &"move": position_value = _snapping.snap_position(position_value + constrained)
            &"rotate": rotation_value = _snapping.snap_rotation(rotation_value + constrained)
            &"scale":
                scale_value += constrained
                scale_value = Vector3(max(0.05, scale_value.x), max(0.05, scale_value.y), max(0.05, scale_value.z))
        var next_transform: Dictionary = _transform_dict(position_value, rotation_value, scale_value)
        var cell_id: String = str(record.get("cell_id", ""))
        if mode == &"move":
            var resolved_cell: String = _resolve_cell_id(position_value)
            if not resolved_cell.is_empty(): cell_id = resolved_cell
        updates[entity_id] = {"transform": next_transform, "cell_id": cell_id}
    var result: Dictionary = _history.execute_command(SetTransformsCommand.new(_project, updates), "Transform selection")
    if not result.get("ok", false): return _history_failure(result)
    return _finish_mutation(true)


func move_selection_to(target: Vector3) -> Dictionary:
    var primary_id: String = _selection.get_primary_entity_id()
    if primary_id.is_empty(): return _failure("Move-to operation requires a primary selection.")
    var record: Dictionary = _find_record(primary_id)
    var current: Vector3 = _vector3(record.get("transform", {}).get("position", [0.0, 0.0, 0.0]))
    return nudge_selected(&"move", target - current)


func drop_selection_to_ground(ground_y: float = 0.5) -> Dictionary:
    var primary_id: String = _selection.get_primary_entity_id()
    if primary_id.is_empty(): return _failure("Drop-to-ground requires a primary selection.")
    var record: Dictionary = _find_record(primary_id)
    var current: Vector3 = _vector3(record.get("transform", {}).get("position", [0.0, 0.0, 0.0]))
    return move_selection_to(_snapping.drop_to_ground(current, ground_y))


func snap_selection_to_surface(hit_position: Vector3, hit_normal: Vector3) -> Dictionary: return move_selection_to(_snapping.snap_to_surface(hit_position, hit_normal))
func snap_selection_to_object(candidates: Array) -> Dictionary: return _snap_selection_to_candidates(candidates, false)
func snap_selection_to_socket(candidates: Array) -> Dictionary: return _snap_selection_to_candidates(candidates, true)


func duplicate_selected() -> Dictionary:
    var ids: Array[String] = _selection.get_selected_ids()
    if ids.is_empty(): return _failure("Duplicate requires a selection.")
    var command = DuplicateEntitiesCommand.new(_project, ids, Vector3(_snapping.grid_size, 0.0, _snapping.grid_size))
    var result: Dictionary = _history.execute_command(command, "Duplicate selection")
    if not result.get("ok", false): return _history_failure(result)
    var finish: Dictionary = _finish_mutation(false)
    if finish.get("ok", false): _selection.set_selected(command.created_ids()); finish["entity_ids"] = command.created_ids()
    return finish


func delete_selected() -> Dictionary:
    var ids: Array[String] = _selection.get_selected_ids()
    if ids.is_empty(): return _failure("Delete requires a selection.")
    var result: Dictionary = _history.execute_command(DeleteEntitiesCommand.new(_project, ids), "Delete selection")
    if not result.get("ok", false): return _history_failure(result)
    _selection.clear(); return _finish_mutation(false)


func group_selected() -> Dictionary:
    var ids: Array[String] = _selection.get_selected_ids()
    if ids.size() < 2: return _failure("Grouping requires at least two selected entities.")
    var command = GroupEntitiesCommand.new(_project, ids)
    var result: Dictionary = _history.execute_command(command, "Group selection")
    if not result.get("ok", false): return _history_failure(result)
    var finish: Dictionary = _finish_mutation(false)
    if finish.get("ok", false): _selection.select_single(command.group_id()); finish["group_id"] = command.group_id()
    return finish


func undo_edit() -> Dictionary:
    var result: Dictionary = _history.undo()
    if not result.get("ok", false): return _history_failure(result)
    _selection.clear(); return _finish_mutation(false)


func redo_edit() -> Dictionary:
    var result: Dictionary = _history.redo()
    if not result.get("ok", false): return _history_failure(result)
    _selection.clear(); return _finish_mutation(false)


func select_entity(entity_id: String) -> Dictionary: return _selection.select_single(entity_id)
func toggle_entity(entity_id: String) -> Dictionary: return _selection.toggle_entity(entity_id)
func select_runtime_node(node: Node, additive: bool = false) -> Dictionary: return _selection.select_node(node, additive)
func clear_selection() -> Dictionary: return _selection.clear()
func set_tool(mode: StringName) -> Dictionary: return _gizmo.set_mode(mode)
func set_axis(axis: StringName) -> Dictionary: return _gizmo.set_axis(axis)
func set_snap_enabled(mode: StringName, enabled: bool) -> Dictionary: return _snapping.set_mode_enabled(mode, enabled)
func is_snap_enabled(mode: StringName) -> bool: return _snapping.is_mode_enabled(mode)
func get_bridge(): return _bridge
func get_ghost(): return _ghost
func get_selected_ids() -> Array[String]: return _selection.get_selected_ids()
func get_primary_entity_id() -> String: return _selection.get_primary_entity_id()
func get_primary_node(): return _selection.get_primary_node()
func get_history_counts() -> Dictionary: return {"undo": _history.undo_count(), "redo": _history.redo_count()}
func is_placement_active() -> bool: return _ghost.is_active()
func get_project_data() -> Dictionary: return {} if _project == null else _project.to_dictionary()


func _finish_mutation(preserve_selection: bool) -> Dictionary:
    var refresh: Dictionary = refresh_runtime(preserve_selection)
    if not refresh.get("ok", false): return refresh
    var dirty_result: Variant = _dirty_callback.call()
    if dirty_result is Dictionary and not dirty_result.get("ok", false): return _failure("Project changed but dirty-state signaling failed: %s" % str(dirty_result.get("errors", [])))
    var data: Dictionary = _project.to_dictionary(); project_changed.emit(data)
    return {"ok": true, "errors": [], "project_data": data}


func _snap_selection_to_candidates(candidates: Array, socket: bool) -> Dictionary:
    var primary_id: String = _selection.get_primary_entity_id()
    if primary_id.is_empty(): return _failure("Snapping requires a primary selection.")
    var record: Dictionary = _find_record(primary_id)
    var current: Vector3 = _vector3(record.get("transform", {}).get("position", [0.0, 0.0, 0.0]))
    var result: Dictionary = _snapping.snap_to_socket(current, candidates) if socket else _snapping.snap_to_object(current, candidates)
    if not result.get("snapped", false): return _failure("No snap candidate is within range.")
    var move_result: Dictionary = move_selection_to(result["position"])
    if move_result.get("ok", false): move_result["snap_id"] = result["id"]
    return move_result


func _runtime_snap_candidates(socket: bool) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for entity_id in _bridge.entity_ids():
        var node: Node3D = _bridge.get_entity_node(entity_id)
        if node == null: continue
        result.append({"id": "%s:origin" % entity_id if socket else entity_id, "position": node.position})
    return result


func _sync_ghost_cell() -> Dictionary:
    if not _ghost.is_active() or not _cell_resolver.is_valid(): return {"ok": true, "errors": [], "changed": false}
    var cell_id: String = _resolve_cell_id(_ghost.position)
    if cell_id.is_empty(): return _failure("Placement preview is outside the authored world partition.")
    var current: String = str(_ghost.get_record().get("cell_id", ""))
    if current == cell_id: return {"ok": true, "errors": [], "changed": false, "cell_id": cell_id}
    var result: Dictionary = _ghost.set_cell_id(cell_id)
    result["changed"] = result.get("ok", false)
    result["cell_id"] = cell_id
    return result


func _resolve_cell_id(position_value: Vector3) -> String:
    if not _cell_resolver.is_valid(): return ""
    var value: Variant = _cell_resolver.call(position_value)
    return str(value) if value != null else ""


func _can_mutate() -> bool: return _project != null and _dirty_callback.is_valid()


func _new_entity_record(display_name: String, cell_id: String) -> Dictionary:
    return {
        "document_type": WorldEntity.DOCUMENT_TYPE,
        "schema_version": WorldEntity.SCHEMA_VERSION,
        "entity_id": StableId.generate(),
        "display_name": display_name.strip_edges() if not display_name.strip_edges().is_empty() else "Entity",
        "cell_id": cell_id,
        "asset_id": null,
        "prefab_id": null,
        "parent_entity_id": null,
        "component_instance_ids": [],
        "transform": _transform_dict(Vector3.ZERO, Vector3.ZERO, Vector3.ONE)
    }


func _find_record(entity_id: String) -> Dictionary:
    if _project == null: return {}
    for record in _project.entity_records:
        if str(record.get("entity_id", "")) == entity_id: return record.duplicate(true)
    return {}


func _history_failure(result: Dictionary) -> Dictionary:
    return _failure(str(result.get("errors", ["Command history operation failed."])[0]))


func _on_selection_changed(entity_ids: Array, primary_entity_id: String, runtime_node: Node3D) -> void:
    selection_changed.emit(entity_ids, primary_entity_id, runtime_node)


static func _vector3(value: Array) -> Vector3:
    return Vector3(float(value[0]), float(value[1]), float(value[2]))


static func _transform_dict(position_value: Vector3, rotation_value: Vector3, scale_value: Vector3) -> Dictionary:
    return {
        "position": [position_value.x, position_value.y, position_value.z],
        "rotation_degrees": [rotation_value.x, rotation_value.y, rotation_value.z],
        "scale": [scale_value.x, scale_value.y, scale_value.z]
    }


func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
