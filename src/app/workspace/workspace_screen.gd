class_name PlayWorldWorkspaceScreen
extends Control

signal home_requested
signal mode_changed(mode: StringName)
signal tool_selected(tool: StringName)

@onready var home_button: Button = %HomeButton
@onready var world_title: Label = %WorldTitle
@onready var world_context: Label = %WorldContext
@onready var mode_switch: Control = $TopBar/TopMargin/TopRow/ModeSlot/ModeSwitch
@onready var mode_badge: Label = %ModeBadge
@onready var inspector_panel: Control = $InspectorLayer/InspectorPanel
@onready var bottom_dock: Control = $BottomDockLayer/BottomToolDock
@onready var transform_toolbar: Control = $TransformToolbar
@onready var status_mode: Label = %StatusMode

var _configuration: Dictionary = {}
var _mode: StringName = &"build"


func _ready() -> void:
    home_button.pressed.connect(_request_home)
    mode_switch.mode_changed.connect(_on_mode_changed)
    bottom_dock.tool_selected.connect(_on_tool_selected)
    transform_toolbar.tool_selected.connect(_on_tool_selected)
    _configure_focus_navigation()
    _apply_mode_label()


func set_configuration(configuration: Dictionary) -> void:
    _configuration = configuration.duplicate(true)
    world_title.text = str(_configuration.get("title", "Untitled World"))
    var profile := str(_configuration.get("world_profile", "medium")).capitalize()
    var template := str(_configuration.get("template_id", "blank_sandbox")).replace("_", " ").capitalize()
    world_context.text = "%s world  •  %s" % [profile, template]


func get_configuration() -> Dictionary:
    return _configuration.duplicate(true)


func get_mode() -> StringName:
    return _mode


func show_inspector(context: Dictionary) -> void:
    inspector_panel.show_context(context)


func hide_inspector() -> void:
    inspector_panel.clear_context()


func is_inspector_open() -> bool:
    return inspector_panel.is_open()


func is_asset_drawer_open() -> bool:
    return bottom_dock.is_asset_drawer_open()


func close_asset_drawer() -> void:
    bottom_dock.close_asset_drawer()


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
