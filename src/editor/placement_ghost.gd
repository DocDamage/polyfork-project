class_name PlayWorldPlacementGhost
extends Node3D

var _record: Dictionary = {}
var _mesh: MeshInstance3D
var _asset_visual: Node3D


func _init() -> void:
    name = "PlacementGhost"
    visible = false
    _ensure_mesh()


func show_record(record: Dictionary, asset_visual: Node3D = null) -> void:
    _record = record.duplicate(true)
    _replace_asset_visual(asset_visual)
    var transform_data: Dictionary = _record.get("transform", {})
    position = _vector3(transform_data.get("position", [0.0, 0.0, 0.0]))
    rotation_degrees = _vector3(transform_data.get("rotation_degrees", [0.0, 0.0, 0.0]))
    scale = _vector3(transform_data.get("scale", [1.0, 1.0, 1.0]))
    visible = true


func update_transform(position_value: Vector3, rotation_value: Vector3 = Vector3.ZERO, scale_value: Vector3 = Vector3.ONE) -> void:
    position = position_value
    rotation_degrees = rotation_value
    scale = scale_value
    if not _record.is_empty():
        _record["transform"] = {
            "position": [position_value.x, position_value.y, position_value.z],
            "rotation_degrees": [rotation_value.x, rotation_value.y, rotation_value.z],
            "scale": [scale_value.x, scale_value.y, scale_value.z]
        }


func hide_preview() -> void:
    visible = false
    _record.clear()
    _replace_asset_visual(null)


func is_active() -> bool:
    return visible and not _record.is_empty()


func get_record() -> Dictionary:
    return _record.duplicate(true)


func has_asset_visual() -> bool:
    return _asset_visual != null


func _replace_asset_visual(value: Node3D) -> void:
    if _asset_visual != null and is_instance_valid(_asset_visual):
        if _asset_visual.get_parent() == self:
            remove_child(_asset_visual)
        _asset_visual.free()
    _asset_visual = value
    _mesh.visible = value == null
    if value != null:
        value.name = "AssetPreview"
        add_child(value)


func _ensure_mesh() -> void:
    if _mesh != null:
        return
    _mesh = MeshInstance3D.new()
    _mesh.name = "GhostMesh"
    var box := BoxMesh.new()
    box.size = Vector3.ONE
    _mesh.mesh = box
    _mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.22, 0.92, 0.74, 0.35)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _mesh.material_override = material
    add_child(_mesh)


static func _vector3(value: Array) -> Vector3:
    return Vector3(float(value[0]), float(value[1]), float(value[2]))
