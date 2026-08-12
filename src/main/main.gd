extends Control

signal route_requested(route: StringName)
signal new_world_requested(configuration: Dictionary)

const ThemeFactory = preload("res://src/app/theme/theme_factory.gd")
const ProjectRepository = preload("res://src/world/project_repository.gd")
const AutosaveService = preload("res://src/world/autosave_service.gd")
const TerrainWorkspaceLayer = preload("res://src/app/workspace/terrain_workspace_layer.gd")
const GameplayWorkspaceLayer = preload("res://src/app/workspace/gameplay_workspace_layer.gd")
const VisualScriptingWorkspaceLayer = preload("res://src/app/workspace/visual_scripting_workspace_layer.gd")
const ProceduralWorkspaceLayer = preload("res://src/app/workspace/procedural_workspace_layer.gd")
const TemplateRegistry = preload("res://src/templates/template_registry.gd")
const TemplateApplication = preload("res://src/templates/template_application_service.gd")

@onready var home_screen: Control = $HomeScreen
@onready var new_world_screen: Control = $NewWorldScreen
@onready var workspace_screen: Control = $WorkspaceScreen

var _project_repository
var _autosave_service
var _active_project
var _terrain_workspace
var _gameplay_workspace
var _visual_scripting_workspace
var _procedural_workspace


func _ready() -> void:
    theme = ThemeFactory.create_theme()
    var storage_root := str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects"))
    _project_repository = ProjectRepository.new(storage_root)
    _autosave_service = AutosaveService.new(_project_repository)
    _attach_workspace_layers()
    home_screen.route_requested.connect(_on_home_route_requested)
    new_world_screen.back_requested.connect(_show_home)
    new_world_screen.create_requested.connect(_on_new_world_create_requested)
    workspace_screen.home_requested.connect(_show_home)
    workspace_screen.mode_changed.connect(_on_workspace_mode_changed)
    _show_home()
    print("PlayWorld Studio application shell loaded.")


func _process(delta: float) -> void:
    if _autosave_service != null:
        var autosave_result: Dictionary = _autosave_service.advance(delta)
        if autosave_result.get("attempted", false) and not autosave_result.get("ok", false):
            push_warning("Autosave checkpoint failed: %s" % autosave_result.get("errors", []))
    if _terrain_workspace != null:
        var terrain_result: Dictionary = _terrain_workspace.advance(delta)
        if terrain_result.get("attempted", false) and not terrain_result.get("ok", false):
            push_warning("Terrain autosave failed: %s" % terrain_result.get("errors", []))


func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed("ui_cancel"):
        return
    if workspace_screen.visible:
        if _procedural_workspace != null and _procedural_workspace.handle_cancel():
            get_viewport().set_input_as_handled()
            return
        if _visual_scripting_workspace != null and _visual_scripting_workspace.handle_cancel():
            get_viewport().set_input_as_handled()
            return
        if _gameplay_workspace != null and _gameplay_workspace.handle_cancel():
            get_viewport().set_input_as_handled()
            return
        if _terrain_workspace != null and _terrain_workspace.handle_cancel():
            get_viewport().set_input_as_handled()
            return
        if workspace_screen.handle_cancel():
            get_viewport().set_input_as_handled()
            return
        _show_home()
        get_viewport().set_input_as_handled()
        return
    if new_world_screen.visible:
        _show_home()
        get_viewport().set_input_as_handled()


func mark_project_dirty() -> Dictionary:
    if _autosave_service == null or _active_project == null:
        return {"ok": false, "errors": ["No active project is available for autosave."]}
    return _autosave_service.mark_dirty()


func get_terrain_workspace(): return _terrain_workspace
func get_gameplay_workspace(): return _gameplay_workspace
func get_visual_scripting_workspace(): return _visual_scripting_workspace
func get_procedural_workspace(): return _procedural_workspace


