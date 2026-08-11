class_name PlayWorldAssetCatalog
extends RefCounted

const AssetRecord = preload("res://src/assets/asset_record.gd")
const SafeJsonWriter = preload("res://src/world/safe_json_writer.gd")

const DOCUMENT_TYPE := "asset_catalog"
const SCHEMA_VERSION := 1
const FILE_NAME := "catalog.json"

var managed_root: String
var catalog_path: String
var records: Array[Dictionary] = []
var _writer


func _init(root: String, writer = null) -> void:
    managed_root = root.trim_suffix("/")
    catalog_path = managed_root.path_join(FILE_NAME)
    _writer = writer if writer != null else SafeJsonWriter.new()


func load_catalog() -> Dictionary:
    var make_result := _ensure_root()
    if not make_result.get("ok", false): return make_result
    if not FileAccess.file_exists(catalog_path):
        records.clear()
        return {"ok": true, "errors": [], "records": []}
    var read_result: Dictionary = _writer.read_dictionary(catalog_path)
    if not read_result.get("ok", false): return read_result
    var errors := validate_dictionary(read_result["data"])
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    records.clear()
    for item in read_result["data"].get("records", []): records.append(item.duplicate(true))
    _sort_records()
    return {"ok": true, "errors": [], "records": get_records(true)}


func reconcile(observations: Array, persist: bool = true) -> Dictionary:
    var old_records: Array[Dictionary] = []
    for record in records: old_records.append(record.duplicate(true))
    var exact: Dictionary = {}
    for record in old_records:
        exact[_path_key(record)] = record
    var matched: Dictionary = {}
    var next_records: Array[Dictionary] = []
    var sorted_observations := observations.duplicate(true)
    sorted_observations.sort_custom(func(a, b): return _observation_key(a) < _observation_key(b))
    for observation in sorted_observations:
        var fresh := AssetRecord.from_observation(observation)
        var identity: Dictionary = exact.get(_observation_key(observation), {})
        if identity.is_empty():
            identity = _unique_move_candidate(observation, old_records, matched)
        if not identity.is_empty():
            _inherit_identity(fresh, identity)
            matched[str(identity.get("asset_id", ""))] = true
        next_records.append(fresh)
    for old_record in old_records:
        var old_id := str(old_record.get("asset_id", ""))
        if matched.has(old_id): continue
        var missing_record := old_record.duplicate(true)
        missing_record["missing"] = true
        next_records.append(missing_record)
    records = next_records
    _sort_records()
    var validation := validate_dictionary(to_dictionary())
    if not validation.is_empty():
        records = old_records
        return {"ok": false, "errors": validation}
    if persist:
        var save_result := save_catalog()
        if not save_result.get("ok", false):
            records = old_records
            return save_result
    return {"ok": true, "errors": [], "records": get_records(true), "duplicate_groups": duplicate_groups()}


func save_catalog() -> Dictionary:
    var make_result := _ensure_root()
    if not make_result.get("ok", false): return make_result
    return _writer.write_validated_dictionary(catalog_path, to_dictionary(), Callable(self, "validate_dictionary"))


func get_records(include_missing: bool = false) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for record in records:
        if not include_missing and bool(record.get("missing", false)): continue
        result.append(record.duplicate(true))
    return result


func get_record(asset_id: String) -> Dictionary:
    for record in records:
        if str(record.get("asset_id", "")) == asset_id: return record.duplicate(true)
    return {}


func previous_by_path(source_id: String) -> Dictionary:
    var result: Dictionary = {}
    for record in records:
        if str(record.get("source_id", "")) == source_id and not bool(record.get("missing", false)):
            result[str(record.get("relative_path", ""))] = record.duplicate(true)
    return result


func query(search_text: String = "", filters: Dictionary = {}) -> Array[Dictionary]:
    var needle := search_text.strip_edges().to_lower()
    var duplicate_ids: Dictionary = {}
    if bool(filters.get("duplicates_only", false)):
        for group in duplicate_groups():
            for asset_id in group: duplicate_ids[str(asset_id)] = true
    var result: Array[Dictionary] = []
    for record in records:
        if bool(record.get("missing", false)) and not bool(filters.get("include_missing", false)): continue
        if filters.has("asset_type") and not str(filters["asset_type"]).is_empty() and str(record.get("asset_type", "")) != str(filters["asset_type"]): continue
        if filters.has("source_id") and not str(filters["source_id"]).is_empty() and str(record.get("source_id", "")) != str(filters["source_id"]): continue
        if bool(filters.get("favorites_only", false)) and not bool(record.get("favorite", false)): continue
        if bool(filters.get("duplicates_only", false)) and not duplicate_ids.has(str(record.get("asset_id", ""))): continue
        var collection := str(filters.get("collection", "")).strip_edges()
        if not collection.is_empty() and not record.get("collections", []).has(collection): continue
        if not needle.is_empty():
            var license: Dictionary = record.get("license", {})
            var haystack := "%s %s %s %s" % [record.get("display_name", ""), record.get("relative_path", ""), license.get("spdx", ""), license.get("author", "")]
            if haystack.to_lower().find(needle) == -1: continue
        result.append(record.duplicate(true))
    result.sort_custom(func(a, b): return _record_sort_key(a) < _record_sort_key(b))
    return result


func set_favorite(asset_id: String, favorite: bool, persist: bool = true) -> Dictionary:
    return _mutate(asset_id, func(record): record["favorite"] = favorite, persist)


func set_license(asset_id: String, license_data: Dictionary, persist: bool = true) -> Dictionary:
    var normalized := {"spdx": str(license_data.get("spdx", "")), "author": str(license_data.get("author", "")), "source_url": str(license_data.get("source_url", "")), "notes": str(license_data.get("notes", ""))}
    return _mutate(asset_id, func(record): record["license"] = normalized, persist)


