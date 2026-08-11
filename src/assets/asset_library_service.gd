class_name PlayWorldAssetLibraryService
extends RefCounted

const SourceRegistry = preload("res://src/assets/source_folder_registry.gd")
const AssetScanner = preload("res://src/assets/asset_scanner.gd")
const AssetAnalyzer = preload("res://src/assets/asset_analyzer.gd")
const AssetCatalog = preload("res://src/assets/asset_catalog.gd")
const AssetImporter = preload("res://src/assets/asset_importer.gd")
const ThumbnailCache = preload("res://src/assets/thumbnail_cache.gd")

var project_directory: String
var managed_root: String
var _registry
var _scanner = AssetScanner.new()
var _analyzer = AssetAnalyzer.new()
var _catalog
var _importer
var _thumbnails


func _init(project_dir: String) -> void:
    project_directory = project_dir.trim_suffix("/")
    managed_root = project_directory.path_join("asset_library")
    _registry = SourceRegistry.new(managed_root)
    _catalog = AssetCatalog.new(managed_root)
    _importer = AssetImporter.new(managed_root.path_join("imports"))
    _thumbnails = ThumbnailCache.new(managed_root.path_join("thumbnails"))


func load_library() -> Dictionary:
    var source_result := _registry.load_registry()
    if not source_result.get("ok", false): return source_result
    var catalog_result := _catalog.load_catalog()
    if not catalog_result.get("ok", false): return catalog_result
    return {"ok": true, "errors": [], "sources": get_sources(), "records": get_records(true)}


func register_source(root_path: String, display_name: String = "") -> Dictionary:
    var result := _registry.register_source(root_path, display_name)
    if not result.get("ok", false): return result
    var scan_result := scan_all()
    scan_result["source"] = result.get("source", {})
    return scan_result


func remove_source(source_id: String) -> Dictionary:
    var result := _registry.remove_source(source_id)
    if not result.get("ok", false): return result
    return scan_all()


func scan_all() -> Dictionary:
    var observations: Array = []
    var scan_errors: Array[String] = []
    var totals := {"files": 0, "hashed": 0, "reused": 0, "sources": 0}
    for source in _registry.get_sources(true):
        totals["sources"] += 1
        var source_id := str(source.get("source_id", ""))
        var scan_result := _scanner.scan_source(source, _catalog.previous_by_path(source_id))
        for key in ["files", "hashed", "reused"]:
            totals[key] += int(scan_result.get("stats", {}).get(key, 0))
        for error in scan_result.get("errors", []): scan_errors.append(str(error))
        for observation in scan_result.get("observations", []):
            var analyzed: Dictionary = observation.duplicate(true)
            analyzed["analysis"] = _analyzer.analyze(observation)
            observations.append(analyzed)
    var reconcile := _catalog.reconcile(observations, false)
    if not reconcile.get("ok", false): return reconcile
    var thumbnail_errors: Array[String] = []
    for record in _catalog.get_records(false):
        var thumbnail_result := _thumbnails.ensure_thumbnail(record)
        if thumbnail_result.get("ok", false):
            _catalog.update_thumbnail(str(record.get("asset_id", "")), thumbnail_result["thumbnail"], false)
        else:
            for error in thumbnail_result.get("errors", []): thumbnail_errors.append(str(error))
    var save_result := _catalog.save_catalog()
    if not save_result.get("ok", false): return save_result
    var all_errors: Array[String] = []
    all_errors.append_array(scan_errors)
    all_errors.append_array(thumbnail_errors)
    return {"ok": all_errors.is_empty(), "errors": all_errors, "stats": totals, "records": get_records(true), "duplicate_groups": _catalog.duplicate_groups()}


func instantiate_asset_scene(asset_id: String) -> Dictionary:
    var record := _catalog.get_record(asset_id)
    if record.is_empty(): return _failure("Asset ID was not found in the catalog.")
    var source := _registry.get_source(str(record.get("source_id", "")))
    if source.is_empty(): return _failure("Asset source registration is missing.")
    var result := _importer.instantiate(record, str(source.get("root_path", "")))
    if result.get("ok", false):
        _catalog.update_derived(asset_id, result.get("derived", {}), true)
    return result


func ensure_import(asset_id: String) -> Dictionary:
    var record := _catalog.get_record(asset_id)
    if record.is_empty(): return _failure("Asset ID was not found in the catalog.")
    var source := _registry.get_source(str(record.get("source_id", "")))
    if source.is_empty(): return _failure("Asset source registration is missing.")
    var result := _importer.ensure_import(record, str(source.get("root_path", "")))
    if result.get("ok", false): _catalog.update_derived(asset_id, result.get("derived", {}), true)
    return result


func query(search_text: String = "", filters: Dictionary = {}) -> Array[Dictionary]:
    return _catalog.query(search_text, filters)


func get_records(include_missing: bool = false) -> Array[Dictionary]: return _catalog.get_records(include_missing)
func get_record(asset_id: String) -> Dictionary: return _catalog.get_record(asset_id)
func get_sources(enabled_only: bool = false) -> Array[Dictionary]: return _registry.get_sources(enabled_only)
func get_collections() -> Array[String]: return _catalog.collections()
func duplicate_groups() -> Array[Array]: return _catalog.duplicate_groups()
func set_favorite(asset_id: String, favorite: bool) -> Dictionary: return _catalog.set_favorite(asset_id, favorite)
func set_license(asset_id: String, value: Dictionary) -> Dictionary: return _catalog.set_license(asset_id, value)
func add_to_collection(asset_id: String, collection: String) -> Dictionary: return _catalog.add_to_collection(asset_id, collection)
func remove_from_collection(asset_id: String, collection: String) -> Dictionary: return _catalog.remove_from_collection(asset_id, collection)


func source_details(asset_id: String) -> Dictionary:
    var record := _catalog.get_record(asset_id)
    if record.is_empty(): return {}
    var source := _registry.get_source(str(record.get("source_id", "")))
    return {"asset": record, "source": source, "license": record.get("license", {}).duplicate(true)}


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
