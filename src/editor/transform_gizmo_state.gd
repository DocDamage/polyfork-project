class_name PlayWorldTransformGizmoState
extends RefCounted

const VALID_MODES := [&"select", &"move", &"rotate", &"scale"]
const VALID_AXES := [&"free", &"x", &"y", &"z"]

var mode: StringName = &"select"
var axis: StringName = &"free"
var local_space := false


func set_mode(value: StringName) -> Dictionary:
    if not VALID_MODES.has(value):
        return {"ok": false, "errors": ["Unsupported transform tool: %s" % value]}
    mode = value
    return {"ok": true, "errors": []}


func set_axis(value: StringName) -> Dictionary:
    if not VALID_AXES.has(value):
        return {"ok": false, "errors": ["Unsupported transform axis: %s" % value]}
    axis = value
    return {"ok": true, "errors": []}


func set_local_space(enabled: bool) -> void:
    local_space = enabled


func constrain(value: Vector3) -> Vector3:
    match axis:
        &"x": return Vector3(value.x, 0.0, 0.0)
        &"y": return Vector3(0.0, value.y, 0.0)
        &"z": return Vector3(0.0, 0.0, value.z)
    return value
