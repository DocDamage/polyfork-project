extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const ProjectRepository = preload("res://src/world/project_repository.gd")
const TerrainRepository = preload("res://src/terrain/terrain_repository.gd")
const GameplayRepository = preload("res://src/gameplay/gameplay_repository.gd")
const VisualRepository = preload("res://src/visual_scripting/visual_graph_repository.gd")
const ProceduralRepository = preload("res://src/procedural/procedural_repository.gd")
const EnvironmentRepository = preload("res://src/environment/environment_repository.gd")
const SourceClosure = preload("res://src/export/export_source_closure.gd")
const StagingService = preload("res://src/export/export_staging_service.gd")
const StandaloneLoader = preload("res://src/export/runtime/standalone_data_loader.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var closure: Dictionary = SourceClosure.resolve(["src/export/runtime/StandaloneRuntime.tscn"])
    if not closure.get("ok", false):
        errors.append("Standalone runtime source dependency closure must resolve.")
    else:
        var paths: Array = closure.get("paths", [])
        for required in ["src/runtime/play_session.gd", "src/editor/runtime_entity_bridge.gd", "src/terrain/terrain_runtime.gd", "src/procedural/procedural_runtime.gd", "src/environment/environment_runtime.gd", "src/input/gameplay_input_map.gd"]:
            if not paths.has(required): errors.append("Standalone runtime source closure is missing required Phase 7/runtime dependency: %s" % required)
        for forbidden in ["src/main/main.gd", "src/app/workspace/workspace_screen.gd", "src/app/workspace/ai_workspace_layer.gd", "src/editor/editor_session.gd"]:
            if paths.has(forbidden): errors.append("Standalone source closure must strip editor/authoring path: %s" % forbidden)

    var root: String = "user://tests/phase13/runtime-%s" % StableId.generate()
    var repository = ProjectRepository.new(root.path_join("projects"))
    var create_result: Dictionary = repository.create_project("Phase 13 Runtime", &"small", "blank_sandbox")
    if not create_result.get("ok", false): errors.append("Phase 13 runtime fixture project must be created."); return errors
    var project = create_result.get("project")
    var project_directory: String = repository.get_project_directory(str(project.project_id))
    var subsystem_results: Array[Dictionary] = [
        TerrainRepository.new(project_directory).open_or_create(project), GameplayRepository.new(project_directory).open_or_create(project),
        VisualRepository.new(project_directory).open_or_create(project), ProceduralRepository.new(project_directory).open_or_create(project),
        EnvironmentRepository.new(project_directory).open_or_create(project),
    ]
    for result in subsystem_results:
        if not result.get("ok", false): errors.append("Representative authored runtime subsystem fixture failed: %s" % str(result.get("errors", [])))
    if not errors.is_empty(): return errors
    var save_result: Dictionary = repository.save_project(project)
    if not save_result.get("ok", false): errors.append("Representative Phase 13 project must save after subsystem initialization."); return errors

    var stage_root: String = root.path_join("stage")
    var build_id: String = StableId.generate()
    var staging = StagingService.new()
    var first: Dictionary = staging.assemble(project_directory, stage_root, project.to_dictionary(), [], build_id, "RuntimeFixture")
    if not first.get("ok", false): errors.append("Deterministic runtime staging must succeed: %s" % str(first.get("errors", []))); return errors
    if FileAccess.file_exists(stage_root.path_join("src/main/main.gd")) or FileAccess.file_exists(stage_root.path_join("src/editor/editor_session.gd")): errors.append("Runtime staging must physically omit editor shell and authoring session code.")
    if not FileAccess.file_exists(stage_root.path_join("src/editor/runtime_entity_bridge.gd")): errors.append("Runtime staging must preserve runtime-required bridge code even though it lives under src/editor.")
    if FileAccess.file_exists(stage_root.path_join("runtime_data/checkpoints/index.json")) or FileAccess.file_exists(stage_root.path_join("runtime_data/ai/history.json")): errors.append("Runtime staging must omit checkpoints and AI history/configuration.")
    var manifest_before: String = FileAccess.get_file_as_string(stage_root.path_join("export_manifest.json"))
    var second: Dictionary = staging.assemble(project_directory, stage_root, project.to_dictionary(), [], build_id, "RuntimeFixture")
    if not second.get("ok", false): errors.append("Repeat runtime staging must succeed.")
    elif FileAccess.get_file_as_string(stage_root.path_join("export_manifest.json")) != manifest_before: errors.append("Repeat staging with identical inputs/build identity must be deterministic and idempotent.")

    var bundle: Dictionary = StandaloneLoader.load_bundle(stage_root.path_join("runtime_data"))
    if not bundle.get("ok", false): errors.append("Standalone data loader must reopen staged authoritative runtime data: %s" % str(bundle.get("errors", [])))
    else:
        if str(bundle.get("project_data", {}).get("project_id", "")) != str(project.project_id): errors.append("Standalone bundle must preserve exact project identity.")
        if bundle.get("project_data", {}).has("editor") or bundle.get("project_data", {}).has("export"): errors.append("Standalone project manifest must strip editor/export authoring state.")
        if bundle.get("terrain_state") == null or bundle.get("gameplay_state") == null or bundle.get("procedural_state") == null: errors.append("Standalone bundle must preserve authored runtime subsystem state.")
    return errors
