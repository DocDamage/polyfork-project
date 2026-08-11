class_name PlayWorldRuntimeEntityNode
extends Node3D

const WorldEntity = preload("res://src/world/world_entity.gd")
const ENTITY_ID_META := &"playworld_entity_id"

var entity_id: String = ""
var entity_record: Dictionary = {}
var _selected := false
var _mesh: MeshInstance3D
var _body: StaticBody3D
var _normal_material: StandardMaterial3D
var _selected_material: StandardMaterial3D
var _asset_visual: Node3D


func apply_record(record: Dictionary) -> Array[String]:
    var errors: Array[String] = WorldEntity.validate_dictionary(record)
    if not errors.is_empty():
        return errors

    entity_id = str(record["entity_id"])
    entity_record = record.duplicate(true)
    set_meta(ENTITY_ID_META, entity_id)
    name = "Entity_%s" % entity_id.substr(0, 8)
    _ensure_proxy()
    _sync_identity_meta()

    var transform_data: Dictionary = record.get("transform", {})
    position = _vector3(transform_data.get("position", [0.0, 0.0, 0.0]))
    rotation_degrees = _vector3(transform_data.get("rotation_degrees", [0.0, 0.0, 0.0]))
    scale = _vector3(transform_data.get("scale", [1.0, 1.0, 1.0]))
    _apply_selection_material()
    return []


func set_asset_visual(value: Node3D) -> void:
    if _asset_visual != null and is_instance_valid(_asset_visual):
        if _asset_visual.get_parent() == self: remove_child(_asset_visual)
        _asset_visual.free()
    _asset_visual = value
    if value != null:
        value.name = "AssetVisual"
        add_child(value)
    _apply_selection_material()


func has_asset_visual() -> bool:
    return _asset_visual != null


func set_selected(value: bool) -> void:
    _selected = value
    _apply_selection_material()


func is_selected() -> bool:
    return _selected


func get_record() -> Dictionary:
    return entity_record.duplicate(true)


func get_proxy_mesh() -> MeshInstance3D:
    _ensure_proxy()
    return _mesh


func get_pick_body() -> StaticBody3D:
    _ensure_proxy()
    return _body


func _ensure_proxy() -> void:
    if _mesh != null:
        return

    _normal_material = StandardMaterial3D.new()
    _normal_material.albedo_color = Color(0.30, 0.58, 0.67, 1.0)
    _normal_material.metallic = 0.12
    _normal_material.roughness = 0.58

    _selected_material = StandardMaterial3D.new()
    _selected_material.albedo_color = Color(0.34, 0.92, 0.70, 0.28)
    _selected_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _selected_material.emission_enabled = true
    _selected_material.emission = Color(0.12, 0.42, 0.28, 1.0)
    _selected_material.emission_energy_multiplier = 1.5

    _mesh = MeshInstance3D.new()
    _mesh.name = "ProxyMesh"
    var box := BoxMesh.new()
    box.size = Vector3.ONE
    _mesh.mesh = box
    _mesh.material_override = _normal_material
    add_child(_mesh)

    _body = StaticBody3D.new()
    _body.name = "PickBody"
    var collision := CollisionShape3D.new()
    collision.name = "CollisionShape3D"
    var shape := BoxShape3D.new()
    shape.size = Vector3.ONE
    collision.shape = shape
    _body.add_child(collision)
    add_child(_body)


func _sync_identity_meta() -> void:
    if entity_id.is_empty(): return
    set_meta(ENTITY_ID_META, entity_id)
    _mesh.set_meta(ENTITY_ID_META, entity_id)
    _body.set_meta(ENTITY_ID_META, entity_id)


func _apply_selection_material() -> void:
    if _mesh == null: return
    _mesh.visible = _asset_visual == null or _selected
    _mesh.material_override = _selected_material if _selected else _normal_material


static func _vector3(value: Array) -> Vector3:
    return Vector3(float(value[0]), float(value[1]), float(value[2]))
