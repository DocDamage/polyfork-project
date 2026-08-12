extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const OUTPUT_DIR := "res://artifacts/phase14"

var _app: Control

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var output_path: String = ProjectSettings.globalize_path(OUTPUT_DIR)
    var make_error: Error = DirAccess.make_dir_recursive_absolute(output_path)
    if make_error != OK and make_error != ERR_ALREADY_EXISTS:
        push_error("Unable to create Phase 14 screenshot directory: %s" % make_error); quit(1); return
    var main_resource := load(MAIN_SCENE) as PackedScene
    if main_resource == null:
        push_error("Unable to load Main.tscn for Phase 14 capture."); quit(1); return
    _app = main_resource.instantiate() as Control
    if _app == null:
        push_error("Unable to instantiate Main.tscn for Phase 14 capture."); quit(1); return
    root.add_child(_app)
    root.size = Vector2i(1600, 900)
    await _settle()

    var home := _app.get_node("HomeScreen") as Control
    var settings_button := home.find_child("SettingsButton", true, false) as Button
    if settings_button == null:
        push_error("Phase 14 Settings button is missing."); quit(1); return
    settings_button.pressed.emit()
    await _settle()
    await _capture("01-settings-full")

    root.size = Vector2i(1024, 640)
    await _settle()
    await _capture("02-settings-compact")
    var settings_screen := home.get_node_or_null("SettingsScreen") as Control
    if settings_screen == null:
        push_error("Phase 14 Settings screen is missing."); quit(1); return
    settings_screen.emit_signal("back_requested")
    root.size = Vector2i(1600, 900)
    await _settle()

    var scale_service: Node = root.get_node_or_null("ScalePolish")
    if scale_service != null and scale_service.has_method("set_performance_preset"):
        var preset_result: Variant = scale_service.call("set_performance_preset", "high")
        if preset_result is Dictionary and not preset_result.get("ok", false):
            push_error("Unable to select High preset for Phase 14 capture: %s" % str(preset_result.get("errors", []))); quit(1); return

    var new_world := _app.get_node("NewWorldScreen") as Control
    home.emit_signal("route_requested", &"new_world")
    await _settle()
    new_world.emit_signal("create_requested", {"title": "Scale Valley", "world_profile": "medium", "template_id": "third_person_adventure"})
    await _settle()
    var workspace := _app.get_node("WorkspaceScreen") as Control
    var export_button := workspace.find_child("ExportButton", true, false) as Button
    if export_button == null:
        await process_frame
        export_button = workspace.find_child("ExportButton", true, false) as Button
    if export_button == null or export_button.disabled:
        push_error("Phase 14 Export button is unavailable in the canonical Build workspace."); quit(1); return
    export_button.pressed.emit()
    await _settle()
    await _capture("03-workspace-export-high")

    root.size = Vector2i(1024, 640)
    await _settle()
    await _capture("04-workspace-compact")

    print("PASS: Phase 14 rendered scale/polish evidence captured.")
    quit(0)

func _settle() -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw

func _capture(file_stem: String) -> void:
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty():
        push_error("Rendered Phase 14 image is empty for %s." % file_stem); quit(1); return
    var output_file: String = "%s/%s.png" % [OUTPUT_DIR, file_stem]
    var save_error: Error = image.save_png(ProjectSettings.globalize_path(output_file))
    if save_error != OK:
        push_error("Unable to save %s: %s" % [output_file, save_error]); quit(1)