func _attach_workspace_layers() -> void:
    _terrain_workspace = TerrainWorkspaceLayer.new()
    workspace_screen.add_child(_terrain_workspace)
    var terrain_result: Dictionary = _terrain_workspace.bind_workspace(workspace_screen)
    if not terrain_result.get("ok", false):
        push_warning("Unable to attach terrain workspace layer: %s" % terrain_result.get("errors", []))
    _terrain_workspace.status_changed.connect(_on_workspace_status)

    _gameplay_workspace = GameplayWorkspaceLayer.new()
    workspace_screen.add_child(_gameplay_workspace)
    var gameplay_result: Dictionary = _gameplay_workspace.bind_workspace(workspace_screen)
    if not gameplay_result.get("ok", false):
        push_warning("Unable to attach gameplay workspace layer: %s" % gameplay_result.get("errors", []))
    _gameplay_workspace.status_changed.connect(_on_workspace_status)

    _visual_scripting_workspace = VisualScriptingWorkspaceLayer.new()
    workspace_screen.add_child(_visual_scripting_workspace)
    var visual_result: Dictionary = _visual_scripting_workspace.bind_workspace(workspace_screen)
    if not visual_result.get("ok", false):
        push_warning("Unable to attach Visual Scripting workspace layer: %s" % visual_result.get("errors", []))
    _visual_scripting_workspace.status_changed.connect(_on_workspace_status)

    _procedural_workspace = ProceduralWorkspaceLayer.new()
    workspace_screen.add_child(_procedural_workspace)
    var procedural_result: Dictionary = _procedural_workspace.bind_workspace(workspace_screen)
    if not procedural_result.get("ok", false):
        push_warning("Unable to attach Procedural workspace layer: %s" % procedural_result.get("errors", []))
    _procedural_workspace.status_changed.connect(_on_workspace_status)


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
    _ensure_build_mode()
    _close_contextual_tools()
    new_world_screen.hide()
    workspace_screen.hide()
    home_screen.show()
    _refresh_recent_project()
    if home_screen.has_method("focus_primary"): home_screen.call_deferred("focus_primary")


func _show_new_world() -> void:
    _ensure_build_mode()
    _close_contextual_tools()
    home_screen.hide()
    workspace_screen.hide()
    new_world_screen.clear_error_message()
    new_world_screen.show()
    if new_world_screen.has_method("focus_primary"): new_world_screen.call_deferred("focus_primary")


func _show_workspace(project_data: Dictionary) -> void:
    home_screen.hide()
    new_world_screen.hide()
    workspace_screen.show()
    workspace_screen.set_configuration(project_data)
    if workspace_screen.has_method("focus_primary"): workspace_screen.call_deferred("focus_primary")


func _activate_project(project) -> bool:
    if project == null:
        return false
    var attach_result: Dictionary = _autosave_service.attach_project(project)
    if not attach_result.get("ok", false):
        push_warning("Unable to attach project autosave: %s" % attach_result.get("errors", []))
        return false
    _active_project = project
    if not workspace_screen.has_method("bind_project"):
        return true

    var project_directory: String = _project_repository.get_project_directory(project.project_id)
    var editor_result: Dictionary = workspace_screen.bind_project(project, Callable(self, "mark_project_dirty"), project_directory)
    if not editor_result.get("ok", false):
        return _activation_failure("Unable to bind project editor session", editor_result)

    var editor_session = _resolve_editor_session()
    if editor_session == null:
        return _activation_failure("Unable to resolve editor session for contextual workspace binding", {})

    var terrain_result: Dictionary = _terrain_workspace.bind_project(project, project_directory, editor_session, Callable(self, "mark_project_dirty"))
    if not terrain_result.get("ok", false):
        return _activation_failure("Unable to bind terrain workspace", terrain_result)

    var cell_resolver := Callable()
    var terrain_controller = _terrain_workspace.get_controller()
    if terrain_controller != null and terrain_controller.get_state() != null:
        cell_resolver = Callable(terrain_controller.get_state(), "cell_id_at_position")

    var gameplay_result: Dictionary = _gameplay_workspace.bind_project(project, project_directory, editor_session, Callable(self, "mark_project_dirty"), cell_resolver)
    if not gameplay_result.get("ok", false):
        return _activation_failure("Unable to bind gameplay workspace", gameplay_result)

    var visual_result: Dictionary = _visual_scripting_workspace.bind_project(project, project_directory, editor_session, Callable(self, "mark_project_dirty"))
    if not visual_result.get("ok", false):
        return _activation_failure("Unable to bind Visual Scripting workspace", visual_result)

    var procedural_result: Dictionary = _procedural_workspace.bind_project(
        project,
        project_directory,
        editor_session,
        Callable(self, "mark_project_dirty"),
        terrain_controller,
        workspace_screen.get_asset_library(),
        _gameplay_workspace.get_service()
    )
    if not procedural_result.get("ok", false):
        return _activation_failure("Unable to bind Procedural workspace", procedural_result)

    var template_result: Dictionary = _prepare_template_baseline(project, editor_session, cell_resolver)
    if not template_result.get("ok", false):
        return _activation_failure("Unable to initialize project template", template_result)

    if workspace_screen.has_method("get_play_session"):
        var play_session = workspace_screen.get_play_session()
        play_session.configure_visual_graph_provider(Callable(_visual_scripting_workspace.get_service(), "get_graphs"))
        play_session.configure_gameplay_state_provider(Callable(_gameplay_workspace.get_service(), "get_runtime_snapshot"))
        if terrain_controller != null:
            play_session.configure_streaming(Callable(terrain_controller, "update_streaming_focus"))
    return true