func add_to_collection(asset_id: String, collection: String, persist: bool = true) -> Dictionary:
    var label := collection.strip_edges()
    if label.is_empty(): return _failure("Collection name is required.")
    return _mutate(asset_id, func(record):
        var values: Array = record.get("collections", []).duplicate()
        if not values.has(label): values.append(label)
        values.sort()
        record["collections"] = values
    , persist)


func remove_from_collection(asset_id: String, collection: String, persist: bool = true) -> Dictionary:
    var label := collection.strip_edges()
    return _mutate(asset_id, func(record):
        var values: Array = record.get("collections", []).duplicate()
        values.erase(label)
        record["collections"] = values
    , persist)


func update_thumbnail(asset_id: String, thumbnail: Dictionary, persist: bool = true) -> Dictionary:
    return _mutate(asset_id, func(record): record["thumbnail"] = thumbnail.duplicate(true), persist)


func update_derived(asset_id: String, derived: Dictionary, persist: bool = true) -> Dictionary:
    return _mutate(asset_id, func(record): record["derived"] = derived.duplicate(true), persist)


func collections() -> Array[String]:
    var names: Dictionary = {}
    for record in records:
        for value in record.get("collections", []): names[str(value)] = true
    var result: Array[String] = []
    for name in names.keys(): result.append(str(name))
    result.sort()
    return result


func duplicate_groups() -> Array[Array]:
    var by_signature: Dictionary = {}
    for record in records:
        if bool(record.get("missing", false)): continue
        var signature := AssetRecord.content_signature(record)
        if not by_signature.has(signature): by_signature[signature] = []
        by_signature[signature].append(str(record.get("asset_id", "")))
    var groups: Array[Array] = []
    for values in by_signature.values():
        if values.size() < 2: continue
        values.sort()
        groups.append(values)
    groups.sort_custom(func(a, b): return str(a[0]) < str(b[0]))
    return groups


func to_dictionary() -> Dictionary:
    return {"document_type": DOCUMENT_TYPE, "schema_version": SCHEMA_VERSION, "records": get_records(true)}


static func validate_dictionary(data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    if data.get("document_type") != DOCUMENT_TYPE: errors.append("Asset catalog document_type is invalid.")
    if data.get("schema_version") != SCHEMA_VERSION: errors.append("Asset catalog schema_version is unsupported.")
    var values = data.get("records")
    if not values is Array:
        errors.append("Asset catalog records must be an array.")
        return errors
    var ids: Dictionary = {}
    for item in values:
        if not item is Dictionary:
            errors.append("Asset catalog records must be dictionaries.")
            continue
        errors.append_array(AssetRecord.validate_dictionary(item))
        var asset_id := str(item.get("asset_id", ""))
        if ids.has(asset_id): errors.append("Asset catalog contains a duplicate asset ID.")
        ids[asset_id] = true
    return errors


func _mutate(asset_id: String, mutation: Callable, persist: bool) -> Dictionary:
    for index in range(records.size()):
        if str(records[index].get("asset_id", "")) != asset_id: continue
        var before := records[index].duplicate(true)
        mutation.call(records[index])
        var errors := AssetRecord.validate_dictionary(records[index])
        if not errors.is_empty():
            records[index] = before
            return {"ok": false, "errors": errors}
        if persist:
            var save_result := save_catalog()
            if not save_result.get("ok", false):
                records[index] = before
                return save_result
        return {"ok": true, "errors": [], "record": records[index].duplicate(true)}
    return _failure("Asset ID was not found in the catalog.")


func _unique_move_candidate(observation: Dictionary, old_records: Array[Dictionary], matched: Dictionary) -> Dictionary:
    var signature := AssetRecord.content_signature(observation)
    var source_id := str(observation.get("source_id", ""))
    var candidates: Array[Dictionary] = []
    for old_record in old_records:
        var old_id := str(old_record.get("asset_id", ""))
        if matched.has(old_id): continue
        if str(old_record.get("source_id", "")) != source_id: continue
        if AssetRecord.content_signature(old_record) == signature: candidates.append(old_record)
    return candidates[0] if candidates.size() == 1 else {}


func _inherit_identity(fresh: Dictionary, old_record: Dictionary) -> void:
    fresh["asset_id"] = old_record["asset_id"]
    fresh["display_name"] = old_record.get("display_name", fresh["display_name"])
    fresh["favorite"] = old_record.get("favorite", false)
    fresh["collections"] = old_record.get("collections", []).duplicate()
    fresh["license"] = old_record.get("license", {}).duplicate(true)
    fresh["user_metadata"] = old_record.get("user_metadata", {}).duplicate(true)
    if str(fresh.get("content_hash", "")) == str(old_record.get("content_hash", "")):
        fresh["derived"] = old_record.get("derived", {}).duplicate(true)
        fresh["thumbnail"] = old_record.get("thumbnail", {}).duplicate(true)


func _ensure_root() -> Dictionary:
    var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(managed_root))
    return {"ok": error == OK, "errors": [] if error == OK else ["Unable to create Asset Library catalog storage: %s" % error]}


func _sort_records() -> void:
    records.sort_custom(func(a, b): return _record_sort_key(a) < _record_sort_key(b))


static func _record_sort_key(record: Dictionary) -> String:
    return "%s/%s/%s" % [str(record.get("source_id", "")), str(record.get("relative_path", "")).to_lower(), str(record.get("asset_id", ""))]


static func _path_key(record: Dictionary) -> String:
    return "%s/%s" % [str(record.get("source_id", "")), str(record.get("relative_path", ""))]


static func _observation_key(observation: Dictionary) -> String:
    return "%s/%s" % [str(observation.get("source_id", "")), str(observation.get("relative_path", ""))]


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
