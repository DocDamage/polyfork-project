class_name PlayWorldProceduralRuntime
extends Node3D

signal runtime_changed(batch_count: int, instance_count: int)
signal wind_changed(wind_state: Dictionary)

const Batch = preload("res://src/procedural/foliage_multimesh_batch.gd")
const ScatterGenerator = preload("res://src/procedural/procedural_scatter_generator.gd")
const SplineBuilder = preload("res://src/procedural/procedural_spline_builder.gd")

var _state
var _terrain_state
var _terrain_runtime
var _source_resolver
var _active_cell_ids: Array[String] = []
var _batches: Dictionary = {}
var _spline_nodes: Dictionary = {}
var _mesh_cache: Dictionary = {}
var _generator = ScatterGenerator.new()
var _spline_builder = SplineBuilder.new()
var _environment_wind: Dictionary = {"enabled": false, "direction": Vector3.RIGHT, "speed_mps": 0.0, "gust_strength": 0.0}
var _performance_profile: Dictionary = {}

func _init() -> void: name = "ProceduralRuntime"
func _ready() -> void: _bind_scale_policy()

func bind_state(state, terrain_state, terrain_runtime, source_resolver) -> Dictionary:
    if state == null or terrain_state == null or terrain_runtime == null or source_resolver == null: return _failure("Procedural runtime requires procedural state, terrain state/runtime, and source resolver.")
    clear_runtime(); _state = state; _terrain_state = terrain_state; _terrain_runtime = terrain_runtime; _source_resolver = source_resolver
    if _terrain_runtime.has_signal("streaming_changed"):
        var streaming_callback := Callable(self, "_on_terrain_streaming_changed")
        if not _terrain_runtime.is_connected("streaming_changed", streaming_callback): _terrain_runtime.connect("streaming_changed", streaming_callback)
    if _terrain_runtime.has_signal("cell_refreshed"):
        var refresh_callback := Callable(self, "_on_terrain_cell_refreshed")
        if not _terrain_runtime.is_connected("cell_refreshed", refresh_callback): _terrain_runtime.connect("cell_refreshed", refresh_callback)
    return set_active_cell_ids(_terrain_runtime.get_loaded_cell_ids())

func configure_performance_profile(profile: Dictionary) -> Dictionary:
    _performance_profile = profile.duplicate(true)
    var configured: int = 0
    for batch_value in _batches.values():
        if batch_value != null and is_instance_valid(batch_value) and batch_value.has_method("configure_quality"):
            batch_value.configure_quality(_performance_profile); configured += 1
    return {"ok": true, "errors": [], "configured_batches": configured, "profile": _performance_profile.duplicate(true)}

func get_performance_profile() -> Dictionary: return _performance_profile.duplicate(true)

func set_active_cell_ids(cell_ids: Array[String]) -> Dictionary:
    if _state == null: return _failure("Procedural runtime is not bound.")
    var unique: Dictionary = {}
    for cell_id in cell_ids:
        if not _terrain_state.get_cell(cell_id).is_empty(): unique[cell_id] = true
    var next_ids: Array[String] = []
    for value in unique.keys(): next_ids.append(str(value))
    next_ids.sort()
    if next_ids == _active_cell_ids: return {"ok": true, "errors": [], "changed": false, "active_cell_ids": _active_cell_ids.duplicate(), "batch_count": batch_count(), "instance_count": total_instance_count(), "spline_node_count": spline_node_count()}
    var previous_set: Dictionary = {}
    for previous_id in _active_cell_ids: previous_set[previous_id] = true
    var next_set: Dictionary = {}
    for cell_id in next_ids: next_set[cell_id] = true
    for key in _batches.keys().duplicate():
        var batch = _batches[key]
        if batch == null or not is_instance_valid(batch): _batches.erase(key); continue
        if not next_set.has(str(batch.cell_id)): _remove_batch(str(key))
    _active_cell_ids = next_ids
    for cell_id in _active_cell_ids:
        if previous_set.has(cell_id): continue
        var result: Dictionary = refresh_cell(cell_id)
        if not result.get("ok", false): return result
    var spline_result: Dictionary = refresh_splines()
    if not spline_result.get("ok", false): return spline_result
    _emit_counts()
    return {"ok": true, "errors": [], "changed": true, "active_cell_ids": _active_cell_ids.duplicate(), "batch_count": batch_count(), "instance_count": total_instance_count(), "spline_node_count": spline_node_count()}

