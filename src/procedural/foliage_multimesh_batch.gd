class_name PlayWorldFoliageMultiMeshBatch
extends MultiMeshInstance3D

var scatter_layer_id: String = ""
var cell_id: String = ""
var _authored_cast_shadows := false


func apply_batch(layer_id: String, owner_cell_id: String, mesh: Mesh, transforms: Array[Transform3D], cast_shadows: bool) -> Dictionary:
    if mesh == null:
        return _failure("Foliage MultiMesh batch requires a mesh.")
    scatter_layer_id = layer_id
    cell_id = owner_cell_id
    _authored_cast_shadows = cast_shadows
    name = "Foliage_%s_%s" % [layer_id.substr(0, 8), owner_cell_id.substr(0, 8)]
    var batch := MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.mesh = mesh
    batch.instance_count = transforms.size()
    for index in range(transforms.size()):
        batch.set_instance_transform(index, transforms[index])
    multimesh = batch
    _apply_shadow_policy(true)
    return {"ok": true, "errors": [], "instance_count": transforms.size()}


func configure_quality(profile: Dictionary) -> Dictionary:
    var visibility_range := maxf(0.0, float(profile.get("foliage_visibility_range_m", 0.0)))
    visibility_range_end = visibility_range
    _apply_shadow_policy(bool(profile.get("foliage_shadow_enabled", true)))
    return {
        "ok": true,
        "errors": [],
        "visibility_range_end": visibility_range_end,
        "cast_shadows": cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
    }


func get_instance_count() -> int:
    return 0 if multimesh == null else multimesh.instance_count


func _apply_shadow_policy(quality_allows_shadows: bool) -> void:
    cast_shadow = (
        GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        if _authored_cast_shadows and quality_allows_shadows
        else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    )


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
