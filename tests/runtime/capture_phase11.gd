extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const OUTPUT_DIR := "res://artifacts/phase11"
const StableId = preload("res://src/world/stable_id.gd")

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS:
        _fail("Unable to create Phase 11 screenshot directory: %s" % make_error); return
    root.size = Vector2i(1600, 900)
    ProjectSettings.set_setting("playworld/storage/projects_root", "user://phase11_visual_%s" % StableId.generate())
    var packed := load(MAIN_SCENE) as PackedScene
    if packed == null: _fail("Unable to load Main.tscn for Phase 11 capture."); return
    var app = packed.instantiate()
    root.add_child(app)
    await _settle()
    app.call("_on_new_world_create_requested", {"title": "Phase 11 Environment World", "world_profile": "medium", "template_id": "blank_sandbox"})
    await _settle()
    var workspace = app.get_node_or_null("WorkspaceScreen")
    var layer = app.call("get_environment_workspace")
    if workspace == null or layer == null or not workspace.visible:
        _fail("Phase 11 capture could not enter the real Environment workspace."); return
    var service = layer.call("get_service")
    if service == null: _fail("Phase 11 capture could not bind the Environment authoring service."); return

    var storm: Dictionary = service.create_weather_profile("Rainfront", {
        "sky_top_color": [0.07, 0.11, 0.21, 1.0],
        "sky_horizon_color": [0.30, 0.39, 0.51, 1.0],
        "ambient_color": [0.42, 0.52, 0.68, 1.0],
        "ambient_energy": 0.48,
        "sun_color": [1.0, 0.72, 0.52, 1.0],
        "sun_energy": 0.8,
        "fog_color": [0.40, 0.48, 0.56, 1.0],
        "fog_density": 0.006,
        "wind_direction": [0.7, 0.0, 0.7],
        "wind_speed_mps": 11.5,
        "wind_gust_strength": 0.7,
        "precipitation": 0.65,
        "cloud_coverage": 0.85,
    })
    if not storm.get("ok", false): _fail("Phase 11 capture could not author Rainfront profile."); return
    var storm_id := str(storm.get("weather_profile_id", ""))
    var config: Dictionary = service.configure_authored_state({"time_of_day_hours": 17.5, "default_weather_profile_id": storm_id, "fog_enabled": true, "wind_enabled": true})
    if not config.get("ok", false): _fail("Phase 11 capture could not configure authored environment state."); return
    var water: Dictionary = service.create_water_hook("Ocean Surface", "environment.water.demo", {"wave_scale": 1.4, "reflection_strength": 0.8}, ["ocean", "demo"])
    if not water.get("ok", false): _fail("Phase 11 capture could not author a representative water hook."); return
    var terrain = app.call("get_terrain_workspace").call("get_controller")
    var biome_ids: Array[String] = terrain.get_state().biome_ids()
    if not biome_ids.is_empty():
        var override: Dictionary = service.set_biome_override(biome_ids[0], {"weather_profile_id": storm_id, "wind_multiplier": 1.15, "fog_density_multiplier": 1.2, "water_hook_ids": [str(water.get("water_hook_id", ""))]})
        if not override.get("ok", false): _fail("Phase 11 capture could not author biome/environment coupling."); return

    var water_button := workspace.find_child("WaterButton", true, false) as Button
    if water_button == null: _fail("Phase 11 capture could not resolve the canonical Water dock entry."); return
    water_button.emit_signal("pressed")
    app.call("_on_workspace_status", "Environment • Rainfront • 17:30 • biome coupled • water hook ready", false)
    await _settle()
    await _capture("01-environment-authoring")

    var mode_switch = workspace.find_child("ModeSwitch", true, false)
    if mode_switch == null: _fail("Phase 11 capture could not resolve Build/Play switch."); return
    mode_switch.call("set_mode", &"play")
    for _index in range(12): await physics_frame
    var play = workspace.call("get_play_session")
    if play == null or not play.call("is_active"):
        _fail("Phase 11 capture could not enter disposable Play environment runtime."); return
    var play_environment = play.call("get_environment_runtime")
    var night: Dictionary = play_environment.call("set_time_of_day", 22.0)
    var weather: Dictionary = play_environment.call("set_weather_profile", storm_id, 0.0)
    if not night.get("ok", false) or not weather.get("ok", false):
        _fail("Phase 11 capture could not evaluate night weather in Play."); return
    app.call("_on_workspace_status", "Play • disposable night weather • Build data isolated", false)
    await _settle()
    await _capture("02-disposable-night-weather-play")

    mode_switch.call("set_mode", &"build")
    await _settle()
    if play.call("is_active") or not layer.call("get_runtime").call("is_rendering_enabled"):
        _fail("Phase 11 capture could not restore authoritative Build environment rendering."); return
    water_button.emit_signal("pressed")
    app.call("_on_workspace_status", "Build restored • authored 17:30 Rainfront remains authoritative", false)
    await _settle()
    await _capture("03-build-environment-restored")
    print("PASS: Phase 11 rendered screenshots captured.")
    quit(0)

func _settle() -> void:
    await process_frame
    await process_frame
    await physics_frame
    await RenderingServer.frame_post_draw

func _capture(file_stem: String) -> void:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    if image == null or image.is_empty(): _fail("Rendered Phase 11 image is empty for %s." % file_stem); return
    var output_file := "%s/%s.png" % [OUTPUT_DIR, file_stem]
    var save_error := image.save_png(ProjectSettings.globalize_path(output_file))
    if save_error != OK: _fail("Unable to save %s: %s" % [output_file, save_error])

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
