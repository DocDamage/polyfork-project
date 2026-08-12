class_name PlayWorldSocketAttachmentService
extends RefCounted

signal attachment_changed

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const GameplayState = preload("res://src/gameplay/gameplay_state.gd")
const SnapshotCommand = preload("res://src/gameplay/gameplay_snapshot_command.gd")

var _project
var _state
var _repository
var _editor_session
var _dirty_callback := Callable()


func bind(project, gameplay_state, repository, editor_session, dirty_callback: Callable) -> Dictionary:
    if project == null or gameplay_state == null or repository == null or editor_session == null: return _failure("Socket authoring requires project, gameplay state, repository, and editor session.")
    if not dirty_callback.is_valid(): return _failure("Socket authoring requires a valid dirty callback.")
    _project = project; _state = gameplay_state; _repository = repository; _editor_session = editor_session; _dirty_callback = dirty_callback
    return {"ok": true, "errors": []}


func add_socket(entity_id: String, name: String, category: String, local_transform: Dictionary, custom_category: String = "") -> Dictionary:
    if not _entity_exists(entity_id): return _failure("Socket owner entity does not exist.")
    var socket_id := StableId.generate()
    var record := {"document_type": Contracts.SOCKET, "schema_version": Contracts.SCHEMA_VERSION, "socket_id": socket_id, "owner_kind": "entity", "owner_id": entity_id, "name": name.strip_edges(), "category": category, "custom_category": custom_category.strip_edges(), "local_transform": local_transform.duplicate(true)}
    var stage = _clone_state(); var put: Dictionary = stage.put_socket(record)
    if not put.get("ok", false): return put
    var validation: Array[String] = stage.validate(null)
    if not validation.is_empty(): return {"ok": false, "errors": validation}
    var result := _execute(stage, ["sockets"], "Add socket")
    if result.get("ok", false): result["socket_id"] = socket_id
    return result


func edit_socket(socket_id: String, patch: Dictionary) -> Dictionary:
    var stage = _clone_state(); var record: Dictionary = stage.get_socket(socket_id)
    if record.is_empty(): return _failure("Socket does not exist.")
    for key in patch.keys():
        if ["name", "category", "custom_category", "local_transform"].has(key): record[key] = patch[key] if not patch[key] is Dictionary else patch[key].duplicate(true)
    var put: Dictionary = stage.put_socket(record)
    if not put.get("ok", false): return put
    var validation: Array[String] = stage.validate(null)
    if not validation.is_empty(): return {"ok": false, "errors": validation}
    return _execute(stage, ["sockets"], "Edit socket")


func remove_socket(socket_id: String) -> Dictionary:
    for attachment in _state.attachments:
        if str(attachment.get("parent_socket_id", "")) == socket_id or str(attachment.get("child_socket_id", "")) == socket_id: return _failure("Socket is used by an attachment and must be detached first.")
    var stage = _clone_state(); var removed: Dictionary = stage.remove_socket(socket_id)
    if not removed.get("ok", false): return removed
    return _execute(stage, ["sockets"], "Remove socket")


func attach(parent_entity_id: String, parent_socket_id: String, child_entity_id: String, child_socket_id: Variant = null, offset_transform: Dictionary = {}) -> Dictionary:
    if not _entity_exists(parent_entity_id) or not _entity_exists(child_entity_id): return _failure("Attachment entities must exist in the world project.")
    var transform := offset_transform.duplicate(true) if not offset_transform.is_empty() else _identity_transform()
    var attachment_id := StableId.generate()
    var record := {"document_type": Contracts.ATTACHMENT, "schema_version": Contracts.SCHEMA_VERSION, "attachment_id": attachment_id, "parent_entity_id": parent_entity_id, "parent_socket_id": parent_socket_id, "child_entity_id": child_entity_id, "child_socket_id": child_socket_id, "offset_transform": transform}
    var stage = _clone_state(); var put: Dictionary = stage.put_attachment(record)
    if not put.get("ok", false): return put
    var validation: Array[String] = stage.validate(null)
    if not validation.is_empty(): return {"ok": false, "errors": validation}
    var result := _execute(stage, ["attachments"], "Attach entity")
    if result.get("ok", false): result["attachment_id"] = attachment_id
    return result


func detach(attachment_id: String) -> Dictionary:
    var stage = _clone_state(); var removed: Dictionary = stage.remove_attachment(attachment_id)
    if not removed.get("ok", false): return removed
    return _execute(stage, ["attachments"], "Detach entity")


func _execute(stage, sections: Array[String], label: String) -> Dictionary:
    var command = SnapshotCommand.new(_project, _state, _repository, _project_snapshot(), _project_snapshot(), _state_snapshot(_state), _state_snapshot(stage), sections)
    var history: Dictionary = _editor_session.get_history().execute_command(command, label)
    if not history.get("ok", false): return _failure(str(history.get("error", "Socket command failed.")))
    var refresh: Dictionary = _editor_session.refresh_runtime(true)
    if not refresh.get("ok", false): return refresh
    var dirty: Variant = _dirty_callback.call()
    if dirty is Dictionary and not dirty.get("ok", false): return _failure("Socket edit succeeded but project dirty-state signaling failed.")
    _editor_session.emit_signal("project_changed", _project.to_dictionary()); attachment_changed.emit()
    return {"ok": true, "errors": []}


func _clone_state():
    var clone = GameplayState.new()
    clone.definitions = _copy_array(_state.definitions); clone.instances = _copy_array(_state.instances); clone.archetypes = _copy_array(_state.archetypes)
    clone.prefabs = _copy_array(_state.prefabs); clone.sockets = _copy_array(_state.sockets); clone.attachments = _copy_array(_state.attachments); clone.prefab_instances = _copy_array(_state.prefab_instances)
    return clone


func _state_snapshot(value) -> Dictionary:
    return {"definitions": _copy_array(value.definitions), "instances": _copy_array(value.instances), "archetypes": _copy_array(value.archetypes), "prefabs": _copy_array(value.prefabs), "sockets": _copy_array(value.sockets), "attachments": _copy_array(value.attachments), "prefab_instances": _copy_array(value.prefab_instances)}


func _project_snapshot() -> Dictionary: return {"entities": _copy_array(_project.entity_records), "registries": _project.registries.duplicate(true)}


func _entity_exists(entity_id: String) -> bool:
    for record in _project.entity_records:
        if str(record.get("entity_id", "")) == entity_id: return true
    return false


static func _identity_transform() -> Dictionary: return {"position": [0.0, 0.0, 0.0], "rotation_degrees": [0.0, 0.0, 0.0], "scale": [1.0, 1.0, 1.0]}


static func _copy_array(records: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for record in records: result.append(record.duplicate(true))
    return result


static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
