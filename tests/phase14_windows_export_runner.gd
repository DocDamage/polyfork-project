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

const CASES := [
    {"world_profile": "small", "performance_preset": "low"},
    {"world_profile": "medium", "performance_preset": "balanced"},
    {"world_profile": "large", "performance_preset": "high"},
]

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var errors: Array[String] = []
    var registry = TemplateRegistry.new()
    var registry_result: Dictionary = registry.load_builtin()
    if not registry_result.get("ok", false): errors.append("Template registry failed: %s" % str(registry_result.get("errors", [])))
    var manifest: Dictionary = registry.get_manifest("third_person_adventure")
    if manifest.is_empty(): errors.append("Third-person Phase 7 template is unavailable.")
    if errors.is_empty():
        for case_value in CASES:
            var case_data: Dictionary = case_value
            var result: Dictionary = _verify_case(str(case_data.get("world_profile", "")), str(case_data.get("performance_preset", "")), manifest)
            if not result.get("ok", false): errors.append_array(result.get("errors", []))
    if errors.is_empty():
        print("PASS: Phase 14 Windows Small/Medium/Large profiled export and clean-package launch completed.")
        quit(0); return
    for error in errors: push_error(error)
    quit(1)

func _verify_case(world_profile: String, performance_preset: String, manifest: Dictionary) -> Dictionary:
    var root_path: String = "user://tests/phase14/windows-%s-%s-%s" % [world_profile, performance_preset, StableId.generate()]
    var repository = ProjectRepository.new(root_path.path_join("projects"))
    var created: Dictionary = repository.create_project("Phase14 %s %s" % [world_profile.capitalize(), performance_preset.capitalize()], StringName(world_profile), "third_person_adventure")
    if not created.get("ok", false): return _failure("%s/%s project creation failed: %s" % [world_profile, performance_preset, str(created.get("errors", []))])
    var project = created.get("project")
    var project_directory: String = repository.get_project_directory(str(project.project_id))
    var applied: Dictionary = TemplateApplication.new().apply_to_project(project, manifest)
    if not applied.get("ok", false): return _failure("%s/%s template application failed: %s" % [world_profile, performance_preset, str(applied.get("errors", []))])
    for result in [TerrainRepository.new(project_directory).open_or_create(project), GameplayRepository.new(project_directory).open_or_create(project), VisualRepository.new(project_directory).open_or_create(project), ProceduralRepository.new(project_directory).open_or_create(project), EnvironmentRepository.new(project_directory).open_or_create(project)]:
        if not result.get("ok", false): return _failure("%s/%s authored subsystem initialization failed: %s" % [world_profile, performance_preset, str(result.get("errors", []))])
    var saved: Dictionary = repository.save_project(project)
    if not saved.get("ok", false): return _failure("%s/%s project save failed before export." % [world_profile, performance_preset])
    var library = AssetLibrary.new(project_directory)
    var library_result: Dictionary = library.load_library()
    if not library_result.get("ok", false): return _failure("%s/%s Asset Library load failed: %s" % [world_profile, performance_preset, str(library_result.get("errors", []))])

    var selected_profile: Dictionary = PerformanceProfiles.get_profile(performance_preset)
    var output_root: String = root_path.path_join("exports")
    var package_name: String = "Phase14_%s_%s" % [world_profile.capitalize(), performance_preset.capitalize()]
    var pipeline = ExportPipeline.new()
    var first: Dictionary = pipeline.export_windows(project, project_directory, library, output_root, package_name, selected_profile)
    if not first.get("ok", false): return _failure("%s/%s Windows export failed: %s" % [world_profile, performance_preset, str(first.get("errors", []))])
    var final_root: String = str(first.get("output_root", ""))
    var executable: String = str(first.get("executable_path", ""))
    for required in [executable, final_root.path_join("%s.pck" % package_name), final_root.path_join("export_manifest.json"), final_root.path_join("export_report.json"), final_root.path_join("ATTRIBUTIONS.txt")]:
        if not FileAccess.file_exists(required): return _failure("%s/%s export package is missing required artifact: %s" % [world_profile, performance_preset, required])
    var manifest_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(final_root.path_join("export_manifest.json")))
    if not manifest_data is Dictionary: return _failure("%s/%s exported manifest is unreadable." % [world_profile, performance_preset])
    var serialized: String = JSON.stringify(manifest_data)
    if not serialized.contains("runtime_data/performance_profile.json"): return _failure("%s/%s export manifest omitted the Phase 14 performance policy." % [world_profile, performance_preset])
    for forbidden in ["src/main/main.gd", "src/app/workspace/workspace_screen.gd", "src/editor/editor_session.gd", "ai_workspace_layer.gd"]:
        if serialized.contains(forbidden): return _failure("%s/%s exported manifest leaked editor/authoring source: %s" % [world_profile, performance_preset, forbidden])
    for required_runtime in ["src/runtime/play_session.gd", "src/editor/runtime_entity_bridge.gd", "src/input/gameplay_input_map.gd", "src/scale/performance_profiles.gd"]:
        if not serialized.contains(required_runtime): return _failure("%s/%s exported manifest omitted required shared runtime source: %s" % [world_profile, performance_preset, required_runtime])
    var report_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(final_root.path_join("export_report.json")))
    if not report_data is Dictionary or str(report_data.get("performance_profile", {}).get("preset_id", "")) != performance_preset:
        return _failure("%s/%s export report did not record the selected performance preset." % [world_profile, performance_preset])

    var stale_path: String = final_root.path_join("stale-marker.txt")
    var stale := FileAccess.open(stale_path, FileAccess.WRITE)
    if stale == null: return _failure("%s/%s idempotency marker could not be created." % [world_profile, performance_preset])
    stale.store_string("stale"); stale.close()
    var second: Dictionary = pipeline.export_windows(project, project_directory, library, output_root, package_name, selected_profile)
    if not second.get("ok", false): return _failure("%s/%s repeat Windows export failed: %s" % [world_profile, performance_preset, str(second.get("errors", []))])
    if FileAccess.file_exists(stale_path): return _failure("%s/%s repeat export retained stale files instead of deterministic replacement." % [world_profile, performance_preset])

    var clean_root: String = root_path.path_join("clean-machine").path_join(package_name)
    if not _reset_directory(clean_root) or not _copy_tree(str(second.get("output_root", "")), clean_root): return _failure("%s/%s clean-machine package copy failed." % [world_profile, performance_preset])
    var clean_executable: String = clean_root.path_join("%s.exe" % package_name)
    OS.set_environment("POLYFORK_EXPORT_SMOKE", "1")
    var output: Array = []
    var exit_code: int = OS.execute(ProjectSettings.globalize_path(clean_executable), PackedStringArray(["--headless"]), output, true, false)
    OS.set_environment("POLYFORK_EXPORT_SMOKE", "")
    var log_text: String = "\n".join(PackedStringArray(output.map(func(value): return str(value))))
    print("PHASE14-%s-%s-STANDALONE-LOG\n%s" % [world_profile.to_upper(), performance_preset.to_upper(), log_text])
    if exit_code != 0: return _failure("%s/%s clean-package standalone launch exited %d." % [world_profile, performance_preset, exit_code])
    if not log_text.contains("PASS: Phase 13 standalone export runtime smoke completed."): return _failure("%s/%s standalone launch did not reach the runtime smoke marker." % [world_profile, performance_preset])
    if not log_text.contains("keyboard_mouse=true gamepad=true"): return _failure("%s/%s standalone launch did not verify keyboard/mouse and gamepad semantic input." % [world_profile, performance_preset])
    if not log_text.contains("controller=third_person"): return _failure("%s/%s standalone launch did not reuse the Phase 7 third-person controller path." % [world_profile, performance_preset])
    if not log_text.contains("preset=%s" % performance_preset): return _failure("%s/%s standalone launch did not consume the selected performance preset." % [world_profile, performance_preset])
    if log_text.contains("SCRIPT ERROR:") or log_text.contains("ERROR:"): return _failure("%s/%s standalone launch emitted strict Godot errors." % [world_profile, performance_preset])
    return {"ok": true, "errors": []}

static func _copy_tree(source_root: String, target_root: String) -> bool:
    var directory: DirAccess = DirAccess.open(ProjectSettings.globalize_path(source_root))
    if directory == null: return false
    directory.list_dir_begin()
    while true:
        var name: String = directory.get_next()
        if name.is_empty(): break
        if name == "." or name == "..": continue
        var source_child: String = source_root.path_join(name)
        var target_child: String = target_root.path_join(name)
        if directory.current_is_dir():
            if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_child)) not in [OK, ERR_ALREADY_EXISTS] or not _copy_tree(source_child, target_child): directory.list_dir_end(); return false
        else:
            var handle := FileAccess.open(target_child, FileAccess.WRITE)
            if handle == null: directory.list_dir_end(); return false
            handle.store_buffer(FileAccess.get_file_as_bytes(source_child)); handle.close()
    directory.list_dir_end(); return true

static func _reset_directory(path: String) -> bool:
    var absolute: String = ProjectSettings.globalize_path(path)
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
    directory.list_dir_end(); return DirAccess.remove_absolute(absolute_path) == OK

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
