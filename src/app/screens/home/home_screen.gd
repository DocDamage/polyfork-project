class_name PlayWorldHomeScreen
extends Control

signal route_requested(route: StringName)

const SettingsScene = preload("res://src/app/screens/settings/SettingsScreen.tscn")
const CreatorOverlay = preload("res://src/app/screens/home/home_creator_overlay.gd")
const ProjectRepository = preload("res://src/world/project_repository.gd")
const TemplateRegistry = preload("res://src/templates/template_registry.gd")
const AssetLibrary = preload("res://src/assets/asset_library_service.gd")
const ProductIdentity = preload("res://src/release/product_identity.gd")
const ROUTE_NEW_WORLD: StringName = &"new_world"
const ROUTE_CONTINUE: StringName = &"continue"
const ROUTE_MY_WORLDS: StringName = &"my_worlds"
const ROUTE_TEMPLATES: StringName = &"templates"
const ROUTE_ASSET_LIBRARY: StringName = &"asset_library"
const ROUTE_ABOUT: StringName = &"about"

@onready var create_button: Button = %CreateButton
@onready var continue_button: Button = %ContinueButton
@onready var worlds_button: Button = %WorldsButton
@onready var templates_button: Button = %TemplatesButton
@onready var asset_library_button: Button = %AssetLibraryButton
@onready var about_button: Button = %AboutButton
@onready var support_button: Button = %SupportButton
@onready var settings_button: Button = %SettingsButton
@onready var hub: GridContainer = %Hub

var _settings_screen: Control
var _creator_overlay: Control
var _scale_service: Node
var _repository
var _library
var _overlay_mode: StringName = &""

func _ready() -> void:
    create_button.pressed.connect(_request_route.bind(ROUTE_NEW_WORLD))
    continue_button.pressed.connect(_request_route.bind(ROUTE_CONTINUE))
    worlds_button.pressed.connect(_request_route.bind(ROUTE_MY_WORLDS))
    templates_button.pressed.connect(_request_route.bind(ROUTE_TEMPLATES))
    asset_library_button.pressed.connect(_request_route.bind(ROUTE_ASSET_LIBRARY))
    about_button.pressed.connect(_request_route.bind(ROUTE_ABOUT))
    support_button.pressed.connect(_open_support)
    settings_button.pressed.connect(_open_settings)
    _settings_screen = SettingsScene.instantiate()
    add_child(_settings_screen)
    _settings_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _settings_screen.hide()
    _settings_screen.back_requested.connect(_close_settings)
    _creator_overlay = CreatorOverlay.new()
    add_child(_creator_overlay)
    _creator_overlay.back_requested.connect(_close_creator_overlay)
    _creator_overlay.item_requested.connect(_on_overlay_item_requested)
    _creator_overlay.path_submitted.connect(_on_library_path_submitted)
    _creator_overlay.primary_requested.connect(_on_overlay_primary_requested)
    var storage_root := str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects"))
    _repository = ProjectRepository.new(storage_root)
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
    if _creator_overlay != null and _creator_overlay.visible: return
    if _settings_screen != null and _settings_screen.visible: _settings_screen.focus_primary()
    else: create_button.grab_focus()

func _configure_focus_navigation() -> void:
    about_button.focus_neighbor_right = about_button.get_path_to(support_button)
    about_button.focus_neighbor_bottom = about_button.get_path_to(create_button)
    support_button.focus_neighbor_left = support_button.get_path_to(about_button)
    support_button.focus_neighbor_right = support_button.get_path_to(settings_button)
    support_button.focus_neighbor_bottom = support_button.get_path_to(create_button)
    settings_button.focus_neighbor_left = settings_button.get_path_to(support_button)
    settings_button.focus_neighbor_bottom = settings_button.get_path_to(create_button)
    create_button.focus_neighbor_top = create_button.get_path_to(about_button)
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
    _set_tab_order([about_button, support_button, settings_button, create_button, continue_button, worlds_button, templates_button, asset_library_button])

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

func _open_support() -> void:
    var maintenance := get_node_or_null("/root/ReleaseMaintenance")
    if maintenance != null and maintenance.has_method("show_support_panel"):
        maintenance.call("show_support_panel")

func _open_settings() -> void:
    _settings_screen.show()
    _settings_screen.focus_primary()

func _close_settings() -> void:
    _settings_screen.hide()
    settings_button.grab_focus()

func _request_route(route: StringName) -> void:
    match route:
        ROUTE_MY_WORLDS: _open_worlds_overlay()
        ROUTE_TEMPLATES: _open_templates_overlay()
        ROUTE_ASSET_LIBRARY: _open_asset_library_overlay()
        ROUTE_ABOUT: _open_about_overlay()
        _: route_requested.emit(route)

func _open_about_overlay() -> void:
    _overlay_mode = ROUTE_ABOUT
    var identity: Dictionary = ProductIdentity.summary()
    var version := str(identity.get("version", "unknown"))
    var items: Array[Dictionary] = [{
        "id": "",
        "title": "%s %s" % [str(identity.get("product_name", "PlayWorld Studio")), version],
        "subtitle": "Stable channel  •  Windows x64  •  Godot %s" % str(identity.get("godot_version", "")),
    }]
    _creator_overlay.call("present", "About PlayWorld Studio", "%s  •  stable  •  Windows x64" % version, items, {
        "status": "Godot %s  •  source %s" % [str(identity.get("godot_version", "")), ProductIdentity.short_commit()],
    })

