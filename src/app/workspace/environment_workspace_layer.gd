class_name PlayWorldEnvironmentWorkspaceLayer
extends Control

signal status_changed(message: String, is_error: bool)
signal open_changed(open: bool)

const EnvironmentRuntime = preload("res://src/environment/environment_runtime.gd")
const EnvironmentService = preload("res://src/environment/environment_service.gd")
const EnvironmentPanel = preload("res://src/app/workspace/environment_tool_panel.gd")

var _workspace: Control
var _editor_viewport
var _bottom_dock: Control
var _transform_toolbar: Control
var _placement_toolbar: Control
var _viewport_center: Control
var _panel
var _runtime
var _service
var _terrain_controller
var _procedural_runtime
var _bound := false
var _play_mode := false
var _focus_accumulator := 0.0
var _weather_serial := 1
var _water_serial := 1

func _ready() -> void:
    name = "EnvironmentWorkspaceLayer"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _panel = EnvironmentPanel.new()
    add_child(_panel)
    _wire_panel()
    set_process_unhandled_input(true)

func bind_workspace(workspace: Control) -> Dictionary:
    _workspace = workspace
    _editor_viewport = workspace.get_node_or_null("ViewportFrame/ViewportBackdrop/EditorViewport3D")
    _bottom_dock = workspace.get_node_or_null("BottomDockLayer/BottomToolDock")
    _transform_toolbar = workspace.get_node_or_null("TransformToolbar")
    _placement_toolbar = workspace.get_node_or_null("PlacementToolbar")
    _viewport_center = workspace.get_node_or_null("ViewportFrame/ViewportBackdrop/ViewportCenter")
    if _editor_viewport == null or _bottom_dock == null: return _failure("Environment workspace could not resolve editor viewport or bottom dock.")
    if not _bottom_dock.tool_selected.is_connected(_on_tool_selected): _bottom_dock.tool_selected.connect(_on_tool_selected)
    return {"ok": true, "errors": []}

func bind_project(project, project_directory: String, editor_session, dirty_callback: Callable, terrain_controller, procedural_runtime = null) -> Dictionary:
    if _workspace == null: return _failure("Environment workspace must bind its workspace before a project.")
    if terrain_controller == null or terrain_controller.get_state() == null: return _failure("Environment workspace requires the bound Phase 5 terrain controller.")
    _terrain_controller = terrain_controller
    _procedural_runtime = procedural_runtime
    if _runtime != null and is_instance_valid(_runtime):
        if _runtime.get_parent() != null: _runtime.get_parent().remove_child(_runtime)
        _runtime.free()
    _runtime = EnvironmentRuntime.new()
    _editor_viewport.get_world_root().add_child(_runtime)
    _service = EnvironmentService.new()
    var result: Dictionary = _service.bind_project(project, project_directory, editor_session, dirty_callback, terrain_controller.get_state(), _runtime)
    if not result.get("ok", false): return result
    var runtime_result: Dictionary = _runtime.initialize(_service.get_state().to_document(), terrain_controller.get_state(), _procedural_runtime, false)
    if not runtime_result.get("ok", false): return runtime_result
    _runtime.set_rendering_enabled(true)
    if not _service.environment_changed.is_connected(_on_environment_changed): _service.environment_changed.connect(_on_environment_changed)
    if not _service.status_changed.is_connected(_on_service_status): _service.status_changed.connect(_on_service_status)
    if not _runtime.environment_changed.is_connected(_on_runtime_changed): _runtime.environment_changed.connect(_on_runtime_changed)
    _bound = true
    _play_mode = false
    _focus_accumulator = 0.0
    _refresh_panel_data()
    close_tool()
    return {
        "ok": true,
        "errors": [],
        "weather_profile_count": _service.get_weather_profiles().size(),
        "biome_override_count": _service.get_biome_overrides().size(),
        "water_hook_count": _service.get_water_hooks().size(),
    }

func toggle_tool() -> void:
    if not _bound or _play_mode: return
    if is_open(): close_tool()
    else: open_tool()

func open_tool() -> void:
    if not _bound or _play_mode: return
    if _workspace.has_method("close_asset_drawer"): _workspace.close_asset_drawer()
    if _workspace.has_method("clear_selection"): _workspace.clear_selection()
    if _viewport_center != null: _viewport_center.hide()
    _panel.open_panel()
    _refresh_panel_data()
    _sync_editor_controls()
    open_changed.emit(true)

func close_tool() -> void:
    if _panel != null: _panel.close_panel()
    _restore_empty_state()
    _sync_editor_controls()
    open_changed.emit(false)

func is_open() -> bool: return _panel != null and _panel.is_open()
func get_panel(): return _panel
func get_service(): return _service
func get_runtime(): return _runtime

func handle_cancel() -> bool:
    if not is_open(): return false
    close_tool()
    return true

func set_play_mode(play_mode: bool) -> void:
    _play_mode = play_mode
    if play_mode:
        close_tool()
        if _runtime != null: _runtime.set_rendering_enabled(false)
    else:
        restore_build_runtime()

func restore_build_runtime() -> Dictionary:
    if not _bound or _runtime == null or _service == null: return {"ok": true, "errors": [], "changed": false}
    var result: Dictionary = _runtime.refresh_authored(_service.get_state().to_document())
    if not result.get("ok", false): return result
    _runtime.set_rendering_enabled(true)
    _refresh_panel_data()
    return {"ok": true, "errors": [], "changed": true}

func get_play_bundle() -> Dictionary:
    if not _bound or _service == null: return {}
    if _runtime != null: _runtime.set_rendering_enabled(false)
    call_deferred("_restore_build_render_if_play_failed")
    return {
        "document": _service.get_state().to_document(),
        "terrain_state": _terrain_controller.get_state() if _terrain_controller != null else null,
        "procedural_runtime": _procedural_runtime,
    }