func refresh_all() -> Dictionary:
    if _state == null: return _failure("Procedural runtime is not bound.")
    _mesh_cache.clear()
    for cell_id in _active_cell_ids:
        var result: Dictionary = refresh_cell(cell_id)
        if not result.get("ok", false): return result
    var spline_result: Dictionary = refresh_splines()
    if not spline_result.get("ok", false): return spline_result
    _emit_counts(); return {"ok": true, "errors": [], "batch_count": batch_count(), "instance_count": total_instance_count(), "spline_node_count": spline_node_count()}

func refresh_cell(cell_id: String) -> Dictionary:
    if _state == null or not _active_cell_ids.has(cell_id): return {"ok": true, "errors": [], "changed": false}
    _remove_cell_batches(cell_id)
    var created: int = 0; var instances: int = 0
    for layer in _state.scatter_layers:
        if not bool(layer.get("enabled", true)): continue
        var foliage_id: String = str(layer.get("foliage_set_id", "")); var foliage: Dictionary = _state.get_foliage_set(foliage_id)
        if foliage.is_empty(): return _failure("Procedural scatter layer references a missing foliage set at runtime.")
        var generated: Dictionary = _generator.generate_for_cell(layer, foliage, cell_id, _terrain_state, _terrain_runtime)
        if not generated.get("ok", false): return generated
        var transforms: Array[Transform3D] = []
        for value in generated.get("transforms", []):
            if value is Transform3D: transforms.append(value)
        if transforms.is_empty(): continue
        var mesh_result: Dictionary = _resolve_foliage_mesh(foliage)
        if not mesh_result.get("ok", false): return mesh_result
        var mesh: Mesh = mesh_result.get("mesh") as Mesh
        if mesh == null: return _failure("Procedural foliage source did not resolve to a Mesh.")
        var batch = Batch.new(); var apply: Dictionary = batch.apply_batch(str(layer.get("scatter_layer_id", "")), cell_id, mesh, transforms, bool(foliage.get("cast_shadows", false)))
        if not apply.get("ok", false): batch.free(); return apply
        if not _performance_profile.is_empty(): batch.configure_quality(_performance_profile)
        _apply_wind_meta(batch); add_child(batch)
        _batches[_batch_key(str(layer.get("scatter_layer_id", "")), cell_id)] = batch
        created += 1; instances += transforms.size()
    _emit_counts(); return {"ok": true, "errors": [], "changed": true, "created_batches": created, "instance_count": instances}

func refresh_splines() -> Dictionary:
    if _state == null: return _failure("Procedural runtime is not bound.")
    _clear_spline_nodes(); var segment_count: int = 0
    for spline in _state.splines:
        var build: Dictionary = _spline_builder.build(spline, _active_cell_ids, _terrain_state, _terrain_runtime, _source_resolver)
        if not build.get("ok", false): _clear_spline_nodes(); return build
        var nodes: Array[Node3D] = []
        for value in build.get("nodes", []):
            if value is Node3D: nodes.append(value)
        for node in nodes: _apply_wind_meta(node); add_child(node)
        if not nodes.is_empty(): _spline_nodes[str(spline.get("spline_id", ""))] = nodes
        segment_count += int(build.get("segment_count", 0))
    _emit_counts(); return {"ok": true, "errors": [], "spline_node_count": spline_node_count(), "segment_count": segment_count}

func set_environment_wind(wind_state: Dictionary) -> Dictionary:
    var direction_value: Variant = wind_state.get("direction", Vector3.RIGHT); var direction := Vector3.RIGHT
    if direction_value is Vector3: direction = direction_value
    elif direction_value is Array and direction_value.size() == 3: direction = Vector3(float(direction_value[0]), float(direction_value[1]), float(direction_value[2]))
    else: return _failure("Procedural environment wind direction is invalid.")
    if direction.length_squared() > 0.000001: direction = direction.normalized()
    var speed: float = float(wind_state.get("speed_mps", 0.0)); var gust: float = float(wind_state.get("gust_strength", 0.0))
    if speed < 0.0 or gust < 0.0: return _failure("Procedural environment wind values must be non-negative.")
    _environment_wind = {"enabled": bool(wind_state.get("enabled", true)), "direction": direction, "speed_mps": speed, "gust_strength": gust}
    for batch in _batches.values():
        if batch is Node and is_instance_valid(batch): _apply_wind_meta(batch)
    for nodes_value in _spline_nodes.values():
        if not nodes_value is Array: continue
        for node_value in nodes_value:
            if node_value is Node and is_instance_valid(node_value): _apply_wind_meta(node_value)
    wind_changed.emit(_environment_wind.duplicate(true)); return {"ok": true, "errors": [], "consumed": true, "batch_count": batch_count(), "spline_node_count": spline_node_count()}

