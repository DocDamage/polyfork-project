class_name PlayWorldExportWorkspaceLayer
extends Node

const WorldProject = preload("res://src/world/world_project.gd")
const ExportPipeline = preload("res://src/export/export_pipeline.gd")

var _workspace
var _export_button: Button
var _panel: PanelContainer
var _output_path: LineEdit
var _export_now: Button
var _status: Label
var _busy := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind_current_workspace")

func _process(_delta: float) -> void:
    if _workspace != null and is_instance_valid(_workspace): refresh_state()

func _unhandled_input(event: InputEvent) -> void:
    if _panel != null and _panel.visible and event.is_action_pressed("ui_cancel"):
        close_panel(); get_viewport().set_input_as_handled()

func bind_workspace(workspace) -> Dictionary:
    if workspace == null: return _failure("Export workspace requires the canonical workspace screen.")
    var top_row = workspace.get_node_or_null("TopBar/TopMargin/TopRow")
    if top_row == null: return _failure("Export workspace could not find the canonical top bar.")
    _workspace = workspace
    if _export_button == null:
        _export_button = Button.new(); _export_button.name = "ExportButton"; _export_button.text = "Export"; _export_button.custom_minimum_size = Vector2(84, 44); _export_button.focus_mode = Control.FOCUS_ALL; _export_button.tooltip_text = "Build a standalone Windows game"
        top_row.add_child(_export_button); _export_button.pressed.connect(_toggle_panel)
    if _panel == null: _create_panel()
    refresh_state()
    return {"ok": true, "errors": []}

func refresh_state() -> void:
    if _export_button == null or _workspace == null: return
    var configuration: Dictionary = _workspace.get_configuration() if _workspace.has_method("get_configuration") else {}
    var build_mode: bool = not _workspace.has_method("get_mode") or _workspace.get_mode() == &"build"
    var transient: bool = _workspace.has_method("is_placement_active") and _workspace.is_placement_active()
    var ready := not configuration.is_empty() and not str(configuration.get("project_id", "")).is_empty() and build_mode and not transient and not _busy
    _export_button.disabled = not ready
    if _export_now != null: _export_now.disabled = not ready
    if _panel != null and _panel.visible and not build_mode: close_panel()

func open_panel() -> void:
    if _panel == null or _export_button == null or _export_button.disabled: return
    _panel.show(); refresh_state(); _export_now.call_deferred("grab_focus")
func close_panel() -> void:
    if _panel != null: _panel.hide()
    if _export_button != null and not _export_button.disabled: _export_button.call_deferred("grab_focus")
func is_panel_open() -> bool: return _panel != null and _panel.visible
func get_export_button() -> Button: return _export_button
func get_export_now_button() -> Button: return _export_now
func get_output_path() -> LineEdit: return _output_path

func _bind_current_workspace() -> void:
    var current := get_tree().current_scene
    if current == null: return
    var workspace = current.get_node_or_null("WorkspaceScreen")
    if workspace == null: workspace = current.find_child("WorkspaceScreen", true, false)
    if workspace == null: return
    var result: Dictionary = bind_workspace(workspace)
    if not result.get("ok", false): push_warning("Unable to attach Export workspace: %s" % str(result.get("errors", [])))

func _toggle_panel() -> void:
    if is_panel_open(): close_panel()
    else: open_panel()

func _create_panel() -> void:
    _panel = PanelContainer.new(); _panel.name = "ExportPanel"; _panel.set_anchors_preset(Control.PRESET_TOP_RIGHT); _panel.position = Vector2(-390, 76); _panel.size = Vector2(370, 214); _panel.z_index = 40; _panel.hide(); _workspace.add_child(_panel)
    var margin := MarginContainer.new(); margin.add_theme_constant_override("margin_left", 16); margin.add_theme_constant_override("margin_top", 14); margin.add_theme_constant_override("margin_right", 16); margin.add_theme_constant_override("margin_bottom", 14); _panel.add_child(margin)
    var stack := VBoxContainer.new(); stack.add_theme_constant_override("separation", 8); margin.add_child(stack)
    var title := Label.new(); title.text = "Export Game"; title.theme_type_variation = &"HeadingLabel"; stack.add_child(title)
    var target := Label.new(); target.text = "Windows Desktop  •  x86_64"; target.theme_type_variation = &"SecondaryLabel"; stack.add_child(target)
    _output_path = LineEdit.new(); _output_path.name = "ExportOutputPath"; _output_path.text = "user://exports"; _output_path.placeholder_text = "Export folder"; _output_path.focus_mode = Control.FOCUS_ALL; stack.add_child(_output_path)
    var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 8); stack.add_child(row)
    _export_now = Button.new(); _export_now.name = "ExportNowButton"; _export_now.text = "Build Export"; _export_now.focus_mode = Control.FOCUS_ALL; _export_now.pressed.connect(_run_export); row.add_child(_export_now)
    var close := Button.new(); close.name = "ExportCloseButton"; close.text = "Close"; close.focus_mode = Control.FOCUS_ALL; close.pressed.connect(close_panel); row.add_child(close)
    _status = Label.new(); _status.name = "ExportStatus"; _status.text = "Ready to build a standalone package."; _status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; stack.add_child(_status)
    _output_path.focus_neighbor_bottom = _output_path.get_path_to(_export_now); _export_now.focus_neighbor_top = _export_now.get_path_to(_output_path); _export_now.focus_neighbor_right = _export_now.get_path_to(close); close.focus_neighbor_left = close.get_path_to(_export_now)

func _run_export() -> void:
    if _busy or _workspace == null: return
    var configuration: Dictionary = _workspace.get_configuration()
    var project = WorldProject.new(); var load_errors: Array[String] = project.load_dictionary(configuration)
    if not load_errors.is_empty(): _set_status("Export blocked: %s" % load_errors[0], true); return
    var storage_root := str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects")); var project_directory := storage_root.trim_suffix("/").path_join(project.project_id)
    var library = _workspace.get_asset_library() if _workspace.has_method("get_asset_library") else null
    _busy = true; refresh_state(); _set_status("Building Windows export…", false)
    var result: Dictionary = ExportPipeline.new().export_windows(project, project_directory, library, _output_path.text.strip_edges(), project.title)
    _busy = false; refresh_state()
    if result.get("ok", false):
        _set_status("Export complete • %s" % str(result.get("output_root", "")), false)
    else: _set_status("Export failed • %s" % str(result.get("errors", ["Unknown export error"])[0]), true)

func _set_status(message: String, is_error: bool) -> void:
    if _status != null: _status.text = message
    var global_status = _workspace.get_node_or_null("StatusBar/StatusMargin/StatusRow/StatusState") if _workspace != null else null
    if global_status is Label: global_status.text = message
    if is_error: push_warning(message)

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
