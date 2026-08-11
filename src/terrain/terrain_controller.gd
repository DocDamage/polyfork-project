class_name PlayWorldTerrainController
extends Node3D

signal terrain_status(message: String, is_error: bool)
signal brush_changed(state: Dictionary)

const TerrainRepository = preload("res://src/terrain/terrain_repository.gd")
const TerrainRuntime = preload("res://src/terrain/terrain_runtime.gd")
const SculptCommand = preload("res://src/terrain/terrain_sculpt_command.gd")
const BiomeCommand = preload("res://src/terrain/terrain_biome_command.gd")

const AUTOSAVE_INTERVAL := 2.0

var _project
var _editor_session
var _dirty_callback := Callable()
var _repository
var _state
var _runtime = TerrainRuntime.new()
var _history
var _cursor := Vector3.ZERO
var _mode: StringName = &"raise"
var _radius := 180.0
var _strength := 4.0
var _save_accumulator := 0.0
var _cursor_visual: MeshInstance3D


func _init() -> void:
    name = "TerrainController"
    _runtime.name = "TerrainRuntime"
    add_child(_runtime)
    _create_cursor_visual()


func bind_project(project, project_directory: String, editor_session, dirty_callback: Callable) -> Dictionary:
    if project == null or editor_session == null or not dirty_callback.is_valid(): return _failure("Terrain controller requires a project, editor session, and dirty callback.")
    _project = project; _editor_session = editor_session; _dirty_callback = dirty_callback
    _history = editor_session.get_history()
    if _history == null or not _history.has_method("execute_command"): return _failure("Terrain controller could not bind the editor command history.")
    _repository = TerrainRepository.new(project_directory)
    var open_result: Dictionary = _repository.open_or_create(project)
    if not open_result.get("ok", false): return open_result
    _state = open_result.get("state")
    var resolver_result: Dictionary = _editor_session.bind_cell_resolver(Callable(_state, "cell_id_at_position"))
    if not resolver_result.get("ok", false): return resolver_result
    var runtime_result: Dictionary = _runtime.bind_state(_state)
    if not runtime_result.get("ok", false): return runtime_result
    var entity_stream_result: Dictionary = _sync_editor_streaming()
    if not entity_stream_result.get("ok", false): return entity_stream_result
    if bool(open_result.get("project_changed", false)):
        var dirty_result: Variant = _dirty_callback.call()
        if dirty_result is Dictionary and not dirty_result.get("ok", false): return _failure("Terrain topology initialized but project dirty signaling failed.")
    set_cursor(Vector3.ZERO); brush_changed.emit(get_brush_state())
    return {"ok": true, "errors": [], "created": open_result.get("created", false), "recovered_cells": open_result.get("recovered_cells", []), "cell_count": _state.cell_ids().size()}


func set_mode(mode: StringName) -> Dictionary:
    if not [&"raise", &"lower", &"smooth", &"flatten"].has(mode): return _failure("Unsupported terrain brush mode.")
    _mode = mode; brush_changed.emit(get_brush_state()); return {"ok": true, "errors": []}


func set_cursor(position_value: Vector3) -> Dictionary:
    if _state == null: return _failure("Terrain controller is not bound.")
    var stream_result: Dictionary = update_streaming_focus(position_value)
    if not stream_result.get("ok", false): return stream_result
    var cell_id: String = _state.cell_id_at_position(position_value)
    if cell_id.is_empty(): return _failure("Terrain cursor is outside the authored world partition.")
    _cursor = Vector3(position_value.x, _runtime.sample_height(position_value), position_value.z)
    _update_cursor_visual(); brush_changed.emit(get_brush_state())
    return {"ok": true, "errors": [], "cursor": _cursor, "cell_id": cell_id}


func move_cursor(delta: Vector2) -> Dictionary:
    var cell: Dictionary = _state.get_cell_at_position(_cursor)
    var step: float = 64.0
    if not cell.is_empty(): step = float(cell.get("cell_size_m", 1024.0)) / float(max(1, int(cell.get("resolution", 17)) - 1))
    return set_cursor(_cursor + Vector3(delta.x * step, 0.0, delta.y * step))


func set_radius(value: float) -> Dictionary:
    if value <= 0.0: return _failure("Terrain brush radius must be positive.")
    _radius = clamp(value, 16.0, 512.0); _update_cursor_visual(); brush_changed.emit(get_brush_state()); return {"ok": true, "errors": []}


func set_strength(value: float) -> Dictionary:
    if value <= 0.0: return _failure("Terrain brush strength must be positive.")
    _strength = clamp(value, 0.05, 32.0); brush_changed.emit(get_brush_state()); return {"ok": true, "errors": []}


func set_cursor_visible(value: bool) -> void:
    if _cursor_visual != null: _cursor_visual.visible = value


func cycle_mode() -> StringName:
    var modes: Array[StringName] = [&"raise", &"lower", &"smooth", &"flatten"]
    var index: int = modes.find(_mode)
    _mode = modes[(index + 1) % modes.size()]
    brush_changed.emit(get_brush_state())
    return _mode


