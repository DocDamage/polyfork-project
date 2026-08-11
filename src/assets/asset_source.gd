class_name PlayWorldAssetSource
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")

const DOCUMENT_TYPE := "asset_source"
const SCHEMA_VERSION := 1


static func create(root_path: String, display_name: String = "") -> Dictionary:
    var normalized := normalize_path(root_path)
    return {
        "document_type": DOCUMENT_TYPE,
        "schema_version": SCHEMA_VERSION,
        "source_id": StableId.generate(),
        "display_name": display_name.strip_edges() if not display_name.strip_edges().is_empty() else normalized.get_file(),
        "root_path": normalized,
        "enabled": true,
        "read_only": true
    }


static func validate_dictionary(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if data.get("document_type") != DOCUMENT_TYPE:
        errors.append("Asset source document_type is invalid.")
    if data.get("schema_version") != SCHEMA_VERSION:
        errors.append("Asset source schema_version is unsupported.")
    if not StableId.is_valid(str(data.get("source_id", ""))):
        errors.append("Asset source source_id must be a stable UUID.")
    if str(data.get("display_name", "")).strip_edges().is_empty():
        errors.append("Asset source display_name is required.")
    if str(data.get("root_path", "")).strip_edges().is_empty():
        errors.append("Asset source root_path is required.")
    if not data.get("enabled") is bool:
        errors.append("Asset source enabled must be boolean.")
    if data.get("read_only") != true:
        errors.append("Asset sources must always be read-only.")
    return errors


static func normalize_path(path: String) -> String:
    var value := path.strip_edges()
    if value.is_empty():
        return ""
    return ProjectSettings.globalize_path(value).replace("\\", "/").simplify_path().trim_suffix("/")
