class_name PlayWorldTerrainMeshBuilder
extends RefCounted


static func build_mesh(cell: Dictionary) -> ArrayMesh:
    var resolution: int = int(cell.get("resolution", 0))
    var size: float = float(cell.get("cell_size_m", 0.0))
    var heights: Array = cell.get("heights", [])
    if resolution < 3 or size <= 0.0 or heights.size() != resolution * resolution: return null
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for z in range(resolution - 1):
        for x in range(resolution - 1):
            _add_vertex(surface, cell, x, z)
            _add_vertex(surface, cell, x + 1, z + 1)
            _add_vertex(surface, cell, x + 1, z)
            _add_vertex(surface, cell, x, z)
            _add_vertex(surface, cell, x, z + 1)
            _add_vertex(surface, cell, x + 1, z + 1)
    surface.generate_normals()
    return surface.commit() as ArrayMesh


static func sample_height(cell: Dictionary, world_position: Vector3) -> float:
    var resolution: int = int(cell.get("resolution", 0))
    if resolution < 2: return 0.0
    var size: float = float(cell.get("cell_size_m", 0.0))
    var coord: Array = cell.get("coord", [0, 0])
    var center_x: float = float(int(coord[0])) * size
    var center_z: float = float(int(coord[1])) * size
    var local_x: float = clamp(world_position.x - center_x + size * 0.5, 0.0, size)
    var local_z: float = clamp(world_position.z - center_z + size * 0.5, 0.0, size)
    var gx: int = int(round(local_x / size * float(resolution - 1)))
    var gz: int = int(round(local_z / size * float(resolution - 1)))
    var heights: Array = cell.get("heights", [])
    var index: int = clampi(gz, 0, resolution - 1) * resolution + clampi(gx, 0, resolution - 1)
    return float(heights[index]) if index >= 0 and index < heights.size() else 0.0


static func vertex_count(cell: Dictionary) -> int:
    var resolution: int = int(cell.get("resolution", 0))
    return max(0, (resolution - 1) * (resolution - 1) * 6)


static func triangle_count(cell: Dictionary) -> int:
    return int(vertex_count(cell) / 3)


static func _add_vertex(surface: SurfaceTool, cell: Dictionary, x: int, z: int) -> void:
    var resolution: int = int(cell["resolution"])
    var size: float = float(cell["cell_size_m"])
    var heights: Array = cell["heights"]
    var u: float = float(x) / float(resolution - 1)
    var v: float = float(z) / float(resolution - 1)
    surface.set_uv(Vector2(u, v))
    surface.add_vertex(Vector3((u - 0.5) * size, float(heights[z * resolution + x]), (v - 0.5) * size))
