class_name PlayWorldExportContracts
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")

const DOCUMENT_TYPE := "export_manifest"
const SCHEMA_VERSION := 1
const TARGET_WINDOWS := "windows"
const RUNTIME_REQUIRED := "runtime_required"
const EDITOR_ONLY := "editor_only"
const MAX_DEPENDENCIES := 10000
const MAX_PACKAGE_FILES := 50000

static func new_manifest(project_data: Dictionary, build_id: String, package_name: String, dependencies: Array = [], files: Array = []) -> Dictionary:
    var ordered_dependencies := dependencies.duplicate(true)
    ordered_dependencies.sort_custom(func(a, b): return str(a.get("asset_id", "")) < str(b.get("asset_id", "")))
    var ordered_files := files.duplicate(true)
    ordered_files.sort_custom(func(a, b): return str(a.get("package_path", "")) < str(b.get("package_path", "")))
    return {
        "document_type": DOCUMENT_TYPE,
        "schema_version": SCHEMA_VERSION,
        "build_id": build_id,
        "project_id": str(project_data.get("project_id", "")),
        "project_title": str(project_data.get("title", "")),
        "world_profile": str(project_data.get("world_profile", "")),
        "template_id": str(project_data.get("template_id", "")),
        "target": TARGET_WINDOWS,
        "package_name": package_name.strip_edges(),
        "dependencies": ordered_dependencies,
        "files": ordered_files,
    }

static func validate_manifest(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if str(data.get("document_type", "")) != DOCUMENT_TYPE: errors.append("Export manifest document_type is invalid.")
    if int(data.get("schema_version", 0)) != SCHEMA_VERSION: errors.append("Export manifest schema_version is unsupported.")
    if not StableId.is_valid(str(data.get("build_id", ""))): errors.append("Export manifest build_id must be a stable UUID.")
    if not StableId.is_valid(str(data.get("project_id", ""))): errors.append("Export manifest project_id must be a stable UUID.")
    if str(data.get("project_title", "")).strip_edges().is_empty(): errors.append("Export manifest project_title is required.")
    if str(data.get("template_id", "")).strip_edges().is_empty(): errors.append("Export manifest template_id is required.")
    if str(data.get("target", "")) != TARGET_WINDOWS: errors.append("Export manifest target is unsupported.")
    if not valid_package_segment(str(data.get("package_name", ""))): errors.append("Export manifest package_name is unsafe or invalid.")
    _validate_dependencies(data.get("dependencies", []), errors)
    _validate_files(data.get("files", []), errors)
    var serialized := JSON.stringify(data)
    for marker in ["api_key", "credential_env_value", ".polyforkAPI"]:
        if serialized.contains(marker): errors.append("Export manifest contains prohibited credential material.")
    return errors

static func valid_package_path(value: String) -> bool:
    var path := value.strip_edges().replace("\\", "/")
    if path.is_empty() or path.begins_with("/") or path.ends_with("/"): return false
    if path.length() >= 2 and path.substr(1, 1) == ":": return false
    for part in path.split("/", false):
        if part.is_empty() or part == "." or part == "..": return false
    return true

static func valid_package_segment(value: String) -> bool:
    var segment := value.strip_edges()
    if segment.is_empty() or segment == "." or segment == "..": return false
    if segment.contains("/") or segment.contains("\\") or segment.contains(":"): return false
    return true

static func validate_classification(value: String) -> bool:
    return value == RUNTIME_REQUIRED or value == EDITOR_ONLY

static func _validate_dependencies(value: Variant, errors: Array[String]) -> void:
    if not value is Array:
        errors.append("Export manifest dependencies must be an array."); return
    if value.size() > MAX_DEPENDENCIES: errors.append("Export manifest dependency limit exceeded.")
    var seen: Dictionary = {}
    for item in value:
        if not item is Dictionary:
            errors.append("Export manifest dependencies must contain dictionaries."); continue
        var asset_id := str(item.get("asset_id", ""))
        if not StableId.is_valid(asset_id): errors.append("Export dependency asset_id must be a stable UUID.")
        elif seen.has(asset_id): errors.append("Export manifest contains a duplicate asset dependency.")
        seen[asset_id] = true
        if not valid_package_path(str(item.get("package_path", ""))): errors.append("Export dependency package_path is unsafe or invalid.")
        if str(item.get("content_hash", "")).length() != 64: errors.append("Export dependency content_hash must be SHA-256.")

static func _validate_files(value: Variant, errors: Array[String]) -> void:
    if not value is Array:
        errors.append("Export manifest files must be an array."); return
    if value.size() > MAX_PACKAGE_FILES: errors.append("Export manifest package file limit exceeded.")
    var seen: Dictionary = {}
    for item in value:
        if not item is Dictionary:
            errors.append("Export manifest files must contain dictionaries."); continue
        var package_path := str(item.get("package_path", ""))
        if not valid_package_path(package_path): errors.append("Export package file path is unsafe or invalid.")
        elif seen.has(package_path): errors.append("Export manifest contains a duplicate package file path.")
        seen[package_path] = true
        if not validate_classification(str(item.get("classification", ""))): errors.append("Export package file classification is invalid.")
