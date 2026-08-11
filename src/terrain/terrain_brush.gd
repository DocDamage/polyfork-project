class_name PlayWorldTerrainBrush
extends RefCounted

const MODES: Array[StringName] = [&"raise", &"lower", &"smooth", &"flatten"]


static func apply(cell: Dictionary, brush: Dictionary) -> Dictionary:
    var mode: StringName = StringName(str(brush.get("mode", "")))
    if not MODES.has(mode): return _failure("Terrain brush mode is unsupported.")
    var center_value: Variant = brush.get("center", Vector3.ZERO)
    if not center_value is Vector3: return _failure("Terrain brush center must be a Vector3.")
    var center: Vector3 = center_value
    var radius: float = float(brush.get("radius", 0.0))
    var strength: float = float(brush.get("strength", 0.0))
    if radius <= 0.0 or strength <= 0.0: return _failure("Terrain brush radius and strength must be positive.")
    var resolution: int = int(cell.get("resolution", 0))
    var size: float = float(cell.get("cell_size_m", 0.0))
    var coord: Array = cell.get("coord", [])
    var source: Array = cell.get("heights", [])
    if resolution < 3 or coord.size() != 2 or source.size() != resolution * resolution: return _failure("Terrain cell cannot be sculpted because its grid is invalid.")
    var output: Array = source.duplicate()
    var center_x: float = float(int(coord[0])) * size
    var center_z: float = float(int(coord[1])) * size
    var target_height: float = float(brush.get("target_height", _nearest_height(cell, center)))
    var changed: int = 0
    for z in range(resolution):
        for x in range(resolution):
            var u: float = float(x) / float(resolution - 1)
            var v: float = float(z) / float(resolution - 1)
            var world_x: float = center_x + (u - 0.5) * size
            var world_z: float = center_z + (v - 0.5) * size
            var distance: float = Vector2(world_x - center.x, world_z - center.z).length()
            if distance > radius: continue
            var weight: float = clamp(1.0 - distance / radius, 0.0, 1.0)
            var index: int = z * resolution + x
            var old_height: float = float(source[index])
            var next_height: float = old_height
            match mode:
                &"raise": next_height = old_height + strength * weight
                &"lower": next_height = old_height - strength * weight
                &"flatten": next_height = lerp(old_height, target_height, clamp(strength * weight, 0.0, 1.0))
                &"smooth":
                    var average: float = _neighbor_average(source, resolution, x, z)
                    next_height = lerp(old_height, average, clamp(strength * weight, 0.0, 1.0))
            if not is_equal_approx(next_height, old_height):
                output[index] = next_height
                changed += 1
    if changed == 0: return _failure("Terrain brush did not overlap any editable height samples.")
    return {"ok": true, "errors": [], "heights": output, "changed_samples": changed}


static func _nearest_height(cell: Dictionary, center: Vector3) -> float:
    var resolution: int = int(cell.get("resolution", 0))
    var size: float = float(cell.get("cell_size_m", 0.0))
    var coord: Array = cell.get("coord", [0, 0])
    var center_x: float = float(int(coord[0])) * size
    var center_z: float = float(int(coord[1])) * size
    var local_x: float = clamp(center.x - center_x + size * 0.5, 0.0, size)
    var local_z: float = clamp(center.z - center_z + size * 0.5, 0.0, size)
    var x: int = clampi(int(round(local_x / size * float(resolution - 1))), 0, resolution - 1)
    var z: int = clampi(int(round(local_z / size * float(resolution - 1))), 0, resolution - 1)
    return float(cell.get("heights", [])[z * resolution + x])


static func _neighbor_average(values: Array, resolution: int, x: int, z: int) -> float:
    var total: float = 0.0
    var count: int = 0
    for dz in range(-1, 2):
        for dx in range(-1, 2):
            var nx: int = x + dx
            var nz: int = z + dz
            if nx < 0 or nz < 0 or nx >= resolution or nz >= resolution: continue
            total += float(values[nz * resolution + nx])
            count += 1
    return total / float(max(1, count))


static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
