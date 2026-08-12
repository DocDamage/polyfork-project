class_name PlayWorldFoliageMultiMeshBatch
extends MultiMeshInstance3D

var scatter_layer_id: String = ""
var cell_id: String = ""


func apply_batch(layer_id: String, owner_cell_id: String, mesh: Mesh, transforms: Array[Transform3D], cast_shadows: bool) -> Dictionary:
    if mesh == null:
        return _failure("Foliage MultiMesh batch requires a mesh.")
    scatter_layer_id = layer_id
    cell_id = owner_cell_id
    name = "Foliage_%s_%s" % [layer_id.substr(0, 8), owner_cell_id.substr(0, 8)]
    var batch := MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.mesh = mesh
    batch.instance_count = transforms.size()
    for index in range(transforms.size()):
        batch.set_instance_transform(index, transforms[index])
    multimesh = batch
    cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    return {"ok": true, "errors": [], "instance_count": transforms.size()}


func get_instance_count() -> int:
    return 0 if multimesh == null else multimesh.instance_count


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
