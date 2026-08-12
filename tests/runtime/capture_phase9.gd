extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const OUTPUT_DIR := "res://artifacts/phase9"
const StableId = preload("res://src/world/stable_id.gd")


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS:
        _fail("Unable to create Phase 9 screenshot directory: %s" % make_error)
        return
    root.size = Vector2i(1600, 900)
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://phase9_visual_%s" % StableId.generate())
    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null:
        _fail("Unable to load Main.tscn for Phase 9 capture.")
        return
    var app = packed.instantiate()
    root.add_child(app)
    await _settle()
    app.call("_on_new_world_create_requested", {"title": "Phase 9 Procedural World", "world_profile": "small", "template_id": "blank_sandbox"})
    await _settle()
    var workspace = app.get_node_or_null("WorkspaceScreen")
    if workspace == null or not workspace.visible:
        _fail("Phase 9 capture could not enter the real workspace.")
        return
    var layer = app.call("get_procedural_workspace")
    if layer == null:
        _fail("Phase 9 capture could not resolve the Procedural workspace.")
        return
    var service = layer.call("get_service")
    var runtime = layer.call("get_runtime")
    if service == null or runtime == null:
        _fail("Phase 9 capture could not resolve procedural service/runtime.")
        return

    var grass: Dictionary = service.create_foliage_set("Meadow Grass", {"kind": "primitive", "primitive": "grass"}, {"scale_range": [0.75, 1.3], "max_instances_per_cell": 1200})
    var trees: Dictionary = service.create_foliage_set("Pine Grove", {"kind": "primitive", "primitive": "tree"}, {"scale_range": [0.85, 1.35], "max_instances_per_cell": 128})
    if not grass.get("ok", false) or not trees.get("ok", false):
        _fail("Phase 9 capture could not create foliage sets.")
        return
    var grass_layer: Dictionary = service.create_scatter_layer("Meadow", str(grass.get("foliage_set_id", "")), {"density_per_100m2": 8.0, "minimum_spacing_m": 0.9, "seed": 911})
    var tree_layer: Dictionary = service.create_scatter_layer("Pines", str(trees.get("foliage_set_id", "")), {"density_per_100m2": 0.5, "minimum_spacing_m": 6.0, "seed": 912})
    if not grass_layer.get("ok", false) or not tree_layer.get("ok", false):
        _fail("Phase 9 capture could not create scatter layers.")
        return
    var grass_id: String = str(grass_layer.get("scatter_layer_id", ""))
    var tree_id: String = str(tree_layer.get("scatter_layer_id", ""))
    for center in [Vector3(-30, 0, -18), Vector3(26, 0, 18), Vector3(38, 0, -30)]:
        var paint: Dictionary = service.add_scatter_stroke(grass_id, "paint", center, 28.0, 1.0)
        if not paint.get("ok", false):
            _fail("Phase 9 capture could not paint meadow foliage.")
            return
    for center in [Vector3(-42, 0, 26), Vector3(36, 0, 34)]:
        var paint: Dictionary = service.add_scatter_stroke(tree_id, "paint", center, 30.0, 1.0)
        if not paint.get("ok", false):
            _fail("Phase 9 capture could not paint tree foliage.")
            return
    var road: Dictionary = service.create_spline("Creek Road", "road", [Vector3(-82, 0, -48), Vector3(-24, 0, -8), Vector3(28, 0, 8), Vector3(84, 0, 44)], {"width_m": 8.0, "sample_spacing_m": 4.0})
    var fence: Dictionary = service.create_spline("North Fence", "fence", [Vector3(-76, 0, 52), Vector3(76, 0, 52)], {"sample_spacing_m": 7.0, "segment_source": {"kind": "primitive", "primitive": "post"}})
    if not road.get("ok", false) or not fence.get("ok", false):
        _fail("Phase 9 capture could not create road/fence splines.")
        return
    if runtime.total_instance_count() < 150:
        _fail("Phase 9 capture requires a visibly representative foliage population.")
        return
    if runtime.get_spline_nodes(str(road.get("spline_id", ""))).is_empty() or runtime.get_spline_nodes(str(fence.get("spline_id", ""))).is_empty():
        _fail("Phase 9 capture requires visible road and fence runtime geometry.")
        return

    var editor_viewport = workspace.get_node_or_null("ViewportFrame/ViewportBackdrop/EditorViewport3D")
    var camera := editor_viewport.get_node_or_null("WorldViewport/WorldRoot/Camera3D") as Camera3D if editor_viewport != null else null
    if camera == null:
        _fail("Phase 9 capture could not resolve the editor camera.")
        return
    camera.position = Vector3(96.0, 72.0, 112.0)
    camera.fov = 58.0
    camera.far = 5000.0
    camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)

    var foliage_button := workspace.find_child("FoliageButton", true, false) as Button
    var roads_button := workspace.find_child("RoadsButton", true, false) as Button
    if foliage_button == null or roads_button == null:
        _fail("Phase 9 capture could not resolve Foliage/Roads dock buttons.")
        return
    foliage_button.emit_signal("pressed")
    await _settle()
    if not layer.call("is_open") or layer.call("get_panel").call("get_section") != &"foliage":
        _fail("Phase 9 capture could not open foliage mode.")
        return
    await _capture("01-foliage-scatter")

    roads_button.emit_signal("pressed")
    await _settle()
    if not layer.call("is_open") or layer.call("get_panel").call("get_section") != &"splines":
        _fail("Phase 9 capture could not open spline mode.")
        return
    await _capture("02-road-fence")
    print("PASS: Phase 9 rendered screenshots captured.")
    quit(0)


func _settle() -> void:
    await process_frame
    await process_frame
    await physics_frame
    await RenderingServer.frame_post_draw


func _capture(file_stem: String) -> void:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("Rendered Phase 9 image is empty for %s." % file_stem)
        return
    var output_file := "%s/%s.png" % [OUTPUT_DIR, file_stem]
    var save_error := image.save_png(ProjectSettings.globalize_path(output_file))
    if save_error != OK: _fail("Unable to save %s: %s" % [output_file, save_error])


func _fail(message: String) -> void:
    push_error(message)
    quit(1)
