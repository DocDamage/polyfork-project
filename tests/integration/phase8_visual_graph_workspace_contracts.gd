extends Node

const StableId = preload("res://src/world/stable_id.gd")
const MAIN_SCENE := "res://src/main/Main.tscn"

func run_checks() -> Array[String]:
    var errors: Array[String] = []; var old_root: Variant = ProjectSettings.get_setting("playworld/storage/projects_root", null); ProjectSettings.set_setting("playworld/storage/projects_root", "user://tests/phase8_workspace_%s" % StableId.generate())
    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null: _restore_root(old_root); return ["Phase 8 workspace suite must load the real Main scene."]
    var main_instance := packed.instantiate(); add_child(main_instance)
    var home := main_instance.get_node_or_null("HomeScreen") as Control; var new_world := main_instance.get_node_or_null("NewWorldScreen") as Control; var workspace := main_instance.get_node_or_null("WorkspaceScreen") as Control
    if home == null or new_world == null or workspace == null: errors.append("Phase 8 workspace requires the real app screens.")
    else:
        home.emit_signal("route_requested", &"new_world"); new_world.emit_signal("create_requested", {"title":"Phase 8 Workspace","world_profile":"small","template_id":"blank_sandbox"})
        if not workspace.visible: errors.append("Phase 8 workspace must enter the real project workspace.")
        else: _check_workspace(main_instance, workspace, errors)
    main_instance.queue_free(); _restore_root(old_root); return errors

func _check_workspace(main_instance: Control, workspace: Control, errors: Array[String]) -> void:
    var layer = main_instance.call("get_visual_scripting_workspace"); var logic_button := workspace.find_child("MoreButton", true, false) as Button
    if layer == null or logic_button == null or logic_button.text != "Logic": errors.append("Real workspace must expose the Phase 8 Logic dock entry and Visual Scripting layer."); return
    var service = layer.call("get_service"); var panel = layer.call("get_panel")
    if service == null or panel == null: errors.append("Visual Scripting workspace must bind its project-managed graph service."); return
    logic_button.emit_signal("pressed")
    if not layer.call("is_open") or not panel.visible: errors.append("Logic must open the native Visual Scripting panel."); return
    var graph_edit = panel.call("get_graph_edit")
    if not graph_edit is GraphEdit: errors.append("Phase 8 authoring surface must use Godot GraphEdit.")
    var new_event := _button(panel, "New Event"); if new_event == null: errors.append("Visual Scripting panel must expose event graph creation."); return
    new_event.emit_signal("pressed")
    var graph_id := str(panel.call("get_current_graph_id")); var graph: Dictionary = service.get_graph(graph_id)
    if graph.is_empty() or graph.get("nodes", []).size() != 1 or str(graph["nodes"][0].get("type_key", "")) != "event.start": errors.append("New Event must materialize a stable graph with one Start entry node.")
    var print_button := _button_contains(panel, "Print")
    if print_button == null: errors.append("Searchable node palette must expose the built-in Print node.")
    else:
        print_button.emit_signal("pressed"); graph = service.get_graph(graph_id)
        if graph.get("nodes", []).size() != 2: errors.append("Native node palette action must create a command-backed graph node.")
    var before_x: int = graph.get("nodes", []).size(); var gamepad_x := InputEventJoypadButton.new(); gamepad_x.button_index = JOY_BUTTON_X; gamepad_x.pressed = true; layer.call("_unhandled_input", gamepad_x); graph = service.get_graph(graph_id)
    if graph.get("nodes", []).size() != before_x + 1: errors.append("Gamepad X must add the currently selected visual node type.")
    var history: Dictionary = workspace.call("get_history_counts")
    if int(history.get("undo", 0)) < 4: errors.append("Visual Scripting workspace actions must share the universal authoring history.")
    var property_edit := _line_edit(panel, "{}")
    if property_edit == null or property_edit.focus_mode != Control.FOCUS_ALL: errors.append("Visual node property editing must remain a native focusable control.")
    var cancel := InputEventAction.new(); cancel.action = &"ui_cancel"; cancel.pressed = true; main_instance.call("_unhandled_input", cancel)
    if layer.call("is_open") or not workspace.visible: errors.append("Back/Cancel must close Visual Scripting before leaving the workspace.")
    logic_button.emit_signal("pressed"); var gameplay_button := workspace.find_child("GameplayButton", true, false) as Button; var gameplay_layer = main_instance.call("get_gameplay_workspace")
    if gameplay_button != null:
        gameplay_button.emit_signal("pressed")
        if layer.call("is_open") or not gameplay_layer.call("is_open"): errors.append("Switching from Logic to Gameplay must close Visual Scripting and preserve the Phase 6 contextual tool.")

func _button(root: Node, text: String) -> Button:
    for node in root.find_children("*", "Button", true, false):
        var button := node as Button
        if button != null and button.text == text: return button
    return null
func _button_contains(root: Node, text: String) -> Button:
    for node in root.find_children("*", "Button", true, false):
        var button := node as Button
        if button != null and button.text.contains(text): return button
    return null
func _line_edit(root: Node, placeholder: String) -> LineEdit:
    for node in root.find_children("*", "LineEdit", true, false):
        var edit := node as LineEdit
        if edit != null and edit.placeholder_text == placeholder: return edit
    return null
func _restore_root(old_root: Variant) -> void:
    if old_root == null: ProjectSettings.set_setting("playworld/storage/projects_root", null)
    else: ProjectSettings.set_setting("playworld/storage/projects_root", old_root)
