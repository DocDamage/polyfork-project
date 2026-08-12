class_name PlayWorldScatterGenerator
extends RefCounted


func generate_for_cell(layer: Dictionary, foliage_set: Dictionary, cell_id: String, terrain_state, terrain_runtime) -> Dictionary:
    if terrain_state == null or terrain_runtime == null:
        return _failure("Scatter generation requires terrain state and runtime height sampling.")
    if not bool(layer.get("enabled", true)):
        return {"ok": true, "errors": [], "transforms": [], "instance_count": 0}
    var cell: Dictionary = terrain_state.get_cell(cell_id)
    if cell.is_empty():
        return _failure("Scatter generation requested an unknown terrain cell.")
    var biome_ids: Array = layer.get("biome_ids", [])
    if not biome_ids.is_empty() and not biome_ids.has(str(cell.get("biome_id", ""))):
        return {"ok": true, "errors": [], "transforms": [], "instance_count": 0}
    var paints: Array[Dictionary] = []
    var erases: Array[Dictionary] = []
    for value in layer.get("strokes", []):
        if not value is Dictionary:
            continue
        var stroke: Dictionary = value
        if str(stroke.get("cell_id", "")) != cell_id:
            continue
        if str(stroke.get("operation", "")) == "paint":
            paints.append(stroke)
        elif str(stroke.get("operation", "")) == "erase":
            erases.append(stroke)
    paints.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return str(a.get("stroke_id", "")) < str(b.get("stroke_id", ""))
    )
    erases.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return str(a.get("stroke_id", "")) < str(b.get("stroke_id", ""))
    )
    var transforms: Array[Transform3D] = []
    var accepted_positions: Array[Vector3] = []
    var density: float = float(layer.get("density_per_100m2", 1.0))
    var minimum_spacing: float = float(layer.get("minimum_spacing_m", 0.0))
    var max_instances: int = int(foliage_set.get("max_instances_per_cell", 1))
    var scale_range: Array = foliage_set.get("scale_range", [1.0, 1.0])
    var slope_range: Array = layer.get("slope_range_deg", [0.0, 90.0])
    var height_range: Array = layer.get("height_range_m", [-100000.0, 100000.0])
    for stroke in paints:
        if transforms.size() >= max_instances:
            break
        var center: Vector3 = _vector3(stroke.get("center", []))
        var radius: float = float(stroke.get("radius_m", 1.0))
        var strength: float = float(stroke.get("strength", 1.0))
        var area_m2: float = PI * radius * radius
        var requested: int = maxi(1, int(round(area_m2 / 100.0 * density * strength)))
        requested = mini(requested, max_instances - transforms.size())
        var rng := RandomNumberGenerator.new()
        rng.seed = _stable_seed(int(layer.get("seed", 0)), str(stroke.get("stroke_id", "")), cell_id)
        var attempts: int = maxi(requested * 8, 16)
        var produced: int = 0
        for _attempt in range(attempts):
            if produced >= requested or transforms.size() >= max_instances:
                break
            var angle: float = rng.randf_range(0.0, TAU)
            var distance: float = sqrt(rng.randf()) * radius
            var candidate := Vector3(center.x + cos(angle) * distance, 0.0, center.z + sin(angle) * distance)
            if terrain_state.cell_id_at_position(candidate) != cell_id:
                continue
            var height: float = terrain_runtime.sample_height(candidate)
            if height < float(height_range[0]) or height > float(height_range[1]):
                continue
            candidate.y = height
            if _is_erased(candidate, erases):
                continue
            if minimum_spacing > 0.0 and _too_close(candidate, accepted_positions, minimum_spacing):
                continue
            var normal: Vector3 = _terrain_normal(candidate, terrain_runtime)
            var slope: float = rad_to_deg(acos(clampf(normal.dot(Vector3.UP), -1.0, 1.0)))
            if slope < float(slope_range[0]) or slope > float(slope_range[1]):
                continue
            var scale_value: float = rng.randf_range(float(scale_range[0]), float(scale_range[1]))
            var yaw: float = rng.randf_range(-PI, PI) if bool(foliage_set.get("random_yaw", true)) else 0.0
            var basis := Basis(Vector3.UP, yaw)
            if bool(foliage_set.get("align_to_normal", true)):
                basis = Basis(Quaternion(Vector3.UP, normal)) * basis
            basis = basis.scaled(Vector3.ONE * scale_value)
            transforms.append(Transform3D(basis, candidate))
            accepted_positions.append(candidate)
            produced += 1
    return {
        "ok": true,
        "errors": [],
        "transforms": transforms,
        "instance_count": transforms.size(),
        "cell_id": cell_id,
        "scatter_layer_id": str(layer.get("scatter_layer_id", "")),
    }


static func _is_erased(position_value: Vector3, erases: Array[Dictionary]) -> bool:
    for stroke in erases:
        var center: Vector3 = _vector3(stroke.get("center", []))
        var effective_radius: float = float(stroke.get("radius_m", 0.0)) * clampf(float(stroke.get("strength", 1.0)), 0.0, 1.0)
        var flat_delta := Vector2(position_value.x - center.x, position_value.z - center.z)
        if flat_delta.length() <= effective_radius:
            return true
    return false


static func _too_close(position_value: Vector3, accepted: Array[Vector3], minimum_spacing: float) -> bool:
    var minimum_squared: float = minimum_spacing * minimum_spacing
    for other in accepted:
        var dx: float = position_value.x - other.x
        var dz: float = position_value.z - other.z
        if dx * dx + dz * dz < minimum_squared:
            return true
    return false


static func _terrain_normal(position_value: Vector3, terrain_runtime) -> Vector3:
    var sample_step: float = 1.0
    var hx: float = terrain_runtime.sample_height(position_value + Vector3(sample_step, 0.0, 0.0))
    var hz: float = terrain_runtime.sample_height(position_value + Vector3(0.0, 0.0, sample_step))
    var dx := Vector3(sample_step, hx - position_value.y, 0.0)
    var dz := Vector3(0.0, hz - position_value.y, sample_step)
    var normal: Vector3 = dz.cross(dx).normalized()
    if normal.dot(Vector3.UP) < 0.0:
        normal = -normal
    return Vector3.UP if normal.length_squared() < 0.5 else normal


static func _vector3(value: Variant) -> Vector3:
    if not value is Array or value.size() != 3:
        return Vector3.ZERO
    return Vector3(float(value[0]), float(value[1]), float(value[2]))


static func _stable_seed(base_seed: int, stroke_id: String, cell_id: String) -> int:
    return int(base_seed) ^ int(stroke_id.hash()) ^ int(cell_id.hash())


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
