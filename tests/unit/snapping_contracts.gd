extends RefCounted

const SnappingService = preload("res://src/editor/snapping_service.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var snapping = SnappingService.new()

    var grid_position: Vector3 = snapping.snap_position(Vector3(1.24, 2.51, -0.49))
    if grid_position != Vector3(1.0, 3.0, 0.0):
        errors.append("Grid snapping must deterministically round all position axes.")

    var rotation: Vector3 = snapping.snap_rotation(Vector3(7.0, 22.0, -16.0))
    if rotation != Vector3(0.0, 15.0, -15.0):
        errors.append("Angle snapping must use the configured step deterministically.")

    var surface: Vector3 = snapping.snap_to_surface(Vector3(3.0, 4.0, 5.0), Vector3.UP, 0.5)
    if surface != Vector3(3.0, 4.5, 5.0):
        errors.append("Surface snapping must offset along the normalized surface normal.")

    var object_result: Dictionary = snapping.snap_to_object(Vector3.ZERO, [
        {"id": "b", "position": Vector3(1.0, 0.0, 0.0)},
        {"id": "a", "position": Vector3(-1.0, 0.0, 0.0)}
    ])
    if not object_result.get("snapped", false) or object_result.get("id") != "a":
        errors.append("Equal-distance object snapping must use stable candidate-ID tie breaking.")

    var socket_result: Dictionary = snapping.snap_to_socket(Vector3.ZERO, [
        {"id": "socket-1", "position": Vector3(0.0, 0.0, 1.5)}
    ])
    if not socket_result.get("snapped", false) or socket_result.get("position") != Vector3(0.0, 0.0, 1.5):
        errors.append("Socket snapping must resolve in-range socket candidates.")

    if snapping.drop_to_ground(Vector3(2.0, 8.0, 4.0), 0.5) != Vector3(2.0, 0.5, 4.0):
        errors.append("Drop-to-ground must preserve horizontal position and apply ground height.")

    var disable_result: Dictionary = snapping.set_mode_enabled(&"grid", false)
    if not disable_result.get("ok", false) or snapping.snap_position(Vector3(1.2, 0.0, 1.2)) != Vector3(1.2, 0.0, 1.2):
        errors.append("Disabled grid snapping must leave positions unchanged.")

    var invalid_result: Dictionary = snapping.set_mode_enabled(&"unknown", true)
    if invalid_result.get("ok", false):
        errors.append("Unknown snapping modes must fail explicitly.")
    return errors
