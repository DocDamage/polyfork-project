extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const OUTPUT_DIR := "res://artifacts/phase16"
const StableId = preload("res://src/world/stable_id.gd")

var _app: Control

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var output_path := ProjectSettings.globalize_path(OUTPUT_DIR)
    var make_error: Error = DirAccess.make_dir_recursive_absolute(output_path)
    if make_error not in [OK, ERR_ALREADY_EXISTS]:
        _fail("Unable to create Phase 16 screenshot directory: %s" % make_error); return
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://phase16_visual_%s" % StableId.generate())
    ProjectSettings.set_setting("playworld/assets/library_root", "user://phase16_visual_assets_%s" % StableId.generate())
    ProjectSettings.set_setting("playworld/assets/use_shared_library", true)
    root.size = Vector2i(1600, 900)
    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null: _fail("Unable to load Main.tscn for Phase 16 capture."); return
    _app = packed.instantiate() as Control
    if _app == null: _fail("Unable to instantiate Main.tscn for Phase 16 capture."); return
    root.add_child(_app)
    await _settle()

    var home := _app.get_node("HomeScreen") as Control
    var worlds := home.find_child("WorldsButton", true, false) as Button
    if worlds == null: _fail("My Worlds button is missing."); return
    worlds.pressed.emit(); await _settle(); await _capture("01-home-worlds-full")
    _close_home_overlay(home)

    var templates := home.find_child("TemplatesButton", true, false) as Button
    if templates == null: _fail("Templates button is missing."); return
    templates.pressed.emit(); await _settle(); await _capture("02-home-templates-full")
    _close_home_overlay(home)

    var assets := home.find_child("AssetLibraryButton", true, false) as Button
    if assets == null: _fail("Asset Library button is missing."); return
    assets.pressed.emit(); await _settle(); await _capture("03-home-assets-full")
    root.size = Vector2i(1024, 640); await _settle(); await _capture("04-home-assets-compact")
    _close_home_overlay(home)

    root.size = Vector2i(1600, 900)
    _app.call("_show_new_world"); await _settle(); await _capture("05-new-world-biome-full")
    root.size = Vector2i(1024, 640); await _settle(); await _capture("06-new-world-biome-compact")

    root.size = Vector2i(1600, 900)
    _app.call("_on_new_world_create_requested", {"title": "Phase 16 Creator Valley", "world_profile": "medium", "biome_preset": "alpine", "template_id": "third_person_adventure"})
    await _settle()
    var workspace := _app.get_node("WorkspaceScreen") as Control
    if workspace == null or not workspace.visible: _fail("Phase 16 capture could not enter the workspace."); return
    var placed: Dictionary = workspace.begin_proxy_placement("Gizmo Preview")
    if not placed.get("ok", false): _fail("Could not begin Phase 16 placement: %s" % str(placed.get("errors", []))); return
    workspace.update_placement_preview(Vector3(4.0, 2.0, 4.0))
    var committed: Dictionary = workspace.commit_placement()
    if not committed.get("ok", false): _fail("Could not commit Phase 16 placement: %s" % str(committed.get("errors", []))); return
    var editor_viewport: Node = workspace.get_node("ViewportFrame/ViewportBackdrop/EditorViewport3D")
    var world_root: Node = editor_viewport.call("get_world_root") as Node
    var session: Node = world_root.get_node_or_null("EditorSession") if world_root != null else null
    if session == null: _fail("Editor session is unavailable for Phase 16 capture."); return
    session.call("set_tool", &"move")
    editor_viewport.call("set_camera_mode", &"orbit")
    editor_viewport.call("focus_selection")
    await _settle(); await _capture("07-workspace-gizmo-orbit-full")
    root.size = Vector2i(1024, 640); await _settle(); await _capture("08-workspace-gizmo-orbit-compact")

    print("PASS: Phase 16 rendered product-completeness evidence captured.")
    quit(0)

func _close_home_overlay(home: Control) -> void:
    var overlay := home.get_node_or_null("HomeCreatorOverlay")
    if overlay != null: overlay.call("close")

func _settle() -> void:
    await process_frame
    await process_frame
    await physics_frame
    await RenderingServer.frame_post_draw

func _capture(file_stem: String) -> void:
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty(): _fail("Rendered Phase 16 image is empty for %s." % file_stem); return
    var output_file := "%s/%s.png" % [OUTPUT_DIR, file_stem]
    var save_error: Error = image.save_png(ProjectSettings.globalize_path(output_file))
    if save_error != OK: _fail("Unable to save %s: %s" % [output_file, save_error])

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
