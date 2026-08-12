class_name PlayWorldBottomToolDock
extends Control

signal tool_selected(tool: StringName)
signal asset_drawer_toggled(open: bool)
signal density_changed(mode: StringName)
signal asset_placement_requested(asset_record: Dictionary)
signal asset_library_status(message: String, is_error: bool)

const Tokens = preload("res://src/app/theme/ui_tokens.gd")
const AssetBrowser = preload("res://src/app/workspace/asset_browser.gd")

const TOOL_COLORS := {&"terrain":Tokens.TERRAIN,&"assets":Tokens.ASSETS,&"foliage":Tokens.FOLIAGE,&"roads":Tokens.ROADS,&"water":Tokens.WATER,&"gameplay":Tokens.GAMEPLAY,&"ai":Tokens.AI,&"more":Tokens.CREATE_PURPLE_HOVER}

@onready var asset_drawer: Control = %AssetDrawer
@onready var density_button: Button = %DensityButton
@onready var search_edit: LineEdit = %AssetSearch
@onready var buttons := {&"terrain":%TerrainButton,&"assets":%AssetsButton,&"foliage":%FoliageButton,&"roads":%RoadsButton,&"water":%WaterButton,&"gameplay":%GameplayButton,&"ai":%AIButton,&"more":%MoreButton}
var _density_mode: StringName = &"large"
var _asset_browser

func _ready() -> void:
    for tool in buttons:
        var button: Button = buttons[tool]; button.pressed.connect(_select_tool.bind(tool)); _apply_tool_color(button, TOOL_COLORS[tool])
    _install_asset_browser(); density_button.pressed.connect(_toggle_density); search_edit.text_changed.connect(_on_search_changed); _configure_focus_navigation(); asset_drawer.hide(); _apply_density_label()

func bind_asset_library(library) -> void:
    if _asset_browser != null: _asset_browser.bind_library(library)
func refresh_asset_browser() -> void:
    if _asset_browser != null: _asset_browser.refresh()
func get_asset_browser(): return _asset_browser
func is_asset_drawer_open() -> bool: return asset_drawer.visible
func open_asset_drawer() -> void: asset_drawer.show(); asset_drawer_toggled.emit(true); search_edit.grab_focus()
func close_asset_drawer() -> void: asset_drawer.hide(); asset_drawer_toggled.emit(false)
func toggle_asset_drawer() -> void:
    if asset_drawer.visible: close_asset_drawer()
    else: open_asset_drawer()
func focus_primary() -> void: (buttons[&"assets"] as Button).grab_focus()
func get_primary_button() -> Button: return buttons[&"assets"]

func _unhandled_input(event: InputEvent) -> void:
    if asset_drawer.visible and _asset_browser != null and _asset_browser.handle_shortcut(event): get_viewport().set_input_as_handled()

func _install_asset_browser() -> void:
    var body_margin := get_node_or_null("AssetDrawer/DrawerMargin/DrawerContent/DrawerBody/BodyMargin")
    if body_margin == null: return
    for child in body_margin.get_children(): child.queue_free()
    _asset_browser = AssetBrowser.new(); _asset_browser.name = "AssetBrowser"; _asset_browser.placement_requested.connect(_on_asset_placement_requested); _asset_browser.library_status.connect(_on_library_status); body_margin.add_child(_asset_browser); asset_drawer.offset_top = -530.0

func _configure_focus_navigation() -> void:
    var ordered_tools := [buttons[&"terrain"],buttons[&"assets"],buttons[&"foliage"],buttons[&"roads"],buttons[&"water"],buttons[&"gameplay"],buttons[&"ai"],buttons[&"more"]]
    for index in range(ordered_tools.size()):
        var current: Control = ordered_tools[index]; var left: Control = ordered_tools[(index - 1 + ordered_tools.size()) % ordered_tools.size()]; var right: Control = ordered_tools[(index + 1) % ordered_tools.size()]; current.focus_neighbor_left = current.get_path_to(left); current.focus_neighbor_right = current.get_path_to(right)
    for index in range(ordered_tools.size() - 1):
        var current: Control = ordered_tools[index]; var next: Control = ordered_tools[index + 1]; current.focus_next = current.get_path_to(next); next.focus_previous = next.get_path_to(current)
    search_edit.focus_neighbor_right = search_edit.get_path_to(density_button); density_button.focus_neighbor_left = density_button.get_path_to(search_edit)

func _select_tool(tool: StringName) -> void: tool_selected.emit(tool); if tool == &"assets": toggle_asset_drawer()
func _toggle_density() -> void: _density_mode = &"compact" if _density_mode == &"large" else &"large"; _apply_density_label(); if _asset_browser != null: _asset_browser.set_density(_density_mode); density_changed.emit(_density_mode)
func _apply_density_label() -> void: density_button.text = "Large Cards" if _density_mode == &"large" else "Compact"
func _on_search_changed(value: String) -> void:
    if _asset_browser != null: _asset_browser.set_search_text(value)
func _on_asset_placement_requested(record: Dictionary) -> void: asset_placement_requested.emit(record)
func _on_library_status(message: String, is_error: bool) -> void: asset_library_status.emit(message, is_error)
func _apply_tool_color(button: Button, color: Color) -> void:
    button.add_theme_color_override("font_color", color); button.add_theme_color_override("font_hover_color", color.lightened(0.12)); button.add_theme_color_override("font_pressed_color", color.lightened(0.18)); button.add_theme_color_override("font_focus_color", color.lightened(0.18))
