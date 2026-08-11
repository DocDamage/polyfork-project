extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const OUTPUT_DIR := "res://artifacts/phase1"

var _app: Control


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var output_path := ProjectSettings.globalize_path(OUTPUT_DIR)
    var make_dir_error := DirAccess.make_dir_recursive_absolute(output_path)
    if make_dir_error != OK and make_dir_error != ERR_ALREADY_EXISTS:
        push_error("Unable to create screenshot output directory: %s" % make_dir_error)
        quit(1)
        return

    var main_resource := load(MAIN_SCENE) as PackedScene
    if main_resource == null:
        push_error("Unable to load Main.tscn for Phase 1 capture.")
        quit(1)
        return

    _app = main_resource.instantiate() as Control
    if _app == null:
        push_error("Unable to instantiate Main.tscn for Phase 1 capture.")
        quit(1)
        return

    root.add_child(_app)
    root.size = Vector2i(1600, 900)
    await _settle()
    await _capture("01-home")

    var home := _app.get_node("HomeScreen") as Control
    var new_world := _app.get_node("NewWorldScreen") as Control
    var workspace := _app.get_node("WorkspaceScreen") as Control

    home.emit_signal("route_requested", &"new_world")
    await _settle()
    await _capture("02-new-world")

    new_world.emit_signal("create_requested", {
        "title": "Sunset Valley",
        "world_profile": "medium",
        "template_id": "third_person_adventure"
    })
    await _settle()
    await _capture("03-workspace-clean")

    workspace.call("show_inspector", {
        "title": "Wooden Cottage",
        "type": "Scenery object",
        "summary": "Placed in Sunset Valley",
        "advanced_summary": "Advanced object controls appear here only when requested."
    })
    var assets_button := workspace.find_child("AssetsButton", true, false) as Button
    assets_button.emit_signal("pressed")
    await _settle()
    await _capture("04-workspace-tools")

    print("PASS: Phase 1 rendered screenshots captured.")
    quit(0)


func _settle() -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw


func _capture(file_stem: String) -> void:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        push_error("Rendered image is empty for %s." % file_stem)
        quit(1)
        return

    var output_file := "%s/%s.png" % [OUTPUT_DIR, file_stem]
    var save_error := image.save_png(ProjectSettings.globalize_path(output_file))
    if save_error != OK:
        push_error("Unable to save %s: %s" % [output_file, save_error])
        quit(1)
