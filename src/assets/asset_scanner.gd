class_name PlayWorldAssetScanner
extends RefCounted

const EXTENSION_TYPES := {
    "gltf": "gltf",
    "glb": "glb",
    "tscn": "godot_text_scene",
    "scn": "godot_binary_scene"
}


func scan_source(source: Dictionary, previous_by_path: Dictionary = {}) -> Dictionary:
    var source_id := str(source.get("source_id", ""))
    var root_path := str(source.get("root_path", ""))
    if source_id.is_empty() or root_path.is_empty():
        return _failure("Asset scan requires a valid source contract.")
    if DirAccess.open(root_path) == null:
        return {"ok": false, "errors": ["Asset source is missing or unreadable."], "observations": [], "stats": _stats()}
    var relative_paths: Array[String] = []
    var walk_errors: Array[String] = []
    _collect_supported_files(root_path, "", relative_paths, walk_errors)
    relative_paths.sort()
    var observations: Array[Dictionary] = []
    var stats := _stats()
    stats["files"] = relative_paths.size()
    for relative_path in relative_paths:
        var absolute_path := root_path.path_join(relative_path)
        var size_bytes := FileAccess.get_size(absolute_path)
        var modified_time := FileAccess.get_modified_time(absolute_path)
        var previous: Dictionary = previous_by_path.get(relative_path, {})
        var content_hash := ""
        if not previous.is_empty() and int(previous.get("size_bytes", -1)) == size_bytes and int(previous.get("modified_time", -1)) == modified_time and str(previous.get("content_hash", "")).length() == 64:
            content_hash = str(previous["content_hash"])
            stats["reused"] += 1
        else:
            content_hash = FileAccess.get_sha256(absolute_path)
            stats["hashed"] += 1
        if content_hash.length() != 64:
            walk_errors.append("Unable to hash source asset: %s" % relative_path)
            continue
        observations.append({
            "source_id": source_id,
            "relative_path": relative_path,
            "absolute_path": absolute_path,
            "asset_type": EXTENSION_TYPES.get(relative_path.get_extension().to_lower(), ""),
            "content_hash": content_hash,
            "size_bytes": size_bytes,
            "modified_time": modified_time
        })
    return {"ok": walk_errors.is_empty(), "errors": walk_errors, "observations": observations, "stats": stats}


func _collect_supported_files(root_path: String, relative_dir: String, output: Array[String], errors: Array[String]) -> void:
    var current_path := root_path if relative_dir.is_empty() else root_path.path_join(relative_dir)
    var directory := DirAccess.open(current_path)
    if directory == null:
        errors.append("Unable to read source directory: %s" % relative_dir)
        return
    directory.list_dir_begin()
    var entry := directory.get_next()
    while not entry.is_empty():
        var relative_path := entry if relative_dir.is_empty() else relative_dir.path_join(entry)
        if directory.current_is_dir():
            if not directory.is_link(entry):
                _collect_supported_files(root_path, relative_path, output, errors)
        elif EXTENSION_TYPES.has(entry.get_extension().to_lower()):
            output.append(relative_path.replace("\\", "/"))
        entry = directory.get_next()
    directory.list_dir_end()


static func _stats() -> Dictionary:
    return {"files": 0, "hashed": 0, "reused": 0}


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message], "observations": [], "stats": _stats()}
