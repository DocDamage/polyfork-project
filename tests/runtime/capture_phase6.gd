extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const OUTPUT_DIR := "res://artifacts/phase6"
const StableId = preload("res://src/world/stable_id.gd")
const Archetypes = preload("res://src/gameplay/builtin_archetype_library.gd")

var _app: Control


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var make_dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
    if make_dir_error != OK and make_dir_error != ERR_ALREADY_EXISTS:
        _fail("Unable to create Phase 6 screenshot directory: %s" % make_dir_error)
        return
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://phase6_visual_%s" % StableId.generate())
    var main_resource := load(MAIN_SCENE) as PackedScene
    if main_resource == null:
        _fail("Unable to load Main.tscn for Phase 6 capture.")
        return
    _app = main_resource.instantiate() as Control
    if _app == null:
        _fail("Unable to instantiate Main.tscn for Phase 6 capture.")
        return
    root.add_child(_app)
    root.size = Vector2i(1600, 900)
    await _settle()

    var home := _app.get_node("HomeScreen") as Control
    var new_world := _app.get_node("NewWorldScreen") as Control
    var workspace := _app.get_node("WorkspaceScreen") as Control
    home.emit_signal("route_requested", &"new_world")
    await _settle()
    new_world.emit_signal("create_requested", {"title": "Copperlight Workshop", "world_profile": "small", "template_id": "third_person_adventure"})
    await _settle()

    var begin: Dictionary = workspace.call("begin_proxy_placement", "Workshop Guardian")
    if not begin.get("ok", false):
        _fail("Unable to begin Phase 6 visual placement.")
        return
    workspace.call("update_placement_preview", Vector3(1.0, 0.5, 1.0))
    var placed: Dictionary = workspace.call("commit_placement")
    var original_id := str(placed.get("entity_id", ""))
    if original_id.is_empty():
        _fail("Unable to commit Phase 6 visual object.")
        return

    var gameplay_button := workspace.find_child("GameplayButton", true, false) as Button
    if gameplay_button == null:
        _fail("Unable to locate Gameplay dock button for Phase 6 capture.")
        return
    gameplay_button.emit_signal("pressed")
    await _settle()

    var layer = _app.call("get_gameplay_workspace")
    var service = layer.call("get_service")
    var prefabs = layer.call("get_prefab_service")
    var sockets = layer.call("get_socket_service")
    var panel = layer.call("get_panel")
    if service == null or prefabs == null or sockets == null or panel == null:
        _fail("Unable to resolve Phase 6 Gameplay services.")
        return

    var archetype_result: Dictionary = service.apply_archetype(original_id, Archetypes.id_for("destructible_prop"))
    if not archetype_result.get("ok", false):
        _fail("Unable to apply Phase 6 visual archetype: %s" % [archetype_result.get("errors", [])])
        return
    var socket_result: Dictionary = sockets.add_socket(original_id, "Grip", "Grip", _transform(Vector3(0.55, 0.45, 0.0)))
    if not socket_result.get("ok", false):
        _fail("Unable to author Phase 6 visual socket: %s" % [socket_result.get("errors", [])])
        return
    var prefab_result: Dictionary = prefabs.save_prefab(original_id, "Guardian Prop")
    if not prefab_result.get("ok", false):
        _fail("Unable to save Phase 6 visual prefab: %s" % [prefab_result.get("errors", [])])
        return
    panel.set_prefabs(service.get_prefabs())
    layer.call("_refresh_selection")
    await _settle()
    await _capture("01-gameplay-composition")

    var prefab_id := str(prefab_result.get("prefab_id", ""))
    var spawn_result: Dictionary = prefabs.instantiate_prefab(prefab_id, Vector3(5.0, 0.5, 3.5))
    if not spawn_result.get("ok", false):
        _fail("Unable to instantiate Phase 6 visual prefab: %s" % [spawn_result.get("errors", [])])
        return
    var spawned_id := str(spawn_result.get("root_entity_id", ""))
    var parent_sockets: Array[Dictionary] = service.sockets_for_entity(original_id)
    var child_sockets: Array[Dictionary] = service.sockets_for_entity(spawned_id)
    if parent_sockets.is_empty() or child_sockets.is_empty():
        _fail("Phase 6 visual prefab instances must expose entity-owned sockets.")
        return
    var attach_result: Dictionary = sockets.attach(original_id, str(parent_sockets[0].get("socket_id", "")), spawned_id, str(child_sockets[0].get("socket_id", "")))
    if not attach_result.get("ok", false):
        _fail("Unable to author Phase 6 visual attachment: %s" % [attach_result.get("errors", [])])
        return
    layer.call("_apply_runtime_attachments")
    workspace.call("select_entity", original_id)
    workspace.call("toggle_entity_selection", spawned_id)
    layer.call("_refresh_selection")
    await _settle()
    await _capture("02-prefab-socket-attachment")

    print("PASS: Phase 6 rendered screenshots captured.")
    quit(0)


func _settle() -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw


func _capture(file_stem: String) -> void:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("Rendered Phase 6 image is empty for %s." % file_stem)
        return
    var output_file := "%s/%s.png" % [OUTPUT_DIR, file_stem]
    var save_error := image.save_png(ProjectSettings.globalize_path(output_file))
    if save_error != OK: _fail("Unable to save %s: %s" % [output_file, save_error])


func _transform(position: Vector3) -> Dictionary:
    return {"position": [position.x, position.y, position.z], "rotation_degrees": [0.0, 0.0, 0.0], "scale": [1.0, 1.0, 1.0]}


func _fail(message: String) -> void:
    push_error(message)
    quit(1)
