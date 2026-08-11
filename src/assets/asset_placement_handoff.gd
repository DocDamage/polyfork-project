class_name PlayWorldAssetPlacementHandoff
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")


func bind_runtime(editor_session, asset_library) -> Dictionary:
    if editor_session == null or asset_library == null:
        return _failure("Asset placement handoff requires an editor session and Asset Library.")
    editor_session.get_bridge().bind_asset_resolver(Callable(asset_library, "instantiate_asset_scene"))
    return {"ok": true, "errors": []}


func begin(editor_session, asset_library, asset_record: Dictionary) -> Dictionary:
    if editor_session == null or asset_library == null:
        return _failure("Asset placement handoff requires an editor session and Asset Library.")
    var asset_id := str(asset_record.get("asset_id", ""))
    if not StableId.is_valid(asset_id):
        return _failure("Asset placement requires a stable catalog asset ID.")
    if bool(asset_record.get("missing", false)):
        return _failure("Missing source assets cannot begin placement.")
    var analysis: Dictionary = asset_record.get("analysis", {})
    if not bool(analysis.get("ok", false)):
        return _failure("Asset placement is blocked because analysis did not pass.")

    var visual_result: Dictionary = asset_library.instantiate_asset_scene(asset_id)
    if not visual_result.get("ok", false): return visual_result
    var node_value = visual_result.get("node")
    if not node_value is Node3D:
        if node_value is Node: node_value.free()
        return _failure("Only 3D scene assets can be handed to the placement editor.")

    var begin_result: Dictionary = editor_session.begin_proxy_placement(str(asset_record.get("display_name", "Asset")))
    if not begin_result.get("ok", false):
        node_value.free()
        return begin_result
    var record: Dictionary = editor_session.get_ghost().get_record()
    record["asset_id"] = asset_id
    editor_session.get_ghost().show_record(record, node_value)
    editor_session.placement_changed.emit(true, record.duplicate(true))
    return {"ok": true, "errors": [], "record": record.duplicate(true), "asset_id": asset_id}


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
