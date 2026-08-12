extends Node

const StableId = preload("res://src/world/stable_id.gd")
const RuntimeAttachmentResolver = preload("res://src/gameplay/runtime_attachment_resolver.gd")
const MAIN_SCENE := "res://src/main/Main.tscn"


func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var old_root: Variant = ProjectSettings.get_setting("playworld/storage/projects_root", null)
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://tests/phase6_runtime_%s" % StableId.generate())
    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null:
        errors.append("Phase 6 runtime smoke must load the real Main scene.")
        _restore_root(old_root); return errors
    var main_instance := packed.instantiate()
    add_child(main_instance)
    var home := main_instance.get_node_or_null("HomeScreen") as Control
    var new_world := main_instance.get_node_or_null("NewWorldScreen") as Control
    var workspace := main_instance.get_node_or_null("WorkspaceScreen") as Control
    if home == null or new_world == null or workspace == null:
        errors.append("Phase 6 runtime smoke requires the real app screens.")
        main_instance.queue_free(); _restore_root(old_root); return errors
    home.emit_signal("route_requested", &"new_world")
    new_world.emit_signal("create_requested", {"title": "Phase 6 Runtime", "world_profile": "small", "template_id": "blank_sandbox"})
    if not workspace.visible: errors.append("Phase 6 runtime smoke must enter the real workspace.")
    else: _check_workspace(main_instance, workspace, errors)
    main_instance.queue_free(); _restore_root(old_root)
    return errors


