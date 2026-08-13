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

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var errors: Array[String] = []
    var registry = TemplateRegistry.new()
    var registry_result: Dictionary = registry.load_builtin()
    if not registry_result.get("ok", false): errors.append("Template registry failed: %s" % str(registry_result.get("errors", [])))
    var manifest: Dictionary = registry.get_manifest("third_person_adventure")
    if manifest.is_empty(): errors.append("Third-person template is unavailable.")
    if errors.is_empty():
        var result: Dictionary = _verify_export(manifest)
        if not result.get("ok", false): errors.append_array(result.get("errors", []))
    if errors.is_empty():
        print("PASS: Phase 16 Windows export closure and clean-package launch completed.")
        quit(0); return
    for error in errors: push_error(error)
    quit(1)

func _verify_export(manifest: Dictionary) -> Dictionary:
    var root_path := "user://tests/phase16/windows-%s" % StableId.generate()
    var repository = ProjectRepository.new(root_path.path_join("projects"))
    var created: Dictionary = repository.create_project("Phase16 Export Closure", &"medium", "third_person_adventure")
    if not created.get("ok", false): return _failure("Project creation failed: %s" % str(created.get("errors", [])))
    var project = created.get("project")
    project.runtime_config["biome_preset"] = "meadow"
    var project_directory: String = repository.get_project_directory(str(project.project_id))
    var applied: Dictionary = TemplateApplication.new().apply_to_project(project, manifest)
    if not applied.get("ok", false): return _failure("Template application failed: %s" % str(applied.get("errors", [])))
    for result in [
        TerrainRepository.new(project_directory).open_or_create(project),
        GameplayRepository.new(project_directory).open_or_create(project),
        VisualRepository.new(project_directory).open_or_create(project),
        ProceduralRepository.new(project_directory).open_or_create(project),
        EnvironmentRepository.new(project_directory).open_or_create(project),
    ]:
        if not result.get("ok", false): return _failure("Authored subsystem initialization failed: %s" % str(result.get("errors", [])))
    var saved: Dictionary = repository.save_project(project)
    if not saved.get("ok", false): return _failure("Project save failed before export.")
    var library = AssetLibrary.new(project_directory)
    var library_result: Dictionary = library.load_library()
    if not library_result.get("ok", false): return _failure("Asset Library load failed: %s" % str(library_result.get("errors", [])))
    var pipeline = ExportPipeline.new()
    var exported: Dictionary = pipeline.export_windows(project, project_directory, library, root_path.path_join("exports"), "Phase16Closure", PerformanceProfiles.get_profile("balanced"))
    if not exported.get("ok", false): return _failure("Windows export failed: %s" % str(exported.get("errors", [])))
    var output_root: String = str(exported.get("output_root", ""))
    var manifest_path := output_root.path_join("export_manifest.json")
    if not FileAccess.file_exists(manifest_path): return _failure("Export manifest is missing.")
    var manifest_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
    if not manifest_data is Dictionary: return _failure("Export manifest is unreadable.")
    var serialized := JSON.stringify(manifest_data)
    for required in [
        "src/environment/environment_runtime.gd",
        "src/environment/water_provider_registry.gd",
        "src/runtime/play_session.gd",
        "src/input/gameplay_input_map.gd",
    ]:
        if not serialized.contains(required): return _failure("Export dependency closure omitted required runtime source: %s" % required)
    for forbidden in ["src/main/main.gd", "src/app/screens/home/home_screen.gd", "src/editor/editor_session.gd"]:
        if serialized.contains(forbidden): return _failure("Export leaked editor-only source: %s" % forbidden)
    var clean_root := root_path.path_join("clean-machine").path_join("Phase16Closure")
    if not _reset_directory(clean_root) or not _copy_tree(output_root, clean_root): return _failure("Clean-package copy failed.")
    var executable := clean_root.path_join("Phase16Closure.exe")
    OS.set_environment("POLYFORK_EXPORT_SMOKE", "1")
    var output: Array = []
    var exit_code: int = OS.execute(ProjectSettings.globalize_path(executable), PackedStringArray(["--headless"]), output, true, false)
    OS.set_environment("POLYFORK_EXPORT_SMOKE", "")
    var log_text := "\n".join(PackedStringArray(output.map(func(value): return str(value))))
    print("PHASE16-STANDALONE-LOG\n%s" % log_text)
    if exit_code != 0: return _failure("Clean-package launch exited %d." % exit_code)
    if not log_text.contains("PASS: Phase 13 standalone export runtime smoke completed."): return _failure("Standalone launch did not reach the runtime smoke marker.")
    if log_text.contains("SCRIPT ERROR:") or log_text.contains("ERROR:"): return _failure("Standalone launch emitted strict Godot errors.")
    return {"ok": true, "errors": []}

static func _copy_tree(source_root: String, target_root: String) -> bool:
    var directory := DirAccess.open(ProjectSettings.globalize_path(source_root))
    if directory == null: return false
    directory.list_dir_begin()
    while true:
        var name := directory.get_next()
        if name.is_empty(): break
        if name == "." or name == "..": continue
        var source_child := source_root.path_join(name)
        var target_child := target_root.path_join(name)
        if directory.current_is_dir():
            if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_child)) not in [OK, ERR_ALREADY_EXISTS] or not _copy_tree(source_child, target_child): directory.list_dir_end(); return false
        else:
            var handle := FileAccess.open(target_child, FileAccess.WRITE)
            if handle == null: directory.list_dir_end(); return false
            handle.store_buffer(FileAccess.get_file_as_bytes(source_child)); handle.close()
    directory.list_dir_end()
    return true

static func _reset_directory(path: String) -> bool:
    var absolute := ProjectSettings.globalize_path(path)
    if DirAccess.dir_exists_absolute(absolute) and not _remove_tree(absolute): return false
    return DirAccess.make_dir_recursive_absolute(absolute) in [OK, ERR_ALREADY_EXISTS]

static func _remove_tree(absolute_path: String) -> bool:
    var directory := DirAccess.open(absolute_path)
    if directory == null: return false
    directory.list_dir_begin()
    while true:
        var name := directory.get_next()
        if name.is_empty(): break
        if name == "." or name == "..": continue
        var child := absolute_path.path_join(name)
        if directory.current_is_dir():
            if not _remove_tree(child): directory.list_dir_end(); return false
        elif DirAccess.remove_absolute(child) != OK: directory.list_dir_end(); return false
    directory.list_dir_end()
    return DirAccess.remove_absolute(absolute_path) == OK

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
