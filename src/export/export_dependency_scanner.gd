class_name PlayWorldExportDependencyScanner
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const ASSET_FIELDS: Array[String] = ["asset_id", "source_asset_id"]

static func discover(project_data: Dictionary, authored_documents: Dictionary = {}) -> Dictionary:
    var ids: Dictionary = {}
    var references: Array[Dictionary] = []
    var errors: Array[String] = []

    _scan_asset_fields(project_data.get("entities", []), "world.entities", ids, references, errors)
    var declared = project_data.get("dependencies", [])
    if not declared is Array:
        errors.append("World project dependencies must be an array for export discovery.")
    else:
        for index in range(declared.size()): _add_asset_id(declared[index], "world.dependencies[%d]" % index, ids, references, errors)

    for key in ["gameplay", "visual_scripting", "environment"]:
        if authored_documents.has(key): _scan_asset_fields(authored_documents[key], str(key), ids, references, errors)
    if authored_documents.has("procedural"):
        _scan_asset_fields(authored_documents["procedural"], "procedural", ids, references, errors)
        _scan_procedural_sources(authored_documents["procedural"], "procedural", ids, references, errors)

    var asset_ids: Array[String] = []
    for value in ids.keys(): asset_ids.append(str(value))
    asset_ids.sort()
    references.sort_custom(func(a, b):
        var ak := "%s:%s" % [str(a.get("asset_id", "")), str(a.get("source", ""))]
        var bk := "%s:%s" % [str(b.get("asset_id", "")), str(b.get("source", ""))]
        return ak < bk
    )
    return {"ok": errors.is_empty(), "errors": errors, "asset_ids": asset_ids, "references": references}

static func _scan_asset_fields(value: Variant, label: String, ids: Dictionary, references: Array[Dictionary], errors: Array[String]) -> void:
    if value is Dictionary:
        var data: Dictionary = value
        var keys: Array = data.keys(); keys.sort()
        for key_value in keys:
            var key := str(key_value)
            var child = data[key_value]
            if ASSET_FIELDS.has(key):
                if child != null and not str(child).is_empty(): _add_asset_id(child, "%s.%s" % [label, key], ids, references, errors)
            else:
                _scan_asset_fields(child, "%s.%s" % [label, key], ids, references, errors)
    elif value is Array:
        for index in range(value.size()): _scan_asset_fields(value[index], "%s[%d]" % [label, index], ids, references, errors)

static func _scan_procedural_sources(value: Variant, label: String, ids: Dictionary, references: Array[Dictionary], errors: Array[String]) -> void:
    if value is Dictionary:
        var data: Dictionary = value
        if str(data.get("kind", "")) == "asset" and data.has("source_id"):
            _add_asset_id(data.get("source_id"), "%s.source_id" % label, ids, references, errors)
        var keys: Array = data.keys(); keys.sort()
        for key_value in keys: _scan_procedural_sources(data[key_value], "%s.%s" % [label, str(key_value)], ids, references, errors)
    elif value is Array:
        for index in range(value.size()): _scan_procedural_sources(value[index], "%s[%d]" % [label, index], ids, references, errors)

static func _add_asset_id(value: Variant, source: String, ids: Dictionary, references: Array[Dictionary], errors: Array[String]) -> void:
    var asset_id := str(value)
    if not StableId.is_valid(asset_id):
        errors.append("Export asset dependency at %s is not a stable UUID." % source); return
    if not ids.has(asset_id): ids[asset_id] = true
    var reference := {"asset_id": asset_id, "source": source}
    if not references.has(reference): references.append(reference)
