class_name PlayWorldAssetAnalyzer
extends RefCounted


func analyze(observation: Dictionary) -> Dictionary:
    var path := str(observation.get("absolute_path", ""))
    var asset_type := str(observation.get("asset_type", ""))
    if path.is_empty() or not FileAccess.file_exists(path):
        return _failure("Asset file is missing.")
    match asset_type:
        "gltf": return _analyze_gltf(path)
        "glb": return _analyze_glb(path)
        "godot_text_scene": return _analyze_tscn(path)
        "godot_binary_scene": return _analyze_scn(path)
        _: return _failure("Asset type is unsupported for analysis.")


func _analyze_gltf(path: String) -> Dictionary:
    var parser := JSON.new()
    if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
        return _failure("GLTF JSON is corrupt or invalid.")
    var data: Dictionary = parser.data
    var asset = data.get("asset")
    if not asset is Dictionary or not str(asset.get("version", "")).begins_with("2"):
        return _failure("GLTF asset.version must be 2.x.")
    return _success({
        "format": "gltf",
        "generator": str(asset.get("generator", "")),
        "scene_count": _array_size(data.get("scenes")),
        "node_count": _array_size(data.get("nodes")),
        "mesh_count": _array_size(data.get("meshes")),
        "material_count": _array_size(data.get("materials"))
    })


func _analyze_glb(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null or file.get_length() < 12:
        if file != null: file.close()
        return _failure("GLB file is too small to contain a valid header.")
    var header := file.get_buffer(12)
    file.close()
    if header.size() != 12 or header.decode_u32(0) != 0x46546c67:
        return _failure("GLB magic header is invalid.")
    if header.decode_u32(4) != 2:
        return _failure("Only GLB version 2 is supported.")
    if int(header.decode_u32(8)) != FileAccess.get_size(path):
        return _failure("GLB declared length does not match file size.")
    return _success({"format": "glb", "declared_length": int(header.decode_u32(8))})


func _analyze_tscn(path: String) -> Dictionary:
    var text := FileAccess.get_file_as_string(path)
    var header := text.strip_edges().split("\n", false, 1)[0] if not text.strip_edges().is_empty() else ""
    if not str(header).begins_with("[gd_scene"):
        return _failure("Godot text scene header is invalid.")
    if text.find("[node") == -1:
        return _failure("Godot text scene does not contain a node declaration.")
    return _success({"format": "tscn", "node_count": text.count("[node")})


func _analyze_scn(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null or file.get_length() < 4:
        if file != null: file.close()
        return _failure("Godot binary scene is too small.")
    var magic := file.get_buffer(4).get_string_from_ascii()
    file.close()
    if magic != "RSRC":
        return _failure("Godot binary scene header is invalid.")
    return _success({"format": "scn"})


static func _array_size(value: Variant) -> int:
    return value.size() if value is Array else 0


static func _success(metadata: Dictionary) -> Dictionary:
    return {"ok": true, "errors": [], "metadata": metadata, "warnings": []}


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message], "metadata": {}, "warnings": []}