func apply_brush() -> Dictionary:
    if _state == null: return _failure("Terrain controller is not bound.")
    var cell_id: String = _state.cell_id_at_position(_cursor)
    if cell_id.is_empty(): return _failure("Terrain brush cursor is outside the authored world partition.")
    var brush: Dictionary = {"mode": str(_mode), "center": _cursor, "radius": _radius, "strength": _strength}
    if _mode == &"flatten": brush["target_height"] = _runtime.sample_height(_cursor)
    var command = SculptCommand.new(_state, cell_id, brush, Callable(_runtime, "refresh_cell"))
    var result: Dictionary = _history.execute_command(command, "Sculpt terrain")
    if not result.get("ok", false): return _history_failure(result)
    var dirty_result: Variant = _dirty_callback.call()
    if dirty_result is Dictionary and not dirty_result.get("ok", false): return _failure("Terrain sculpt committed but dirty-state signaling failed.")
    set_cursor(_cursor); terrain_status.emit("Terrain sculpt applied", false)
    return {"ok": true, "errors": [], "cell_id": cell_id}


func assign_biome(biome_id: String) -> Dictionary:
    if _state == null: return _failure("Terrain controller is not bound.")
    var cell_id: String = _state.cell_id_at_position(_cursor)
    if cell_id.is_empty(): return _failure("Biome assignment cursor is outside the world partition.")
    var command = BiomeCommand.new(_state, cell_id, biome_id, Callable(_runtime, "refresh_cell"))
    var result: Dictionary = _history.execute_command(command, "Assign terrain biome")
    if not result.get("ok", false): return _history_failure(result)
    var dirty_result: Variant = _dirty_callback.call()
    if dirty_result is Dictionary and not dirty_result.get("ok", false): return _failure("Biome assignment committed but dirty-state signaling failed.")
    terrain_status.emit("Biome assigned", false)
    return {"ok": true, "errors": [], "cell_id": cell_id}


func update_streaming_focus(position_value: Vector3) -> Dictionary:
    var result: Dictionary = _runtime.update_focus(position_value)
    if not result.get("ok", false): return result
    var entity_result: Dictionary = _sync_editor_streaming()
    if not entity_result.get("ok", false): return entity_result
    result["entity_count"] = _editor_session.get_bridge().entity_count()
    return result


func flush_dirty() -> Dictionary:
    if _repository == null or _state == null: return _failure("Terrain controller is not bound.")
    var result: Dictionary = _repository.flush_dirty(_state)
    if result.get("ok", false):
        var stream_result: Dictionary = _runtime.update_focus(_runtime.focus_position())
        if not stream_result.get("ok", false): return stream_result
        var entity_result: Dictionary = _sync_editor_streaming()
        if not entity_result.get("ok", false): return entity_result
    return result


func advance(delta: float) -> Dictionary:
    if _state == null: return {"ok": true, "attempted": false, "errors": []}
    _save_accumulator += max(0.0, delta)
    if _save_accumulator < AUTOSAVE_INTERVAL or not _state.has_dirty_cells(): return {"ok": true, "attempted": false, "errors": []}
    _save_accumulator = 0.0
    var result: Dictionary = flush_dirty(); result["attempted"] = true
    if not result.get("ok", false): terrain_status.emit(str(result.get("errors", ["Terrain autosave failed."])[0]), true)
    return result


func get_state(): return _state
func get_runtime(): return _runtime
func get_repository(): return _repository
func get_biomes() -> Array: return [] if _state == null else _state.biome_registry.get("biomes", []).duplicate(true)
func get_brush_state() -> Dictionary: return {"mode": str(_mode), "cursor": _cursor, "radius": _radius, "strength": _strength, "cell_id": "" if _state == null else _state.cell_id_at_position(_cursor)}


func _sync_editor_streaming() -> Dictionary:
    if _editor_session == null or _state == null: return _failure("Terrain entity streaming requires a bound editor session.")
    var bridge = _editor_session.get_bridge()
    if bridge == null: return _failure("Terrain entity streaming could not resolve the runtime entity bridge.")
    if not bool(_state.manifest.get("streaming", false)): return bridge.clear_cell_filter()
    var active_ids: Array[String] = _runtime.get_loaded_cell_ids()
    var terrain_ids: Dictionary = {}
    for cell_id in _state.cell_ids(): terrain_ids[cell_id] = true
    for record in _project.entity_records:
        var entity_cell: String = str(record.get("cell_id", ""))
        if not terrain_ids.has(entity_cell) and not active_ids.has(entity_cell): active_ids.append(entity_cell)
    active_ids.sort(); return bridge.set_active_cell_ids(active_ids)


func _create_cursor_visual() -> void:
    _cursor_visual = MeshInstance3D.new(); _cursor_visual.name = "TerrainBrushCursor"
    var immediate := ImmediateMesh.new(); immediate.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
    for index in range(49):
        var angle: float = TAU * float(index) / 48.0
        immediate.surface_add_vertex(Vector3(cos(angle), 0.0, sin(angle)))
    immediate.surface_end(); _cursor_visual.mesh = immediate
    var material := StandardMaterial3D.new(); material.albedo_color = Color(0.46, 0.83, 0.31, 0.95); material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _cursor_visual.material_override = material; _cursor_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; _cursor_visual.visible = false
    add_child(_cursor_visual)


func _update_cursor_visual() -> void:
    if _cursor_visual == null: return
    _cursor_visual.position = _cursor + Vector3(0.0, 0.18, 0.0)
    _cursor_visual.scale = Vector3(_radius, 1.0, _radius)


func _history_failure(result: Dictionary) -> Dictionary: return _failure(str(result.get("error", "Terrain command failed.")))
func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
