extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const OUTPUT_DIR := "res://artifacts/phase10"
const StableId = preload("res://src/world/stable_id.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const GameplayInput = preload("res://src/input/gameplay_input_map.gd")


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS:
        _fail("Unable to create Phase 10 screenshot directory: %s" % make_error)
        return
    root.size = Vector2i(1600, 900)
    GameplayInput.uninstall_owned()
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://phase10_visual_%s" % StableId.generate())
    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null:
        _fail("Unable to load Main.tscn for Phase 10 capture.")
        return
    var app = packed.instantiate()
    root.add_child(app)
    await _settle()
    app.call("_on_new_world_create_requested", {"title": "Phase 10 Gameplay World", "world_profile": "small", "template_id": "third_person_adventure"})
    await _settle()
    var workspace = app.get_node_or_null("WorkspaceScreen")
    if workspace == null or not workspace.visible:
        _fail("Phase 10 capture could not enter the real workspace.")
        return

    var begin: Dictionary = workspace.call("begin_proxy_placement", "Gameplay Framework Hub")
    if not begin.get("ok", false):
        _fail("Phase 10 capture could not begin representative gameplay placement.")
        return
    workspace.call("update_placement_preview", Vector3(3.0, 0.5, 2.0))
    var placed: Dictionary = workspace.call("commit_placement")
    var entity_id := str(placed.get("entity_id", ""))
    if entity_id.is_empty():
        _fail("Phase 10 capture could not commit representative gameplay entity.")
        return

    var gameplay_button := workspace.find_child("GameplayButton", true, false) as Button
    if gameplay_button == null:
        _fail("Phase 10 capture could not resolve the Gameplay dock button.")
        return
    gameplay_button.emit_signal("pressed")
    await _settle()
    var layer = app.call("get_gameplay_workspace")
    var service = layer.call("get_service") if layer != null else null
    var panel = layer.call("get_panel") if layer != null else null
    if layer == null or service == null or panel == null or not layer.call("is_open"):
        _fail("Phase 10 capture could not open the real Gameplay workspace.")
        return

    for key in ["health", "inventory_container", "dialogue_participant", "quest_participant", "save_state"]:
        var result: Dictionary = service.add_component(entity_id, Components.id_for(key))
        if not result.get("ok", false):
            _fail("Phase 10 capture could not add %s: %s" % [key, result.get("errors", [])])
            return
    layer.call("_refresh_selection")
    app.call("_on_workspace_status", "Gameplay framework ready • inventory • health • narrative • save state", false)
    await _settle()
    await _capture("01-gameplay-framework-workspace")

    var controller_begin: Dictionary = workspace.call("begin_proxy_placement", "Controller Gameplay Target")
    if not controller_begin.get("ok", false):
        _fail("Phase 10 capture could not create controller UX target.")
        return
    workspace.call("update_placement_preview", Vector3(-3.0, 0.5, 2.0))
    var controller_placed: Dictionary = workspace.call("commit_placement")
    var controller_id := str(controller_placed.get("entity_id", ""))
    if controller_id.is_empty():
        _fail("Phase 10 capture could not commit controller UX target.")
        return
    layer.call("_refresh_selection")
    var before_count: int = service.components_for_entity(controller_id).size()
    var joy := InputEventJoypadButton.new()
    joy.button_index = JOY_BUTTON_X
    joy.pressed = true
    if not panel.call("handle_shortcut", joy):
        _fail("Phase 10 Gameplay workspace did not consume its documented gamepad component shortcut.")
        return
    await _settle()
    if service.components_for_entity(controller_id).size() <= before_count:
        _fail("Phase 10 gamepad component shortcut did not perform a real authoring action.")
        return

    workspace.call("select_entity", entity_id)
    layer.call("_refresh_selection")
    await _settle()
    var mode_switch = workspace.find_child("ModeSwitch", true, false)
    if mode_switch == null:
        _fail("Phase 10 capture could not resolve the Build/Play switch.")
        return
    mode_switch.call("set_mode", &"play")
    for _index in range(55):
        await physics_frame
    var play = workspace.call("get_play_session")
    var player = play.call("get_player") if play != null else null
    if workspace.call("get_mode") != &"play" or play == null or not play.call("is_active") or player == null:
        _fail("Phase 10 capture did not enter a real disposable Play session.")
        return
    app.call("_on_workspace_status", "Play runtime active • authored Build state isolated", false)
    await _settle()
    await _capture("02-disposable-play-runtime")

    mode_switch.call("set_mode", &"build")
    await _settle()
    if workspace.call("get_mode") != &"build" or play.call("is_active"):
        _fail("Phase 10 capture could not restore authoritative Build mode.")
        return
    GameplayInput.uninstall_owned()
    print("PASS: Phase 10 rendered screenshots captured.")
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
        _fail("Rendered Phase 10 image is empty for %s." % file_stem)
        return
    var output_file := "%s/%s.png" % [OUTPUT_DIR, file_stem]
    var save_error := image.save_png(ProjectSettings.globalize_path(output_file))
    if save_error != OK:
        _fail("Unable to save %s: %s" % [output_file, save_error])


func _fail(message: String) -> void:
    push_error(message)
    GameplayInput.uninstall_owned()
    quit(1)
