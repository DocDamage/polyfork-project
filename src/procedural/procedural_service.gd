class_name PlayWorldProceduralService
extends RefCounted

signal procedural_changed
signal status_changed(message: String, is_error: bool)

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/procedural/procedural_contracts.gd")
const Repository = preload("res://src/procedural/procedural_repository.gd")
const SnapshotCommand = preload("res://src/procedural/procedural_snapshot_command.gd")
const SourceResolver = preload("res://src/procedural/procedural_source_resolver.gd")

var _project
var _editor_session
var _dirty_callback := Callable()
var _repository
var _state
var _history
var _terrain_state
var _runtime
var _source_resolver = SourceResolver.new()


func bind_project(project, project_directory: String, editor_session, dirty_callback: Callable, terrain_state = null, runtime = null, asset_library = null, gameplay_service = null) -> Dictionary:
    if project == null or editor_session == null or not dirty_callback.is_valid():
        return _failure("Procedural service requires project, editor session, and dirty callback.")
    _project = project
    _editor_session = editor_session
    _dirty_callback = dirty_callback
    _terrain_state = terrain_state
    _runtime = runtime
    _history = editor_session.get_history()
    if _history == null or not _history.has_method("execute_command"):
        return _failure("Procedural service could not bind universal command history.")
    _repository = Repository.new(project_directory)
    var open_result: Dictionary = _repository.open_or_create(project)
    if not open_result.get("ok", false):
        _clear()
        return open_result
    _state = open_result.get("state")
    _source_resolver.bind(asset_library, gameplay_service)
    if _runtime != null:
        if terrain_state == null:
            return _failure("Procedural runtime binding requires terrain state.")
        var terrain_runtime: Variant = _runtime.get_meta("terrain_runtime") if _runtime.has_meta("terrain_runtime") else null
        if terrain_runtime != null:
            var bind_runtime: Dictionary = _runtime.bind_state(_state, terrain_state, terrain_runtime, _source_resolver)
            if not bind_runtime.get("ok", false):
                return bind_runtime
    return {
        "ok": true,
        "errors": [],
        "created": open_result.get("created", false),
        "foliage_set_count": _state.foliage_sets.size(),
        "scatter_layer_count": _state.scatter_layers.size(),
        "spline_count": _state.splines.size(),
    }


func get_state(): return _state
func get_repository(): return _repository
func get_source_resolver(): return _source_resolver
func get_foliage_sets() -> Array[Dictionary]: return [] if _state == null else _state.foliage_sets.duplicate(true)
func get_scatter_layers() -> Array[Dictionary]: return [] if _state == null else _state.scatter_layers.duplicate(true)
func get_splines() -> Array[Dictionary]: return [] if _state == null else _state.splines.duplicate(true)


func create_foliage_set(display_name: String, source: Dictionary, options: Dictionary = {}) -> Dictionary:
    if not _is_bound(): return _failure("Procedural service is not bound.")
    var foliage_id: String = StableId.generate()
    var record: Dictionary = {
        "foliage_set_id": foliage_id,
        "display_name": display_name.strip_edges(),
        "source": source.duplicate(true),
        "scale_range": options.get("scale_range", [0.8, 1.2]),
        "random_yaw": bool(options.get("random_yaw", true)),
        "align_to_normal": bool(options.get("align_to_normal", true)),
        "cast_shadows": bool(options.get("cast_shadows", false)),
        "max_instances_per_cell": int(options.get("max_instances_per_cell", 4000)),
    }
    var record_errors: Array[String] = Contracts.validate_foliage_set(record)
    if not record_errors.is_empty(): return {"ok": false, "errors": record_errors}
    var after: Dictionary = _state.to_document()
    var records: Array = after.get("foliage_sets", []).duplicate(true)
    records.append(record)
    after["foliage_sets"] = records
    var result: Dictionary = _commit(after, "Create foliage set")
    if result.get("ok", false): result["foliage_set_id"] = foliage_id
    return result


