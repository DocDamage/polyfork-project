class_name PlayWorldProceduralRuntime
extends Node3D

signal runtime_changed(batch_count: int, instance_count: int)

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


func _init() -> void:
    name = "ProceduralRuntime"


func bind_state(state, terrain_state, terrain_runtime, source_resolver) -> Dictionary:
    if state == null or terrain_state == null or terrain_runtime == null or source_resolver == null:
        return _failure("Procedural runtime requires procedural state, terrain state/runtime, and source resolver.")
    clear_runtime()
    _state = state
    _terrain_state = terrain_state
    _terrain_runtime = terrain_runtime
    _source_resolver = source_resolver
    if _terrain_runtime.has_signal("streaming_changed"):
        var streaming_callback := Callable(self, "_on_terrain_streaming_changed")
        if not _terrain_runtime.is_connected("streaming_changed", streaming_callback):
            _terrain_runtime.connect("streaming_changed", streaming_callback)
    if _terrain_runtime.has_signal("cell_refreshed"):
        var refresh_callback := Callable(self, "_on_terrain_cell_refreshed")
        if not _terrain_runtime.is_connected("cell_refreshed", refresh_callback):
            _terrain_runtime.connect("cell_refreshed", refresh_callback)
    return set_active_cell_ids(_terrain_runtime.get_loaded_cell_ids())


func set_active_cell_ids(cell_ids: Array[String]) -> Dictionary:
    if _state == null:
        return _failure("Procedural runtime is not bound.")
    var unique: Dictionary = {}
    for cell_id in cell_ids:
        if not _terrain_state.get_cell(cell_id).is_empty():
            unique[cell_id] = true
    var next_ids: Array[String] = []
    for value in unique.keys():
        next_ids.append(str(value))
    next_ids.sort()
    var next_set: Dictionary = {}
    for cell_id in next_ids:
        next_set[cell_id] = true
    for key in _batches.keys().duplicate():
        var batch = _batches[key]
        if batch == null or not is_instance_valid(batch):
            _batches.erase(key)
            continue
        if not next_set.has(str(batch.cell_id)):
            _remove_batch(str(key))
    _active_cell_ids = next_ids
    for cell_id in _active_cell_ids:
        var result: Dictionary = refresh_cell(cell_id)
        if not result.get("ok", false):
            return result
    var spline_result: Dictionary = refresh_splines()
    if not spline_result.get("ok", false):
        return spline_result
    _emit_counts()
    return {"ok": true, "errors": [], "active_cell_ids": _active_cell_ids.duplicate(), "batch_count": batch_count(), "instance_count": total_instance_count(), "spline_node_count": spline_node_count()}


func refresh_all() -> Dictionary:
    if _state == null:
        return _failure("Procedural runtime is not bound.")
    _mesh_cache.clear()
    for cell_id in _active_cell_ids:
        var result: Dictionary = refresh_cell(cell_id)
        if not result.get("ok", false):
            return result
    var spline_result: Dictionary = refresh_splines()
    if not spline_result.get("ok", false):
        return spline_result
    _emit_counts()
    return {"ok": true, "errors": [], "batch_count": batch_count(), "instance_count": total_instance_count(), "spline_node_count": spline_node_count()}


func refresh_cell(cell_id: String) -> Dictionary:
    if _state == null or not _active_cell_ids.has(cell_id):
        return {"ok": true, "errors": [], "changed": false}
    _remove_cell_batches(cell_id)
    var created: int = 0
    var instances: int = 0
    for layer in _state.scatter_layers:
        if not bool(layer.get("enabled", true)):
            continue
        var foliage_id: String = str(layer.get("foliage_set_id", ""))
        var foliage: Dictionary = _state.get_foliage_set(foliage_id)
        if foliage.is_empty():
            return _failure("Procedural scatter layer references a missing foliage set at runtime.")
        var generated: Dictionary = _generator.generate_for_cell(layer, foliage, cell_id, _terrain_state, _terrain_runtime)
        if not generated.get("ok", false):
            return generated
        var transforms: Array[Transform3D] = []
        for value in generated.get("transforms", []):
            if value is Transform3D:
                transforms.append(value)
        if transforms.is_empty():
            continue
        var mesh_result: Dictionary = _resolve_foliage_mesh(foliage)
        if not mesh_result.get("ok", false):
            return mesh_result
        var mesh: Mesh = mesh_result.get("mesh") as Mesh
        if mesh == null:
            return _failure("Procedural foliage source did not resolve to a Mesh.")
        var batch = Batch.new()
        var apply: Dictionary = batch.apply_batch(str(layer.get("scatter_layer_id", "")), cell_id, mesh, transforms, bool(foliage.get("cast_shadows", false)))
        if not apply.get("ok", false):
            batch.free()
            return apply
        add_child(batch)
        var key: String = _batch_key(str(layer.get("scatter_layer_id", "")), cell_id)
        _batches[key] = batch
        created += 1
        instances += transforms.size()
    _emit_counts()
    return {"ok": true, "errors": [], "changed": true, "created_batches": created, "instance_count": instances}