func _check_workspace(main_instance: Control, workspace: Control, errors: Array[String]) -> void:
    var layer = main_instance.call("get_gameplay_workspace")
    var gameplay_button := workspace.find_child("GameplayButton", true, false) as Button
    if layer == null or gameplay_button == null:
        errors.append("Real workspace must expose the Phase 6 Gameplay layer and dock entry."); return
    var service = layer.call("get_service"); var panel = layer.call("get_panel")
    if service == null or panel == null or service.get_definitions().size() != 21 or service.get_archetypes().size() != 9:
        errors.append("Gameplay workspace must bind the complete component and archetype registries."); return

    var begin: Dictionary = workspace.call("begin_proxy_placement", "Gameplay Runtime Object")
    if not begin.get("ok", false): errors.append("Gameplay smoke must begin a real Phase 3 placement."); return
    workspace.call("update_placement_preview", Vector3(1.0, 0.5, 1.0))
    var placed: Dictionary = workspace.call("commit_placement")
    var original_id := str(placed.get("entity_id", ""))
    if original_id.is_empty(): errors.append("Gameplay smoke must commit a real selected entity."); return

    gameplay_button.emit_signal("pressed")
    if not layer.call("is_open") or not panel.visible:
        errors.append("Gameplay dock button must open the contextual composition panel."); return

    var gamepad_x := InputEventJoypadButton.new(); gamepad_x.button_index = JOY_BUTTON_X; gamepad_x.pressed = true
    layer.call("_unhandled_input", gamepad_x)
    if service.components_for_entity(original_id).size() != 1:
        errors.append("Gamepad X must add the selected component through the real Gameplay layer.")

    var gamepad_y := InputEventJoypadButton.new(); gamepad_y.button_index = JOY_BUTTON_Y; gamepad_y.pressed = true
    layer.call("_unhandled_input", gamepad_y)
    if service.components_for_entity(original_id).size() < 5:
        errors.append("Gamepad Y must apply the selected archetype while preserving the existing component.")

    var socket_name := _line_edit(panel, "Socket name")
    var add_socket := _button(panel, "Add Socket")
    if socket_name == null or add_socket == null or add_socket.focus_mode != Control.FOCUS_ALL:
        errors.append("Gameplay socket controls must remain native focusable editor controls.")
    else:
        socket_name.text = "Grip"
        add_socket.emit_signal("pressed")
        if service.sockets_for_entity(original_id).size() != 1:
            errors.append("Native Gameplay controls must add a stable entity socket.")

    var prefab_name := _line_edit(panel, "Prefab name")
    var save_prefab := _button(panel, "Save Prefab")
    if prefab_name == null or save_prefab == null or save_prefab.focus_mode != Control.FOCUS_ALL:
        errors.append("Gameplay prefab save must remain a native keyboard/gamepad-focusable action.")
        return
    prefab_name.text = "Runtime Prefab"
    save_prefab.emit_signal("pressed")
    if service.get_prefabs().size() != 1:
        errors.append("Gameplay panel must save the selected configured object as one managed prefab."); return
    var prefab: Dictionary = service.get_prefabs()[0]
    if prefab.get("socket_ids", []).size() != 1:
        errors.append("Saved prefab must capture the selected object's named socket.")

    var before_count: int = workspace.call("get_runtime_entity_count")
    var place_prefab := _button(panel, "Place Prefab")
    if place_prefab == null: errors.append("Gameplay panel must expose prefab placement."); return
    place_prefab.emit_signal("pressed")
    var spawned_id: String = workspace.call("get_selected_entity_id")
    if spawned_id.is_empty() or spawned_id == original_id or workspace.call("get_runtime_entity_count") != before_count + 1:
        errors.append("Native prefab placement must instantiate and select a fresh world entity.")
    if service.sockets_for_entity(spawned_id).size() != 1:
        errors.append("Instantiated prefab must materialize fresh entity-owned sockets.")

    workspace.call("select_entity", original_id); workspace.call("toggle_entity_selection", spawned_id)
    var attach := _button(panel, "Attach 2")
    if attach == null or attach.disabled:
        errors.append("Exactly two selected socket-capable objects must enable the contextual Attach action.")
    else:
        attach.emit_signal("pressed")
        var attachments: Array[Dictionary] = service.get_attachments()
        if attachments.size() != 1:
            errors.append("Gameplay panel must author a stable socket attachment between two selected entities.")
        else:
            var authored_child_id := str(attachments[0].get("child_entity_id", ""))
            var runtime_child = workspace.call("get_runtime_entity_node", authored_child_id)
            if runtime_child == null or runtime_child.get_parent() == null or not runtime_child.get_parent().has_meta(RuntimeAttachmentResolver.ANCHOR_META):
                errors.append("Real workspace attachment must resolve the authored child through a transient runtime anchor.")

    var cancel := InputEventAction.new(); cancel.action = &"ui_cancel"; cancel.pressed = true
    main_instance.call("_unhandled_input", cancel)
    if layer.call("is_open") or not workspace.visible:
        errors.append("Cancel must close Gameplay before leaving the workspace.")

    var left_shoulder := InputEventJoypadButton.new(); left_shoulder.button_index = JOY_BUTTON_LEFT_SHOULDER; left_shoulder.pressed = true
    workspace.call("_unhandled_input", left_shoulder)
    if not workspace.call("is_tool_wheel_open"): errors.append("Phase 6 must preserve the Phase 3 left-shoulder tool wheel.")
    else: workspace.call("handle_cancel")

    gameplay_button.emit_signal("pressed")
    var terrain_button := workspace.find_child("TerrainButton", true, false) as Button
    var terrain_layer = main_instance.call("get_terrain_workspace")
    if terrain_button != null:
        terrain_button.emit_signal("pressed")
        if layer.call("is_open") or not terrain_layer.call("is_open"):
            errors.append("Switching from Gameplay to Terrain must close Gameplay and preserve the Phase 5 contextual tool.")
        terrain_button.emit_signal("pressed")
    var assets_button := workspace.find_child("AssetsButton", true, false) as Button
    if assets_button != null:
        assets_button.emit_signal("pressed")
        if not workspace.call("is_asset_drawer_open"): errors.append("Phase 4 Asset Library must remain accessible after Gameplay composition.")
        workspace.call("close_asset_drawer")


func _button(root: Node, text: String) -> Button:
    for node in root.find_children("*", "Button", true, false):
        var button := node as Button
        if button != null and button.text == text: return button
    return null


func _line_edit(root: Node, placeholder: String) -> LineEdit:
    for node in root.find_children("*", "LineEdit", true, false):
        var edit := node as LineEdit
        if edit != null and edit.placeholder_text == placeholder: return edit
    return null


func _restore_root(old_root: Variant) -> void:
    if old_root == null: ProjectSettings.set_setting("playworld/storage/projects_root", null)
    else: ProjectSettings.set_setting("playworld/storage/projects_root", old_root)