func create_scatter_layer(display_name: String, foliage_set_id: String, options: Dictionary = {}) -> Dictionary:
    if not _is_bound(): return _failure("Procedural service is not bound.")
    if _state.get_foliage_set(foliage_set_id).is_empty(): return _failure("Scatter layer requires an existing foliage set.")
    var scatter_id: String = StableId.generate()
    var record: Dictionary = {
        "scatter_layer_id": scatter_id,
        "display_name": display_name.strip_edges(),
        "foliage_set_id": foliage_set_id,
        "enabled": bool(options.get("enabled", true)),
        "seed": int(options.get("seed", 1)),
        "density_per_100m2": float(options.get("density_per_100m2", 6.0)),
        "minimum_spacing_m": float(options.get("minimum_spacing_m", 1.0)),
        "slope_range_deg": options.get("slope_range_deg", [0.0, 45.0]),
        "height_range_m": options.get("height_range_m", [-10000.0, 10000.0]),
        "biome_ids": options.get("biome_ids", []).duplicate(true),
        "strokes": [],
    }
    var foliage_ids: Array = _state.foliage_set_ids()
    var record_errors: Array[String] = Contracts.validate_scatter_layer(record, foliage_ids)
    if not record_errors.is_empty(): return {"ok": false, "errors": record_errors}
    var after: Dictionary = _state.to_document()
    var records: Array = after.get("scatter_layers", []).duplicate(true)
    records.append(record)
    after["scatter_layers"] = records
    var result: Dictionary = _commit(after, "Create scatter layer")
    if result.get("ok", false): result["scatter_layer_id"] = scatter_id
    return result


func add_scatter_stroke(scatter_layer_id: String, operation: String, center: Vector3, radius_m: float, strength: float = 1.0) -> Dictionary:
    if not _is_bound(): return _failure("Procedural service is not bound.")
    if _terrain_state == null: return _failure("Scatter painting requires bound terrain state.")
    var cell_id: String = _terrain_state.cell_id_at_position(center)
    if cell_id.is_empty(): return _failure("Scatter brush center is outside the authored terrain partition.")
    var layer: Dictionary = _state.get_scatter_layer(scatter_layer_id)
    if layer.is_empty(): return _failure("Scatter layer does not exist.")
    var stroke_id: String = StableId.generate()
    var stroke: Dictionary = {
        "stroke_id": stroke_id,
        "operation": operation,
        "cell_id": cell_id,
        "center": [center.x, center.y, center.z],
        "radius_m": radius_m,
        "strength": strength,
    }
    var stroke_errors: Array[String] = Contracts.validate_stroke(stroke)
    if not stroke_errors.is_empty(): return {"ok": false, "errors": stroke_errors}
    var after: Dictionary = _state.to_document()
    var layers: Array = after.get("scatter_layers", []).duplicate(true)
    var found: bool = false
    for index in range(layers.size()):
        if str(layers[index].get("scatter_layer_id", "")) != scatter_layer_id: continue
        var staged: Dictionary = layers[index].duplicate(true)
        var strokes: Array = staged.get("strokes", []).duplicate(true)
        strokes.append(stroke)
        staged["strokes"] = strokes
        layers[index] = staged
        found = true
        break
    if not found: return _failure("Scatter layer disappeared before stroke staging.")
    after["scatter_layers"] = layers
    var result: Dictionary = _commit(after, "%s scatter" % operation.capitalize())
    if result.get("ok", false):
        result["stroke_id"] = stroke_id
        result["cell_id"] = cell_id
    return result


