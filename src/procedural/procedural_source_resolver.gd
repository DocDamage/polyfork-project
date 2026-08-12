class_name PlayWorldProceduralSourceResolver
extends RefCounted

const PrefabResolver = preload("res://src/gameplay/prefab_resolver.gd")

var _asset_library
var _gameplay_service


func bind(asset_library = null, gameplay_service = null) -> void:
    _asset_library = asset_library
    _gameplay_service = gameplay_service


func resolve_mesh(source: Dictionary) -> Dictionary:
    var kind: String = str(source.get("kind", ""))
    match kind:
        "primitive": return _primitive_mesh(str(source.get("primitive", "")))
        "asset": return _asset_mesh(str(source.get("source_id", "")))
        "prefab": return _prefab_mesh(str(source.get("source_id", "")))
    return _failure("Unsupported procedural source kind: %s" % kind)


func _primitive_mesh(key: String) -> Dictionary:
    var mesh: Mesh
    match key:
        "grass":
            var quad := QuadMesh.new()
            quad.size = Vector2(0.75, 1.5)
            mesh = quad
        "shrub":
            var sphere := SphereMesh.new()
            sphere.radius = 0.65
            sphere.height = 1.25
            sphere.radial_segments = 8
            sphere.rings = 4
            mesh = sphere
        "tree":
            var cylinder := CylinderMesh.new()
            cylinder.top_radius = 0.28
            cylinder.bottom_radius = 0.42
            cylinder.height = 3.5
            cylinder.radial_segments = 8
            mesh = cylinder
        "post":
            var box := BoxMesh.new()
            box.size = Vector3(0.22, 1.8, 0.22)
            mesh = box
        _: return _failure("Unsupported procedural primitive: %s" % key)
    return {"ok": true, "errors": [], "mesh": mesh, "source_kind": "primitive"}


func _asset_mesh(asset_id: String) -> Dictionary:
    if _asset_library == null:
        return _failure("Asset-backed procedural sources require the Asset Library.")
    var instantiate_result: Dictionary = _asset_library.instantiate_asset_scene(asset_id)
    if not instantiate_result.get("ok", false):
        return instantiate_result
    var root_node: Node = instantiate_result.get("node")
    if root_node == null:
        return _failure("Asset Library procedural source did not instantiate a scene node.")
    var found_mesh: Mesh = _first_mesh(root_node)
    root_node.free()
    if found_mesh == null:
        return _failure("Asset Library source does not contain a MeshInstance3D mesh.")
    var copied: Resource = found_mesh.duplicate()
    var mesh: Mesh = copied as Mesh
    if mesh == null:
        return _failure("Asset Library source mesh could not be duplicated for procedural runtime use.")
    return {"ok": true, "errors": [], "mesh": mesh, "source_kind": "asset", "source_id": asset_id}


func _prefab_mesh(prefab_id: String) -> Dictionary:
    if _gameplay_service == null or _gameplay_service.get_state() == null:
        return _failure("Prefab-backed procedural sources require the gameplay prefab registry.")
    var resolver = PrefabResolver.new(_gameplay_service.get_state())
    var resolved: Dictionary = resolver.resolve(prefab_id)
    if not resolved.get("ok", false):
        return resolved
    for value in resolved.get("nodes", []):
        if not value is Dictionary:
            continue
        var node: Dictionary = value
        var asset_value: Variant = node.get("asset_id")
        if asset_value == null or str(asset_value).is_empty():
            continue
        var asset_result: Dictionary = _asset_mesh(str(asset_value))
        if asset_result.get("ok", false):
            asset_result["source_kind"] = "prefab"
            asset_result["prefab_id"] = prefab_id
            return asset_result
        return asset_result
    return _failure("Resolved prefab does not contain an asset-backed visual node for foliage batching.")


static func _first_mesh(root_node: Node) -> Mesh:
    if root_node is MeshInstance3D:
        var direct := root_node as MeshInstance3D
        if direct.mesh != null:
            return direct.mesh
    for child in root_node.find_children("*", "MeshInstance3D", true, false):
        var mesh_node := child as MeshInstance3D
        if mesh_node != null and mesh_node.mesh != null:
            return mesh_node.mesh
    return null


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
