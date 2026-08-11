class_name PlayWorldHomeScreen
extends Control

signal route_requested(route: StringName)

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


func _ready() -> void:
    create_button.pressed.connect(_request_route.bind(ROUTE_NEW_WORLD))
    continue_button.pressed.connect(_request_route.bind(ROUTE_CONTINUE))
    worlds_button.pressed.connect(_request_route.bind(ROUTE_MY_WORLDS))
    templates_button.pressed.connect(_request_route.bind(ROUTE_TEMPLATES))
    asset_library_button.pressed.connect(_request_route.bind(ROUTE_ASSET_LIBRARY))
    _configure_focus_navigation()
    focus_primary()


func focus_primary() -> void:
    create_button.grab_focus()


func _configure_focus_navigation() -> void:
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

    _set_tab_order([
        create_button,
        continue_button,
        worlds_button,
        templates_button,
        asset_library_button
    ])


func _set_tab_order(controls: Array) -> void:
    for index in range(controls.size() - 1):
        var current: Control = controls[index]
        var next: Control = controls[index + 1]
        current.focus_next = current.get_path_to(next)
        next.focus_previous = next.get_path_to(current)


func _request_route(route: StringName) -> void:
    route_requested.emit(route)
