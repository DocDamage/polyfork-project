class_name PlayWorldBottomToolDock
extends Control

signal tool_selected(tool: StringName)
signal asset_drawer_toggled(open: bool)
signal density_changed(mode: StringName)

const Tokens = preload("res://src/app/theme/ui_tokens.gd")

const TOOL_COLORS := {
    &"terrain": Tokens.TERRAIN,
    &"assets": Tokens.ASSETS,
    &"foliage": Tokens.FOLIAGE,
    &"roads": Tokens.ROADS,
    &"water": Tokens.WATER,
    &"gameplay": Tokens.GAMEPLAY,
    &"ai": Tokens.AI,
    &"more": Tokens.TEXT_SECONDARY
}

@onready var asset_drawer: Control = %AssetDrawer
@onready var density_button: Button = %DensityButton
@onready var search_edit: LineEdit = %AssetSearch
@onready var buttons := {
    &"terrain": %TerrainButton,
    &"assets": %AssetsButton,
    &"foliage": %FoliageButton,
    &"roads": %RoadsButton,
    &"water": %WaterButton,
    &"gameplay": %GameplayButton,
    &"ai": %AIButton,
    &"more": %MoreButton
}

var _density_mode: StringName = &"large"


func _ready() -> void:
    for tool in buttons:
        var button: Button = buttons[tool]
        button.pressed.connect(_select_tool.bind(tool))
        _apply_tool_color(button, TOOL_COLORS[tool])

    density_button.pressed.connect(_toggle_density)
    asset_drawer.hide()
    _apply_density_label()


func is_asset_drawer_open() -> bool:
    return asset_drawer.visible


func open_asset_drawer() -> void:
    asset_drawer.show()
    asset_drawer_toggled.emit(true)
    search_edit.grab_focus()


func close_asset_drawer() -> void:
    asset_drawer.hide()
    asset_drawer_toggled.emit(false)


func toggle_asset_drawer() -> void:
    if asset_drawer.visible:
        close_asset_drawer()
    else:
        open_asset_drawer()


func focus_primary() -> void:
    var button: Button = buttons[&"assets"]
    button.grab_focus()


func _select_tool(tool: StringName) -> void:
    tool_selected.emit(tool)
    if tool == &"assets":
        toggle_asset_drawer()


func _toggle_density() -> void:
    _density_mode = &"compact" if _density_mode == &"large" else &"large"
    _apply_density_label()
    density_changed.emit(_density_mode)


func _apply_density_label() -> void:
    density_button.text = "Large Cards" if _density_mode == &"large" else "Compact"


func _apply_tool_color(button: Button, color: Color) -> void:
    button.add_theme_color_override("font_color", color)
    button.add_theme_color_override("font_hover_color", color.lightened(0.12))
    button.add_theme_color_override("font_pressed_color", color.lightened(0.18))
    button.add_theme_color_override("font_focus_color", color.lightened(0.18))
