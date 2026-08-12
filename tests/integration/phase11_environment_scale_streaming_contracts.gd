extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const TerrainRepository = preload("res://src/terrain/terrain_repository.gd")
const EnvironmentContracts = preload("res://src/environment/environment_contracts.gd")
const EnvironmentEvaluator = preload("res://src/environment/environment_evaluator.gd")
const EnvironmentRuntime = preload("res://src/environment/environment_runtime.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new()
    project.initialize_new("Phase 11 Scale", &"large", "blank_sandbox")
    var terrain_result: Dictionary = TerrainRepository.new("user://phase11-scale-%d" % Time.get_ticks_usec()).open_or_create(project)
    if not terrain_result.get("ok", false): return ["Phase 11 scale test requires a valid large-world terrain state."]
    var terrain_state = terrain_result.get("state")
    var document: Dictionary = EnvironmentContracts.empty_document(str(project.project_id))
    var profile_ids: Array[String] = [str(document["weather_profiles"][0]["weather_profile_id"])]
    for index in range(1, 256):
        var profile: Dictionary = document["weather_profiles"][0].duplicate(true)
        var profile_id := StableId.generate()
        profile["weather_profile_id"] = profile_id
        profile["display_name"] = "Profile %03d" % index
        profile["wind_speed_mps"] = float(index % 30)
        profile["fog_density"] = float(index % 20) / 1000.0
        profile["cloud_coverage"] = float(index % 100) / 100.0
        document["weather_profiles"].append(profile)
        profile_ids.append(profile_id)
    for index in range(64):
        document["water_hooks"].append({
            "water_hook_id": StableId.generate(),
            "display_name": "Water %02d" % index,
            "provider_key": "scale.water.%d" % index,
            "settings": {"index": index},
            "tags": ["scale"],
        })
    for index in range(768):
        document["biome_overrides"].append({
            "override_id": StableId.generate(),
            "biome_id": StableId.generate(),
            "weather_profile_id": profile_ids[index % profile_ids.size()],
            "time_offset_hours": float(index % 24),
            "wind_multiplier": 0.5 + float(index % 5) * 0.25,
            "fog_density_multiplier": 0.5 + float(index % 3) * 0.5,
            "water_hook_ids": [],
        })
    var start_us := Time.get_ticks_usec()
    var validation: Array[String] = EnvironmentContracts.validate_document(document)
    var validation_ms := float(Time.get_ticks_usec() - start_us) / 1000.0
    if not validation.is_empty(): errors.append("Representative Phase 11 scale document must validate: %s" % str(validation.slice(0, mini(3, validation.size()))))
    if validation_ms > 2500.0: errors.append("Phase 11 schema validation exceeded the representative 2.5s scale budget: %.1fms" % validation_ms)

    var profile: Dictionary = document["weather_profiles"][200]
    start_us = Time.get_ticks_usec()
    var deterministic: Dictionary = {}
    for index in range(4096):
        deterministic = EnvironmentEvaluator.evaluate(profile, float(index % 96) / 4.0, document["authored_state"], {})
        if not deterministic.get("ok", false): break
    var evaluation_ms := float(Time.get_ticks_usec() - start_us) / 1000.0
    if not deterministic.get("ok", false): errors.append("Environment evaluator must remain valid under repeated scale evaluation.")
    if evaluation_ms > 2500.0: errors.append("4096 deterministic environment evaluations exceeded the representative 2.5s budget: %.1fms" % evaluation_ms)

    var cells: Array[Dictionary] = terrain_state.all_cells()
    if cells.size() < 2: errors.append("Large-world Phase 11 streaming test requires multiple Phase 5 cells.")
    else:
        var base_biome: Dictionary = terrain_state.get_biome(terrain_state.biome_ids()[0])
        var coupled_document: Dictionary = EnvironmentContracts.empty_document(str(project.project_id))
        var default_profile: Dictionary = coupled_document["weather_profiles"][0]
        for index in range(mini(cells.size(), 12)):
            var biome_id := StableId.generate()
            var biome: Dictionary = base_biome.duplicate(true)
            biome["biome_id"] = biome_id
            biome["display_name"] = "Streaming Biome %02d" % index
            terrain_state.biome_registry["biomes"].append(biome)
            var cell: Dictionary = cells[index]
            cell["biome_id"] = biome_id
            var set_result: Dictionary = terrain_state.set_cell(cell, false)
            if not set_result.get("ok", false): errors.append("Streaming scale fixture could not assign a biome to a Phase 5 cell.")
            var weather: Dictionary = default_profile.duplicate(true)
            var weather_id := StableId.generate()
            weather["weather_profile_id"] = weather_id
            weather["display_name"] = "Cell Weather %02d" % index
            weather["wind_speed_mps"] = float(index + 1)
            coupled_document["weather_profiles"].append(weather)
            coupled_document["biome_overrides"].append({"override_id": StableId.generate(), "biome_id": biome_id, "weather_profile_id": weather_id, "time_offset_hours": 0.0, "wind_multiplier": 1.0, "fog_density_multiplier": 1.0, "water_hook_ids": []})
        var runtime = EnvironmentRuntime.new()
        var init: Dictionary = runtime.initialize(coupled_document, terrain_state, null, false)
        if not init.get("ok", false): errors.append("Streaming-aware environment runtime must initialize against a large Phase 5 world.")
        else:
            var cell_size: float = float(terrain_state.manifest.get("cell_size_m", 1024.0))
            for index in range(mini(cells.size(), 12)):
                var coord: Array = terrain_state.manifest.get("cells", [])[index].get("coord", [])
                if coord.size() != 2: continue
                var focus := Vector3(float(coord[0]) * cell_size, 0.0, float(coord[1]) * cell_size)
                var result: Dictionary = runtime.advance(0.0, focus)
                if not result.get("ok", false):
                    errors.append("Environment runtime failed while moving streaming focus between authored cells.")
                    break
                var state: Dictionary = runtime.get_evaluated_state()
                if str(state.get("cell_id", "")) != str(cells[index].get("cell_id", "")):
                    errors.append("Environment runtime must resolve the Phase 5 cell at each streamed-world focus.")
                    break
                if not str(state.get("weather_display_name", "")).begins_with("Cell Weather"):
                    errors.append("Environment runtime must switch deterministic biome weather as streamed-world focus crosses cells.")
                    break
        runtime.free()
    return errors
