extends Control

signal route_requested(route: StringName)
signal new_world_requested(configuration: Dictionary)

const ThemeFactory = preload("res://src/app/theme/theme_factory.gd")
const ProjectRepository = preload("res://src/world/project_repository.gd")

@onready var home_screen: Control = $HomeScreen
@onready var new_world_screen: Control = $NewWorldScreen
@onready var workspace_screen: Control = $WorkspaceScreen

var _project_repository


func _ready() -> void:
    theme = ThemeFactory.create_theme()
    var storage_root := str(ProjectSettings.get_setting(
        "playworld/storage/projects_root",
        "user://projects"
    ))
    _project_repository = ProjectRepository.new(storage_root)

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
    if route == &"continue":
        _open_recent_project()
        return

    route_requested.emit(route)
    print("PlayWorld route requested: %s" % route)


func _show_home() -> void:
    new_world_screen.hide()
    workspace_screen.hide()
    home_screen.show()
    _refresh_recent_project()
    if home_screen.has_method("focus_primary"):
        home_screen.call_deferred("focus_primary")


func _show_new_world() -> void:
    home_screen.hide()
    workspace_screen.hide()
    new_world_screen.clear_error_message()
    new_world_screen.show()
    if new_world_screen.has_method("focus_primary"):
        new_world_screen.call_deferred("focus_primary")


func _show_workspace(project_data: Dictionary) -> void:
    home_screen.hide()
    new_world_screen.hide()
    workspace_screen.show()
    workspace_screen.set_configuration(project_data)
    if workspace_screen.has_method("focus_primary"):
        workspace_screen.call_deferred("focus_primary")


func _on_new_world_create_requested(configuration: Dictionary) -> void:
    var create_result: Dictionary = _project_repository.create_project(
        str(configuration.get("title", "")),
        StringName(str(configuration.get("world_profile", ""))),
        str(configuration.get("template_id", ""))
    )
    if not create_result.get("ok", false):
        new_world_screen.set_error_message(
            "Could not create the project: " + str(create_result.get("errors", []))
        )
        return

    var project = create_result["project"]
    var project_data: Dictionary = project.to_dictionary()
    new_world_requested.emit(project_data)
    _show_workspace(project_data)
    print("Persisted world project opened in workspace: %s" % project.project_id)


func _open_recent_project() -> void:
    var recent: Dictionary = _project_repository.get_recent_project()
    var project = recent.get("project")
    if not recent.get("ok", false) or project == null:
        _refresh_recent_project()
        return
    _show_workspace(project.to_dictionary())


func _refresh_recent_project() -> void:
    var recent: Dictionary = _project_repository.get_recent_project()
    var project = recent.get("project")
    if recent.get("ok", false) and project != null:
        home_screen.set_recent_project(project.title, true)
    else:
        home_screen.set_recent_project("", false)
