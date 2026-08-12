class_name PlayWorldVisualScriptingWorkspaceLayer
extends Control

signal status_changed(message: String, is_error: bool)
signal open_changed(open: bool)

const VisualGraphService = preload("res://src/visual_scripting/visual_graph_service.gd")
const VisualGraphPanel = preload("res://src/app/workspace/visual_graph_tool_panel.gd")

var _workspace: Control
var _bottom_dock: Control
var _panel
var _service
var _bound := false


func _ready() -> void:
    name = "VisualScriptingWorkspaceLayer"; mouse_filter = Control.MOUSE_FILTER_IGNORE; set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _panel = VisualGraphPanel.new(); add_child(_panel); _panel.close_requested.connect(close_tool); _panel.status_changed.connect(func(message: String, is_error: bool): status_changed.emit(message, is_error)); set_process_unhandled_input(true)


func bind_workspace(workspace: Control) -> Dictionary:
    _workspace = workspace; _bottom_dock = workspace.get_node_or_null("BottomDockLayer/BottomToolDock")
    if _bottom_dock == null: return _failure("Visual Scripting workspace could not resolve the bottom tool dock.")
    if not _bottom_dock.tool_selected.is_connected(_on_tool_selected): _bottom_dock.tool_selected.connect(_on_tool_selected)
    return {"ok":true,"errors":[]}


func bind_project(project, project_directory: String, editor_session, dirty_callback: Callable) -> Dictionary:
    if _workspace == null: return _failure("Visual Scripting workspace must bind its workspace first.")
    _service = VisualGraphService.new(); var result: Dictionary = _service.bind_project(project, project_directory, editor_session, dirty_callback)
    if not result.get("ok", false): return result
    _panel.bind_service(_service); _bound = true; close_tool()
    return {"ok":true,"errors":[],"graph_count":_service.get_graphs().size()}


func toggle_tool() -> void:
    if not _bound: return
    if is_open(): close_tool()
    else: open_tool()

func open_tool() -> void:
    if not _bound: return
    if _workspace.has_method("close_asset_drawer"): _workspace.close_asset_drawer()
    _panel.open_panel(); open_changed.emit(true)

func close_tool() -> void:
    if _panel != null: _panel.close_panel()
    open_changed.emit(false)

func is_open() -> bool: return _panel != null and _panel.is_open()
func get_service(): return _service
func get_panel(): return _panel
func handle_cancel() -> bool:
    if not is_open(): return false
    close_tool(); return true

func _unhandled_input(event: InputEvent) -> void:
    if is_open() and _panel.handle_shortcut(event): get_viewport().set_input_as_handled()

func _on_tool_selected(tool: StringName) -> void:
    if tool == &"more": toggle_tool()
    elif is_open(): close_tool()

static func _failure(message: String) -> Dictionary: return {"ok":false,"errors":[message]}
