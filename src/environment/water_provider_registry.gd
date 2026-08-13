class_name PlayWorldWaterProviderRegistry
extends RefCounted

const BASIC_PROVIDER := "basic_plane"
const IMPORTED_PROVIDER := "imported_scene"

func available_providers() -> Array[String]: return [BASIC_PROVIDER, IMPORTED_PROVIDER]
func has_provider(provider_key: String) -> bool: return available_providers().has(provider_key)

func instantiate_hook(hook: Dictionary) -> Dictionary:
    var provider_key: String = str(hook.get("provider_key", "")).strip_edges()
    var settings: Dictionary = hook.get("settings", {})
    match provider_key:
        BASIC_PROVIDER: return _create_basic(hook, settings)
        IMPORTED_PROVIDER: return _create_imported(hook, settings)
        _: return _failure("Unknown water provider: %s" % provider_key)

func apply_modifiers(root: Node3D, modifiers: Dictionary) -> Dictionary:
    if root == null: return _failure("Water modifier target is missing.")
    root.set_meta("water_modifiers", modifiers.duplicate(true))
    var tint_value: Variant = modifiers.get("tint", null)
    var opacity_value: Variant = modifiers.get("opacity", null)
    for mesh_node in _mesh_instances(root):
        var mesh_instance := mesh_node as MeshInstance3D
        var material := mesh_instance.material_override as StandardMaterial3D
        if material == null: continue
        var copy := material.duplicate() as StandardMaterial3D
        if tint_value is Array and tint_value.size() >= 3:
            var alpha: float = copy.albedo_color.a
            copy.albedo_color = Color(float(tint_value[0]), float(tint_value[1]), float(tint_value[2]), alpha)
        if opacity_value != null:
            var color: Color = copy.albedo_color
            color.a = clampf(float(opacity_value), 0.05, 1.0)
            copy.albedo_color = color
            copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 0.999 else BaseMaterial3D.TRANSPARENCY_DISABLED
        mesh_instance.material_override = copy
    return {"ok": true, "errors": []}

func _create_basic(hook: Dictionary, settings: Dictionary) -> Dictionary:
    var width: float = maxf(1.0, float(settings.get("width", settings.get("size", 80.0))))
    var depth: float = maxf(1.0, float(settings.get("depth", settings.get("size", 80.0))))
    var height: float = float(settings.get("height", 0.0))
    var color: Color = _color(settings.get("color", [0.10, 0.42, 0.62, 0.72]), Color(0.10, 0.42, 0.62, 0.72))
    var root := Node3D.new()
    root.name = _safe_name(str(hook.get("display_name", "Water")))
    root.position = _vector3(settings.get("position", [0.0, height, 0.0]), Vector3(0.0, height, 0.0))
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = "WaterSurface"
    var plane := PlaneMesh.new(); plane.size = Vector2(width, depth); mesh_instance.mesh = plane
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = clampf(float(settings.get("metallic", 0.0)), 0.0, 1.0)
    material.roughness = clampf(float(settings.get("roughness", 0.18)), 0.0, 1.0)
    if color.a < 0.999: material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh_instance.material_override = material
    root.add_child(mesh_instance)
    _tag(root, hook, BASIC_PROVIDER)
    return {"ok": true, "errors": [], "node": root, "provider_key": BASIC_PROVIDER}

func _create_imported(hook: Dictionary, settings: Dictionary) -> Dictionary:
    var scene_path: String = str(settings.get("scene_path", "")).strip_edges()
    if scene_path.is_empty(): return _failure("Imported water provider requires settings.scene_path.")
    if not ResourceLoader.exists(scene_path): return _failure("Imported water scene does not exist: %s" % scene_path)
    var resource: Resource = ResourceLoader.load(scene_path)
    if not resource is PackedScene: return _failure("Imported water scene is not a PackedScene: %s" % scene_path)
    var instance: Node = (resource as PackedScene).instantiate()
    if not instance is Node3D:
        if instance != null: instance.free()
        return _failure("Imported water scene root must be Node3D: %s" % scene_path)
    var root := instance as Node3D
    root.name = _safe_name(str(hook.get("display_name", root.name)))
    root.position = _vector3(settings.get("position", [0.0, 0.0, 0.0]), root.position)
    root.rotation_degrees = _vector3(settings.get("rotation_degrees", [0.0, 0.0, 0.0]), root.rotation_degrees)
    root.scale = _vector3(settings.get("scale", [1.0, 1.0, 1.0]), root.scale)
    _tag(root, hook, IMPORTED_PROVIDER)
    return {"ok": true, "errors": [], "node": root, "provider_key": IMPORTED_PROVIDER, "scene_path": scene_path}

func _tag(root: Node3D, hook: Dictionary, provider_key: String) -> void:
    root.set_meta("water_hook_id", str(hook.get("water_hook_id", "")))
    root.set_meta("water_provider_key", provider_key)
    root.set_meta("water_settings", hook.get("settings", {}).duplicate(true))

func _mesh_instances(root: Node) -> Array[Node]:
    var result: Array[Node] = []
    if root is MeshInstance3D: result.append(root)
    for child in root.get_children(): result.append_array(_mesh_instances(child))
    return result

static func _vector3(value: Variant, fallback: Vector3) -> Vector3:
    if value is Array and value.size() >= 3: return Vector3(float(value[0]), float(value[1]), float(value[2]))
    return fallback

static func _color(value: Variant, fallback: Color) -> Color:
    if value is Array and value.size() >= 3:
        return Color(float(value[0]), float(value[1]), float(value[2]), float(value[3]) if value.size() >= 4 else 1.0)
    return fallback

static func _safe_name(value: String) -> String:
    var clean := value.strip_edges()
    return "Water" if clean.is_empty() else clean.replace("/", "_").replace("\\", "_")

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
