extends Control

signal route_requested(route: StringName)
signal new_world_requested(configuration: Dictionary)

const ThemeFactory = preload("res://src/app/theme/theme_factory.gd")

@onready var home_screen: Control = $HomeScreen
@onready var new_world_screen: Control = $NewWorldScreen
@onready var workspace_screen: Control = $WorkspaceScreen


func _ready() -> void:
    theme = ThemeFactory.create_theme()
    home_screen.route_requested.connect(_on_home_route_requested)
    new_world_screen.back_requested.connect(_show_home)
    new_world_screen.create_requested.connect(_on_new_world_create_requested)
    workspace_screen.home_requested.connect(_show_home)
    _show_home()
    print("PlayWorld Studio application shell loaded.")


func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed("ui_cancel"):
        return

    if workspace_screen.visible:
        if workspace_screen.handle_cancel():
            get_viewport().set_input_as_handled()
            return
        _show_home()
        get_viewport().set_input_as_handled()
        return

    if new_world_screen.visible:
        _show_home()
        get_viewport().set_input_as_handled()


func _on_home_route_requested(route: StringName) -> void:
    if route == &"new_world":
        _show_new_world()
        return

    route_requested.emit(route)
    print("PlayWorld route requested: %s" % route)


func _show_home() -> void:
    new_world_screen.hide()
    workspace_screen.hide()
    home_screen.show()
    if home_screen.has_method("focus_primary"):
        home_screen.call_deferred("focus_primary")


func _show_new_world() -> void:
    home_screen.hide()
    workspace_screen.hide()
    new_world_screen.show()
    if new_world_screen.has_method("focus_primary"):
        new_world_screen.call_deferred("focus_primary")


func _show_workspace(configuration: Dictionary) -> void:
    home_screen.hide()
    new_world_screen.hide()
    workspace_screen.show()
    workspace_screen.set_configuration(configuration)
    if workspace_screen.has_method("focus_primary"):
        workspace_screen.call_deferred("focus_primary")


func _on_new_world_create_requested(configuration: Dictionary) -> void:
    new_world_requested.emit(configuration)
    _show_workspace(configuration)
    print("New world configuration routed to workspace: %s" % configuration)