func _prepare_template_baseline(project, editor_session, cell_resolver: Callable) -> Dictionary:
    var registry = TemplateRegistry.new()
    var load_result: Dictionary = registry.load_builtin()
    if not load_result.get("ok", false): return load_result

    var manifest_result: Dictionary = registry.require_manifest(project.template_id)
    if not manifest_result.get("ok", false): return manifest_result

    var manifest: Dictionary = manifest_result["manifest"]
    var application = TemplateApplication.new()
    var changed := false
    if project.runtime_config.is_empty() or str(project.runtime_config.get("template_id", "")) != project.template_id:
        var apply_result: Dictionary = application.apply_to_project(project, manifest)
        if not apply_result.get("ok", false): return apply_result
        changed = true

    var gameplay_service = _gameplay_workspace.get_service()
    var starter_result: Dictionary = application.materialize_starters(project, manifest, editor_session, gameplay_service, cell_resolver)
    if not starter_result.get("ok", false): return starter_result
    changed = changed or bool(starter_result.get("changed", false))
    if not changed: return {"ok": true, "errors": [], "changed": false}

    var save_result: Dictionary = _project_repository.save_project(project)
    if not save_result.get("ok", false): return save_result
    _autosave_service.mark_clean()
    return {"ok": true, "errors": [], "changed": true, "starter_entity_ids": starter_result.get("starter_entity_ids", {})}


func _resolve_editor_session():
    var editor_viewport = workspace_screen.get_node_or_null("ViewportFrame/ViewportBackdrop/EditorViewport3D")
    if editor_viewport == null: return null
    return editor_viewport.get_world_root().get_node_or_null("EditorSession")


func _on_new_world_create_requested(configuration: Dictionary) -> void:
    var create_result: Dictionary = _project_repository.create_project(
        str(configuration.get("title", "")),
        StringName(str(configuration.get("world_profile", ""))),
        str(configuration.get("template_id", ""))
    )
    if not create_result.get("ok", false):
        new_world_screen.set_error_message("Could not create the project: " + str(create_result.get("errors", [])))
        return
    var project = create_result["project"]
    if not _activate_project(project):
        new_world_screen.set_error_message("Could not activate the new project editor session.")
        return
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
    var recovery: Dictionary = recent.get("recovery", {})
    if recovery.get("recoverable", false): print("Recovery checkpoint available for project: %s" % project.project_id)
    if not _activate_project(project): return
    _show_workspace(project.to_dictionary())


func _refresh_recent_project() -> void:
    var recent: Dictionary = _project_repository.get_recent_project()
    var project = recent.get("project")
    if recent.get("ok", false) and project != null: home_screen.set_recent_project(project.title, true)
    else: home_screen.set_recent_project("", false)


func _on_workspace_mode_changed(mode: StringName) -> void:
    if _autosave_service != null: _autosave_service.set_suspended(mode == &"play")
    if mode == &"play": _close_contextual_tools()


func _ensure_build_mode() -> void:
    if workspace_screen == null or not workspace_screen.has_method("get_mode"): return
    if workspace_screen.get_mode() != &"play": return
    var switch = workspace_screen.get_node_or_null("TopBar/TopMargin/TopRow/ModeSlot/ModeSwitch")
    if switch != null and switch.has_method("set_mode"): switch.set_mode(&"build")


func _close_contextual_tools() -> void:
    if _procedural_workspace != null: _procedural_workspace.close_tool()
    if _visual_scripting_workspace != null: _visual_scripting_workspace.close_tool()
    if _gameplay_workspace != null: _gameplay_workspace.close_tool()
    if _terrain_workspace != null: _terrain_workspace.close_tool()


func _activation_failure(message: String, result: Dictionary) -> bool:
    push_warning("%s: %s" % [message, result.get("errors", [])])
    _active_project = null
    if _autosave_service != null: _autosave_service.detach_project()
    return false


func _on_workspace_status(message: String, _is_error: bool) -> void:
    var status_label := workspace_screen.get_node_or_null("StatusBar/StatusMargin/StatusRow/StatusState") as Label
    if status_label != null: status_label.text = message
