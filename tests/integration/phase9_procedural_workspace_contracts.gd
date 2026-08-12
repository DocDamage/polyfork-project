extends Node

const StableId = preload("res://src/world/stable_id.gd")
const MAIN_SCENE := "res://src/main/Main.tscn"


func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var old_root: Variant = ProjectSettings.get_setting("playworld/storage/projects_root", null)
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://tests/phase9_workspace_%s" % StableId.generate())
    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null:
        _restore_root(old_root)
        return ["Phase 9 workspace suite must load the real Main scene."]
    var app = packed.instantiate()
    add_child(app)
    var home := app.get_node_or_null("HomeScreen") as Control
    var new_world := app.get_node_or_null("NewWorldScreen") as Control
    var workspace := app.get_node_or_null("WorkspaceScreen") as Control
    if home == null or new_world == null or workspace == null:
        errors.append("Phase 9 workspace requires the real app screens.")
    else:
        home.emit_signal("route_requested", &"new_world")
        new_world.emit_signal("create_requested", {"title": "Phase 9 Workspace", "world_profile": "small", "template_id": "blank_sandbox"})
        if not workspace.visible:
            errors.append("Phase 9 workspace must enter the real project workspace.")
        else:
            _check_workspace(app, workspace, errors)
    app.queue_free()
    _restore_root(old_root)
    return errors


func _check_workspace(app: Control, workspace: Control, errors: Array[String]) -> void:
    var layer = app.call("get_procedural_workspace")
    var foliage_button := workspace.find_child("FoliageButton", true, false) as Button
    var roads_button := workspace.find_child("RoadsButton", true, false) as Button
    if layer == null or foliage_button == null or roads_button == null:
        errors.append("Real workspace must expose Foliage/Roads dock entries and the Phase 9 Procedural layer.")
        return
    var service = layer.call("get_service")
    var runtime = layer.call("get_runtime")
    var panel = layer.call("get_panel")
    if service == null or runtime == null or panel == null:
        errors.append("Procedural workspace must bind project service, derived runtime, and panel.")
        return

    foliage_button.emit_signal("pressed")
    if not layer.call("is_open") or panel.call("get_section") != &"foliage":
        errors.append("Foliage dock entry must open the shared Procedural panel in foliage mode.")
        return
    var new_grass := _button(panel, "New Grass")
    var new_scatter := _button(panel, "New Scatter")
    if new_grass == null or new_scatter == null:
        errors.append("Foliage mode must expose foliage-set and scatter-layer creation controls.")
        return
    new_grass.emit_signal("pressed")
    new_scatter.emit_signal("pressed")
    if service.get_foliage_sets().size() != 1 or service.get_scatter_layers().size() != 1:
        errors.append("Procedural panel creation controls must author project-managed foliage/scatter data.")

    var apply := InputEventJoypadButton.new()
    apply.button_index = JOY_BUTTON_A
    apply.pressed = true
    layer.call("_unhandled_input", apply)
    var painted_count: int = runtime.total_instance_count()
    if painted_count <= 0:
        errors.append("Gamepad A in foliage mode must apply paint at the procedural cursor and generate MultiMesh foliage.")
    var toggle := InputEventJoypadButton.new()
    toggle.button_index = JOY_BUTTON_X
    toggle.pressed = true
    layer.call("_unhandled_input", toggle)
    layer.call("_unhandled_input", apply)
    if runtime.total_instance_count() != 0:
        errors.append("Gamepad X must toggle Paint/Erase and A must apply the erase mask at the same cursor.")
    if not workspace.call("undo_edit").get("ok", false):
        errors.append("Universal workspace Undo must undo procedural erase authoring.")
    elif runtime.total_instance_count() != painted_count:
        errors.append("Undoing a procedural erase through the real workspace must regenerate the prior foliage result.")

    roads_button.emit_signal("pressed")
    if not layer.call("is_open") or panel.call("get_section") != &"splines":
        errors.append("Roads dock entry must switch the shared Procedural panel to spline mode.")
    var new_road := _button(panel, "New Road")
    if new_road == null:
        errors.append("Spline mode must expose two-point road creation.")
    else:
        new_road.emit_signal("pressed")
        layer.call("_unhandled_input", apply)
        var right := InputEventJoypadButton.new()
        right.button_index = JOY_BUTTON_DPAD_RIGHT
        right.pressed = true
        layer.call("_unhandled_input", right)
        layer.call("_unhandled_input", apply)
        if service.get_splines().size() != 1:
            errors.append("Gamepad D-pad + A must complete command-backed two-point road creation.")
        else:
            var spline_id: String = str(service.get_splines()[0].get("spline_id", ""))
            if runtime.get_spline_nodes(spline_id).is_empty():
                errors.append("Road creation through the real workspace must generate derived spline geometry.")

    var terrain_button := workspace.find_child("TerrainButton", true, false) as Button
    var terrain_layer = app.call("get_terrain_workspace")
    if terrain_button != null:
        terrain_button.emit_signal("pressed")
        if layer.call("is_open") or terrain_layer == null or not terrain_layer.call("is_open"):
            errors.append("Switching from Procedural to Terrain must close Procedural and preserve contextual-tool exclusivity.")
        terrain_layer.call("close_tool")

    foliage_button.emit_signal("pressed")
    var cancel := InputEventAction.new()
    cancel.action = &"ui_cancel"
    cancel.pressed = true
    app.call("_unhandled_input", cancel)
    if layer.call("is_open") or not workspace.visible:
        errors.append("Back/Cancel must close Procedural before leaving the real workspace.")


func _button(root: Node, text: String) -> Button:
    for node in root.find_children("*", "Button", true, false):
        var button := node as Button
        if button != null and button.text == text: return button
    return null


func _restore_root(old_root: Variant) -> void:
    if old_root == null: ProjectSettings.set_setting("playworld/storage/projects_root", null)
    else: ProjectSettings.set_setting("playworld/storage/projects_root", old_root)
