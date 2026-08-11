extends RefCounted

const WorldProject = preload("res://src/world/world_project.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new()
    project.initialize_new("Placement Snap", &"small", "blank_sandbox")
    var session = EditorSession.new()
    var bind_result: Dictionary = session.bind_project(project, func() -> Dictionary:
        return {"ok": true, "errors": []}
    )
    if not bind_result.get("ok", false):
        errors.append("Placement snapping fixture must bind an editor session.")
        session.free()
        return errors

    session.begin_proxy_placement("Anchor")
    session.update_placement_preview(Vector3(2.0, 1.0, 4.0))
    var first: Dictionary = session.commit_placement()
    if not first.get("ok", false):
        errors.append("Placement snapping fixture must create its anchor entity.")
        session.free()
        return errors

    session.set_snap_enabled(&"object", true)
    session.begin_proxy_placement("Object Snap")
    var object_preview: Dictionary = session.update_placement_preview(Vector3(2.6, 1.0, 4.0))
    var object_position: Array = object_preview.get("record", {}).get("transform", {}).get("position", [])
    if object_preview.get("snap_mode") != "object" or object_position != [2.0, 1.0, 4.0]:
        errors.append("Object-enabled placement must discover bridged runtime entities without caller-supplied candidates.")
    session.cancel_placement()

    session.set_snap_enabled(&"object", false)
    session.set_snap_enabled(&"socket", true)
    session.begin_proxy_placement("Socket Snap")
    var socket_preview: Dictionary = session.update_placement_preview(Vector3(2.4, 1.0, 4.0))
    var socket_position: Array = socket_preview.get("record", {}).get("transform", {}).get("position", [])
    if socket_preview.get("snap_mode") != "socket" or socket_position != [2.0, 1.0, 4.0]:
        errors.append("Socket-enabled placement must expose deterministic proxy-origin sockets until richer socket metadata exists.")
    session.cancel_placement()

    session.free()
    return errors
