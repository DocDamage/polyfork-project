extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const OUTPUT_DIR := "res://artifacts/phase8"
const StableId = preload("res://src/world/stable_id.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var make_dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
    if make_dir_error != OK and make_dir_error != ERR_ALREADY_EXISTS:
        _fail("Unable to create Phase 8 screenshot directory: %s" % make_dir_error)
        return
    root.size = Vector2i(1600, 900)
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://phase8_visual_%s" % StableId.generate())
    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null:
        _fail("Unable to load Main.tscn for Phase 8 capture.")
        return
    var app = packed.instantiate()
    root.add_child(app)
    await _settle()
    app.call("_on_new_world_create_requested", {"title":"Phase 8 Visual Scripting","world_profile":"small","template_id":"blank_sandbox"})
    await _settle()
    var workspace = app.get_node_or_null("WorkspaceScreen")
    if workspace == null or not workspace.visible:
        _fail("Phase 8 capture could not enter the real workspace.")
        return
    var layer = app.call("get_visual_scripting_workspace")
    if layer == null:
        _fail("Phase 8 capture could not resolve Visual Scripting workspace.")
        return
    var logic_button := workspace.find_child("MoreButton", true, false) as Button
    if logic_button == null:
        _fail("Phase 8 capture could not resolve the Logic dock button.")
        return
    logic_button.emit_signal("pressed")
    await _settle()
    var service = layer.call("get_service")
    var panel = layer.call("get_panel")
    var toolbar = layer.call("get_debug_toolbar")
    if service == null or panel == null or toolbar == null:
        _fail("Phase 8 capture could not resolve graph authoring/debugger services.")
        return
    var graph_result: Dictionary = service.create_graph("Door Interaction", "event")
    if not graph_result.get("ok", false):
        _fail("Phase 8 capture could not create a graph: %s" % str(graph_result.get("errors", [])))
        return
    var graph_id := str(graph_result.get("graph_id", ""))
    var start: Dictionary = service.add_node(graph_id, "event.start", Vector2(70, 140))
    var left: Dictionary = service.add_node(graph_id, "value.literal", Vector2(130, 330), {"value": 2})
    var right: Dictionary = service.add_node(graph_id, "value.literal", Vector2(390, 330), {"value": 3})
    var add: Dictionary = service.add_node(graph_id, "math.add", Vector2(520, 250))
    var print_node: Dictionary = service.add_node(graph_id, "debug.print", Vector2(820, 140))
    for result in [start, left, right, add, print_node]:
        if not result.get("ok", false):
            _fail("Phase 8 capture could not materialize graph nodes.")
            return
    var start_id := str(start.get("node_id", "")); var left_id := str(left.get("node_id", "")); var right_id := str(right.get("node_id", "")); var add_id := str(add.get("node_id", "")); var print_id := str(print_node.get("node_id", ""))
    for result in [
        service.connect_nodes(graph_id, start_id, "next", print_id, "in", "exec"),
        service.connect_nodes(graph_id, left_id, "value", add_id, "a", "data"),
        service.connect_nodes(graph_id, right_id, "value", add_id, "b", "data"),
        service.connect_nodes(graph_id, add_id, "value", print_id, "value", "data")
    ]:
        if not result.get("ok", false):
            _fail("Phase 8 capture could not connect graph nodes: %s" % str(result.get("errors", [])))
            return
    await _settle()
    await _capture("01-visual-scripting-graph")
    if not toolbar.call("select_node", print_id):
        _fail("Phase 8 capture could not select debugger node.")
        return
    toolbar.call("_toggle_breakpoint")
    toolbar.call("_run_graph")
    await _settle()
    var debug_state: Dictionary = toolbar.call("get_debugger").get_state()
    if debug_state.get("status") != "paused" or str(debug_state.get("node_id", "")) != print_id:
        _fail("Phase 8 capture debugger did not pause on the expected breakpoint.")
        return
    await _capture("02-debugger-paused")
    print("PASS: Phase 8 rendered screenshots captured.")
    quit(0)

func _settle() -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw

func _capture(file_stem: String) -> void:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("Rendered Phase 8 image is empty for %s." % file_stem)
        return
    var output_file := "%s/%s.png" % [OUTPUT_DIR, file_stem]
    var save_error := image.save_png(ProjectSettings.globalize_path(output_file))
    if save_error != OK:
        _fail("Unable to save %s: %s" % [output_file, save_error])

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
