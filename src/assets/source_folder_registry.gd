class_name PlayWorldSourceFolderRegistry
extends RefCounted

const AssetSource = preload("res://src/assets/asset_source.gd")
const SafeJsonWriter = preload("res://src/world/safe_json_writer.gd")

const DOCUMENT_TYPE := "asset_source_registry"
const SCHEMA_VERSION := 1
const FILE_NAME := "sources.json"

var managed_root: String
var registry_path: String
var sources: Array[Dictionary] = []
var _writer


func _init(root: String, writer = null) -> void:
    managed_root = root.trim_suffix("/")
    registry_path = managed_root.path_join(FILE_NAME)
    _writer = writer if writer != null else SafeJsonWriter.new()


func load_registry() -> Dictionary:
    var make_result := _ensure_managed_root()
    if not make_result.get("ok", false):
        return make_result
    if not FileAccess.file_exists(registry_path):
        sources.clear()
        return {"ok": true, "errors": [], "sources": []}
    var read_result: Dictionary = _writer.read_dictionary(registry_path)
    if not read_result.get("ok", false):
        return read_result
    var errors := validate_dictionary(read_result["data"])
    if not errors.is_empty():
        return {"ok": false, "errors": errors}
    sources.clear()
    for item in read_result["data"].get("sources", []):
        sources.append(item.duplicate(true))
    _sort_sources()
    return {"ok": true, "errors": [], "sources": get_sources()}


func register_source(root_path: String, display_name: String = "") -> Dictionary:
    var normalized := AssetSource.normalize_path(root_path)
    if normalized.is_empty():
        return _failure("Asset source folder path is required.")
    if DirAccess.open(normalized) == null:
        return _failure("Asset source folder does not exist or is not readable.")
    var managed_normalized := AssetSource.normalize_path(managed_root)
    if _paths_overlap(normalized, managed_normalized):
        return _failure("Asset source folder cannot overlap project-managed Asset Library storage.")
    for source in sources:
        if str(source.get("root_path", "")) == normalized:
            return {"ok": true, "errors": [], "source": source.duplicate(true), "changed": false}
    var source := AssetSource.create(normalized, display_name)
    var errors := AssetSource.validate_dictionary(source)
    if not errors.is_empty():
        return {"ok": false, "errors": errors}
    sources.append(source)
    _sort_sources()
    var save_result := save_registry()
    if not save_result.get("ok", false):
        sources.erase(source)
        return save_result
    return {"ok": true, "errors": [], "source": source.duplicate(true), "changed": true}


func remove_source(source_id: String) -> Dictionary:
    for index in range(sources.size()):
        if str(sources[index].get("source_id", "")) == source_id:
            var removed := sources[index]
            sources.remove_at(index)
            var result := save_registry()
            if not result.get("ok", false):
                sources.insert(index, removed)
                return result
            return {"ok": true, "errors": [], "changed": true}
    return _failure("Asset source ID was not found.")


func set_source_enabled(source_id: String, enabled: bool) -> Dictionary:
    for source in sources:
        if str(source.get("source_id", "")) == source_id:
            if bool(source.get("enabled", true)) == enabled:
                return {"ok": true, "errors": [], "changed": false}
            source["enabled"] = enabled
            var result := save_registry()
            if not result.get("ok", false):
                source["enabled"] = not enabled
                return result
            return {"ok": true, "errors": [], "changed": true}
    return _failure("Asset source ID was not found.")


func get_sources(enabled_only: bool = false) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for source in sources:
        if enabled_only and not bool(source.get("enabled", true)):
            continue
        result.append(source.duplicate(true))
    return result


func get_source(source_id: String) -> Dictionary:
    for source in sources:
        if str(source.get("source_id", "")) == source_id:
            return source.duplicate(true)
    return {}


func save_registry() -> Dictionary:
    var make_result := _ensure_managed_root()
    if not make_result.get("ok", false):
        return make_result
    return _writer.write_validated_dictionary(registry_path, to_dictionary(), Callable(self, "validate_dictionary"))


func to_dictionary() -> Dictionary:
    return {"document_type": DOCUMENT_TYPE, "schema_version": SCHEMA_VERSION, "sources": get_sources()}


static func validate_dictionary(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if data.get("document_type") != DOCUMENT_TYPE:
        errors.append("Asset source registry document_type is invalid.")
    if data.get("schema_version") != SCHEMA_VERSION:
        errors.append("Asset source registry schema_version is unsupported.")
    var values = data.get("sources")
    if not values is Array:
        errors.append("Asset source registry sources must be an array.")
        return errors
    var ids: Dictionary = {}
    var paths: Dictionary = {}
    for item in values:
        if not item is Dictionary:
            errors.append("Asset source registry entries must be dictionaries.")
            continue
        errors.append_array(AssetSource.validate_dictionary(item))
        var source_id := str(item.get("source_id", ""))
        var root_path := str(item.get("root_path", ""))
        if ids.has(source_id): errors.append("Asset source registry contains a duplicate source ID.")
        if paths.has(root_path): errors.append("Asset source registry contains a duplicate root path.")
        ids[source_id] = true
        paths[root_path] = true
    return errors


func _ensure_managed_root() -> Dictionary:
    if managed_root.strip_edges().is_empty():
        return _failure("Managed Asset Library root is required.")
    var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(managed_root))
    if error != OK:
        return _failure("Unable to create managed Asset Library storage: %s" % error)
    return {"ok": true, "errors": []}


func _sort_sources() -> void:
    sources.sort_custom(func(a, b): return str(a.get("source_id", "")) < str(b.get("source_id", "")))


static func _paths_overlap(a: String, b: String) -> bool:
    if a.is_empty() or b.is_empty(): return false
    return a == b or a.begins_with(b + "/") or b.begins_with(a + "/")


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
