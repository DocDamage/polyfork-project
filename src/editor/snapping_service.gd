class_name PlayWorldSnappingService
extends RefCounted

var grid_enabled := true
var surface_enabled := false
var vertex_enabled := false
var object_enabled := false
var socket_enabled := false
var grid_size := 1.0
var angle_step_degrees := 15.0
var vertex_threshold := 1.0
var object_threshold := 1.5
var socket_threshold := 2.0

func set_mode_enabled(mode: StringName, enabled: bool) -> Dictionary:
    match mode:
        &"grid": grid_enabled = enabled
        &"surface": surface_enabled = enabled
        &"vertex": vertex_enabled = enabled
        &"object": object_enabled = enabled
        &"socket": socket_enabled = enabled
        _: return {"ok": false, "errors": ["Unknown snapping mode: %s" % mode]}
    return {"ok": true, "errors": []}

func is_mode_enabled(mode: StringName) -> bool:
    match mode:
        &"grid": return grid_enabled
        &"surface": return surface_enabled
        &"vertex": return vertex_enabled
        &"object": return object_enabled
        &"socket": return socket_enabled
    return false

func snap_position(value: Vector3) -> Vector3:
    if not grid_enabled or grid_size <= 0.0: return value
    return Vector3(snappedf(value.x, grid_size), snappedf(value.y, grid_size), snappedf(value.z, grid_size))

func snap_rotation(value: Vector3) -> Vector3:
    if angle_step_degrees <= 0.0: return value
    return Vector3(snappedf(value.x, angle_step_degrees), snappedf(value.y, angle_step_degrees), snappedf(value.z, angle_step_degrees))

func drop_to_ground(value: Vector3, ground_y: float = 0.0) -> Vector3: return Vector3(value.x, ground_y, value.z)

func snap_to_surface(hit_position: Vector3, hit_normal: Vector3, offset: float = 0.5) -> Vector3:
    var normal := hit_normal.normalized()
    if normal.is_zero_approx(): normal = Vector3.UP
    return hit_position + normal * offset

func surface_rotation(hit_normal: Vector3) -> Vector3:
    var up := hit_normal.normalized()
    if up.is_zero_approx(): up = Vector3.UP
    if up.is_equal_approx(Vector3.UP): return Vector3.ZERO
    if up.is_equal_approx(Vector3.DOWN): return Vector3(180.0, 0.0, 0.0)
    var alignment := Quaternion(Vector3.UP, up)
    return alignment.get_euler() * (180.0 / PI)

func snap_to_vertex(value: Vector3, candidates: Array) -> Dictionary: return _nearest_candidate(value, candidates, vertex_threshold, "vertex")
func snap_to_object(value: Vector3, candidates: Array) -> Dictionary: return _nearest_candidate(value, candidates, object_threshold, "object")
func snap_to_socket(value: Vector3, candidates: Array) -> Dictionary: return _nearest_candidate(value, candidates, socket_threshold, "socket")

func resolve_position(value: Vector3, context: Dictionary = {}) -> Dictionary:
    var result := snap_position(value)
    var mode := "grid" if grid_enabled else "free"
    if surface_enabled and context.has("surface_position"):
        var surface_position: Vector3 = context["surface_position"]
        var surface_normal: Vector3 = context.get("surface_normal", Vector3.UP)
        result = snap_to_surface(surface_position, surface_normal, float(context.get("surface_offset", 0.5))); mode = "surface"
    if vertex_enabled:
        var vertex_result := snap_to_vertex(result, context.get("vertex_candidates", []))
        if vertex_result.get("snapped", false): result = vertex_result["position"]; mode = "vertex"
    if object_enabled:
        var object_result := snap_to_object(result, context.get("object_candidates", []))
        if object_result.get("snapped", false): result = object_result["position"]; mode = "object"
    if socket_enabled:
        var socket_result := snap_to_socket(result, context.get("socket_candidates", []))
        if socket_result.get("snapped", false): result = socket_result["position"]; mode = "socket"
    return {"position": result, "mode": mode}

func _nearest_candidate(value: Vector3, candidates: Array, threshold: float, kind: String) -> Dictionary:
    var best_id := ""; var best_position := value; var best_distance := INF
    for item in candidates:
        if not item is Dictionary or not item.has("position"): continue
        var candidate_position: Vector3 = item["position"]
        var candidate_id := str(item.get("id", ""))
        var distance := value.distance_to(candidate_position)
        if distance > threshold: continue
        if distance < best_distance or (is_equal_approx(distance, best_distance) and candidate_id < best_id):
            best_distance = distance; best_id = candidate_id; best_position = candidate_position
    return {"snapped": not best_id.is_empty(), "position": best_position, "id": best_id, "kind": kind, "distance": best_distance}
