extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const TerrainSchema = preload("res://src/terrain/terrain_schema.gd")
const MeshBuilder = preload("res://src/terrain/terrain_mesh_builder.gd")
const TerrainBrush = preload("res://src/terrain/terrain_brush.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var cell: Dictionary = _cell(5, 4.0)
    var mesh: ArrayMesh = MeshBuilder.build_mesh(cell)
    if mesh == null or MeshBuilder.vertex_count(cell) != 96 or MeshBuilder.triangle_count(cell) != 32:
        errors.append("A 5x5 terrain grid must deterministically build 32 triangles / 96 triangle vertices.")
    var heights: Array = cell["heights"]
    heights[12] = 3.0
    cell["heights"] = heights
    if not is_equal_approx(MeshBuilder.sample_height(cell, Vector3.ZERO), 3.0):
        errors.append("Terrain height sampling must resolve the deterministic center grid sample.")

    var flat: Dictionary = _cell(5, 4.0)
    var raise_result: Dictionary = TerrainBrush.apply(flat, {"mode": "raise", "center": Vector3.ZERO, "radius": 2.1, "strength": 2.0})
    if not raise_result.get("ok", false) or float(raise_result.get("heights", [])[12]) <= 0.0:
        errors.append("Raise brush must increase overlapped terrain samples.")
    var raised: Dictionary = flat.duplicate(true)
    raised["heights"] = raise_result.get("heights", []).duplicate()
    var lower_result: Dictionary = TerrainBrush.apply(raised, {"mode": "lower", "center": Vector3.ZERO, "radius": 2.1, "strength": 2.0})
    if not lower_result.get("ok", false) or float(lower_result.get("heights", [])[12]) >= float(raised.get("heights", [])[12]):
        errors.append("Lower brush must decrease overlapped terrain samples.")

    var peak: Dictionary = _cell(5, 4.0)
    var peak_heights: Array = peak["heights"]
    peak_heights[12] = 8.0
    peak["heights"] = peak_heights
    var smooth_result: Dictionary = TerrainBrush.apply(peak, {"mode": "smooth", "center": Vector3.ZERO, "radius": 1.1, "strength": 1.0})
    if not smooth_result.get("ok", false) or float(smooth_result.get("heights", [])[12]) >= 8.0:
        errors.append("Smooth brush must move an isolated peak toward its neighborhood average.")
    var flatten_result: Dictionary = TerrainBrush.apply(peak, {"mode": "flatten", "center": Vector3.ZERO, "radius": 2.1, "strength": 1.0, "target_height": 2.0})
    if not flatten_result.get("ok", false) or not is_equal_approx(float(flatten_result.get("heights", [])[12]), 2.0):
        errors.append("Flatten brush at full strength must set the center sample to the requested height.")

    var outside: Dictionary = TerrainBrush.apply(flat, {"mode": "raise", "center": Vector3(100.0, 0.0, 100.0), "radius": 1.0, "strength": 1.0})
    if outside.get("ok", false):
        errors.append("A brush outside the cell must fail without reporting a committed terrain edit.")
    return errors


static func _cell(resolution: int, size: float) -> Dictionary:
    var heights: Array[float] = []
    heights.resize(resolution * resolution)
    heights.fill(0.0)
    return {
        "document_type": TerrainSchema.CELL_TYPE,
        "schema_version": TerrainSchema.SCHEMA_VERSION,
        "project_id": StableId.generate(),
        "cell_id": StableId.generate(),
        "coord": [0, 0],
        "cell_size_m": size,
        "resolution": resolution,
        "heights": heights,
        "revision": 0,
        "biome_id": StableId.generate(),
        "saved_at_msec": 1
    }
