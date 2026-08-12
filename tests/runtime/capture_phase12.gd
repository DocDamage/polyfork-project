extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const OUTPUT_DIR := "res://artifacts/phase12"
const StableId = preload("res://src/world/stable_id.gd")
const AiContracts = preload("res://src/ai/ai_contracts.gd")
const PreviewService = preload("res://src/ai/ai_preview_service.gd")

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS: _fail("Unable to create Phase 12 screenshot directory."); return
    root.size = Vector2i(1600, 900)
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://phase12_visual_%s" % StableId.generate())
    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null: _fail("Unable to load Main.tscn for Phase 12 capture."); return
    var app = packed.instantiate(); root.add_child(app); await _settle()
    app.call("_on_new_world_create_requested", {"title": "Phase 12 AI Creation", "world_profile": "small", "template_id": "blank_sandbox"}); await _settle()
    var workspace = app.get_node_or_null("WorkspaceScreen")
    if workspace == null or not workspace.visible: _fail("Phase 12 capture could not enter the real workspace."); return
    var ai_button := workspace.find_child("AIButton", true, false) as Button
    var layer = app.call("get_ai_workspace")
    if ai_button == null or layer == null: _fail("Phase 12 capture could not resolve the AI dock/layer."); return
    ai_button.emit_signal("pressed"); await _settle()
    var service = layer.call("get_service"); var panel = layer.call("get_panel")
    if service == null or panel == null or not layer.call("is_open"): _fail("Phase 12 capture could not open the real AI workspace."); return
    panel.emit_signal("provider_saved", {"provider_id": "visual-local", "display_name": "Local AI", "protocol": "openai_compatible_chat_v1", "scope": "local", "endpoint": "http://127.0.0.1:11434/v1/chat/completions", "model": "local-model", "credential_env": "", "timeout_seconds": 45.0, "enabled": true})
    var prompt := panel.find_child("*", "TextEdit", true, false) as TextEdit
    if prompt != null: prompt.text = "Create a playable landmark and make the world feel like dusk."
    var proposal: Dictionary = AiContracts.new_proposal(StableId.generate(), "Create a dusk landmark with safe existing systems", [
        _action("entity.place_proxy", {"display_name": "AI Landmark", "position": [2.0, 0.5, 2.0], "scale": [1.8, 2.8, 1.8], "result_ref": "landmark"}),
        _action("environment.configure", {"patch": {"time_of_day_hours": 18.5, "fog_enabled": true}}),
    ])
    var previewer = PreviewService.new(); previewer.bind(service.call("get_query_service"), service.call("get_action_registry"))
    var preview: Dictionary = previewer.preview(proposal)
    if not preview.get("ok", false): _fail("Phase 12 capture Preview validation failed: %s" % preview.get("errors", [])); return
    panel.call("show_result", {"ok": true, "mode": "preview", "proposal": proposal, "preview": preview, "executable": true})
    panel.call("set_status", "Preview validated • local provider • no Build mutation", false)
    await _settle(); await _capture("01-ai-preview")

    var executor = service.get("_execution_service")
    var execute: Dictionary = executor.execute(proposal, "visual-local", "visual evidence", false)
    if not execute.get("ok", false): _fail("Phase 12 capture Execute failed: %s" % execute.get("errors", [])); return
    panel.call("show_result", {"ok": true, "mode": "execute", "proposal": proposal, "preview": preview, "execution_id": execute.get("execution_id", "")})
    panel.call("set_status", "Executed • one universal Undo step • Build data authoritative", false)
    await _settle(); await _capture("02-ai-executed")

    var undo: Dictionary = workspace.call("undo_edit")
    if not undo.get("ok", false): _fail("Phase 12 capture could not Undo AI Execute."); return
    panel.call("show_result", {"ok": true, "mode": "preview", "proposal": proposal, "preview": preview, "executable": true})
    panel.call("set_status", "Undo restored the complete AI transaction", false)
    await _settle(); await _capture("03-ai-undo-restored")
    print("PASS: Phase 12 rendered screenshots captured."); quit(0)

func _settle() -> void:
    await process_frame; await process_frame; await physics_frame; await RenderingServer.frame_post_draw

func _capture(file_stem: String) -> void:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    if image == null or image.is_empty(): _fail("Rendered Phase 12 image is empty for %s." % file_stem); return
    var output_file := "%s/%s.png" % [OUTPUT_DIR, file_stem]
    var save_error := image.save_png(ProjectSettings.globalize_path(output_file))
    if save_error != OK: _fail("Unable to save %s: %s" % [output_file, save_error])

func _fail(message: String) -> void:
    push_error(message); quit(1)

static func _action(type_name: String, arguments: Dictionary) -> Dictionary:
    return {"action_id": StableId.generate(), "type": type_name, "arguments": arguments, "reason": "Phase 12 rendered evidence"}
