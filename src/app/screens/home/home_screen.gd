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
    create_button.grab_focus()


func _request_route(route: StringName) -> void:
    route_requested.emit(route)
