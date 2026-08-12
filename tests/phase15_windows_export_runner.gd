extends SceneTree

const StableId = preload("res://src/world/stable_id.gd")
const ProjectRepository = preload("res://src/world/project_repository.gd")
const TerrainRepository = preload("res://src/terrain/terrain_repository.gd")
const GameplayRepository = preload("res://src/gameplay/gameplay_repository.gd")
const VisualRepository = preload("res://src/visual_scripting/visual_graph_repository.gd")
const ProceduralRepository = preload("res://src/procedural/procedural_repository.gd")
const EnvironmentRepository = preload("res://src/environment/environment_repository.gd")
const AssetLibrary = preload("res://src/assets/asset_library_service.gd")
const TemplateRegistry = preload("res://src/templates/template_registry.gd")
const TemplateApplication = preload("res://src/templates/template_application_service.gd")
const ExportPipeline = preload("res://src/export/export_pipeline.gd")
const PerformanceProfiles = preload("res://src/scale/performance_profiles.gd")

const OUTPUT_ROOT := "res://artifacts/phase15/windows"
const MULTIPLAYER_PACKAGE := "Phase15_Multiplayer"
const OFFLINE_PACKAGE := "Phase15_Offline"

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var errors: Array[String] = []
    var registry = TemplateRegistry.new()
    var registry_result: Dictionary = registry.load_builtin()
    if not registry_result.get("ok", false): errors.append("Template registry failed: %s" % str(registry_result.get("errors", [])))
    if errors.is_empty():
        var multiplayer_result: Dictionary = _build_case(registry, "third_person_adventure", MULTIPLAYER_PACKAGE, true)
        if not multiplayer_result.get("ok", false): errors.append_array(_strings(multiplayer_result.get("errors", [])))
        var offline_result: Dictionary = _build_case(registry, "blank_sandbox", OFFLINE_PACKAGE, false)
        if not offline_result.get("ok", false): errors.append_array(_strings(offline_result.get("errors", [])))
    if errors.is_empty():
        print("PASS: Phase 15 Windows multiplayer/offline export packages verified.")
        print("PHASE15_MULTIPLAYER_PACKAGE=%s" % ProjectSettings.globalize_path(OUTPUT_ROOT.path_join(MULTIPLAYER_PACKAGE)))
        print("PHASE15_OFFLINE_PACKAGE=%s" % ProjectSettings.globalize_path(OUTPUT_ROOT.path_join(OFFLINE_PACKAGE)))
        quit(0); return
    for error in errors: push_error(error)
    quit(1)

