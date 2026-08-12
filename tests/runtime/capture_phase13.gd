extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const OUTPUT_DIR := "res://artifacts/phase13"
const StableId = preload("res://src/world/stable_id.gd")

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS: _fail("Unable to create Phase 13 screenshot directory."); return
    root.size = Vector2i(1600, 900)
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://phase13_visual_%s" % StableId.generate())
    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null: _fail("Unable to load Main.tscn for Phase 13 capture."); return
    var app = packed.instantiate(); root.add_child(app)
    await _settle()
    app.call("_on_new_world_create_requested", {"title": "Phase 13 Export Pipeline", "world_profile": "medium", "template_id": "third_person_adventure"})
    await _settle()
    var workspace = app.get_node_or_null("WorkspaceScreen")
    if workspace == null or not workspace.visible: _fail("Phase 13 capture could not enter the real workspace."); return
    var layer = root.get_node_or_null("ExportWorkspace")
    if layer == null: _fail("Phase 13 capture could not resolve the Export workspace autoload."); return
    var bind: Dictionary = layer.call("bind_workspace", workspace)
    if not bind.get("ok", false): _fail("Phase 13 capture could not bind Export workspace: %s" % str(bind.get("errors", []))); return
    layer.call("refresh_state")
    var button = layer.call("get_export_button") as Button
    if button == null or button.disabled: _fail("Phase 13 capture Export button is not Build-ready."); return
    layer.call("open_panel")
    await _settle()
    if not layer.call("is_panel_open"): _fail("Phase 13 capture could not open the Export panel."); return
    await _capture("01-build-export-ready")
    print("PASS: Phase 13 rendered Export workspace screenshot captured.")
    quit(0)

func _settle() -> void:
    await process_frame
    await process_frame
    await physics_frame
    await RenderingServer.frame_post_draw

func _capture(file_stem: String) -> void:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    if image == null or image.is_empty(): _fail("Rendered Phase 13 image is empty."); return
    var output_file := "%s/%s.png" % [OUTPUT_DIR, file_stem]
    var save_error := image.save_png(ProjectSettings.globalize_path(output_file))
    if save_error != OK: _fail("Unable to save Phase 13 screenshot: %s" % save_error)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
