extends Node

const StableId = preload("res://src/world/stable_id.gd")
const MAIN_SCENE := "res://src/main/Main.tscn"


func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var old_root: Variant = ProjectSettings.get_setting("playworld/storage/projects_root", null)
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://tests/phase5_runtime_%s" % StableId.generate())
    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null:
        errors.append("Phase 5 runtime smoke must load the real Main scene.")
        _restore_root(old_root); return errors
    var main_instance := packed.instantiate()
    add_child(main_instance)
    var home := main_instance.get_node_or_null("HomeScreen") as Control
    var new_world := main_instance.get_node_or_null("NewWorldScreen") as Control
    var workspace := main_instance.get_node_or_null("WorkspaceScreen") as Control
    if home == null or new_world == null or workspace == null:
        errors.append("Phase 5 runtime smoke requires the real app screens.")
        main_instance.queue_free(); _restore_root(old_root); return errors
    home.emit_signal("route_requested", &"new_world")
    new_world.emit_signal("create_requested", {"title": "Phase 5 Runtime", "world_profile": "medium", "template_id": "blank_sandbox"})
    if not workspace.visible:
        errors.append("Phase 5 runtime smoke must enter the workspace through the real creation flow.")
    else:
        _check_terrain_workspace(main_instance, workspace, errors)
    main_instance.queue_free()
    _restore_root(old_root)
    return errors


func _check_terrain_workspace(main_instance: Control, workspace: Control, errors: Array[String]) -> void:
    var terrain_layer = main_instance.call("get_terrain_workspace")
    var terrain_button := workspace.find_child("TerrainButton", true, false) as Button
    var placement_toolbar := workspace.find_child("PlacementToolbar", true, false) as Control
    var transform_toolbar := workspace.find_child("TransformToolbar", true, false) as Control
    var editor_viewport = workspace.find_child("EditorViewport3D", true, false)
    if terrain_layer == null or terrain_button == null or editor_viewport == null:
        errors.append("Real workspace must expose the Phase 5 terrain layer, dock entry, and viewport.")
        return
    var controller = terrain_layer.call("get_controller")
    if controller == null or controller.get_runtime().chunk_count() != 9:
        errors.append("Medium workspace must bind all nine terrain chunks into the real editor viewport.")
        return
    if editor_viewport.ground.visible:
        errors.append("Phase 5 terrain binding must hide the old proxy ground to avoid overlapping editor surfaces.")

    terrain_button.emit_signal("pressed")
    if not terrain_layer.call("is_open"):
        errors.append("Terrain dock button must open the compact terrain authoring panel.")
        return
    if placement_toolbar != null and placement_toolbar.visible:
        errors.append("Object placement toolbar must hide while contextual terrain authoring is active.")
    if transform_toolbar != null and transform_toolbar.visible:
        errors.append("Object transform toolbar must hide while contextual terrain authoring is active.")
    if not editor_viewport.call("is_terrain_view"):
        errors.append("Opening Terrain must switch the editor camera to the terrain-scale view.")

    var state = controller.get_state()
    var before_cursor: Vector3 = controller.get_brush_state().get("cursor", Vector3.ZERO)
    var right_key := InputEventKey.new()
    right_key.keycode = KEY_RIGHT; right_key.pressed = true
    terrain_layer.call("_unhandled_input", right_key)
    var after_keyboard: Vector3 = controller.get_brush_state().get("cursor", Vector3.ZERO)
    if after_keyboard.x <= before_cursor.x:
        errors.append("Keyboard arrows must move the terrain brush cursor through the real workspace input layer.")

    var cell_id: String = str(controller.get_brush_state().get("cell_id", ""))
    var before_revision: int = int(state.get_cell(cell_id).get("revision", 0))
    var enter := InputEventKey.new()
    enter.keycode = KEY_ENTER; enter.pressed = true
    terrain_layer.call("_unhandled_input", enter)
    if int(state.get_cell(cell_id).get("revision", 0)) <= before_revision:
        errors.append("Keyboard Enter must commit a command-backed terrain brush edit.")

    var dpad_up := InputEventJoypadButton.new()
    dpad_up.button_index = JOY_BUTTON_DPAD_UP; dpad_up.pressed = true
    var before_gamepad: Vector3 = controller.get_brush_state().get("cursor", Vector3.ZERO)
    terrain_layer.call("_unhandled_input", dpad_up)
    var after_gamepad: Vector3 = controller.get_brush_state().get("cursor", Vector3.ZERO)
    if after_gamepad.z >= before_gamepad.z:
        errors.append("Gamepad D-pad must move the terrain brush cursor.")
    var gamepad_cell: String = str(controller.get_brush_state().get("cell_id", ""))
    var revision_before_a: int = int(state.get_cell(gamepad_cell).get("revision", 0))
    var button_a := InputEventJoypadButton.new()
    button_a.button_index = JOY_BUTTON_A; button_a.pressed = true
    terrain_layer.call("_unhandled_input", button_a)
    if int(state.get_cell(gamepad_cell).get("revision", 0)) <= revision_before_a:
        errors.append("Gamepad A must commit the current terrain brush edit.")

    var mode_before: String = str(controller.get_brush_state().get("mode", ""))
    var shoulder_right := InputEventJoypadButton.new()
    shoulder_right.button_index = JOY_BUTTON_RIGHT_SHOULDER; shoulder_right.pressed = true
    terrain_layer.call("_unhandled_input", shoulder_right)
    if str(controller.get_brush_state().get("mode", "")) == mode_before:
        errors.append("Gamepad right shoulder must cycle terrain brush modes.")

    var shoulder_left := InputEventJoypadButton.new()
    shoulder_left.button_index = JOY_BUTTON_LEFT_SHOULDER; shoulder_left.pressed = true
    workspace.call("_unhandled_input", shoulder_left)
    if not workspace.call("is_tool_wheel_open"):
        errors.append("Phase 5 must preserve the Phase 3 left-shoulder controller tool wheel.")
    else:
        workspace.call("handle_cancel")

    if not state.has_dirty_cells():
        errors.append("Committed terrain workspace edits must remain dirty until terrain persistence runs.")
    var save_result: Dictionary = terrain_layer.call("advance", 2.1)
    if not save_result.get("attempted", false) or not save_result.get("ok", false) or state.has_dirty_cells():
        errors.append("Terrain workspace autosave must incrementally flush dirty cells after its interval.")

    terrain_button.emit_signal("pressed")
    if terrain_layer.call("is_open"):
        errors.append("Terrain dock button must toggle the contextual terrain authoring panel closed.")
    var assets_button := workspace.find_child("AssetsButton", true, false) as Button
    if assets_button != null:
        assets_button.emit_signal("pressed")
        if not workspace.call("is_asset_drawer_open"):
            errors.append("Phase 4 Asset Library must remain accessible after using the Phase 5 terrain tool.")
        workspace.call("close_asset_drawer")


func _restore_root(old_root: Variant) -> void:
    if old_root == null: ProjectSettings.set_setting("playworld/storage/projects_root", null)
    else: ProjectSettings.set_setting("playworld/storage/projects_root", old_root)
