extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const OUTPUT_DIR := "res://artifacts/phase14"
const StableId = preload("res://src/world/stable_id.gd")

var _app: Control

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var output_path: String = ProjectSettings.globalize_path(OUTPUT_DIR)
    var make_error: Error = DirAccess.make_dir_recursive_absolute(output_path)
    if make_error != OK and make_error != ERR_ALREADY_EXISTS:
        _fail("Unable to create Phase 14 screenshot directory: %s" % make_error); return
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://phase14_visual_%s" % StableId.generate())
    root.size = Vector2i(1600, 900)
    var main_resource := load(MAIN_SCENE) as PackedScene
    if main_resource == null:
        _fail("Unable to load Main.tscn for Phase 14 capture."); return
    _app = main_resource.instantiate() as Control
    if _app == null:
        _fail("Unable to instantiate Main.tscn for Phase 14 capture."); return
    root.add_child(_app)
    await _settle()

    var home := _app.get_node("HomeScreen") as Control
    var settings_button := home.find_child("SettingsButton", true, false) as Button
    if settings_button == null:
        _fail("Phase 14 Settings button is missing."); return
    settings_button.pressed.emit()
    await _settle()
    await _capture("01-settings-full")

    root.size = Vector2i(1024, 640)
    await _settle()
    await _capture("02-settings-compact")
    var settings_screen := home.get_node_or_null("SettingsScreen") as Control
    if settings_screen == null:
        _fail("Phase 14 Settings screen is missing."); return
    settings_screen.emit_signal("back_requested")
    root.size = Vector2i(1600, 900)
    await _settle()

    var scale_service: Node = root.get_node_or_null("ScalePolish")
    if scale_service != null and scale_service.has_method("set_performance_preset"):
        var preset_result: Variant = scale_service.call("set_performance_preset", "high")
        if preset_result is Dictionary and not preset_result.get("ok", false):
            _fail("Unable to select High preset for Phase 14 capture: %s" % str(preset_result.get("errors", []))); return

    _app.call("_on_new_world_create_requested", {"title": "Scale Valley", "world_profile": "medium", "template_id": "third_person_adventure"})
    await _settle()
    var workspace := _app.get_node("WorkspaceScreen") as Control
    if workspace == null or not workspace.visible:
        _fail("Phase 14 capture could not enter the canonical workspace."); return
    var export_layer: Node = root.get_node_or_null("ExportWorkspace")
    if export_layer == null:
        _fail("Phase 14 capture could not resolve the Export workspace autoload."); return
    var bind_value: Variant = export_layer.call("bind_workspace", workspace)
    if not bind_value is Dictionary or not bind_value.get("ok", false):
        _fail("Phase 14 capture could not bind the Export workspace: %s" % str(bind_value)); return
    export_layer.call("refresh_state")
    var export_button := export_layer.call("get_export_button") as Button
    if export_button == null or export_button.disabled:
        _fail("Phase 14 Export button is unavailable in the canonical Build workspace."); return
    export_layer.call("open_panel")
    await _settle()
    if not bool(export_layer.call("is_panel_open")):
        _fail("Phase 14 Export panel did not open."); return
    await _capture("03-workspace-export-high")

    root.size = Vector2i(1024, 640)
    await _settle()
    await _capture("04-workspace-compact")

    print("PASS: Phase 14 rendered scale/polish evidence captured.")
    quit(0)

func _settle() -> void:
    await process_frame
    await process_frame
    await physics_frame
    await RenderingServer.frame_post_draw

func _capture(file_stem: String) -> void:
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("Rendered Phase 14 image is empty for %s." % file_stem); return
    var output_file: String = "%s/%s.png" % [OUTPUT_DIR, file_stem]
    var save_error: Error = image.save_png(ProjectSettings.globalize_path(output_file))
    if save_error != OK:
        _fail("Unable to save %s: %s" % [output_file, save_error])

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
