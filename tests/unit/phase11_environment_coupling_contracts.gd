extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const TerrainRepository = preload("res://src/terrain/terrain_repository.gd")
const EnvironmentContracts = preload("res://src/environment/environment_contracts.gd")
const EnvironmentRuntime = preload("res://src/environment/environment_runtime.gd")
const ProceduralRuntime = preload("res://src/procedural/procedural_runtime.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new()
    project.initialize_new("Phase 11 Coupling", &"small", "blank_sandbox")
    var project_dir := "user://phase11-coupling-%d" % Time.get_ticks_usec()
    var terrain_repo = TerrainRepository.new(project_dir)
    var terrain_result := terrain_repo.open_or_create(project)
    if not terrain_result.get("ok", false): return ["Phase 11 coupling requires valid Phase 5 terrain state: %s" % str(terrain_result.get("errors", []))]
    var terrain_state = terrain_result.get("state")
    var biome_ids: Array[String] = terrain_state.biome_ids()
    if biome_ids.is_empty(): return ["Phase 5 terrain must expose biome IDs to Phase 11."]
    var biome_id := biome_ids[0]

    var document := EnvironmentContracts.empty_document(str(project.project_id))
    var default_profile: Dictionary = document["weather_profiles"][0].duplicate(true)
    var windy_id := StableId.generate()
    var windy := default_profile.duplicate(true)
    windy["weather_profile_id"] = windy_id
    windy["display_name"] = "Windy"
    windy["wind_speed_mps"] = 12.0
    windy["fog_density"] = 0.01
    document["weather_profiles"].append(windy)
    var water_id := StableId.generate()
    document["water_hooks"].append({"water_hook_id": water_id, "display_name": "Ocean Provider", "provider_key": "basic_plane", "settings": {"size": 80.0, "height": 0.0, "roughness": 0.18}, "tags": ["ocean"]})
    document["biome_overrides"].append({"override_id": StableId.generate(), "biome_id": biome_id, "weather_profile_id": windy_id, "time_offset_hours": 1.0, "wind_multiplier": 2.0, "fog_density_multiplier": 0.5, "water_hook_ids": [water_id]})
    var validation := EnvironmentContracts.validate_document(document)
    if not validation.is_empty(): return ["Coupled environment document must validate: %s" % str(validation)]

    var procedural = ProceduralRuntime.new()
    var runtime = EnvironmentRuntime.new()
    var init := runtime.initialize(document, terrain_state, procedural, false)
    if not init.get("ok", false): errors.append("Coupled environment runtime must initialize: %s" % str(init.get("errors", [])))
    var evaluated := runtime.get_evaluated_state()
    if str(evaluated.get("biome_id", "")) != biome_id: errors.append("Environment runtime must resolve the Phase 5 biome at its streaming focus.")
    if str(evaluated.get("weather_profile_id", "")) != windy_id: errors.append("Environment-owned biome weather override must take precedence over the authored default.")
    if float(runtime.get_wind_state().get("speed_mps", 0.0)) != 24.0: errors.append("Biome wind multipliers must feed the reusable environment wind state.")
    if float(procedural.get_environment_wind().get("speed_mps", 0.0)) != 24.0: errors.append("Phase 9 procedural runtime must consume Phase 11 wind without mutating authored foliage.")
    var water := runtime.get_water_state()
    if water.get("water_hooks", []).size() != 1: errors.append("Biome environment coupling must expose stable water integration hooks.")
    var water_snapshot := runtime.get_water_runtime_snapshot()
    if int(water_snapshot.get("count", 0)) != 1: errors.append("Biome environment coupling must materialize its supported water provider.")

    var fallback_document := document.duplicate(true)
    fallback_document["biome_overrides"] = []
    var biome_registry: Dictionary = terrain_state.biome_registry.duplicate(true)
    var missing_profile_id := StableId.generate()
    for index in range(biome_registry.get("biomes", []).size()):
        if str(biome_registry["biomes"][index].get("biome_id", "")) == biome_id:
            biome_registry["biomes"][index]["future_defaults"]["environment_profile_id"] = missing_profile_id
    terrain_state.biome_registry = biome_registry
    var fallback_runtime = EnvironmentRuntime.new()
    var fallback := fallback_runtime.initialize(fallback_document, terrain_state, null, false)
    if not fallback.get("ok", false): errors.append("Missing terrain biome environment references must fail safely to the authored default.")
    elif fallback_runtime.get_last_warning().is_empty(): errors.append("Missing terrain biome environment references must surface a safe warning.")
    elif fallback_runtime.get_active_weather_profile_id() != str(fallback_document["authored_state"]["default_weather_profile_id"]): errors.append("Missing biome environment references must resolve to the authored default profile.")

    runtime.free()
    fallback_runtime.free()
    procedural.free()
    return errors
