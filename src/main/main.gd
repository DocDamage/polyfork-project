extends Control

signal route_requested(route: StringName)

const ThemeFactory = preload("res://src/app/theme/theme_factory.gd")

@onready var home_screen: Control = $HomeScreen


func _ready() -> void:
    theme = ThemeFactory.create_theme()
    home_screen.route_requested.connect(_on_home_route_requested)
    print("PlayWorld Studio application shell loaded.")


func _on_home_route_requested(route: StringName) -> void:
    route_requested.emit(route)
    print("PlayWorld route requested: %s" % route)
