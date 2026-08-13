class_name PlayWorldAssetLibraryService
extends RefCounted

const SourceRegistry = preload("res://src/assets/source_folder_registry.gd")
const AssetScanner = preload("res://src/assets/asset_scanner.gd")
const AssetAnalyzer = preload("res://src/assets/asset_analyzer.gd")
const AssetCatalog = preload("res://src/assets/asset_catalog.gd")
const AssetImporter = preload("res://src/assets/asset_importer.gd")
const ThumbnailCache = preload("res://src/assets/thumbnail_cache.gd")
const SemanticSearch = preload("res://src/assets/asset_semantic_search.gd")

var project_directory: String
var managed_root: String
var _registry
var _scanner = AssetScanner.new()
var _analyzer = AssetAnalyzer.new()
var _catalog
var _importer
var _thumbnails
var _semantic = SemanticSearch.new()

func _init(project_dir: String, explicit_library_root: String = "") -> void:
    project_directory = project_dir.trim_suffix("/")
    managed_root = explicit_library_root.trim_suffix("/")
    if managed_root.is_empty() and bool(ProjectSettings.get_setting("playworld/assets/use_shared_library", false)):
        managed_root = str(ProjectSettings.get_setting("playworld/assets/library_root", "user://asset_library")).trim_suffix("/")
    if managed_root.is_empty(): managed_root = project_directory.path_join("asset_library")
    _registry = SourceRegistry.new(managed_root)
    _catalog = AssetCatalog.new(managed_root)
    _importer = AssetImporter.new(managed_root.path_join("imports"))
    _thumbnails = ThumbnailCache.new(managed_root.path_join("thumbnails"))

func load_library() -> Dictionary:
    var source_result: Dictionary = _registry.load_registry()
    if not source_result.get("ok", false): return source_result
    var catalog_result: Dictionary = _catalog.load_catalog()
    if not catalog_result.get("ok", false): return catalog_result
    return {"ok": true, "errors": [], "sources": get_sources(), "records": get_records(true), "managed_root": managed_root}

func migrate_legacy_sources(legacy_project_directory: String) -> Dictionary:
    var legacy_root := legacy_project_directory.trim_suffix("/").path_join("asset_library")
    if legacy_root == managed_root or not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(legacy_root)):
        return {"ok": true, "errors": [], "migrated": 0, "changed": false}
    var legacy = SourceRegistry.new(legacy_root)
    var loaded: Dictionary = legacy.load_registry()
    if not loaded.get("ok", false): return loaded
    var migrated := 0
    var changed := false
    for source in legacy.get_sources(false):
        var result: Dictionary = _registry.register_source(str(source.get("root_path", "")), str(source.get("display_name", "")))
        if not result.get("ok", false): return result
        if bool(result.get("changed", false)):
            migrated += 1
            changed = true
        if not bool(source.get("enabled", true)):
            var registered: Dictionary = result.get("source", {})
            var source_id := str(registered.get("source_id", ""))
            if not source_id.is_empty(): _registry.set_source_enabled(source_id, false)
    if changed:
        var scan_result: Dictionary = scan_all()
        if not scan_result.get("ok", false): return scan_result
    return {"ok": true, "errors": [], "migrated": migrated, "changed": changed}

func register_source(root_path: String, display_name: String = "") -> Dictionary:
    var result: Dictionary = _registry.register_source(root_path, display_name)
    if not result.get("ok", false): return result
    var scan_result: Dictionary = scan_all(); scan_result["source"] = result.get("source", {})
    return scan_result

func remove_source(source_id: String) -> Dictionary:
    var result: Dictionary = _registry.remove_source(source_id)
    if not result.get("ok", false): return result
    return scan_all()

