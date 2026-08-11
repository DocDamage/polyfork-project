class_name PlayWorldRuntimeAttachmentResolver
extends RefCounted

const ANCHOR_META: StringName = &"playworld_attachment_id"


func apply(runtime_bridge, gameplay_state) -> Dictionary:
    if runtime_bridge == null or gameplay_state == null: return _failure("Runtime attachment resolver requires a runtime bridge and gameplay state.")
    var resolved: Array[String] = []; var unresolved: Array[String] = []
    for attachment in gameplay_state.attachments:
        var attachment_id := str(attachment.get("attachment_id", ""))
        var parent = runtime_bridge.get_entity_node(str(attachment.get("parent_entity_id", "")))
        var child = runtime_bridge.get_entity_node(str(attachment.get("child_entity_id", "")))
        var parent_socket: Dictionary = gameplay_state.get_socket(str(attachment.get("parent_socket_id", "")))
        if parent == null or child == null or parent_socket.is_empty(): unresolved.append(attachment_id); continue
        var child_socket: Dictionary = {}
        var child_socket_id = attachment.get("child_socket_id")
        if child_socket_id != null and not str(child_socket_id).is_empty():
            child_socket = gameplay_state.get_socket(str(child_socket_id))
            if child_socket.is_empty(): unresolved.append(attachment_id); continue
        var anchor := Node3D.new(); anchor.name = "Attachment_%s" % attachment_id.substr(0, 8); anchor.set_meta(ANCHOR_META, attachment_id)
        parent.add_child(anchor)
        anchor.transform = _transform(parent_socket.get("local_transform", {})) * _transform(attachment.get("offset_transform", {}))
        child.reparent(anchor, false)
        child.transform = _transform(child_socket.get("local_transform", {})).affine_inverse() if not child_socket.is_empty() else Transform3D.IDENTITY
        resolved.append(attachment_id)
    return {"ok": true, "errors": [], "resolved": resolved, "unresolved": unresolved}


static func _transform(data: Dictionary) -> Transform3D:
    if data.is_empty(): return Transform3D.IDENTITY
    var position := _vector3(data.get("position", [0.0, 0.0, 0.0]))
    var rotation := _vector3(data.get("rotation_degrees", [0.0, 0.0, 0.0]))
    var scale := _vector3(data.get("scale", [1.0, 1.0, 1.0]))
    var basis := Basis.from_euler(Vector3(deg_to_rad(rotation.x), deg_to_rad(rotation.y), deg_to_rad(rotation.z))).scaled(scale)
    return Transform3D(basis, position)


static func _vector3(value: Array) -> Vector3: return Vector3(float(value[0]), float(value[1]), float(value[2]))
static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
