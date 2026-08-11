class_name PlayWorldWorkspaceScreen
extends Control

signal home_requested
signal mode_changed(mode: StringName)
signal tool_selected(tool: StringName)

@onready var home_button: Button = %HomeButton
@onready var world_title: Label = %WorldTitle
@onready var world_context: Label = %WorldContext
@onready var mode_switch: Control = $TopBar/TopMargin/TopRow/ModeSlot/ModeSwitch
@onready var mode_badge: Label = $ViewportFrame/ViewportBackdrop/ViewportBadge/BadgeText
@onready var inspector_panel: Control = $InspectorLayer/InspectorPanel
@onready var bottom_dock: Control = $BottomDockLayer/BottomToolDock

var _configuration: Dictionary = {}
var _mode: StringName = &"build"


func _ready() -> void:
    home_button.pressed.connect(_request_home)
    mode_switch.mode_changed.connect(_on_mode_changed)
    bottom_dock.tool_selected.connect(_on_tool_selected)
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


func focus_primary() -> void:
    mode_switch.focus_primary()


func focus_bottom_dock() -> void:
    bottom_dock.focus_primary()


func _on_mode_changed(mode: StringName) -> void:
    _mode = mode
    _apply_mode_label()
    mode_changed.emit(_mode)


func _on_tool_selected(tool: StringName) -> void:
    tool_selected.emit(tool)


func _apply_mode_label() -> void:
    mode_badge.text = "%s MODE" % str(_mode).to_upper()


func _request_home() -> void:
    home_requested.emit()
