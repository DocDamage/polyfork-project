extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const OUTPUT_DIR := "res://artifacts/phase5"

var _app: Control


func _init() -> void: call_deferred("_run")


func _run() -> void:
    var make_dir_error: int = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
    if make_dir_error != OK and make_dir_error != ERR_ALREADY_EXISTS:
        push_error("Unable to create Phase 5 screenshot directory: %s" % make_dir_error)
        quit(1); return
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://phase5_visual_projects")
    var main_resource := load(MAIN_SCENE) as PackedScene
    if main_resource == null:
        push_error("Unable to load Main.tscn for Phase 5 capture.")
        quit(1); return
    _app = main_resource.instantiate() as Control
    if _app == null:
        push_error("Unable to instantiate Main.tscn for Phase 5 capture.")
        quit(1); return
    root.add_child(_app)
    root.size = Vector2i(1600, 900)
    await _settle()

    var home := _app.get_node("HomeScreen") as Control
    var new_world := _app.get_node("NewWorldScreen") as Control
    var workspace := _app.get_node("WorkspaceScreen") as Control
    home.emit_signal("route_requested", &"new_world")
    await _settle()
    new_world.emit_signal("create_requested", {"title": "Mosslight Valley", "world_profile": "medium", "template_id": "third_person_adventure"})
    await _settle()
    var terrain_layer = _app.call("get_terrain_workspace")
    var controller = terrain_layer.call("get_controller")
    if controller == null:
        push_error("Phase 5 visual capture could not resolve the terrain controller.")
        quit(1); return

    var terrain_button := workspace.find_child("TerrainButton", true, false) as Button
    if terrain_button == null:
        push_error("Phase 5 visual capture could not find the Terrain dock button.")
        quit(1); return
    terrain_button.emit_signal("pressed")
    await _settle()

    controller.set_radius(280.0)
    controller.set_strength(32.0)
    controller.set_mode(&"raise")
    for index in range(7):
        controller.set_cursor(Vector3.ZERO)
        var result: Dictionary = controller.apply_brush()
        if not result.get("ok", false):
            push_error("Phase 5 visual sculpt failed: %s" % result.get("errors", []))
            quit(1); return
    controller.set_cursor(Vector3(240.0, 0.0, -140.0))
    controller.set_radius(190.0)
    controller.set_strength(24.0)
    for index in range(3): controller.apply_brush()
    controller.set_cursor(Vector3(-220.0, 0.0, 170.0))
    for index in range(3): controller.apply_brush()
    controller.set_cursor(Vector3.ZERO)
    controller.set_radius(260.0)
    await _settle()
    await _capture("01-terrain-sculpt")

    var biomes: Array = controller.get_biomes()
    if biomes.size() >= 2:
        var target_biome_id: String = str(biomes[1].get("biome_id", ""))
        var biome_result: Dictionary = controller.assign_biome(target_biome_id)
        if not biome_result.get("ok", false):
            push_error("Phase 5 visual biome assignment failed: %s" % biome_result.get("errors", []))
            quit(1); return
        var panel = terrain_layer.call("get_panel")
        if panel != null: panel.call("select_biome", target_biome_id)
    controller.set_mode(&"smooth")
    controller.set_radius(320.0)
    controller.set_strength(0.70)
    controller.apply_brush()
    await _settle()
    await _capture("02-terrain-biome")

    print("PASS: Phase 5 rendered screenshots captured.")
    quit(0)


func _settle() -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw


func _capture(file_stem: String) -> void:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        push_error("Rendered Phase 5 image is empty for %s." % file_stem)
        quit(1); return
    var output_file := "%s/%s.png" % [OUTPUT_DIR, file_stem]
    var save_error := image.save_png(ProjectSettings.globalize_path(output_file))
    if save_error != OK:
        push_error("Unable to save %s: %s" % [output_file, save_error])
        quit(1)
