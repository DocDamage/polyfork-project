class_name PlayWorldTerrainChunkNode
extends Node3D

const MeshBuilder = preload("res://src/terrain/terrain_mesh_builder.gd")
const CELL_ID_META: StringName = &"playworld_terrain_cell_id"

var cell_id: String = ""
var revision: int = -1


func apply_cell(cell: Dictionary, biome: Dictionary) -> Dictionary:
    _clear_content()
    var mesh: ArrayMesh = MeshBuilder.build_mesh(cell)
    if mesh == null: return _failure("Terrain chunk could not build a mesh from the cell record.")
    cell_id = str(cell.get("cell_id", ""))
    revision = int(cell.get("revision", 0))
    set_meta(CELL_ID_META, cell_id)
    var coord: Array = cell.get("coord", [0, 0])
    var size: float = float(cell.get("cell_size_m", 0.0))
    position = Vector3(float(int(coord[0])) * size, 0.0, float(int(coord[1])) * size)
    var material := StandardMaterial3D.new()
    var color: Array = biome.get("color", [0.28, 0.48, 0.30, 1.0])
    var biome_color := Color(0.28, 0.48, 0.30, 1.0)
    if color.size() == 4:
        biome_color = Color(float(color[0]), float(color[1]), float(color[2]), float(color[3]))
    material.albedo_color = biome_color
    material.roughness = 0.92
    material.emission_enabled = true
    material.emission = biome_color.darkened(0.48)
    material.emission_energy_multiplier = 0.55
    mesh.surface_set_material(0, material)
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = "TerrainMesh"
    mesh_instance.mesh = mesh
    mesh_instance.set_meta(CELL_ID_META, cell_id)
    add_child(mesh_instance)
    var shape: Shape3D = mesh.create_trimesh_shape()
    if shape is ConcavePolygonShape3D:
        shape.backface_collision = true
    if shape != null:
        var body := StaticBody3D.new()
        body.name = "TerrainCollision"
        body.set_meta(CELL_ID_META, cell_id)
        var collision := CollisionShape3D.new()
        collision.name = "CollisionShape3D"
        collision.shape = shape
        body.add_child(collision)
        add_child(body)
    return {"ok": true, "errors": [], "cell_id": cell_id, "revision": revision}


func _clear_content() -> void:
    for child in get_children():
        remove_child(child)
        child.free()


func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}