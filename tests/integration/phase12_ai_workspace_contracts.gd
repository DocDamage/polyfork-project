extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const MAIN_SCENE := "res://src/main/Main.tscn"

static func run_checks(tree_root: Node) -> Array[String]:
    var errors: Array[String] = []
    var old_root: Variant = ProjectSettings.get_setting("playworld/storage/projects_root", null)
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://tests/phase12/workspace-%s" % StableId.generate())
    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null:
        _restore_root(old_root)
        return ["Phase 12 workspace suite must load the real Main scene."]
    var app = packed.instantiate(); tree_root.add_child(app)
    var home := app.get_node_or_null("HomeScreen") as Control
    var new_world := app.get_node_or_null("NewWorldScreen") as Control
    var workspace := app.get_node_or_null("WorkspaceScreen") as Control
    if home == null or new_world == null or workspace == null:
        errors.append("Phase 12 workspace requires the real app screens.")
    else:
        home.emit_signal("route_requested", &"new_world")
        new_world.emit_signal("create_requested", {"title": "Phase 12 AI Workspace", "world_profile": "small", "template_id": "blank_sandbox"})
        if not workspace.visible: errors.append("Phase 12 workspace must enter the real project workspace.")
        else: _check_workspace(app, workspace, errors)
    app.queue_free(); _restore_root(old_root)
    return errors

static func _check_workspace(app: Control, workspace: Control, errors: Array[String]) -> void:
    var layer = app.call("get_ai_workspace")
    var ai_button := workspace.find_child("AIButton", true, false) as Button
    if layer == null or ai_button == null:
        errors.append("Real workspace must expose the existing AI dock entry and the Phase 12 AI layer.")
        return
    var service = layer.call("get_service"); var panel = layer.call("get_panel")
    if service == null or panel == null: errors.append("AI workspace must bind its real creation service and panel."); return
    ai_button.emit_signal("pressed")
    if not layer.call("is_open") or not panel.visible: errors.append("Existing AI dock entry must open the native Phase 12 panel.")

    var provider: Dictionary = {"provider_id": "workspace-local", "display_name": "Workspace Local", "protocol": "openai_compatible_chat_v1", "scope": "local", "endpoint": "http://127.0.0.1:11434/v1/chat/completions", "model": "workspace-model", "credential_env": "", "timeout_seconds": 10.0, "enabled": true}
    panel.emit_signal("provider_saved", provider)
    var registry = service.call("get_provider_registry")
    if registry == null or registry.get_providers().is_empty(): errors.append("AI panel provider controls must persist user-scoped provider metadata.")
    elif str(registry.get_active_provider_descriptor().get("provider_id", "")) != "workspace-local": errors.append("Saving a provider through the AI panel must make it active.")

    panel.emit_signal("privacy_changed", {"local_only": false})
    panel.emit_signal("privacy_changed", {"cloud_consent": true})
    var privacy: Dictionary = registry.get_privacy_policy()
    if bool(privacy.get("local_only", true)) or not bool(privacy.get("cloud_consent", false)): errors.append("AI workspace privacy controls must update user-scoped policy.")
    panel.emit_signal("privacy_changed", {"local_only": true, "cloud_consent": false})

    var before_configuration: Dictionary = workspace.call("get_configuration")
    var preview_shortcut := InputEventJoypadButton.new(); preview_shortcut.button_index = JOY_BUTTON_X; preview_shortcut.pressed = true
    if not panel.call("handle_shortcut", preview_shortcut): errors.append("AI workspace must consume its documented gamepad X Preview shortcut.")
    if workspace.call("get_configuration") != before_configuration: errors.append("A rejected/empty gamepad Preview request must not mutate authored Build state.")

    var terrain_button := workspace.find_child("TerrainButton", true, false) as Button
    var terrain_layer = app.call("get_terrain_workspace")
    if terrain_button != null:
        terrain_button.emit_signal("pressed")
        if layer.call("is_open") or terrain_layer == null or not terrain_layer.call("is_open"): errors.append("Switching from AI to Terrain must preserve contextual-tool exclusivity.")
        terrain_layer.call("close_tool")

    ai_button.emit_signal("pressed")
    var mode_switch = workspace.find_child("ModeSwitch", true, false)
    if mode_switch == null: errors.append("Phase 12 workspace could not resolve Build/Play switch.")
    else:
        mode_switch.call("set_mode", &"play")
        if workspace.call("get_mode") != &"play": errors.append("Phase 12 workspace must preserve the existing Play transition.")
        if layer.call("is_open"): errors.append("Entering Play must close AI authoring so providers cannot write during Play.")
        mode_switch.call("set_mode", &"build")

    ai_button.emit_signal("pressed")
    var cancel := InputEventAction.new(); cancel.action = &"ui_cancel"; cancel.pressed = true
    app.call("_unhandled_input", cancel)
    if layer.call("is_open") or not workspace.visible: errors.append("Back/Cancel must close AI before leaving the real workspace.")

static func _restore_root(old_root: Variant) -> void:
    if old_root == null: ProjectSettings.set_setting("playworld/storage/projects_root", null)
    else: ProjectSettings.set_setting("playworld/storage/projects_root", old_root)
