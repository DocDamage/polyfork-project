class_name PlayWorldHomeScreen
extends Control

signal route_requested(route: StringName)

const SettingsScene = preload("res://src/app/screens/settings/SettingsScreen.tscn")
const ROUTE_NEW_WORLD: StringName = &"new_world"
const ROUTE_CONTINUE: StringName = &"continue"
const ROUTE_MY_WORLDS: StringName = &"my_worlds"
const ROUTE_TEMPLATES: StringName = &"templates"
const ROUTE_ASSET_LIBRARY: StringName = &"asset_library"

@onready var create_button: Button = %CreateButton
@onready var continue_button: Button = %ContinueButton
@onready var worlds_button: Button = %WorldsButton
@onready var templates_button: Button = %TemplatesButton
@onready var asset_library_button: Button = %AssetLibraryButton
@onready var settings_button: Button = %SettingsButton
@onready var hub: GridContainer = %Hub

var _settings_screen: Control
var _scale_service: Node

func _ready() -> void:
    create_button.pressed.connect(_request_route.bind(ROUTE_NEW_WORLD))
    continue_button.pressed.connect(_request_route.bind(ROUTE_CONTINUE))
    worlds_button.pressed.connect(_request_route.bind(ROUTE_MY_WORLDS))
    templates_button.pressed.connect(_request_route.bind(ROUTE_TEMPLATES))
    asset_library_button.pressed.connect(_request_route.bind(ROUTE_ASSET_LIBRARY))
    settings_button.pressed.connect(_open_settings)
    _settings_screen = SettingsScene.instantiate()
    add_child(_settings_screen)
    _settings_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _settings_screen.hide()
    _settings_screen.back_requested.connect(_close_settings)
    _scale_service = get_node_or_null("/root/ScalePolish")
    if _scale_service != null:
        var layout_callback: Callable = Callable(self, "_apply_layout")
        if _scale_service.has_signal("layout_mode_changed") and not _scale_service.is_connected("layout_mode_changed", layout_callback):
            _scale_service.connect("layout_mode_changed", layout_callback)
    _configure_focus_navigation()
    _apply_layout(_current_compact_layout())
    set_recent_project("", false)
    focus_primary()

func set_recent_project(project_title: String, available: bool) -> void:
    continue_button.disabled = not available
    continue_button.text = "Continue\n%s" % project_title if available else "Continue\nNo recent world yet"

func focus_primary() -> void:
    if _settings_screen != null and _settings_screen.visible: _settings_screen.focus_primary()
    else: create_button.grab_focus()

func _configure_focus_navigation() -> void:
    settings_button.focus_neighbor_bottom = settings_button.get_path_to(create_button)
    create_button.focus_neighbor_top = create_button.get_path_to(settings_button)
    create_button.focus_neighbor_right = create_button.get_path_to(continue_button)
    create_button.focus_neighbor_bottom = create_button.get_path_to(worlds_button)
    continue_button.focus_neighbor_left = continue_button.get_path_to(create_button)
    continue_button.focus_neighbor_bottom = continue_button.get_path_to(templates_button)
    worlds_button.focus_neighbor_top = worlds_button.get_path_to(create_button)
    worlds_button.focus_neighbor_right = worlds_button.get_path_to(templates_button)
    worlds_button.focus_neighbor_bottom = worlds_button.get_path_to(asset_library_button)
    templates_button.focus_neighbor_top = templates_button.get_path_to(continue_button)
    templates_button.focus_neighbor_left = templates_button.get_path_to(worlds_button)
    templates_button.focus_neighbor_bottom = templates_button.get_path_to(asset_library_button)
    asset_library_button.focus_neighbor_top = asset_library_button.get_path_to(worlds_button)
    _set_tab_order([settings_button, create_button, continue_button, worlds_button, templates_button, asset_library_button])

func _set_tab_order(controls: Array) -> void:
    for index in range(controls.size() - 1):
        var current: Control = controls[index]
        var next: Control = controls[index + 1]
        current.focus_next = current.get_path_to(next)
        next.focus_previous = next.get_path_to(current)

func _current_compact_layout() -> bool:
    if _scale_service != null and _scale_service.has_method("is_compact_layout"):
        return bool(_scale_service.call("is_compact_layout"))
    return size.x < 1120.0 or size.y < 700.0

func _apply_layout(compact: bool) -> void:
    hub.columns = 1 if compact else 2
    create_button.custom_minimum_size.x = 0.0 if compact else 420.0

func _open_settings() -> void:
    _settings_screen.show()
    _settings_screen.focus_primary()

func _close_settings() -> void:
    _settings_screen.hide()
    settings_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
    if visible and _settings_screen != null and _settings_screen.visible and event.is_action_pressed("ui_cancel"):
        _close_settings()
        get_viewport().set_input_as_handled()

func _request_route(route: StringName) -> void: route_requested.emit(route)
