class_name PlayWorldAssetAnalyzer
extends RefCounted

func analyze(observation: Dictionary) -> Dictionary:
    var path := str(observation.get("absolute_path", ""))
    var asset_type := str(observation.get("asset_type", ""))
    if path.is_empty() or not FileAccess.file_exists(path): return _failure("Asset file is missing.")
    match asset_type:
        "gltf": return _analyze_gltf(path)
        "glb": return _analyze_glb(path)
        "godot_text_scene": return _analyze_tscn(path)
        "godot_binary_scene": return _analyze_scn(path)
        _: return _failure("Asset type is unsupported for analysis.")

func _analyze_gltf(path: String) -> Dictionary:
    var parser := JSON.new()
    if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary: return _failure("GLTF JSON is corrupt or invalid.")
    var data: Dictionary = parser.data
    var asset = data.get("asset")
    if not asset is Dictionary or not str(asset.get("version", "")).begins_with("2"): return _failure("GLTF asset.version must be 2.x.")
    return _success(_gltf_metadata(data, "gltf", FileAccess.get_size(path)))

func _analyze_glb(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null or file.get_length() < 20:
        if file != null: file.close()
        return _failure("GLB file is too small to contain a valid document.")
    var header := file.get_buffer(12)
    if header.size() != 12 or header.decode_u32(0) != 0x46546c67:
        file.close(); return _failure("GLB magic header is invalid.")
    if header.decode_u32(4) != 2:
        file.close(); return _failure("Only GLB version 2 is supported.")
    var declared := int(header.decode_u32(8))
    if declared != file.get_length(): file.close(); return _failure("GLB declared length does not match file size.")
    var json_text := ""
    while file.get_position() + 8 <= file.get_length():
        var chunk_header := file.get_buffer(8)
        var chunk_length := int(chunk_header.decode_u32(0)); var chunk_type := int(chunk_header.decode_u32(4))
        if chunk_length < 0 or file.get_position() + chunk_length > file.get_length(): file.close(); return _failure("GLB chunk length is invalid.")
        var bytes := file.get_buffer(chunk_length)
        if chunk_type == 0x4E4F534A: json_text = bytes.get_string_from_utf8().strip_edges()
    file.close()
    if json_text.is_empty(): return _failure("GLB does not contain a JSON metadata chunk.")
    var parser := JSON.new()
    if parser.parse(json_text) != OK or not parser.data is Dictionary: return _failure("GLB JSON metadata is invalid.")
    var metadata := _gltf_metadata(parser.data, "glb", declared)
    metadata["declared_length"] = declared
    return _success(metadata)

func _gltf_metadata(data: Dictionary, format_name: String, source_size: int) -> Dictionary:
    var asset: Dictionary = data.get("asset", {})
    var metadata := {
        "format": format_name,
        "generator": str(asset.get("generator", "")),
        "scene_count": _array_size(data.get("scenes")),
        "node_count": _array_size(data.get("nodes")),
        "mesh_count": _array_size(data.get("meshes")),
        "material_count": _array_size(data.get("materials")),
        "texture_count": _array_size(data.get("textures")),
        "image_count": _array_size(data.get("images")),
        "animation_count": _array_size(data.get("animations")),
        "skeleton_count": _array_size(data.get("skins")),
        "material_names": _named_entries(data.get("materials", [])),
        "animation_names": _named_entries(data.get("animations", [])),
        "mesh_names": _named_entries(data.get("meshes", [])),
        "collision_status": _contains_named_hint(data, ["collision", "collider", "physics"]),
        "lod_status": _has_lod(data),
        "estimated_memory_bytes": _estimate_gltf_memory(data, source_size),
        "source_size_bytes": source_size,
    }
    var bounds := _gltf_bounds(data)
    if bool(bounds.get("available", false)):
        metadata["bounds_min"] = bounds["min"]
        metadata["bounds_max"] = bounds["max"]
        metadata["dimensions"] = bounds["dimensions"]
    else: metadata["dimensions"] = []
    return metadata

func _gltf_bounds(data: Dictionary) -> Dictionary:
    var accessor_ids: Dictionary = {}
    for mesh_value in data.get("meshes", []):
        if not mesh_value is Dictionary: continue
        for primitive_value in mesh_value.get("primitives", []):
            if not primitive_value is Dictionary: continue
            var attrs: Dictionary = primitive_value.get("attributes", {})
            if attrs.has("POSITION"): accessor_ids[int(attrs["POSITION"])] = true
    var accessors: Array = data.get("accessors", []) if data.get("accessors", []) is Array else []
    var minimum := Vector3(INF, INF, INF); var maximum := Vector3(-INF, -INF, -INF); var found := false
    for index in accessor_ids.keys():
        if int(index) < 0 or int(index) >= accessors.size() or not accessors[int(index)] is Dictionary: continue
        var accessor: Dictionary = accessors[int(index)]; var min_value = accessor.get("min", []); var max_value = accessor.get("max", [])
        if not _vec3_array(min_value) or not _vec3_array(max_value): continue
        var low := Vector3(float(min_value[0]), float(min_value[1]), float(min_value[2])); var high := Vector3(float(max_value[0]), float(max_value[1]), float(max_value[2]))
        minimum.x = min(minimum.x, low.x); minimum.y = min(minimum.y, low.y); minimum.z = min(minimum.z, low.z)
        maximum.x = max(maximum.x, high.x); maximum.y = max(maximum.y, high.y); maximum.z = max(maximum.z, high.z); found = true
    if not found: return {"available": false}
    var dimensions := maximum - minimum
    return {"available": true, "min": [minimum.x, minimum.y, minimum.z], "max": [maximum.x, maximum.y, maximum.z], "dimensions": [dimensions.x, dimensions.y, dimensions.z]}

func _estimate_gltf_memory(data: Dictionary, source_size: int) -> int:
    var declared := 0
    for buffer_value in data.get("buffers", []):
        if buffer_value is Dictionary: declared += maxi(0, int(buffer_value.get("byteLength", 0)))
    return maxi(source_size, declared + source_size)

func _has_lod(data: Dictionary) -> bool:
    for value in data.get("extensionsUsed", []):
        if str(value).to_lower().contains("lod"): return true
    return _contains_named_hint(data, ["lod0", "lod1", "lod2", "lod_", "_lod"])

func _contains_named_hint(data: Dictionary, hints: Array[String]) -> bool:
    for section in ["nodes", "meshes"]:
        for value in data.get(section, []):
            if not value is Dictionary: continue
            var name := str(value.get("name", "")).to_lower()
            for hint in hints:
                if name.contains(hint): return true
    return false

func _analyze_tscn(path: String) -> Dictionary:
    var text := FileAccess.get_file_as_string(path)
    var header := text.strip_edges().split("\n", false, 1)[0] if not text.strip_edges().is_empty() else ""
    if not str(header).begins_with("[gd_scene"): return _failure("Godot text scene header is invalid.")
    if text.find("[node") == -1: return _failure("Godot text scene does not contain a node declaration.")
    return _success({
        "format": "tscn", "node_count": text.count("[node"), "mesh_count": text.count("MeshInstance3D"),
        "material_count": text.count("Material"), "animation_count": text.count("AnimationPlayer"), "skeleton_count": text.count("Skeleton3D"),
        "collision_status": text.contains("CollisionShape3D") or text.contains("CollisionPolygon3D"), "lod_status": text.to_lower().contains("lod"),
        "source_size_bytes": FileAccess.get_size(path), "estimated_memory_bytes": FileAccess.get_size(path), "dimensions": [],
    })

func _analyze_scn(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null or file.get_length() < 4:
        if file != null: file.close()
        return _failure("Godot binary scene is too small.")
    var magic := file.get_buffer(4).get_string_from_ascii(); file.close()
    if magic != "RSRC": return _failure("Godot binary scene header is invalid.")
    return _success({"format": "scn", "source_size_bytes": FileAccess.get_size(path), "estimated_memory_bytes": FileAccess.get_size(path), "dimensions": [], "collision_status": false, "lod_status": false})

static func _named_entries(value: Variant) -> Array[String]:
    var result: Array[String] = []
    if value is Array:
        for item in value:
            if item is Dictionary and not str(item.get("name", "")).is_empty(): result.append(str(item.get("name", "")))
    return result

static func _vec3_array(value: Variant) -> bool: return value is Array and value.size() >= 3
static func _array_size(value: Variant) -> int: return value.size() if value is Array else 0
static func _success(metadata: Dictionary) -> Dictionary: return {"ok": true, "errors": [], "metadata": metadata, "warnings": []}
static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message], "metadata": {}, "warnings": []}