func refresh_splines() -> Dictionary:
    if _state == null:
        return _failure("Procedural runtime is not bound.")
    _clear_spline_nodes()
    var segment_count: int = 0
    for spline in _state.splines:
        var build: Dictionary = _spline_builder.build(spline, _active_cell_ids, _terrain_state, _terrain_runtime, _source_resolver)
        if not build.get("ok", false):
            _clear_spline_nodes()
            return build
        var nodes: Array[Node3D] = []
        for value in build.get("nodes", []):
            if value is Node3D:
                nodes.append(value)
        for node in nodes:
            add_child(node)
        if not nodes.is_empty():
            _spline_nodes[str(spline.get("spline_id", ""))] = nodes
        segment_count += int(build.get("segment_count", 0))
    _emit_counts()
    return {"ok": true, "errors": [], "spline_node_count": spline_node_count(), "segment_count": segment_count}


func clear_runtime() -> void:
    for key in _batches.keys().duplicate():
        _remove_batch(str(key))
    _batches.clear()
    _clear_spline_nodes()
    _mesh_cache.clear()
    _active_cell_ids.clear()


func batch_count() -> int:
    return _batches.size()


func total_instance_count() -> int:
    var total: int = 0
    for batch in _batches.values():
        if batch != null and is_instance_valid(batch):
            total += int(batch.get_instance_count())
    return total


func spline_node_count() -> int:
    var total: int = 0
    for nodes_value in _spline_nodes.values():
        if nodes_value is Array:
            total += nodes_value.size()
    return total


func get_batch(scatter_layer_id: String, cell_id: String):
    return _batches.get(_batch_key(scatter_layer_id, cell_id))


func get_spline_nodes(spline_id: String) -> Array[Node3D]:
    var result: Array[Node3D] = []
    var value: Variant = _spline_nodes.get(spline_id, [])
    if value is Array:
        for node_value in value:
            if node_value is Node3D and is_instance_valid(node_value):
                result.append(node_value)
    return result


func get_active_cell_ids() -> Array[String]:
    return _active_cell_ids.duplicate()


func _resolve_foliage_mesh(foliage: Dictionary) -> Dictionary:
    var foliage_id: String = str(foliage.get("foliage_set_id", ""))
    if _mesh_cache.has(foliage_id):
        return {"ok": true, "errors": [], "mesh": _mesh_cache[foliage_id]}
    var result: Dictionary = _source_resolver.resolve_mesh(foliage.get("source", {}))
    if result.get("ok", false):
        _mesh_cache[foliage_id] = result.get("mesh")
    return result


func _remove_cell_batches(cell_id: String) -> void:
    for key in _batches.keys().duplicate():
        var batch = _batches[key]
        if batch != null and is_instance_valid(batch) and str(batch.cell_id) == cell_id:
            _remove_batch(str(key))


func _remove_batch(key: String) -> void:
    var batch = _batches.get(key)
    if batch != null and is_instance_valid(batch):
        if batch.get_parent() == self:
            remove_child(batch)
        batch.free()
    _batches.erase(key)


func _clear_spline_nodes() -> void:
    for nodes_value in _spline_nodes.values():
        if not nodes_value is Array:
            continue
        for node_value in nodes_value:
            if node_value is Node and is_instance_valid(node_value):
                if node_value.get_parent() == self:
                    remove_child(node_value)
                node_value.free()
    _spline_nodes.clear()


func _on_terrain_streaming_changed(loaded_cell_ids: Array, _unloaded_cell_ids: Array, _blocked_dirty: Array) -> void:
    var typed: Array[String] = []
    for value in loaded_cell_ids:
        typed.append(str(value))
    var result: Dictionary = set_active_cell_ids(typed)
    if not result.get("ok", false):
        push_warning("Procedural streaming refresh failed: %s" % str(result.get("errors", [])))


func _on_terrain_cell_refreshed(cell_id: String) -> void:
    if not _active_cell_ids.has(cell_id):
        return
    var foliage_result: Dictionary = refresh_cell(cell_id)
    if not foliage_result.get("ok", false):
        push_warning("Procedural terrain refresh failed: %s" % str(foliage_result.get("errors", [])))
        return
    var spline_result: Dictionary = refresh_splines()
    if not spline_result.get("ok", false):
        push_warning("Procedural spline terrain refresh failed: %s" % str(spline_result.get("errors", [])))


func _emit_counts() -> void:
    runtime_changed.emit(batch_count(), total_instance_count())


static func _batch_key(scatter_layer_id: String, cell_id: String) -> String:
    return "%s:%s" % [scatter_layer_id, cell_id]


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
