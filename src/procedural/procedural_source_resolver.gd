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
    var mesh: PrimitiveMesh
    var color := Color(0.35, 0.70, 0.27, 1.0)
    match key:
        "grass":
            var box := BoxMesh.new()
            box.size = Vector3(0.16, 1.05, 0.16)
            mesh = box
            color = Color(0.30, 0.72, 0.24, 1.0)
        "shrub":
            var sphere := SphereMesh.new()
            sphere.radius = 0.72
            sphere.height = 1.35
            sphere.radial_segments = 8
            sphere.rings = 4
            mesh = sphere
            color = Color(0.22, 0.58, 0.20, 1.0)
        "tree":
            var cone := CylinderMesh.new()
            cone.top_radius = 0.08
            cone.bottom_radius = 1.15
            cone.height = 3.6
            cone.radial_segments = 10
            mesh = cone
            color = Color(0.16, 0.46, 0.18, 1.0)
        "post":
            var post := BoxMesh.new()
            post.size = Vector3(0.28, 1.8, 0.28)
            mesh = post
            color = Color(0.43, 0.25, 0.12, 1.0)
        _: return _failure("Unsupported procedural primitive: %s" % key)
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.95
    mesh.material = material
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
