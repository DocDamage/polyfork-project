extends Control

signal route_requested(route: StringName)
signal new_world_requested(configuration: Dictionary)

const ThemeFactory = preload("res://src/app/theme/theme_factory.gd")

@onready var home_screen: Control = $HomeScreen
@onready var new_world_screen: Control = $NewWorldScreen


func _ready() -> void:
    theme = ThemeFactory.create_theme()
    home_screen.route_requested.connect(_on_home_route_requested)
    new_world_screen.back_requested.connect(_show_home)
    new_world_screen.create_requested.connect(_on_new_world_create_requested)
    _show_home()
    print("PlayWorld Studio application shell loaded.")


func _on_home_route_requested(route: StringName) -> void:
    if route == &"new_world":
        _show_new_world()
        return

    route_requested.emit(route)
    print("PlayWorld route requested: %s" % route)


func _show_home() -> void:
    new_world_screen.hide()
    home_screen.show()


func _show_new_world() -> void:
    home_screen.hide()
    new_world_screen.show()
    if new_world_screen.has_method("focus_primary"):
        new_world_screen.call_deferred("focus_primary")


func _on_new_world_create_requested(configuration: Dictionary) -> void:
    new_world_requested.emit(configuration)
    print("New world configuration requested: %s" % configuration)
