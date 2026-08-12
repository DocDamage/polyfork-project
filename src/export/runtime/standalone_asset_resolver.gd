class_name PlayWorldStandaloneAssetResolver
extends RefCounted

const PrefabResolver = preload("res://src/gameplay/prefab_resolver.gd")

var _dependencies: Dictionary = {}
var _gameplay_state

func bind_manifest(manifest: Dictionary, gameplay_state = null) -> Dictionary:
    _dependencies.clear(); _gameplay_state = gameplay_state
    for value in manifest.get("dependencies", []):
        if not value is Dictionary: return _failure("Standalone export manifest contains an invalid dependency entry.")
        var dependency: Dictionary = value
        var asset_id: String = str(dependency.get("asset_id", ""))
        var package_path: String = str(dependency.get("package_path", ""))
        if asset_id.is_empty() or package_path.is_empty(): return _failure("Standalone export dependency is incomplete.")
        _dependencies[asset_id] = package_path
    return {"ok": true, "errors": [], "dependency_count": _dependencies.size()}

func instantiate_asset_scene(asset_id: String) -> Dictionary:
    if not _dependencies.has(asset_id): return _failure("Standalone asset dependency does not resolve: %s" % asset_id)
    var resource_path: String = "res://%s" % str(_dependencies[asset_id])
    if not ResourceLoader.exists(resource_path): return _failure("Standalone packaged asset is unavailable: %s" % asset_id)
    var resource: Resource = ResourceLoader.load(resource_path)
    if resource is PackedScene:
        var node: Node = (resource as PackedScene).instantiate()
        if node is Node3D: return {"ok": true, "errors": [], "node": node}
        node.free(); return _failure("Standalone packaged asset root must be Node3D.")
    if resource is Mesh:
        var mesh_node := MeshInstance3D.new(); mesh_node.mesh = resource as Mesh
        return {"ok": true, "errors": [], "node": mesh_node}
    return _failure("Standalone packaged asset is not a supported scene or mesh resource: %s" % asset_id)

func resolve_mesh(source: Dictionary) -> Dictionary:
    var kind: String = str(source.get("kind", ""))
    if kind == "primitive": return _primitive_mesh(str(source.get("primitive", "")))
    if kind == "asset": return _asset_mesh(str(source.get("source_id", "")))
    if kind == "prefab": return _prefab_mesh(str(source.get("source_id", "")))
    return _failure("Unsupported standalone procedural source kind: %s" % kind)

func _asset_mesh(asset_id: String) -> Dictionary:
    var instantiated: Dictionary = instantiate_asset_scene(asset_id)
    if not instantiated.get("ok", false): return instantiated
    var root: Node = instantiated.get("node")
    var mesh: Mesh = _first_mesh(root)
    root.free()
    if mesh == null: return _failure("Standalone asset does not contain a MeshInstance3D mesh.")
    var duplicated: Resource = mesh.duplicate()
    if not duplicated is Mesh: return _failure("Standalone procedural asset mesh could not be duplicated.")
    return {"ok": true, "errors": [], "mesh": duplicated as Mesh, "source_kind": "asset", "source_id": asset_id}

func _prefab_mesh(prefab_id: String) -> Dictionary:
    if _gameplay_state == null: return _failure("Standalone prefab procedural sources require gameplay state.")
    var resolved: Dictionary = PrefabResolver.new(_gameplay_state).resolve(prefab_id)
    if not resolved.get("ok", false): return resolved
    for value in resolved.get("nodes", []):
        if not value is Dictionary: continue
        var asset_value: Variant = value.get("asset_id")
        if asset_value == null or str(asset_value).is_empty(): continue
        var result: Dictionary = _asset_mesh(str(asset_value))
        if result.get("ok", false): result["source_kind"] = "prefab"; result["prefab_id"] = prefab_id
        return result
    return _failure("Standalone prefab procedural source has no asset-backed visual node.")

static func _primitive_mesh(key: String) -> Dictionary:
    var mesh: PrimitiveMesh
    match key:
        "grass": var box := BoxMesh.new(); box.size = Vector3(0.16, 1.05, 0.16); mesh = box
        "shrub": var sphere := SphereMesh.new(); sphere.radius = 0.72; sphere.height = 1.35; sphere.radial_segments = 8; sphere.rings = 4; mesh = sphere
        "tree": var cone := CylinderMesh.new(); cone.top_radius = 0.08; cone.bottom_radius = 1.15; cone.height = 3.6; cone.radial_segments = 10; mesh = cone
        "post": var post := BoxMesh.new(); post.size = Vector3(0.28, 1.8, 0.28); mesh = post
        _: return _failure("Unsupported standalone procedural primitive: %s" % key)
    return {"ok": true, "errors": [], "mesh": mesh, "source_kind": "primitive"}

static func _first_mesh(root: Node) -> Mesh:
    if root is MeshInstance3D and (root as MeshInstance3D).mesh != null: return (root as MeshInstance3D).mesh
    for child in root.find_children("*", "MeshInstance3D", true, false):
        var mesh_node: MeshInstance3D = child as MeshInstance3D
        if mesh_node != null and mesh_node.mesh != null: return mesh_node.mesh
    return null

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
