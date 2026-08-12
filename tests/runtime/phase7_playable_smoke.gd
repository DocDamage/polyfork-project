extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const GameplayInput = preload("res://src/input/gameplay_input_map.gd")
const StableId = preload("res://src/world/stable_id.gd")


func _init() -> void: call_deferred("_run")


func _run() -> void:
    var errors: Array[String] = []
    await _exercise_template("third_person_adventure", errors)
    await _exercise_template("fps", errors)
    if errors.is_empty(): print("PASS: Phase 7 playable controller smoke completed."); quit(0); return
    for error in errors: push_error(error)
    quit(1)


func _exercise_template(template_id: String, errors: Array[String]) -> void:
    GameplayInput.uninstall_owned()
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://tests/phase7_playable_%s_%s" % [template_id, StableId.generate()])
    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null: errors.append("%s playable smoke could not load Main scene." % template_id); return
    var main = packed.instantiate(); root.add_child(main); await process_frame
    main.call("_on_new_world_create_requested", {"title": "Playable %s" % template_id, "world_profile": "small", "template_id": template_id}); await process_frame
    var workspace = main.get_node("WorkspaceScreen"); var project = main.get("_active_project")
    if project == null or not bool(project.runtime_config.get("materialized", false)):
        errors.append("%s must materialize its real template baseline before Play." % template_id); await _dispose(main); return
    var spawn_id := str(project.runtime_config.get("spawn_entity_id", ""))
    if spawn_id.is_empty(): errors.append("%s must persist a stable player spawn entity." % template_id); await _dispose(main); return
    var authored_before: Dictionary = project.to_dictionary()
    var mode_switch = workspace.find_child("ModeSwitch", true, false); mode_switch.call("set_mode", &"play")
    for _index in range(50): await physics_frame
    var play = workspace.call("get_play_session"); var player = play.call("get_player")
    if workspace.call("get_mode") != &"play" or not play.call("is_active") or player == null:
        errors.append("%s Build -> Play must create an active real player controller." % template_id); await _dispose(main); return
    if workspace.call("get_runtime_entity_node", spawn_id) != null: errors.append("%s authored player-start proxy must be excluded from Play runtime physics/visuals." % template_id)
    _assert_terrain_contact(template_id, player, errors)
    if not player.call("is_on_floor"): errors.append("%s player must settle against real terrain collision/gravity." % template_id)
    var start_position: Vector3 = player.global_position
    Input.action_press(GameplayInput.MOVE_FORWARD, 1.0)
    for _index in range(16): await physics_frame
    Input.action_release(GameplayInput.MOVE_FORWARD)
    var horizontal_distance := Vector2(player.global_position.x - start_position.x, player.global_position.z - start_position.z).length()
    if horizontal_distance < 0.25: errors.append("%s semantic gameplay movement must move the real controller." % template_id)
    var yaw_before := float(player.rotation.y)
    var mouse := InputEventMouseMotion.new(); mouse.relative = Vector2(80.0, 0.0); player.call("_unhandled_input", mouse)
    if is_equal_approx(float(player.rotation.y), yaw_before): errors.append("%s mouse look must rotate the real player/camera controller." % template_id)
    var yaw_stick_before := float(player.rotation.y)
    Input.action_press(GameplayInput.LOOK_RIGHT, 0.8)
    for _index in range(8): await physics_frame
    Input.action_release(GameplayInput.LOOK_RIGHT)
    if is_equal_approx(float(player.rotation.y), yaw_stick_before): errors.append("%s right-stick semantic look must rotate the real controller." % template_id)
    if player.call("get_camera") == null or not player.call("get_camera").current: errors.append("%s Play controller must own the active camera." % template_id)
    mode_switch.call("set_mode", &"build"); await process_frame
    if workspace.call("get_mode") != &"build" or play.call("is_active") or play.call("get_player") != null: errors.append("%s Play -> Build must dispose controller state cleanly." % template_id)
    var restored_spawn = workspace.call("get_runtime_entity_node", spawn_id)
    if restored_spawn == null or not restored_spawn.visible: errors.append("%s returning to Build must restore the authored player-start marker." % template_id)
    if project.to_dictionary() != authored_before: errors.append("%s disposable Play activity must leave authored Build data unchanged." % template_id)
    if InputMap.has_action(GameplayInput.MOVE_FORWARD): errors.append("%s gameplay actions must be inactive after returning to Build." % template_id)
    if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE: errors.append("%s must release mouse capture after Play." % template_id)
    for _repeat in range(3): mode_switch.call("set_mode", &"play"); await process_frame; mode_switch.call("set_mode", &"build"); await process_frame
    if play.get_child_count() != 0: errors.append("%s repeated Play sessions must not accumulate runtime nodes." % template_id)
    await _dispose(main)


func _assert_terrain_contact(template_id: String, player: CharacterBody3D, errors: Array[String]) -> void:
    var start := Vector3(player.global_position.x, player.global_position.y + 3.0, player.global_position.z)
    var finish := Vector3(player.global_position.x, player.global_position.y - 3.0, player.global_position.z)
    var query := PhysicsRayQueryParameters3D.create(start, finish)
    query.exclude = [player.get_rid()]
    var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
    var collider = hit.get("collider") if not hit.is_empty() else null
    if not collider is StaticBody3D or collider.name != "TerrainCollision":
        errors.append("%s player contact ray must resolve the real Phase 5 TerrainCollision surface." % template_id)


func _dispose(main: Node) -> void:
    GameplayInput.uninstall_owned()
    if is_instance_valid(main): main.queue_free()
    await process_frame