func advance(delta: float) -> Dictionary:
    if not _bound or _play_mode or _runtime == null: return {"ok": true, "attempted": false, "errors": []}
    _focus_accumulator += maxf(0.0, delta)
    if _focus_accumulator < 0.25: return {"ok": true, "attempted": false, "errors": []}
    _focus_accumulator = 0.0
    var focus := Vector3.ZERO
    if _editor_viewport != null and _editor_viewport.camera != null: focus = _editor_viewport.camera.global_position
    var result: Dictionary = _runtime.advance(0.0, focus)
    result["attempted"] = true
    return result

func _unhandled_input(event: InputEvent) -> void:
    if not is_open() or _play_mode: return
    if _panel.handle_shortcut(event): get_viewport().set_input_as_handled()

func _on_tool_selected(tool: StringName) -> void:
    if tool == &"water": toggle_tool()
    elif is_open(): close_tool()

func _wire_panel() -> void:
    _panel.time_requested.connect(func(hours: float) -> void: _report(_service.configure_authored_state({"time_of_day_hours": hours}), "Time of day updated"))
    _panel.weather_requested.connect(func(profile_id: String) -> void:
        if not profile_id.is_empty(): _report(_service.configure_authored_state({"default_weather_profile_id": profile_id}), "Weather profile applied"))
    _panel.create_weather_requested.connect(_create_weather_profile)
    _panel.fog_toggled.connect(func(enabled: bool) -> void: _report(_service.configure_authored_state({"fog_enabled": enabled}), "Fog updated"))
    _panel.wind_toggled.connect(func(enabled: bool) -> void: _report(_service.configure_authored_state({"wind_enabled": enabled}), "Wind updated"))
    _panel.wind_speed_requested.connect(_set_wind_speed)
    _panel.biome_override_requested.connect(func(biome_id: String, profile_id: String) -> void:
        _report(_service.set_biome_override(biome_id, {"weather_profile_id": profile_id}), "Biome environment override updated"))
    _panel.clear_biome_requested.connect(func(biome_id: String) -> void:
        var result: Dictionary = _service.clear_biome_override(biome_id)
        if not result.get("ok", false) and str(result.get("errors", [""])[0]).contains("does not exist"):
            status_changed.emit("Biome already uses inherited environment defaults", false)
        else: _report(result, "Biome environment override cleared"))
    _panel.create_water_hook_requested.connect(_create_water_hook)
    _panel.close_requested.connect(close_tool)

func _create_weather_profile() -> void:
    var profile_name := "Weather %d" % _weather_serial
    _weather_serial += 1
    var result: Dictionary = _service.create_weather_profile(profile_name, {})
    if result.get("ok", false):
        var profile_id: String = str(result.get("weather_profile_id", ""))
        if not profile_id.is_empty(): result = _service.configure_authored_state({"default_weather_profile_id": profile_id})
    _report(result, "%s created" % profile_name)

func _create_water_hook() -> void:
    var display_name := "Water Hook %d" % _water_serial
    var provider_key := "environment.water.%d" % _water_serial
    _water_serial += 1
    _report(_service.create_water_hook(display_name, provider_key, {}, ["environment"]), "%s created" % display_name)

func _set_wind_speed(speed_mps: float) -> void:
    var profile_id: String = _panel.selected_weather_id()
    if profile_id.is_empty():
        status_changed.emit("Select a weather profile before editing wind", true)
        return
    _report(_service.configure_weather_profile(profile_id, {"wind_speed_mps": speed_mps}), "Weather wind updated")

func _on_environment_changed() -> void: _refresh_panel_data()
func _on_runtime_changed(_state: Dictionary) -> void:
    if is_open(): _refresh_panel_data()
func _on_service_status(message: String, is_error: bool) -> void: status_changed.emit(message, is_error)

func _refresh_panel_data() -> void:
    if _panel == null or _service == null: return
    var state = _service.get_state()
    if state == null: return
    var biomes: Array = []
    if _terrain_controller != null: biomes = _terrain_controller.get_biomes()
    _panel.set_data(state.authored_state, _service.get_weather_profiles(), biomes, _service.get_water_hooks(), _runtime.get_evaluated_state() if _runtime != null else {})

func _report(result: Dictionary, success_message: String) -> void:
    if result.get("ok", false):
        _refresh_panel_data()
        status_changed.emit(success_message, false)
    else:
        status_changed.emit(str(result.get("errors", ["Environment action failed."])[0]), true)

func _restore_build_render_if_play_failed() -> void:
    if not _bound or _runtime == null or _workspace == null: return
    var play_session = _workspace.get_play_session() if _workspace.has_method("get_play_session") else null
    var still_build: bool = not _workspace.has_method("get_mode") or _workspace.get_mode() == &"build"
    if still_build and (play_session == null or not play_session.is_active()): restore_build_runtime()

func _restore_empty_state() -> void:
    if _viewport_center == null or _workspace == null: return
    var should_show: bool = not _workspace.has_method("get_mode") or _workspace.get_mode() == &"build"
    if should_show and _workspace.has_method("get_runtime_entity_count"): should_show = int(_workspace.call("get_runtime_entity_count")) == 0
    if should_show and _workspace.has_method("is_placement_active") and bool(_workspace.call("is_placement_active")): should_show = false
    _viewport_center.visible = should_show

func _sync_editor_controls() -> void:
    if _workspace == null: return
    var build_mode: bool = not _workspace.has_method("get_mode") or _workspace.get_mode() == &"build"
    var show_editors: bool = build_mode and not is_open()
    if _transform_toolbar != null: _transform_toolbar.visible = show_editors
    if _placement_toolbar != null: _placement_toolbar.visible = show_editors

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