func _open_worlds_overlay() -> void:
    _overlay_mode = ROUTE_MY_WORLDS
    var items: Array[Dictionary] = []
    for project in _repository.list_projects():
        items.append({"id": str(project.project_id), "title": str(project.title), "subtitle": "%s  •  %s" % [str(project.world_profile).capitalize(), str(project.template_id).replace("_", " ").capitalize()]})
    _creator_overlay.call("present", "My Worlds", "Open a saved world without leaving the runtime creator.", items, {"status": "%d saved world%s" % [items.size(), "" if items.size() == 1 else "s"]})

func _open_templates_overlay() -> void:
    _overlay_mode = ROUTE_TEMPLATES
    var registry = TemplateRegistry.new()
    var load_result: Dictionary = registry.load_builtin()
    if not load_result.get("ok", false):
        _creator_overlay.call("present", "Templates", "Built-in starter experiences", _empty_overlay_items(), {"status": "Could not load templates: %s" % str(load_result.get("errors", []))}); return
    var items: Array[Dictionary] = []
    for manifest in registry.list_manifests():
        var display: Dictionary = manifest.get("display", {})
        items.append({"id": str(manifest.get("template_id", "")), "title": str(display.get("name", "Template")), "subtitle": str(display.get("summary", ""))})
    _creator_overlay.call("present", "Templates", "Choose a starter, then customize world size and biome before creation.", items, {"status": "%d built-in templates" % items.size()})

func _open_asset_library_overlay() -> void:
    _overlay_mode = ROUTE_ASSET_LIBRARY
    _library = AssetLibrary.new("", _shared_asset_library_root())
    var load_result: Dictionary = _library.load_library()
    if not load_result.get("ok", false):
        _creator_overlay.call("present", "Asset Library", "Universal external asset library", _empty_overlay_items(), {"status": "Could not load library: %s" % str(load_result.get("errors", []))}); return
    for project in _repository.list_projects():
        var migration: Dictionary = _library.migrate_legacy_sources(_repository.get_project_directory(str(project.project_id)))
        if not migration.get("ok", false):
            _creator_overlay.call("present", "Asset Library", "Universal external asset library", _empty_overlay_items(), {"status": "Legacy source migration failed: %s" % str(migration.get("errors", []))}); return
    _present_library()

func _present_library() -> void:
    if _library == null: return
    var items: Array[Dictionary] = []
    for source in _library.get_sources(false):
        items.append({"id": "", "title": str(source.get("display_name", "Asset source")), "subtitle": str(source.get("root_path", ""))})
    _creator_overlay.call("present", "Asset Library", "Universal source folders shared by every world. Originals remain read-only.", items, {
        "allow_path": true,
        "path_placeholder": "C:\\Assets or another external folder",
        "show_primary": true,
        "primary_label": "Scan Library",
        "status": "%d sources  •  %d indexed assets" % [items.size(), _library.get_records(true).size()],
    })

func _empty_overlay_items() -> Array[Dictionary]:
    var items: Array[Dictionary] = []
    return items

func _on_overlay_item_requested(item_id: String) -> void:
    if _overlay_mode == ROUTE_MY_WORLDS:
        var result: Dictionary = _repository.open_project(item_id)
        var project = result.get("project")
        if not result.get("ok", false) or project == null:
            _creator_overlay.call("set_status", "Could not open world: %s" % str(result.get("errors", []))); return
        var main := get_parent()
        if main == null or not bool(main.call("_activate_project", project)):
            _creator_overlay.call("set_status", "Could not activate the selected world."); return
        _close_creator_overlay()
        main.call("_show_workspace", project.to_dictionary())
        return
    if _overlay_mode == ROUTE_TEMPLATES:
        var new_world := get_parent().get_node_or_null("NewWorldScreen")
        if new_world == null or not new_world.has_method("select_template"):
            _creator_overlay.call("set_status", "New World screen is unavailable."); return
        new_world.call("select_template", item_id)
        _close_creator_overlay()
        get_parent().call("_show_new_world")

func _on_library_path_submitted(path: String) -> void:
    if _overlay_mode != ROUTE_ASSET_LIBRARY or _library == null: return
    var result: Dictionary = _library.register_source(path)
    if not result.get("ok", false):
        _creator_overlay.call("set_status", "Could not add source: %s" % str(result.get("errors", []))); return
    _present_library()

func _on_overlay_primary_requested() -> void:
    if _overlay_mode != ROUTE_ASSET_LIBRARY or _library == null: return
    var result: Dictionary = _library.scan_all()
    if not result.get("ok", false):
        _creator_overlay.call("set_status", "Scan completed with errors: %s" % str(result.get("errors", []))); return
    _present_library()

func _shared_asset_library_root() -> String:
    return str(ProjectSettings.get_setting("playworld/assets/library_root", "user://asset_library"))

func _close_creator_overlay() -> void:
    _overlay_mode = &""
    _creator_overlay.call("close")
    _library = null
    create_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
    if not visible or not event.is_action_pressed("ui_cancel"): return
    if _creator_overlay != null and _creator_overlay.visible:
        _close_creator_overlay(); get_viewport().set_input_as_handled(); return
    if _settings_screen != null and _settings_screen.visible:
        _close_settings(); get_viewport().set_input_as_handled()
