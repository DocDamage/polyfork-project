class_name PlayWorldExportAssetResolver
extends RefCounted

const Contracts = preload("res://src/export/export_contracts.gd")

static func resolve(asset_ids: Array[String], catalog_records: Array, sources: Array, verify_files: bool = true) -> Dictionary:
    var records_by_id: Dictionary = {}
    for value in catalog_records:
        if value is Dictionary: records_by_id[str(value.get("asset_id", ""))] = value
    var sources_by_id: Dictionary = {}
    for value in sources:
        if value is Dictionary: sources_by_id[str(value.get("source_id", ""))] = value

    var entries: Array[Dictionary] = []
    var errors: Array[String] = []
    var ordered := asset_ids.duplicate(); ordered.sort()
    for asset_id in ordered:
        var record: Dictionary = records_by_id.get(asset_id, {})
        if record.is_empty():
            errors.append("Required Asset Library dependency is not cataloged: %s" % asset_id); continue
        if bool(record.get("missing", false)):
            errors.append("Required Asset Library dependency is marked missing: %s" % asset_id); continue
        var source_id := str(record.get("source_id", ""))
        var source: Dictionary = sources_by_id.get(source_id, {})
        if source.is_empty():
            errors.append("Required Asset Library source is unavailable for asset: %s" % asset_id); continue
        var relative_path := str(record.get("relative_path", "")).replace("\\", "/")
        if not Contracts.valid_package_path(relative_path):
            errors.append("Asset Library dependency has an unsafe relative path: %s" % asset_id); continue
        var source_path := str(source.get("root_path", "")).trim_suffix("/").path_join(relative_path)
        if verify_files and not FileAccess.file_exists(source_path):
            errors.append("Required Asset Library source file is unavailable: %s" % asset_id); continue
        entries.append({
            "asset_id": asset_id,
            "source_id": source_id,
            "source_path": source_path,
            "relative_path": relative_path,
            "package_path": "assets/%s/%s" % [asset_id, relative_path],
            "asset_type": str(record.get("asset_type", "")),
            "content_hash": str(record.get("content_hash", "")),
            "size_bytes": int(record.get("size_bytes", 0)),
            "license": record.get("license", {}).duplicate(true),
        })
    return {"ok": errors.is_empty(), "errors": errors, "dependencies": entries}