func scan_all() -> Dictionary:
    var observations: Array = []; var scan_errors: Array[String] = []; var totals := {"files": 0, "hashed": 0, "reused": 0, "sources": 0}
    for source in _registry.get_sources(true):
        totals["sources"] += 1
        var source_id := str(source.get("source_id", "")); var scan_result: Dictionary = _scanner.scan_source(source, _catalog.previous_by_path(source_id))
        for key in ["files", "hashed", "reused"]: totals[key] += int(scan_result.get("stats", {}).get(key, 0))
        for error in scan_result.get("errors", []): scan_errors.append(str(error))
        for observation in scan_result.get("observations", []):
            var analyzed: Dictionary = observation.duplicate(true); analyzed["analysis"] = _analyzer.analyze(observation); observations.append(analyzed)
    var reconcile: Dictionary = _catalog.reconcile(observations, false)
    if not reconcile.get("ok", false): return reconcile
    var thumbnail_errors: Array[String] = []
    for record in _catalog.get_records(false):
        var thumbnail_result: Dictionary
        if _thumbnails.has_current_thumbnail(record):
            thumbnail_result = _thumbnails.ensure_thumbnail(record)
        else:
            var preview_node: Node = null; var reason := "Asset type could not be depicted by the thumbnail studio."
            var source: Dictionary = _registry.get_source(str(record.get("source_id", "")))
            if not source.is_empty():
                var import_result: Dictionary = _importer.instantiate(record, str(source.get("root_path", "")))
                if import_result.get("ok", false):
                    preview_node = import_result.get("node") as Node
                    _catalog.update_derived(str(record.get("asset_id", "")), import_result.get("derived", {}), false)
                else: reason = str(import_result.get("errors", [reason])[0])
            thumbnail_result = _thumbnails.ensure_thumbnail(record, preview_node, reason)
            if preview_node != null: preview_node.free()
        if thumbnail_result.get("ok", false): _catalog.update_thumbnail(str(record.get("asset_id", "")), thumbnail_result["thumbnail"], false)
        else:
            for error in thumbnail_result.get("errors", []): thumbnail_errors.append(str(error))
    var save_result: Dictionary = _catalog.save_catalog()
    if not save_result.get("ok", false): return save_result
    var all_errors: Array[String] = []; all_errors.append_array(scan_errors); all_errors.append_array(thumbnail_errors)
    return {"ok": all_errors.is_empty(), "errors": all_errors, "stats": totals, "records": get_records(true), "duplicate_groups": _catalog.duplicate_groups()}

func instantiate_asset_scene(asset_id: String) -> Dictionary:
    var record: Dictionary = _catalog.get_record(asset_id)
    if record.is_empty(): return _failure("Asset ID was not found in the catalog.")
    var source: Dictionary = _registry.get_source(str(record.get("source_id", "")))
    if source.is_empty(): return _failure("Asset source registration is missing.")
    var result: Dictionary = _importer.instantiate(record, str(source.get("root_path", "")))
    if result.get("ok", false): _catalog.update_derived(asset_id, result.get("derived", {}), true)
    return result

func ensure_import(asset_id: String) -> Dictionary:
    var record: Dictionary = _catalog.get_record(asset_id)
    if record.is_empty(): return _failure("Asset ID was not found in the catalog.")
    var source: Dictionary = _registry.get_source(str(record.get("source_id", "")))
    if source.is_empty(): return _failure("Asset source registration is missing.")
    var result: Dictionary = _importer.ensure_import(record, str(source.get("root_path", "")))
    if result.get("ok", false): _catalog.update_derived(asset_id, result.get("derived", {}), true)
    return result

func query(search_text: String = "", filters: Dictionary = {}) -> Array[Dictionary]:
    var filtered: Array[Dictionary] = _catalog.query("", filters)
    return _semantic.rank(filtered, search_text) if not search_text.strip_edges().is_empty() else filtered

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
    var record: Dictionary = _catalog.get_record(asset_id)
    if record.is_empty(): return {}
    var source: Dictionary = _registry.get_source(str(record.get("source_id", "")))
    return {"asset": record, "source": source, "license": record.get("license", {}).duplicate(true)}

func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