func get_environment_wind() -> Dictionary: return _environment_wind.duplicate(true)
func clear_runtime() -> void:
    for key in _batches.keys().duplicate(): _remove_batch(str(key))
    _batches.clear(); _clear_spline_nodes(); _mesh_cache.clear(); _active_cell_ids.clear()
func batch_count() -> int: return _batches.size()
func total_instance_count() -> int:
    var total: int = 0
    for batch in _batches.values():
        if batch != null and is_instance_valid(batch): total += int(batch.get_instance_count())
    return total
func spline_node_count() -> int:
    var total: int = 0
    for nodes_value in _spline_nodes.values():
        if nodes_value is Array: total += nodes_value.size()
    return total
func get_batch(scatter_layer_id: String, cell_id: String): return _batches.get(_batch_key(scatter_layer_id, cell_id))
func get_spline_nodes(spline_id: String) -> Array[Node3D]:
    var result: Array[Node3D] = []; var value: Variant = _spline_nodes.get(spline_id, [])
    if value is Array:
        for node_value in value:
            if node_value is Node3D and is_instance_valid(node_value): result.append(node_value)
    return result
func get_active_cell_ids() -> Array[String]: return _active_cell_ids.duplicate()

func _resolve_foliage_mesh(foliage: Dictionary) -> Dictionary:
    var foliage_id: String = str(foliage.get("foliage_set_id", ""))
    if _mesh_cache.has(foliage_id): return {"ok": true, "errors": [], "mesh": _mesh_cache[foliage_id]}
    var result: Dictionary = _source_resolver.resolve_mesh(foliage.get("source", {}))
    if result.get("ok", false): _mesh_cache[foliage_id] = result.get("mesh")
    return result
func _remove_cell_batches(cell_id: String) -> void:
    for key in _batches.keys().duplicate():
        var batch = _batches[key]
        if batch != null and is_instance_valid(batch) and str(batch.cell_id) == cell_id: _remove_batch(str(key))
func _remove_batch(key: String) -> void:
    var batch = _batches.get(key)
    if batch != null and is_instance_valid(batch):
        if batch.get_parent() == self: remove_child(batch)
        batch.free()
    _batches.erase(key)
func _clear_spline_nodes() -> void:
    for nodes_value in _spline_nodes.values():
        if not nodes_value is Array: continue
        for node_value in nodes_value:
            if node_value is Node and is_instance_valid(node_value):
                if node_value.get_parent() == self: remove_child(node_value)
                node_value.free()
    _spline_nodes.clear()
func _apply_wind_meta(node: Node) -> void:
    if node != null: node.set_meta("environment_wind", _environment_wind.duplicate(true))
func _bind_scale_policy() -> void:
    var scale_service: Node = get_node_or_null("/root/ScalePolish")
    if scale_service == null: return
    _apply_scale_service_profile(scale_service)
    var callback: Callable = Callable(self, "_on_scale_preferences_changed")
    if scale_service.has_signal("preferences_changed") and not scale_service.is_connected("preferences_changed", callback): scale_service.connect("preferences_changed", callback)
func _apply_scale_service_profile(scale_service: Node) -> void:
    if not scale_service.has_method("get_effective_profile"): return
    var profile_value: Variant = scale_service.call("get_effective_profile")
    if profile_value is Dictionary: configure_performance_profile(profile_value)
func _on_scale_preferences_changed(_settings: Dictionary) -> void:
    var scale_service: Node = get_node_or_null("/root/ScalePolish")
    if scale_service != null: _apply_scale_service_profile(scale_service)
func _on_terrain_streaming_changed(loaded_cell_ids: Array, _unloaded_cell_ids: Array, _blocked_dirty: Array) -> void:
    var typed: Array[String] = []
    for value in loaded_cell_ids: typed.append(str(value))
    var result: Dictionary = set_active_cell_ids(typed)
    if not result.get("ok", false): push_warning("Procedural streaming refresh failed: %s" % str(result.get("errors", [])))
func _on_terrain_cell_refreshed(cell_id: String) -> void:
    if not _active_cell_ids.has(cell_id): return
    var foliage_result: Dictionary = refresh_cell(cell_id)
    if not foliage_result.get("ok", false): push_warning("Procedural terrain refresh failed: %s" % str(foliage_result.get("errors", []))); return
    var spline_result: Dictionary = refresh_splines()
    if not spline_result.get("ok", false): push_warning("Procedural spline terrain refresh failed: %s" % str(spline_result.get("errors", [])))
func _emit_counts() -> void: runtime_changed.emit(batch_count(), total_instance_count())
static func _batch_key(scatter_layer_id: String, cell_id: String) -> String: return "%s:%s" % [scatter_layer_id, cell_id]
static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
