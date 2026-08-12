extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const OUTPUT_DIR := "res://artifacts/phase15/visual"
const StableId = preload("res://src/world/stable_id.gd")

var _app: Control

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS: _fail("Unable to create Phase 15 screenshot directory."); return
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://phase15_visual_%s" % StableId.generate())
    root.size = Vector2i(1600, 900)
    var main_resource := load(MAIN_SCENE) as PackedScene
    if main_resource == null: _fail("Unable to load Main.tscn for Phase 15 capture."); return
    _app = main_resource.instantiate() as Control
    if _app == null: _fail("Unable to instantiate Main.tscn for Phase 15 capture."); return
    root.add_child(_app)
    await _settle()
    _app.call("_on_new_world_create_requested", {"title": "Co-op Valley", "world_profile": "medium", "template_id": "third_person_adventure"})
    await _settle()
    var workspace := _app.get_node("WorkspaceScreen") as Control
    if workspace == null or not workspace.visible: _fail("Phase 15 capture could not enter the workspace."); return
    var multiplayer_layer: Node = root.get_node_or_null("MultiplayerWorkspace")
    var network: Node = root.get_node_or_null("NetworkRuntime")
    if multiplayer_layer == null or network == null: _fail("Phase 15 multiplayer autoloads are unavailable."); return
    var bind_result: Variant = multiplayer_layer.call("bind_workspace", workspace)
    if not bind_result is Dictionary or not bind_result.get("ok", false): _fail("Phase 15 multiplayer workspace failed to bind."); return
    multiplayer_layer.call("refresh_state")
    var multiplayer_button := multiplayer_layer.call("get_multiplayer_button") as Button
    if multiplayer_button == null or multiplayer_button.disabled: _fail("Multiplayer button is unavailable for a multiplayer-capable template."); return
    multiplayer_layer.call("open_panel")
    await _settle()
    await _capture("01-multiplayer-full")

    var host_result: Variant = network.call("host", 24815, "Host QA")
    if not host_result is Dictionary or not host_result.get("ok", false): _fail("Unable to arm host state for visual evidence."); return
    multiplayer_layer.call("refresh_state")
    await _settle()
    await _capture("02-host-armed-full")

    root.size = Vector2i(1024, 640)
    await _settle()
    var join_result: Variant = network.call("join", "127.0.0.1", 24815, "Client QA")
    if not join_result is Dictionary or not join_result.get("ok", false): _fail("Unable to arm join state for compact visual evidence."); return
    multiplayer_layer.call("refresh_state")
    await _settle()
    await _capture("03-join-armed-compact")

    print("PASS: Phase 15 rendered multiplayer evidence captured.")
    quit(0)

func _settle() -> void:
    await process_frame
    await process_frame
    await physics_frame
    await RenderingServer.frame_post_draw

func _capture(file_stem: String) -> void:
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty(): _fail("Rendered Phase 15 image is empty for %s." % file_stem); return
    var output_file: String = "%s/%s.png" % [OUTPUT_DIR, file_stem]
    var save_error: Error = image.save_png(ProjectSettings.globalize_path(output_file))
    if save_error != OK: _fail("Unable to save %s: %s" % [output_file, save_error])

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
