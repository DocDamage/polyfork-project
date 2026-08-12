extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const ProjectRepository = preload("res://src/world/project_repository.gd")
const TerrainRepository = preload("res://src/terrain/terrain_repository.gd")
const GameplayRepository = preload("res://src/gameplay/gameplay_repository.gd")
const VisualRepository = preload("res://src/visual_scripting/visual_graph_repository.gd")
const ProceduralRepository = preload("res://src/procedural/procedural_repository.gd")
const EnvironmentRepository = preload("res://src/environment/environment_repository.gd")
const StagingService = preload("res://src/export/export_staging_service.gd")
const StandaloneLoader = preload("res://src/export/runtime/standalone_data_loader.gd")
const Profiles = preload("res://src/scale/performance_profiles.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var root: String = "user://tests/phase14/export-%s" % StableId.generate()
    var repository = ProjectRepository.new(root.path_join("projects"))
    var create_result: Dictionary = repository.create_project("Phase 14 Export", &"small", "blank_sandbox")
    if not create_result.get("ok", false): return ["Phase 14 export fixture project must be created."]
    var project = create_result.get("project")
    var project_directory: String = repository.get_project_directory(str(project.project_id))
    var subsystem_results: Array[Dictionary] = [
        TerrainRepository.new(project_directory).open_or_create(project),
        GameplayRepository.new(project_directory).open_or_create(project),
        VisualRepository.new(project_directory).open_or_create(project),
        ProceduralRepository.new(project_directory).open_or_create(project),
        EnvironmentRepository.new(project_directory).open_or_create(project),
    ]
    for result in subsystem_results:
        if not result.get("ok", false): errors.append("Phase 14 export fixture subsystem failed: %s" % str(result.get("errors", [])))
    if not errors.is_empty(): return errors
    var save_result: Dictionary = repository.save_project(project)
    if not save_result.get("ok", false): return ["Phase 14 export fixture must save."]

    var profile: Dictionary = Profiles.get_profile(Profiles.HIGH)
    var stage_root: String = root.path_join("stage-high")
    var build_id: String = StableId.generate()
    var staging = StagingService.new()
    var first: Dictionary = staging.assemble(project_directory, stage_root, project.to_dictionary(), [], build_id, "ScaleFixture", {}, profile)
    if not first.get("ok", false): return ["Phase 14 profiled export staging must succeed: %s" % str(first.get("errors", []))]
    var profile_path: String = stage_root.path_join("runtime_data/performance_profile.json")
    if not FileAccess.file_exists(profile_path): errors.append("Selected performance profile must be packaged with the runtime data.")
    var manifest_text: String = FileAccess.get_file_as_string(stage_root.path_join("export_manifest.json"))
    if not manifest_text.contains("runtime_data/performance_profile.json"): errors.append("Export manifest must classify packaged performance policy as runtime-required.")
    var report_text: String = FileAccess.get_file_as_string(stage_root.path_join("export_report.json"))
    if not report_text.contains("\"preset_id\": \"high\""): errors.append("Export report must record the selected performance preset.")
    var manifest_before: String = manifest_text
    var second: Dictionary = staging.assemble(project_directory, stage_root, project.to_dictionary(), [], build_id, "ScaleFixture", {}, profile)
    if not second.get("ok", false): errors.append("Repeat profiled staging must succeed.")
    elif FileAccess.get_file_as_string(stage_root.path_join("export_manifest.json")) != manifest_before: errors.append("Profiled staging must remain deterministic for identical inputs.")
    var bundle: Dictionary = StandaloneLoader.load_bundle(stage_root.path_join("runtime_data"))
    if not bundle.get("ok", false): errors.append("Standalone loader must reopen profiled runtime data: %s" % str(bundle.get("errors", [])))
    elif str(bundle.get("performance_profile", {}).get("preset_id", "")) != "high": errors.append("Standalone runtime must consume the packaged performance preset.")
    if project.to_dictionary().has("performance_profile"): errors.append("Performance preset must remain user/export policy, not authored project state.")

    var fallback_root: String = root.path_join("stage-default")
    var fallback: Dictionary = staging.assemble(project_directory, fallback_root, project.to_dictionary(), [], StableId.generate(), "DefaultFixture")
    if not fallback.get("ok", false): errors.append("Legacy/default export staging must remain compatible.")
    elif FileAccess.file_exists(fallback_root.path_join("runtime_data/performance_profile.json")): errors.append("Legacy staging without an explicit profile must not invent a packaged policy file.")
    else:
        var fallback_bundle: Dictionary = StandaloneLoader.load_bundle(fallback_root.path_join("runtime_data"))
        if not fallback_bundle.get("ok", false) or str(fallback_bundle.get("performance_profile", {}).get("preset_id", "")) != "balanced": errors.append("Standalone runtime must safely default legacy packages to Balanced.")
    return errors
