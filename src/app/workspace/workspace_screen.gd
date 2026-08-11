class_name PlayWorldWorkspaceScreen
extends Control

signal home_requested
signal mode_changed(mode: StringName)
signal tool_selected(tool: StringName)

const RuntimeEntityBridge = preload("res://src/editor/runtime_entity_bridge.gd")
const SingleSelection = preload("res://src/editor/single_selection.gd")

@onready var home_button: Button = %HomeButton
@onready var world_title: Label = %WorldTitle
@onready var world_context: Label = %WorldContext
@onready var mode_switch: Control = $TopBar/TopMargin/TopRow/ModeSlot/ModeSwitch
@onready var mode_badge: Label = %ModeBadge
@onready var inspector_panel: Control = $InspectorLayer/InspectorPanel
@onready var bottom_dock: Control = $BottomDockLayer/BottomToolDock
@onready var transform_toolbar: Control = $TransformToolbar
@onready var status_mode: Label = %StatusMode
@onready var status_state: Label = $StatusBar/StatusMargin/StatusRow/StatusState

var _configuration: Dictionary = {}
var _mode: StringName = &"build"
var _runtime_bridge
var _selection


func _ready() -> void:
    _runtime_bridge = RuntimeEntityBridge.new()
    _runtime_bridge.name = "RuntimeEntityBridge"
    add_child(_runtime_bridge)

    _selection = SingleSelection.new()
    _selection.bind_bridge(_runtime_bridge)
    _selection.selection_changed.connect(_on_selection_changed)

    home_button.pressed.connect(_request_home)
    mode_switch.mode_changed.connect(_on_mode_changed)
    bottom_dock.tool_selected.connect(_on_tool_selected)
    transform_toolbar.tool_selected.connect(_on_tool_selected)
    inspector_panel.closed.connect(_on_inspector_closed)
    _configure_focus_navigation()
    _apply_mode_label()


func set_configuration(configuration: Dictionary) -> Dictionary:
    if _selection != null:
        _selection.clear()

    _configuration = configuration.duplicate(true)
    world_title.text = str(_configuration.get("title", "Untitled World"))
    var profile := str(_configuration.get("world_profile", "medium")).capitalize()
    var template := str(_configuration.get("template_id", "blank_sandbox")).replace("_", " ").capitalize()
    world_context.text = "%s world  •  %s" % [profile, template]

    var bridge_result: Dictionary = _runtime_bridge.rebuild(_configuration.get("entities", []))
    if not bridge_result.get("ok", false):
        status_state.text = "Entity load failed"
        return bridge_result

    var project_id := str(_configuration.get("project_id", ""))
    if project_id.length() >= 8:
        status_state.text = "Saved project • %s" % project_id.substr(0, 8)
    else:
        status_state.text = "Session only • persistence not attached"
    return {"ok": true, "errors": [], "entity_count": _runtime_bridge.entity_count()}


func get_configuration() -> Dictionary:
    return _configuration.duplicate(true)


func get_mode() -> StringName:
    return _mode


func show_inspector(context: Dictionary) -> void:
    inspector_panel.show_context(context)


func hide_inspector() -> void:
    if _selection != null and _selection.has_selection():
        _selection.clear()
        return
    inspector_panel.clear_context()


func is_inspector_open() -> bool:
    return inspector_panel.is_open()


func is_asset_drawer_open() -> bool:
    return bottom_dock.is_asset_drawer_open()


func close_asset_drawer() -> void:
    bottom_dock.close_asset_drawer()


func select_entity(entity_id: String) -> Dictionary:
    return _selection.select_entity(entity_id)


func select_runtime_node(node: Node) -> Dictionary:
    return _selection.select_node(node)


func clear_selection() -> Dictionary:
    return _selection.clear()


func get_selected_entity_id() -> String:
    return _selection.get_selected_entity_id()


func get_selected_runtime_node():
    return _selection.get_selected_node()


func get_runtime_entity_node(entity_id: String):
    return _runtime_bridge.get_entity_node(entity_id)


