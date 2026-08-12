extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const GameplayService = preload("res://src/gameplay/gameplay_service.gd")
const SocketService = preload("res://src/gameplay/socket_attachment_service.gd")
const RuntimeAttachmentResolver = preload("res://src/gameplay/runtime_attachment_resolver.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new(); project.initialize_new("Phase 6 Sockets", &"small", "blank_sandbox")
    var session = EditorSession.new(); var dirty: Array[int] = [0]
    session.bind_project(project, func() -> Dictionary: dirty[0] += 1; return {"ok": true, "errors": []})
    var parent_id := _place(session, "Socket Parent", Vector3.ZERO); var child_id := _place(session, "Socket Child", Vector3(2.0, 0.0, 0.0))
    if parent_id.is_empty() or child_id.is_empty(): errors.append("Socket fixture must place two real entities."); session.free(); return errors

    var root := "user://tests/phase6_sockets_%s" % StableId.generate(); var gameplay = GameplayService.new()
    var bound: Dictionary = gameplay.bind_project(project, root.path_join("project"), session, func() -> Dictionary: dirty[0] += 1; return {"ok": true, "errors": []})
    if not bound.get("ok", false): errors.append("Socket fixture gameplay service must bind."); session.free(); return errors
    var sockets = SocketService.new(); sockets.bind(project, gameplay.get_state(), gameplay.get_repository(), session, func() -> Dictionary: dirty[0] += 1; return {"ok": true, "errors": []})

    var parent_socket: Dictionary = sockets.add_socket(parent_id, "Grip", "Grip", _transform(Vector3(0.5, 0.0, 0.0)))
    var child_socket: Dictionary = sockets.add_socket(child_id, "Mount", "Mount", _transform(Vector3(-0.5, 0.0, 0.0)))
    var parent_socket_id := str(parent_socket.get("socket_id", "")); var child_socket_id := str(child_socket.get("socket_id", ""))
    if not parent_socket.get("ok", false) or not child_socket.get("ok", false) or not StableId.is_valid(parent_socket_id) or not StableId.is_valid(child_socket_id): errors.append("Named typed sockets must receive stable UUID identity.")
    var duplicate_name: Dictionary = sockets.add_socket(parent_id, "Grip", "Muzzle", _transform(Vector3.ZERO))
    if duplicate_name.get("ok", false): errors.append("Socket names must be unique per owner regardless of category.")
    var invalid_custom: Dictionary = sockets.add_socket(parent_id, "CustomPoint", "Custom", _transform(Vector3.ZERO))
    if invalid_custom.get("ok", false): errors.append("Custom sockets must require an explicit custom category.")

    var attachment: Dictionary = sockets.attach(parent_id, parent_socket_id, child_id, child_socket_id); var attachment_id := str(attachment.get("attachment_id", ""))
    if not attachment.get("ok", false) or gameplay.get_state().attachments.size() != 1 or not StableId.is_valid(attachment_id): errors.append("Attachment authoring must create one stable record.")
    var remove_in_use: Dictionary = sockets.remove_socket(parent_socket_id)
    if remove_in_use.get("ok", false): errors.append("Sockets referenced by attachments must reject deletion until detached.")

    var runtime: Dictionary = RuntimeAttachmentResolver.new().apply(session.get_bridge(), gameplay.get_state())
    if not runtime.get("ok", false) or runtime.get("resolved", []).size() != 1: errors.append("Loaded attachment references must resolve into runtime presentation.")
    var runtime_child = session.get_bridge().get_entity_node(child_id)
    if runtime_child == null or runtime_child.get_parent() == null or not runtime_child.get_parent().has_meta(RuntimeAttachmentResolver.ANCHOR_META): errors.append("Runtime attachment must use a transient anchor rather than persistent scene paths.")

    var undo_attach: Dictionary = session.undo_edit()
    if not undo_attach.get("ok", false) or not gameplay.get_state().attachments.is_empty(): errors.append("Universal Undo must remove socket attachment authored state.")
    var redo_attach: Dictionary = session.redo_edit()
    if not redo_attach.get("ok", false) or gameplay.get_state().attachments.size() != 1 or str(gameplay.get_state().attachments[0].get("attachment_id", "")) != attachment_id: errors.append("Universal Redo must restore the same attachment stable ID.")
    var detach: Dictionary = sockets.detach(attachment_id)
    if not detach.get("ok", false) or not gameplay.get_state().attachments.is_empty(): errors.append("Detach must remove the authored attachment without deleting either world entity.")
    if _entity(project, parent_id).is_empty() or _entity(project, child_id).is_empty(): errors.append("Attachment lifecycle must never delete its participating entities.")

    var edit: Dictionary = sockets.edit_socket(parent_socket_id, {"category": "Muzzle", "local_transform": _transform(Vector3(0.0, 0.75, 0.0))})
    var edited: Dictionary = gameplay.get_state().get_socket(parent_socket_id)
    if not edit.get("ok", false) or edited.get("category") != "Muzzle" or float(edited.get("local_transform", {}).get("position", [0.0, 0.0, 0.0])[1]) != 0.75: errors.append("Socket editing must preserve socket identity while updating typed local-transform data.")
    var remove: Dictionary = sockets.remove_socket(parent_socket_id)
    if not remove.get("ok", false) or not gameplay.get_state().get_socket(parent_socket_id).is_empty(): errors.append("Unused sockets must be removable through command history.")
    session.undo_edit()
    if gameplay.get_state().get_socket(parent_socket_id).is_empty(): errors.append("Undo socket removal must restore the same socket stable ID.")

    var streamed_attachment: Dictionary = sockets.attach(parent_id, parent_socket_id, child_id, child_socket_id)
    if streamed_attachment.get("ok", false):
        var filtered_cells: Array[String] = []
        var filtered: Dictionary = session.get_bridge().set_active_cell_ids(filtered_cells)
        if not filtered.get("ok", false): errors.append("Runtime cell filtering must accept an empty active set for unloaded attachment verification.")
        var unresolved: Dictionary = RuntimeAttachmentResolver.new().apply(session.get_bridge(), gameplay.get_state())
        if not unresolved.get("ok", false) or unresolved.get("unresolved", []).size() != 1: errors.append("Attachment resolver must report stable unresolved attachment state when related streamed entities are unavailable.")
        session.get_bridge().clear_cell_filter()
    else: errors.append("Streaming attachment fixture must recreate an attachment after socket editing.")

    session.free(); return errors


static func _place(session, label: String, position: Vector3) -> String:
    if not session.begin_proxy_placement(label).get("ok", false): return ""
    session.update_placement_preview(position); var result: Dictionary = session.commit_placement(); return str(result.get("entity_id", "")) if result.get("ok", false) else ""


static func _entity(project, entity_id: String) -> Dictionary:
    for record in project.entity_records:
        if str(record.get("entity_id", "")) == entity_id: return record
    return {}


static func _transform(position: Vector3) -> Dictionary: return {"position": [position.x, position.y, position.z], "rotation_degrees": [0.0, 0.0, 0.0], "scale": [1.0, 1.0, 1.0]}