func configure_scatter_layer(scatter_layer_id: String, patch: Dictionary) -> Dictionary:
    if not _is_bound(): return _failure("Procedural service is not bound.")
    var allowed: Array[String] = ["display_name", "enabled", "seed", "density_per_100m2", "minimum_spacing_m", "slope_range_deg", "height_range_m", "biome_ids"]
    for key_value in patch.keys():
        if not allowed.has(str(key_value)): return _failure("Unsupported scatter-layer property: %s" % str(key_value))
    var after: Dictionary = _state.to_document()
    var layers: Array = after.get("scatter_layers", []).duplicate(true)
    var found: bool = false
    for index in range(layers.size()):
        if str(layers[index].get("scatter_layer_id", "")) != scatter_layer_id: continue
        var staged: Dictionary = layers[index].duplicate(true)
        for key_value in patch.keys(): staged[key_value] = patch[key_value]
        layers[index] = staged
        found = true
        break
    if not found: return _failure("Scatter layer does not exist.")
    after["scatter_layers"] = layers
    var validation: Array[String] = Contracts.validate_document(after)
    if not validation.is_empty(): return {"ok": false, "errors": validation}
    return _commit(after, "Configure scatter layer")


func create_spline(display_name: String, kind: String, positions: Array[Vector3], options: Dictionary = {}) -> Dictionary:
    if not _is_bound(): return _failure("Procedural service is not bound.")
    if positions.size() < 2: return _failure("Spline creation requires at least two control points.")
    var spline_id: String = StableId.generate()
    var points: Array[Dictionary] = []
    for position_value in positions:
        points.append({"point_id": StableId.generate(), "position": [position_value.x, position_value.y, position_value.z]})
    var record: Dictionary = {
        "spline_id": spline_id,
        "display_name": display_name.strip_edges(),
        "kind": kind,
        "closed": bool(options.get("closed", false)),
        "width_m": float(options.get("width_m", 6.0 if kind == "road" else 2.0)),
        "sample_spacing_m": float(options.get("sample_spacing_m", 3.0)),
        "terrain_conform": bool(options.get("terrain_conform", true)),
        "points": points,
    }
    if kind == "fence": record["segment_source"] = options.get("segment_source", {"kind": "primitive", "primitive": "post"}).duplicate(true)
    var record_errors: Array[String] = Contracts.validate_spline(record)
    if not record_errors.is_empty(): return {"ok": false, "errors": record_errors}
    var after: Dictionary = _state.to_document()
    var splines: Array = after.get("splines", []).duplicate(true)
    splines.append(record)
    after["splines"] = splines
    var result: Dictionary = _commit(after, "Create %s spline" % kind)
    if result.get("ok", false):
        result["spline_id"] = spline_id
        var point_ids: Array[String] = []
        for point in points: point_ids.append(str(point.get("point_id", "")))
        result["point_ids"] = point_ids
    return result


func add_spline_point(spline_id: String, position_value: Vector3, insert_index: int = -1) -> Dictionary:
    var spline: Dictionary = _state.get_spline(spline_id) if _state != null else {}
    if spline.is_empty(): return _failure("Spline does not exist.")
    var point_id: String = StableId.generate()
    var point: Dictionary = {"point_id": point_id, "position": [position_value.x, position_value.y, position_value.z]}
    var points: Array = spline.get("points", []).duplicate(true)
    if insert_index < 0 or insert_index >= points.size(): points.append(point)
    else: points.insert(insert_index, point)
    spline["points"] = points
    var result: Dictionary = _replace_spline(spline, "Add spline point")
    if result.get("ok", false): result["point_id"] = point_id
    return result


func move_spline_point(spline_id: String, point_id: String, position_value: Vector3) -> Dictionary:
    var spline: Dictionary = _state.get_spline(spline_id) if _state != null else {}
    if spline.is_empty(): return _failure("Spline does not exist.")
    var points: Array = spline.get("points", []).duplicate(true)
    var found: bool = false
    for index in range(points.size()):
        if str(points[index].get("point_id", "")) != point_id: continue
        var point: Dictionary = points[index].duplicate(true)
        point["position"] = [position_value.x, position_value.y, position_value.z]
        points[index] = point
        found = true
        break
    if not found: return _failure("Spline point does not exist.")
    spline["points"] = points
    return _replace_spline(spline, "Move spline point")


