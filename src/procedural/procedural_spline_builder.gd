class_name PlayWorldProceduralSplineBuilder
extends RefCounted


func build(spline: Dictionary, active_cell_ids: Array[String], terrain_state, terrain_runtime, source_resolver) -> Dictionary:
    if terrain_state == null or terrain_runtime == null:
        return _failure("Spline runtime generation requires terrain state and runtime.")
    var samples: Array[Vector3] = _sample_spline(spline, terrain_runtime)
    if samples.size() < 2:
        return _failure("Spline runtime requires at least two sampled points.")
    match str(spline.get("kind", "")):
        "road", "path": return _build_ribbon(spline, samples, active_cell_ids, terrain_state)
        "fence": return _build_fence(spline, samples, active_cell_ids, terrain_state, source_resolver)
    return _failure("Unsupported spline runtime kind.")


func _build_ribbon(spline: Dictionary, samples: Array[Vector3], active_cell_ids: Array[String], terrain_state) -> Dictionary:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var half_width: float = float(spline.get("width_m", 1.0)) * 0.5
    var active_set: Dictionary = _set_from_ids(active_cell_ids)
    var segment_count: int = 0
    for index in range(samples.size() - 1):
        var start: Vector3 = samples[index]
        var finish: Vector3 = samples[index + 1]
        var midpoint: Vector3 = (start + finish) * 0.5
        var cell_id: String = terrain_state.cell_id_at_position(midpoint)
        if cell_id.is_empty() or not active_set.has(cell_id):
            continue
        var direction: Vector3 = finish - start
        direction.y = 0.0
        if direction.length_squared() < 0.0001:
            continue
        direction = direction.normalized()
        var side := Vector3(-direction.z, 0.0, direction.x) * half_width
        var lift := Vector3(0.0, 0.08, 0.0)
        var a: Vector3 = start - side + lift
        var b: Vector3 = start + side + lift
        var c: Vector3 = finish - side + lift
        var d: Vector3 = finish + side + lift
        _triangle(surface, a, c, b, Vector2(0.0, 0.0), Vector2(0.0, 1.0), Vector2(1.0, 0.0))
        _triangle(surface, b, c, d, Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0))
        segment_count += 1
    if segment_count == 0:
        return {"ok": true, "errors": [], "nodes": [], "segment_count": 0}
    var mesh: ArrayMesh = surface.commit()
    var node := MeshInstance3D.new()
    node.name = "%s_%s" % [str(spline.get("kind", "spline")).capitalize(), str(spline.get("spline_id", "")).substr(0, 8)]
    node.mesh = mesh
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.22, 0.24, 0.27, 1.0) if str(spline.get("kind", "")) == "road" else Color(0.46, 0.34, 0.20, 1.0)
    material.roughness = 0.95
    node.material_override = material
    node.set_meta("spline_id", str(spline.get("spline_id", "")))
    node.set_meta("spline_kind", str(spline.get("kind", "")))
    return {"ok": true, "errors": [], "nodes": [node], "segment_count": segment_count}


func _build_fence(spline: Dictionary, samples: Array[Vector3], active_cell_ids: Array[String], terrain_state, source_resolver) -> Dictionary:
    if source_resolver == null:
        return _failure("Fence spline generation requires a procedural source resolver.")
    var source_result: Dictionary = source_resolver.resolve_mesh(spline.get("segment_source", {}))
    if not source_result.get("ok", false):
        return source_result
    var mesh: Mesh = source_result.get("mesh") as Mesh
    if mesh == null:
        return _failure("Fence spline source did not resolve to a mesh.")
    var active_set: Dictionary = _set_from_ids(active_cell_ids)
    var transforms: Array[Transform3D] = []
    for index in range(samples.size()):
        var position_value: Vector3 = samples[index]
        var cell_id: String = terrain_state.cell_id_at_position(position_value)
        if cell_id.is_empty() or not active_set.has(cell_id):
            continue
        var tangent: Vector3
        if index + 1 < samples.size(): tangent = samples[index + 1] - position_value
        else: tangent = position_value - samples[index - 1]
        tangent.y = 0.0
        var yaw: float = 0.0 if tangent.length_squared() < 0.0001 else atan2(tangent.x, tangent.z)
        transforms.append(Transform3D(Basis(Vector3.UP, yaw), position_value + Vector3(0.0, 0.9, 0.0)))
    if transforms.is_empty():
        return {"ok": true, "errors": [], "nodes": [], "segment_count": 0}
    var multi_mesh := MultiMesh.new()
    multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
    multi_mesh.mesh = mesh
    multi_mesh.instance_count = transforms.size()
    for index in range(transforms.size()): multi_mesh.set_instance_transform(index, transforms[index])
    var node := MultiMeshInstance3D.new()
    node.name = "Fence_%s" % str(spline.get("spline_id", "")).substr(0, 8)
    node.multimesh = multi_mesh
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    node.set_meta("spline_id", str(spline.get("spline_id", "")))
    node.set_meta("spline_kind", "fence")
    return {"ok": true, "errors": [], "nodes": [node], "segment_count": transforms.size()}


func _sample_spline(spline: Dictionary, terrain_runtime) -> Array[Vector3]:
    var controls: Array[Vector3] = []
    for value in spline.get("points", []):
        if not value is Dictionary: continue
        var position_value: Variant = value.get("position", [])
        if position_value is Array and position_value.size() == 3:
            controls.append(Vector3(float(position_value[0]), float(position_value[1]), float(position_value[2])))
    if controls.size() < 2: return []
    if bool(spline.get("closed", false)): controls.append(controls[0])
    var spacing: float = maxf(0.25, float(spline.get("sample_spacing_m", 2.0)))
    var result: Array[Vector3] = []
    for index in range(controls.size() - 1):
        var start: Vector3 = controls[index]
        var finish: Vector3 = controls[index + 1]
        var distance: float = start.distance_to(finish)
        var divisions: int = maxi(1, int(ceil(distance / spacing)))
        for step in range(divisions):
            if index > 0 and step == 0: continue
            var t: float = float(step) / float(divisions)
            result.append(_conform(start.lerp(finish, t), spline, terrain_runtime))
        result.append(_conform(finish, spline, terrain_runtime))
    return _dedupe_samples(result)


static func _conform(position_value: Vector3, spline: Dictionary, terrain_runtime) -> Vector3:
    if not bool(spline.get("terrain_conform", true)): return position_value
    return Vector3(position_value.x, terrain_runtime.sample_height(position_value), position_value.z)


static func _dedupe_samples(samples: Array[Vector3]) -> Array[Vector3]:
    var result: Array[Vector3] = []
    for sample in samples:
        if result.is_empty() or result[-1].distance_squared_to(sample) > 0.000001: result.append(sample)
    return result


static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, uv_a: Vector2, uv_b: Vector2, uv_c: Vector2) -> void:
    surface.set_normal(Vector3.UP); surface.set_uv(uv_a); surface.add_vertex(a)
    surface.set_normal(Vector3.UP); surface.set_uv(uv_b); surface.add_vertex(b)
    surface.set_normal(Vector3.UP); surface.set_uv(uv_c); surface.add_vertex(c)


static func _set_from_ids(ids: Array[String]) -> Dictionary:
    var result: Dictionary = {}
    for value in ids: result[value] = true
    return result


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
