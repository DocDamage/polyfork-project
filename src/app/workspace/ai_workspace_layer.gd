class_name PlayWorldAiWorkspaceLayer
extends Control

signal status_changed(message: String, is_error: bool)
signal open_changed(open: bool)

const AiCreationService = preload("res://src/ai/ai_creation_service.gd")
const AiPanel = preload("res://src/app/workspace/ai_tool_panel.gd")

var _workspace: Control
var _bottom_dock: Control
var _panel
var _service
var _bound := false

func _ready() -> void:
    name = "AiWorkspaceLayer"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _panel = AiPanel.new(); add_child(_panel); _wire_panel(); set_process_unhandled_input(true)

func bind_workspace(workspace: Control) -> Dictionary:
    _workspace = workspace
    _bottom_dock = workspace.get_node_or_null("BottomDockLayer/BottomToolDock")
    if _bottom_dock == null: return _failure("AI workspace could not resolve the bottom tool dock.")
    if not _bottom_dock.tool_selected.is_connected(_on_tool_selected): _bottom_dock.tool_selected.connect(_on_tool_selected)
    return {"ok": true, "errors": []}

func bind_project(project, project_directory: String, editor_session, dirty_callback: Callable, asset_library, terrain_controller = null, gameplay_service = null, visual_service = null, procedural_service = null, procedural_runtime = null, environment_service = null) -> Dictionary:
    if _workspace == null: return _failure("AI workspace must bind its workspace before a project.")
    if _service != null and is_instance_valid(_service): _service.queue_free()
    _service = AiCreationService.new()
    add_child(_service)
    var result: Dictionary = _service.bind(project, project_directory, editor_session, dirty_callback, asset_library, terrain_controller, gameplay_service, visual_service, procedural_service, procedural_runtime, environment_service, Callable(_workspace, "get_mode"))
    if not result.get("ok", false): return result
    _service.status_changed.connect(_on_service_status)
    _service.result_ready.connect(_on_result_ready)
    _service.busy_changed.connect(func(value: bool) -> void: _panel.set_busy(value))
    _service.get_provider_registry().settings_changed.connect(func(settings: Dictionary) -> void: _panel.set_provider_settings(settings))
    _panel.set_provider_settings(_service.get_provider_registry().get_settings())
    _panel.set_preview_ready(false)
    _bound = true; close_tool()
    return {"ok": true, "errors": [], "provider_count": _service.get_provider_registry().get_providers().size(), "history_count": _service.get_execution_history().size()}

func toggle_tool() -> void:
    if not _bound: return
    if is_open(): close_tool()
    else: open_tool()
func open_tool() -> void:
    if not _bound: return
    if _workspace.has_method("close_asset_drawer"): _workspace.close_asset_drawer()
    if _workspace.has_method("clear_selection"): _workspace.clear_selection()
    _panel.set_provider_settings(_service.get_provider_registry().get_settings())
    _panel.open_panel(); open_changed.emit(true)
func close_tool() -> void:
    if _panel != null: _panel.close_panel()
    open_changed.emit(false)
func is_open() -> bool: return _panel != null and _panel.is_open()
func get_service(): return _service
func get_panel(): return _panel

func handle_cancel() -> bool:
    if not is_open(): return false
    if _service != null and _service.is_busy(): _service.cancel(); return true
    close_tool(); return true

func _unhandled_input(event: InputEvent) -> void:
    if is_open() and _panel.handle_shortcut(event): get_viewport().set_input_as_handled()

func _wire_panel() -> void:
    _panel.provider_saved.connect(_on_provider_saved)
    _panel.provider_selected.connect(func(provider_id: String) -> void: _report(_service.get_provider_registry().set_active_provider(provider_id), "Active AI provider changed"))
    _panel.privacy_changed.connect(func(patch: Dictionary) -> void: _report(_service.get_provider_registry().set_privacy_policy(patch), "AI privacy settings changed"))
    _panel.suggest_requested.connect(func(prompt: String) -> void: _request("suggest", prompt))
    _panel.preview_requested.connect(func(prompt: String) -> void: _request("preview", prompt))
    _panel.execute_requested.connect(_execute_preview)
    _panel.cancel_requested.connect(func() -> void: _report(_service.cancel(), "AI request cancelled"))
    _panel.close_requested.connect(close_tool)

func _on_provider_saved(descriptor: Dictionary) -> void:
    var result: Dictionary = _service.get_provider_registry().upsert_provider(descriptor)
    if result.get("ok", false): _service.get_provider_registry().set_active_provider(str(descriptor.get("provider_id", "")))
    _report(result, "AI provider saved")

func _request(mode: String, prompt: String) -> void:
    var result: Dictionary = _service.request(mode, prompt)
    if not result.get("ok", false): _report(result, "")
    else: status_changed.emit("AI %s started" % mode.capitalize(), false)

func _execute_preview() -> void:
    var result: Dictionary = _service.execute_last_preview()
    if not result.get("ok", false): _report(result, "")

func _on_result_ready(result: Dictionary) -> void:
    _panel.show_result(result)
    if result.get("ok", false): status_changed.emit("AI %s ready" % str(result.get("mode", "result")).capitalize(), false)
    else: status_changed.emit(str(result.get("errors", ["AI request failed."])[0]), true)

func _on_service_status(message: String, is_error: bool) -> void:
    _panel.set_status(message, is_error); status_changed.emit(message, is_error)

func _on_tool_selected(tool: StringName) -> void:
    if tool == &"ai": toggle_tool()
    elif is_open(): close_tool()

func _report(result: Dictionary, success: String) -> void:
    if result.get("ok", false):
        _panel.set_provider_settings(_service.get_provider_registry().get_settings())
        if not success.is_empty(): status_changed.emit(success, false)
    else:
        var message: String = str(result.get("errors", ["AI action failed."])[0]); _panel.set_status(message, true); status_changed.emit(message, true)

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
