class_name PlayWorldAssetRecord
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")

const DOCUMENT_TYPE := "asset_record"
const SCHEMA_VERSION := 1
const SUPPORTED_TYPES := ["gltf", "glb", "godot_text_scene", "godot_binary_scene"]


static func from_observation(observation: Dictionary) -> Dictionary:
    var display_name := str(observation.get("relative_path", "Asset")).get_file().get_basename()
    return {
        "document_type": DOCUMENT_TYPE,
        "schema_version": SCHEMA_VERSION,
        "asset_id": StableId.generate(),
        "source_id": str(observation.get("source_id", "")),
        "relative_path": str(observation.get("relative_path", "")),
        "display_name": display_name if not display_name.is_empty() else "Asset",
        "asset_type": str(observation.get("asset_type", "")),
        "content_hash": str(observation.get("content_hash", "")),
        "size_bytes": int(observation.get("size_bytes", 0)),
        "modified_time": int(observation.get("modified_time", 0)),
        "missing": false,
        "favorite": false,
        "collections": [],
        "license": {"spdx": "", "author": "", "source_url": "", "notes": ""},
        "user_metadata": {},
        "analysis": observation.get("analysis", {}).duplicate(true),
        "derived": {},
        "thumbnail": {}
    }


static func validate_dictionary(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if data.get("document_type") != DOCUMENT_TYPE:
        errors.append("Asset record document_type is invalid.")
    if data.get("schema_version") != SCHEMA_VERSION:
        errors.append("Asset record schema_version is unsupported.")
    if not StableId.is_valid(str(data.get("asset_id", ""))):
        errors.append("Asset record asset_id must be a stable UUID.")
    if not StableId.is_valid(str(data.get("source_id", ""))):
        errors.append("Asset record source_id must be a stable UUID.")
    if str(data.get("relative_path", "")).strip_edges().is_empty():
        errors.append("Asset record relative_path is required.")
    if str(data.get("display_name", "")).strip_edges().is_empty():
        errors.append("Asset record display_name is required.")
    if not SUPPORTED_TYPES.has(str(data.get("asset_type", ""))):
        errors.append("Asset record asset_type is unsupported.")
    var hash_text := str(data.get("content_hash", ""))
    if hash_text.length() != 64:
        errors.append("Asset record content_hash must be a SHA-256 value.")
    if int(data.get("size_bytes", -1)) < 0:
        errors.append("Asset record size_bytes cannot be negative.")
    for field_name in ["missing", "favorite"]:
        if not data.get(field_name) is bool:
            errors.append("Asset record %s must be boolean." % field_name)
    var collections = data.get("collections")
    if not collections is Array:
        errors.append("Asset record collections must be an array.")
    else:
        var seen: Dictionary = {}
        for collection in collections:
            var label := str(collection).strip_edges()
            if label.is_empty(): errors.append("Asset record collection names cannot be blank.")
            if seen.has(label): errors.append("Asset record collections cannot contain duplicates.")
            seen[label] = true
    if not data.get("license") is Dictionary:
        errors.append("Asset record license must be a dictionary.")
    if not data.get("user_metadata") is Dictionary:
        errors.append("Asset record user_metadata must be a dictionary.")
    if not data.get("analysis") is Dictionary:
        errors.append("Asset record analysis must be a dictionary.")
    if not data.get("derived") is Dictionary:
        errors.append("Asset record derived must be a dictionary.")
    if not data.get("thumbnail") is Dictionary:
        errors.append("Asset record thumbnail must be a dictionary.")
    return errors


static func content_signature(data: Dictionary) -> String:
    return "%s:%s:%s" % [str(data.get("content_hash", "")), int(data.get("size_bytes", 0)), str(data.get("asset_type", ""))]