func _build_case(registry, template_id: String, package_name: String, multiplayer_expected: bool) -> Dictionary:
    var root_path: String = "user://tests/phase15/windows-%s-%s" % [template_id, StableId.generate()]
    var repository = ProjectRepository.new(root_path.path_join("projects"))
    var created: Dictionary = repository.create_project("Phase15 %s" % template_id, &"small", template_id)
    if not created.get("ok", false): return _failure("%s project creation failed: %s" % [template_id, str(created.get("errors", []))])
    var project = created.get("project")
    var project_directory: String = repository.get_project_directory(str(project.project_id))
    var manifest: Dictionary = registry.get_manifest(template_id)
    if manifest.is_empty(): return _failure("Template manifest is unavailable: %s" % template_id)
    var applied: Dictionary = TemplateApplication.new().apply_to_project(project, manifest)
    if not applied.get("ok", false): return _failure("%s template application failed: %s" % [template_id, str(applied.get("errors", []))])
    var subsystem_results: Array[Dictionary] = [
        TerrainRepository.new(project_directory).open_or_create(project),
        GameplayRepository.new(project_directory).open_or_create(project),
        VisualRepository.new(project_directory).open_or_create(project),
        ProceduralRepository.new(project_directory).open_or_create(project),
        EnvironmentRepository.new(project_directory).open_or_create(project),
    ]
    for result in subsystem_results:
        if not result.get("ok", false): return _failure("%s authored subsystem initialization failed: %s" % [template_id, str(result.get("errors", []))])
    var saved: Dictionary = repository.save_project(project)
    if not saved.get("ok", false): return _failure("%s project save failed before export." % template_id)
    var library = AssetLibrary.new(project_directory)
    var library_result: Dictionary = library.load_library()
    if not library_result.get("ok", false): return _failure("%s Asset Library load failed: %s" % [template_id, str(library_result.get("errors", []))])

    var profile: Dictionary = PerformanceProfiles.get_profile(PerformanceProfiles.DEFAULT)
    var pipeline = ExportPipeline.new()
    var first: Dictionary = pipeline.export_windows(project, project_directory, library, OUTPUT_ROOT, package_name, profile)
    if not first.get("ok", false): return _failure("%s Windows export failed: %s" % [template_id, str(first.get("errors", []))])
    var final_root: String = str(first.get("output_root", ""))
    var executable: String = str(first.get("executable_path", ""))
    for required in [executable, final_root.path_join("%s.pck" % package_name), final_root.path_join("export_manifest.json"), final_root.path_join("export_report.json")]:
        if not FileAccess.file_exists(required): return _failure("%s export is missing required artifact: %s" % [template_id, required])
    var manifest_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(final_root.path_join("export_manifest.json")))
    if not manifest_data is Dictionary: return _failure("%s export manifest is unreadable." % template_id)
    var serialized: String = JSON.stringify(manifest_data)
    var report_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(final_root.path_join("export_report.json")))
    if not report_value is Dictionary: return _failure("%s export report is unreadable." % template_id)
    var report: Dictionary = report_value
    if multiplayer_expected:
        for required_runtime in [
            "runtime_data/multiplayer_profile.json",
            "src/network/network_runtime_service.gd",
            "src/network/enet_session_adapter.gd",
            "src/network/player_replication_service.gd",
            "src/network/gameplay_replication_service.gd",
            "src/network/match_replication_service.gd",
        ]:
            if not serialized.contains(required_runtime): return _failure("Multiplayer export omitted required runtime source: %s" % required_runtime)
        if not bool(report.get("multiplayer_enabled", false)): return _failure("Multiplayer export report did not record multiplayer capability.")
        if int(report.get("multiplayer_capability", {}).get("max_players", 0)) != 4: return _failure("Multiplayer export report lost declared player limits.")
    else:
        for forbidden in ["runtime_data/multiplayer_profile.json", "src/network/network_runtime_service.gd", "src/network/enet_session_adapter.gd", "src/network/player_replication_service.gd"]:
            if serialized.contains(forbidden): return _failure("Offline export unnecessarily included multiplayer runtime source: %s" % forbidden)
        if bool(report.get("multiplayer_enabled", true)): return _failure("Offline export report incorrectly marked multiplayer enabled.")
    for forbidden_editor in ["src/app/workspace/multiplayer_workspace_layer.gd", "src/editor/editor_session.gd", "src/main/main.gd"]:
        if serialized.contains(forbidden_editor): return _failure("Export leaked editor-only source: %s" % forbidden_editor)

    var stale_path: String = final_root.path_join("stale-marker.txt")
    var stale: FileAccess = FileAccess.open(stale_path, FileAccess.WRITE)
    if stale == null: return _failure("Repeat-export stale marker could not be created.")
    stale.store_string("stale"); stale.close()
    var second: Dictionary = pipeline.export_windows(project, project_directory, library, OUTPUT_ROOT, package_name, profile)
    if not second.get("ok", false): return _failure("%s repeat Windows export failed: %s" % [template_id, str(second.get("errors", []))])
    if FileAccess.file_exists(stale_path): return _failure("%s repeat export retained stale files." % template_id)

    if not multiplayer_expected:
        OS.set_environment("POLYFORK_EXPORT_SMOKE", "1")
        var output: Array = []
        var exit_code: int = OS.execute(ProjectSettings.globalize_path(str(second.get("executable_path", ""))), PackedStringArray(["--headless"]), output, true, false)
        OS.set_environment("POLYFORK_EXPORT_SMOKE", "")
        var log_text: String = "\n".join(PackedStringArray(output.map(func(value): return str(value))))
        print("PHASE15-OFFLINE-STANDALONE-LOG\n%s" % log_text)
        if exit_code != 0: return _failure("Offline standalone launch exited %d." % exit_code)
        if not log_text.contains("PASS: Phase 13 standalone export runtime smoke completed."): return _failure("Offline standalone launch did not preserve the Phase 13 runtime marker.")
        if not log_text.contains("keyboard_mouse=true gamepad=true"): return _failure("Offline standalone launch did not preserve semantic input coverage.")
        if log_text.contains("SCRIPT ERROR:") or log_text.contains("ERROR:"): return _failure("Offline standalone launch emitted strict Godot errors.")
    return {"ok": true, "errors": []}

static func _strings(values: Variant) -> Array[String]:
    var result: Array[String] = []
    if values is Array:
        for value in values: result.append(str(value))
    return result

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
