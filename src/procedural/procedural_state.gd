class_name PlayWorldProceduralState
extends RefCounted

const Contracts = preload("res://src/procedural/procedural_contracts.gd")

var project_id: String = ""
var foliage_sets: Array[Dictionary] = []
var scatter_layers: Array[Dictionary] = []
var splines: Array[Dictionary] = []


func load_document(data: Dictionary) -> Array[String]:
    var errors: Array[String] = Contracts.validate_document(data)
    if not errors.is_empty():
        return errors
    project_id = str(data.get("project_id", ""))
    foliage_sets = _typed_records(data.get("foliage_sets", []))
    scatter_layers = _typed_records(data.get("scatter_layers", []))
    splines = _typed_records(data.get("splines", []))
    return []


func replace_document(data: Dictionary) -> Array[String]:
    return load_document(data)


func validate() -> Array[String]:
    return Contracts.validate_document(to_document())


func to_document() -> Dictionary:
    return {
        "document_type": Contracts.DOCUMENT_TYPE,
        "schema_version": Contracts.SCHEMA_VERSION,
        "project_id": project_id,
        "foliage_sets": foliage_sets.duplicate(true),
        "scatter_layers": scatter_layers.duplicate(true),
        "splines": splines.duplicate(true),
    }


func get_foliage_set(foliage_set_id: String) -> Dictionary:
    return _find_record(foliage_sets, "foliage_set_id", foliage_set_id)


func get_scatter_layer(scatter_layer_id: String) -> Dictionary:
    return _find_record(scatter_layers, "scatter_layer_id", scatter_layer_id)


func get_spline(spline_id: String) -> Dictionary:
    return _find_record(splines, "spline_id", spline_id)


func foliage_set_ids() -> Array[String]:
    return _sorted_ids(foliage_sets, "foliage_set_id")


func scatter_layer_ids() -> Array[String]:
    return _sorted_ids(scatter_layers, "scatter_layer_id")


func spline_ids() -> Array[String]:
    return _sorted_ids(splines, "spline_id")


func replace_foliage_sets(records: Array[Dictionary]) -> Array[String]:
    var document: Dictionary = to_document()
    document["foliage_sets"] = records.duplicate(true)
    return load_document(document)


func replace_scatter_layers(records: Array[Dictionary]) -> Array[String]:
    var document: Dictionary = to_document()
    document["scatter_layers"] = records.duplicate(true)
    return load_document(document)


func replace_splines(records: Array[Dictionary]) -> Array[String]:
    var document: Dictionary = to_document()
    document["splines"] = records.duplicate(true)
    return load_document(document)


static func _typed_records(value: Variant) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not value is Array:
        return result
    for item in value:
        if item is Dictionary:
            result.append(item.duplicate(true))
    return result


static func _find_record(records: Array[Dictionary], key: String, expected: String) -> Dictionary:
    for record in records:
        if str(record.get(key, "")) == expected:
            return record.duplicate(true)
    return {}


static func _sorted_ids(records: Array[Dictionary], key: String) -> Array[String]:
    var result: Array[String] = []
    for record in records:
        result.append(str(record.get(key, "")))
    result.sort()
    return result
