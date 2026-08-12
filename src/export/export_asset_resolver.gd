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
    var entries: Array[Dictionary] = []; var errors: Array[String] = []; var ordered := asset_ids.duplicate(); ordered.sort()
    for asset_id in ordered:
        var record: Dictionary = records_by_id.get(asset_id, {})
        if record.is_empty(): errors.append("Required Asset Library dependency is not cataloged: %s" % asset_id); continue
        if bool(record.get("missing", false)): errors.append("Required Asset Library dependency is marked missing: %s" % asset_id); continue
        var source_id := str(record.get("source_id", "")); var source: Dictionary = sources_by_id.get(source_id, {})
        if source.is_empty(): errors.append("Required Asset Library source is unavailable for asset: %s" % asset_id); continue
        var relative_path := str(record.get("relative_path", "")).replace("\\", "/")
        if not Contracts.valid_package_path(relative_path): errors.append("Asset Library dependency has an unsafe relative path: %s" % asset_id); continue
        var source_path := str(source.get("root_path", "")).trim_suffix("/").path_join(relative_path)
        if verify_files and not FileAccess.file_exists(source_path): errors.append("Required Asset Library source file is unavailable: %s" % asset_id); continue
        entries.append(_entry(record, source_id, source_path, source_path, "assets/%s/%s" % [asset_id, relative_path.get_file()], []))
    return {"ok": errors.is_empty(), "errors": errors, "dependencies": entries}

static func resolve_with_library(asset_ids: Array[String], asset_library) -> Dictionary:
    if not asset_ids.is_empty() and asset_library == null: return {"ok": false, "errors": ["Export dependencies require a bound Phase 4 Asset Library."], "dependencies": []}
    var entries: Array[Dictionary] = []; var errors: Array[String] = []; var ordered := asset_ids.duplicate(); ordered.sort()
    for asset_id in ordered:
        var record: Dictionary = asset_library.get_record(asset_id)
        if record.is_empty(): errors.append("Required Asset Library dependency is not cataloged: %s" % asset_id); continue
        if bool(record.get("missing", false)): errors.append("Required Asset Library dependency is marked missing: %s" % asset_id); continue
        var source_details: Dictionary = asset_library.source_details(asset_id); var source: Dictionary = source_details.get("source", {})
        if source.is_empty(): errors.append("Required Asset Library source is unavailable for asset: %s" % asset_id); continue
        var imported: Dictionary = asset_library.ensure_import(asset_id)
        if not imported.get("ok", false): errors.append_array(_prefixed(asset_id, imported.get("errors", []))); continue
        var derived: Dictionary = imported.get("derived", {}); var imported_path: String = str(derived.get("imported_path", "")); var import_root: String = str(derived.get("import_root", ""))
        if imported_path.is_empty() or not FileAccess.file_exists(imported_path): errors.append("Phase 4 managed import is unavailable for export asset: %s" % asset_id); continue
        var support_result: Dictionary = _support_files(import_root, imported_path, asset_id)
        if not support_result.get("ok", false): errors.append_array(support_result.get("errors", [])); continue
        var original_path: String = str(source.get("root_path", "")).trim_suffix("/").path_join(str(record.get("relative_path", "")))
        entries.append(_entry(record, str(record.get("source_id", "")), imported_path, original_path, "assets/%s/%s" % [asset_id, imported_path.get_file()], support_result.get("files", [])))
    return {"ok": errors.is_empty(), "errors": errors, "dependencies": entries}

static func _support_files(import_root: String, primary_path: String, asset_id: String) -> Dictionary:
    var files: Array[Dictionary] = []
    if import_root.is_empty() or not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(import_root)): return {"ok": true, "errors": [], "files": files}
    var collect: Dictionary = _collect_files(import_root, import_root)
    if not collect.get("ok", false): return collect
    for value in collect.get("files", []):
        var source_path: String = str(value.get("source_path", ""))
        if source_path == primary_path: continue
        var relative_path: String = str(value.get("relative_path", ""))
        if not Contracts.valid_package_path(relative_path): return {"ok": false, "errors": ["Managed asset dependency has an unsafe support path: %s" % relative_path]}
        files.append({"source_path": source_path, "package_path": "assets/%s/%s" % [asset_id, relative_path]})
    files.sort_custom(func(a, b): return str(a.get("package_path", "")) < str(b.get("package_path", "")))
    return {"ok": true, "errors": [], "files": files}

static func _collect_files(root: String, current: String) -> Dictionary:
    var directory: DirAccess = DirAccess.open(current)
    if directory == null: return {"ok": false, "errors": ["Unable to inspect managed Phase 4 import directory."], "files": []}
    var files: Array[Dictionary] = []; directory.list_dir_begin()
    while true:
        var name: String = directory.get_next(); if name.is_empty(): break
        if name == "." or name == "..": continue
        var child: String = current.path_join(name)
        if directory.current_is_dir():
            var nested: Dictionary = _collect_files(root, child); if not nested.get("ok", false): directory.list_dir_end(); return nested
            files.append_array(nested.get("files", []))
        else:
            files.append({"source_path": child, "relative_path": child.trim_prefix(root.trim_suffix("/") + "/").replace("\\", "/")})
    directory.list_dir_end(); return {"ok": true, "errors": [], "files": files}

static func _entry(record: Dictionary, source_id: String, copy_source: String, lineage_source: String, package_path: String, support_files: Array) -> Dictionary:
    return {"asset_id": str(record.get("asset_id", "")), "source_id": source_id, "source_path": copy_source, "lineage_source_path": lineage_source, "relative_path": str(record.get("relative_path", "")), "package_path": package_path, "support_files": support_files.duplicate(true), "asset_type": str(record.get("asset_type", "")), "content_hash": str(record.get("content_hash", "")), "size_bytes": int(record.get("size_bytes", 0)), "license": record.get("license", {}).duplicate(true)}

static func _prefixed(asset_id: String, values: Array) -> Array[String]:
    var result: Array[String] = []
    for value in values: result.append("Asset %s: %s" % [asset_id, str(value)])
    return result
