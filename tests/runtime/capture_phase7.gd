extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const OUTPUT_DIR := "res://artifacts/phase7"
const StableId = preload("res://src/world/stable_id.gd")
const GameplayInput = preload("res://src/input/gameplay_input_map.gd")


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var make_dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
    if make_dir_error != OK and make_dir_error != ERR_ALREADY_EXISTS:
        _fail("Unable to create Phase 7 screenshot directory: %s" % make_dir_error)
        return
    root.size = Vector2i(1600, 900)
    var third_result := await _capture_template("third_person_adventure", "01-third-person-play", true)
    if not third_result: return
    var fps_result := await _capture_template("fps", "03-fps-play", false)
    if not fps_result: return
    print("PASS: Phase 7 rendered screenshots captured.")
    quit(0)


func _capture_template(template_id: String, play_stem: String, capture_build_restore: bool) -> bool:
    GameplayInput.uninstall_owned()
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://phase7_visual_%s_%s" % [template_id, StableId.generate()])
    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null:
        _fail("Unable to load Main.tscn for %s Phase 7 capture." % template_id)
        return false
    var app = packed.instantiate()
    root.add_child(app)
    await _settle()
    app.call("_on_new_world_create_requested", {"title": "Phase 7 %s" % template_id.replace("_", " ").capitalize(), "world_profile": "small", "template_id": template_id})
    await _settle()
    var workspace = app.get_node_or_null("WorkspaceScreen")
    if workspace == null or not workspace.visible:
        _fail("Unable to enter workspace for %s Phase 7 capture." % template_id)
        return false
    var mode_switch = workspace.find_child("ModeSwitch", true, false)
    if mode_switch == null:
        _fail("Unable to find Build/Play mode switch for %s Phase 7 capture." % template_id)
        return false
    mode_switch.call("set_mode", &"play")
    for _index in range(55): await physics_frame
    var play = workspace.call("get_play_session")
    var player = play.call("get_player") if play != null else null
    if workspace.call("get_mode") != &"play" or play == null or not play.call("is_active") or player == null:
        _fail("%s Phase 7 capture did not enter a real Play session." % template_id)
        return false
    await _capture(play_stem)
    if capture_build_restore:
        mode_switch.call("set_mode", &"build")
        await _settle()
        if workspace.call("get_mode") != &"build" or play.call("is_active"):
            _fail("Third-person Phase 7 visual capture could not restore Build mode.")
            return false
        await _capture("02-build-restored")
    else:
        mode_switch.call("set_mode", &"build")
        await _settle()
    GameplayInput.uninstall_owned()
    app.queue_free()
    await process_frame
    return true


func _settle() -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw


func _capture(file_stem: String) -> void:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("Rendered Phase 7 image is empty for %s." % file_stem)
        return
    var output_file := "%s/%s.png" % [OUTPUT_DIR, file_stem]
    var save_error := image.save_png(ProjectSettings.globalize_path(output_file))
    if save_error != OK: _fail("Unable to save %s: %s" % [output_file, save_error])


func _fail(message: String) -> void:
    push_error(message)
    quit(1)