func delete_spline_point(spline_id: String, point_id: String) -> Dictionary:
    var spline: Dictionary = _state.get_spline(spline_id) if _state != null else {}
    if spline.is_empty(): return _failure("Spline does not exist.")
    var points: Array = spline.get("points", []).duplicate(true)
    if points.size() <= 2: return _failure("Spline must retain at least two control points.")
    var removed: bool = false
    for index in range(points.size() - 1, -1, -1):
        if str(points[index].get("point_id", "")) == point_id:
            points.remove_at(index)
            removed = true
            break
    if not removed: return _failure("Spline point does not exist.")
    spline["points"] = points
    return _replace_spline(spline, "Delete spline point")


func configure_spline(spline_id: String, patch: Dictionary) -> Dictionary:
    var spline: Dictionary = _state.get_spline(spline_id) if _state != null else {}
    if spline.is_empty(): return _failure("Spline does not exist.")
    var allowed: Array[String] = ["display_name", "closed", "width_m", "sample_spacing_m", "terrain_conform", "segment_source"]
    for key_value in patch.keys():
        if not allowed.has(str(key_value)): return _failure("Unsupported spline property: %s" % str(key_value))
        spline[key_value] = patch[key_value]
    return _replace_spline(spline, "Configure spline")


func delete_spline(spline_id: String) -> Dictionary:
    if not _is_bound(): return _failure("Procedural service is not bound.")
    var after: Dictionary = _state.to_document()
    var splines: Array = after.get("splines", []).duplicate(true)
    var removed: bool = false
    for index in range(splines.size() - 1, -1, -1):
        if str(splines[index].get("spline_id", "")) == spline_id:
            splines.remove_at(index)
            removed = true
            break
    if not removed: return _failure("Spline does not exist.")
    after["splines"] = splines
    return _commit(after, "Delete spline")


func _replace_spline(spline: Dictionary, label: String) -> Dictionary:
    var after: Dictionary = _state.to_document()
    var splines: Array = after.get("splines", []).duplicate(true)
    var found: bool = false
    for index in range(splines.size()):
        if str(splines[index].get("spline_id", "")) == str(spline.get("spline_id", "")):
            splines[index] = spline.duplicate(true)
            found = true
            break
    if not found: return _failure("Spline disappeared before staging.")
    after["splines"] = splines
    return _commit(after, label)


func _commit(after: Dictionary, label: String) -> Dictionary:
    var validation: Array[String] = Contracts.validate_document(after)
    if not validation.is_empty(): return {"ok": false, "errors": validation}
    var refresh := Callable()
    if _runtime != null and _runtime.has_method("refresh_all"): refresh = Callable(_runtime, "refresh_all")
    var command = SnapshotCommand.new(_project, _state, _repository, _state.to_document(), after, refresh)
    var history_result: Dictionary = _history.execute_command(command, label)
    if not history_result.get("ok", false): return _failure(str(history_result.get("error", history_result.get("errors", ["Procedural command failed."]))))
    var dirty_result: Variant = _dirty_callback.call()
    if dirty_result is Dictionary and not dirty_result.get("ok", false): return _failure("Procedural edit succeeded but project dirty-state signaling failed.")
    if _editor_session.has_signal("project_changed"): _editor_session.emit_signal("project_changed", _project.to_dictionary())
    procedural_changed.emit()
    status_changed.emit(label, false)
    return {"ok": true, "errors": [], "project_data": _project.to_dictionary()}


func _is_bound() -> bool:
    return _project != null and _editor_session != null and _state != null and _repository != null and _history != null


func _clear() -> void:
    _project = null
    _editor_session = null
    _repository = null
    _state = null
    _history = null
    _terrain_state = null
    _runtime = null
    _dirty_callback = Callable()


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