func get_runtime_entity_count() -> int:
    return _runtime_bridge.entity_count()


func get_runtime_entity_ids() -> Array[String]:
    return _runtime_bridge.entity_ids()


func handle_cancel() -> bool:
    if is_asset_drawer_open():
        close_asset_drawer()
        call_deferred("focus_bottom_dock")
        return true
    if is_inspector_open():
        hide_inspector()
        call_deferred("focus_primary")
        return true
    return false


func focus_primary() -> void:
    mode_switch.focus_primary()


func focus_bottom_dock() -> void:
    bottom_dock.focus_primary()


func _configure_focus_navigation() -> void:
    var build_button := find_child("BuildButton", true, false) as Button
    var play_button := find_child("PlayButton", true, false) as Button
    var assets_button := find_child("AssetsButton", true, false) as Button
    if build_button == null or play_button == null or assets_button == null:
        return

    home_button.focus_neighbor_right = home_button.get_path_to(build_button)
    home_button.focus_neighbor_bottom = home_button.get_path_to(assets_button)
    build_button.focus_neighbor_left = build_button.get_path_to(home_button)
    build_button.focus_neighbor_bottom = build_button.get_path_to(assets_button)
    play_button.focus_neighbor_bottom = play_button.get_path_to(assets_button)
    assets_button.focus_neighbor_top = assets_button.get_path_to(build_button)

    for node_name in ["TerrainButton", "AssetsButton", "FoliageButton", "RoadsButton", "WaterButton", "GameplayButton", "AIButton", "MoreButton"]:
        var tool_button := find_child(node_name, true, false) as Button
        if tool_button != null:
            tool_button.focus_neighbor_top = tool_button.get_path_to(build_button)


func _on_selection_changed(entity_id: String, runtime_node: Node3D) -> void:
    if entity_id.is_empty() or runtime_node == null:
        var existing_context: Dictionary = inspector_panel.get_context()
        if existing_context.get("source") == "entity_selection":
            inspector_panel.clear_context()
        return

    var record: Dictionary = _runtime_bridge.get_entity_record(entity_id)
    if record.is_empty():
        inspector_panel.clear_context()
        return
    inspector_panel.show_context(_entity_inspector_context(record))


func _on_inspector_closed() -> void:
    if _selection != null and _selection.has_selection():
        _selection.clear()


func _entity_inspector_context(record: Dictionary) -> Dictionary:
    var entity_id := str(record.get("entity_id", ""))
    var cell_id := str(record.get("cell_id", ""))
    var parent_id := _optional_id(record.get("parent_entity_id"))
    var transform_data: Dictionary = record.get("transform", {})
    var parent_summary := "None" if parent_id.is_empty() else parent_id
    return {
        "source": "entity_selection",
        "title": str(record.get("display_name", "Entity")),
        "type": "World entity",
        "summary": "Stable entity • %s" % entity_id.substr(0, 8),
        "position": _format_vector(transform_data.get("position", [])),
        "rotation": _format_vector(transform_data.get("rotation_degrees", [])),
        "scale": _format_vector(transform_data.get("scale", [])),
        "advanced_summary": "Entity ID: %s\nCell ID: %s\nParent: %s" % [entity_id, cell_id, parent_summary]
    }


func _format_vector(value: Variant) -> String:
    if not value is Array or value.size() != 3:
        return "—"
    return "%.2f, %.2f, %.2f" % [float(value[0]), float(value[1]), float(value[2])]


func _optional_id(value: Variant) -> String:
    return "" if value == null else str(value)


func _on_mode_changed(mode: StringName) -> void:
    _mode = mode
    _apply_mode_label()
    mode_changed.emit(_mode)


func _on_tool_selected(tool: StringName) -> void:
    tool_selected.emit(tool)


func _apply_mode_label() -> void:
    mode_badge.text = "%s MODE" % str(_mode).to_upper()
    status_mode.text = str(_mode).capitalize()


func _request_home() -> void:
    home_requested.emit()
