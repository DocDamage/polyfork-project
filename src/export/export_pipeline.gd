class_name PlayWorldExportPipeline
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const AuthoredReader = preload("res://src/export/export_authored_reader.gd")
const DependencyScanner = preload("res://src/export/export_dependency_scanner.gd")
const AssetResolver = preload("res://src/export/export_asset_resolver.gd")
const LicenseReport = preload("res://src/export/export_license_report.gd")
const StagingService = preload("res://src/export/export_staging_service.gd")
const WindowsPreset = preload("res://src/export/windows_export_preset.gd")
const PerformanceProfiles = preload("res://src/scale/performance_profiles.gd")

const PRESET_NAME := "Windows Desktop"
const EXPORT_TEMPLATE_VERSION := "4.7.1.stable"
const WINDOWS_RELEASE_TEMPLATE := "windows_release_x86_64.exe"
const WINDOWS_DEBUG_TEMPLATE := "windows_debug_x86_64.exe"

func export_windows(project, project_directory: String, asset_library, output_root: String, package_name: String, performance_profile: Dictionary = {}) -> Dictionary:
    if project == null: return _failure("Export requires an active project.")
    var project_data: Dictionary = project.to_dictionary() if project.has_method("to_dictionary") else {}
    var project_errors: Array[String] = WorldProject.validate_dictionary(project_data)
    if not project_errors.is_empty(): return {"ok": false, "errors": project_errors}
    var safe_name: String = _package_name(package_name)
    if safe_name.is_empty(): return _failure("Export package name must contain letters or numbers.")
    if output_root.strip_edges().is_empty(): return _failure("Export output directory is required.")
    var effective_profile: Dictionary = {}
    if not performance_profile.is_empty():
        var profile_errors: Array[String] = PerformanceProfiles.validate_profile(performance_profile)
        if not profile_errors.is_empty(): return {"ok": false, "errors": profile_errors}
        effective_profile = PerformanceProfiles.get_profile(performance_profile.get("preset_id", PerformanceProfiles.DEFAULT))

    var authored: Dictionary = AuthoredReader.read_documents(project_directory)
    if not authored.get("ok", false): return authored
    var discovery: Dictionary = DependencyScanner.discover(project_data, authored.get("documents", {}))
    if not discovery.get("ok", false): return discovery
    var asset_ids: Array[String] = []
    for value in discovery.get("asset_ids", []): asset_ids.append(str(value))
    var resolution: Dictionary = AssetResolver.resolve_with_library(asset_ids, asset_library)
    if not resolution.get("ok", false): return resolution
    var dependencies: Array = resolution.get("dependencies", [])
    var licenses: Dictionary = LicenseReport.build(dependencies)

    var project_id: String = str(project_data.get("project_id", "")); var build_id: String = StableId.generate()
    var stage_root: String = str(ProjectSettings.get_setting("playworld/export/staging_root", "user://polyfork_exports/staging")).trim_suffix("/").path_join(project_id).path_join(safe_name)
    var staging = StagingService.new()
    var staged: Dictionary = staging.assemble(project_directory, stage_root, project_data, dependencies, build_id, safe_name, licenses, effective_profile)
    if not staged.get("ok", false): return staged
    var preset_write: Dictionary = _write_text(stage_root.path_join("export_presets.cfg"), WindowsPreset.text(safe_name))
    if not preset_write.get("ok", false): return preset_write

    var final_root: String = output_root.trim_suffix("/").path_join(safe_name)
    var partial_root: String = output_root.trim_suffix("/").path_join(".%s.partial" % safe_name)
    if _same_or_nested(project_directory, final_root) or _same_or_nested(project_directory, partial_root): return _failure("Export output cannot be inside the authored project directory.")
    if not _reset_directory(partial_root): return _failure("Unable to prepare temporary export package directory.")

    var tooling: Dictionary = _resolve_export_tooling()
    if not tooling.get("ok", false): return tooling
    var templates: Dictionary = _ensure_windows_export_templates()
    if not templates.get("ok", false): return templates
    var godot_path: String = str(tooling.get("executable_path", ""))
    var executable_path: String = partial_root.path_join("%s.exe" % safe_name)
    var import_result: Dictionary = _run_process(godot_path, PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path(stage_root), "--import"]))
    if not import_result.get("ok", false): return _process_failure("Godot staged-project import failed.", import_result)
    var export_result: Dictionary = _run_process(godot_path, PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path(stage_root), "--export-release", PRESET_NAME, ProjectSettings.globalize_path(executable_path)]))
    if not export_result.get("ok", false): return _process_failure("Godot Windows export failed. Verify the PlayWorld export tooling and Windows templates are available.", export_result)
    if not FileAccess.file_exists(executable_path): return _failure("Godot reported success but the Windows executable was not created.")

    for report_name in ["export_manifest.json", "ATTRIBUTIONS.txt", "export_report.json"]:
        var copy: Dictionary = _copy_file(stage_root.path_join(report_name), partial_root.path_join(report_name))
        if not copy.get("ok", false): return copy
    if not _promote(partial_root, final_root): return _failure("Unable to promote completed export package into its deterministic output folder.")
    return {"ok": true, "errors": [], "target": "windows", "build_id": build_id, "package_name": safe_name, "output_root": final_root, "executable_path": final_root.path_join("%s.exe" % safe_name), "manifest_path": final_root.path_join("export_manifest.json"), "attribution_path": final_root.path_join("ATTRIBUTIONS.txt"), "report_path": final_root.path_join("export_report.json"), "dependency_count": dependencies.size(), "license_findings": licenses.get("findings", []), "performance_profile": effective_profile.duplicate(true), "export_tool": tooling.get("source", "unknown"), "import_output": import_result.get("output", []), "export_output": export_result.get("output", [])}

static func _resolve_export_tooling() -> Dictionary:
    var configured := str(ProjectSettings.get_setting("playworld/export/godot_executable", "")).strip_edges()
    if not configured.is_empty():
        var configured_path := _globalize_if_needed(configured)
        if FileAccess.file_exists(configured_path): return {"ok": true, "errors": [], "executable_path": configured_path, "source": "configured"}
        return _failure("Configured Godot export executable is missing or unreadable.")
    var environment := OS.get_environment("PLAYWORLD_GODOT_EXPORTER").strip_edges()
    if not environment.is_empty():
        var environment_path := _globalize_if_needed(environment)
        if FileAccess.file_exists(environment_path): return {"ok": true, "errors": [], "executable_path": environment_path, "source": "environment"}
        return _failure("PLAYWORLD_GODOT_EXPORTER points to a missing or unreadable executable.")
    var packaged := OS.get_executable_path().get_base_dir().path_join("tools").path_join("godot").path_join("godot.exe")
    if FileAccess.file_exists(packaged): return {"ok": true, "errors": [], "executable_path": packaged, "source": "packaged"}
    var current := OS.get_executable_path()
    if FileAccess.file_exists(current) and current.get_file().to_lower().contains("godot"):
        return {"ok": true, "errors": [], "executable_path": current, "source": "current_godot"}
    return _failure("Windows export tooling is unavailable. Reinstall PlayWorld Studio or configure a Godot 4.7.1 exporter in Settings.")

static func _ensure_windows_export_templates() -> Dictionary:
    var appdata := OS.get_environment("APPDATA").strip_edges()
    if appdata.is_empty(): return _failure("Windows export templates cannot be prepared because APPDATA is unavailable.")
    var target_root := appdata.path_join("Godot").path_join("export_templates").path_join(EXPORT_TEMPLATE_VERSION)
    var release_target := target_root.path_join(WINDOWS_RELEASE_TEMPLATE)
    if FileAccess.file_exists(release_target): return {"ok": true, "errors": [], "template_root": target_root, "source": "installed"}
    var bundle_root := OS.get_executable_path().get_base_dir().path_join("tools").path_join("export_templates").path_join(EXPORT_TEMPLATE_VERSION)
    var release_source := bundle_root.path_join(WINDOWS_RELEASE_TEMPLATE)
    if not FileAccess.file_exists(release_source):
        return _failure("Windows export templates are missing. Reinstall PlayWorld Studio or install Godot 4.7.1 Windows export templates.")
    var make_error := DirAccess.make_dir_recursive_absolute(target_root)
    if make_error not in [OK, ERR_ALREADY_EXISTS]: return _failure("Unable to create the per-user Windows export template directory.")
    var release_copy := _copy_absolute_file(release_source, release_target)
    if not release_copy.get("ok", false): return release_copy
    var debug_source := bundle_root.path_join(WINDOWS_DEBUG_TEMPLATE)
    if FileAccess.file_exists(debug_source):
        var debug_copy := _copy_absolute_file(debug_source, target_root.path_join(WINDOWS_DEBUG_TEMPLATE))
        if not debug_copy.get("ok", false): return debug_copy
    return {"ok": true, "errors": [], "template_root": target_root, "source": "packaged"}

static func _run_process(path: String, arguments: PackedStringArray) -> Dictionary:
    var output: Array = []; var exit_code: int = OS.execute(path, arguments, output, true, false)
    return {"ok": exit_code == 0, "errors": [], "exit_code": exit_code, "output": output}

static func _process_failure(message: String, result: Dictionary) -> Dictionary:
    return {"ok": false, "errors": [message, "Godot exit code: %d" % int(result.get("exit_code", -1)), str(result.get("output", []))], "process_output": result.get("output", [])}

static func _package_name(value: String) -> String:
    var regex := RegEx.new(); if regex.compile("[^A-Za-z0-9_-]+") != OK: return ""
    var cleaned: String = regex.sub(value.strip_edges().replace(" ", "_"), "_", true).strip_edges().trim_prefix("_").trim_suffix("_")
    return cleaned.substr(0, 80)

static func _same_or_nested(parent: String, child: String) -> bool:
    var p: String = ProjectSettings.globalize_path(parent).replace("\\", "/").simplify_path().trim_suffix("/")
    var c: String = ProjectSettings.globalize_path(child).replace("\\", "/").simplify_path().trim_suffix("/")
    return c == p or c.begins_with(p + "/")

static func _globalize_if_needed(path: String) -> String:
    if path.begins_with("res://") or path.begins_with("user://"): return ProjectSettings.globalize_path(path)
    return path

static func _write_text(path: String, value: String) -> Dictionary:
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS: return _failure("Unable to create export configuration directory.")
    var handle: FileAccess = FileAccess.open(path, FileAccess.WRITE); if handle == null: return _failure("Unable to write export configuration: %s" % path)
    handle.store_string(value); handle.close(); return {"ok": true, "errors": []}

static func _copy_file(source_path: String, target_path: String) -> Dictionary:
    if not FileAccess.file_exists(source_path): return _failure("Expected export report file is missing: %s" % source_path)
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_path.get_base_dir()))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS: return _failure("Unable to create export report output directory.")
    var handle: FileAccess = FileAccess.open(target_path, FileAccess.WRITE); if handle == null: return _failure("Unable to write export report output.")
    handle.store_buffer(FileAccess.get_file_as_bytes(source_path)); handle.close(); return {"ok": true, "errors": []}

static func _copy_absolute_file(source_path: String, target_path: String) -> Dictionary:
    if not FileAccess.file_exists(source_path): return _failure("Required packaged export tooling file is missing.")
    var handle := FileAccess.open(target_path, FileAccess.WRITE)
    if handle == null: return _failure("Unable to install required Windows export tooling into per-user storage.")
    handle.store_buffer(FileAccess.get_file_as_bytes(source_path)); handle.close()
    return {"ok": true, "errors": []}

static func _promote(source_root: String, final_root: String) -> bool:
    if not _reset_directory(final_root): return false
    if not _copy_tree(source_root, final_root): return false
    return _remove_tree(ProjectSettings.globalize_path(source_root))

static func _copy_tree(source_root: String, target_root: String) -> bool:
    var source_abs: String = ProjectSettings.globalize_path(source_root); var directory: DirAccess = DirAccess.open(source_abs)
    if directory == null: return false
    directory.list_dir_begin()
    while true:
        var name: String = directory.get_next(); if name.is_empty(): break
        if name == "." or name == "..": continue
        var source_child: String = source_root.path_join(name); var target_child: String = target_root.path_join(name)
        if directory.current_is_dir():
            if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_child)) not in [OK, ERR_ALREADY_EXISTS] or not _copy_tree(source_child, target_child): directory.list_dir_end(); return false
        else:
            var copied: Dictionary = _copy_file(source_child, target_child); if not copied.get("ok", false): directory.list_dir_end(); return false
    directory.list_dir_end(); return true

static func _reset_directory(path: String) -> bool:
    var absolute: String = ProjectSettings.globalize_path(path)
    if DirAccess.dir_exists_absolute(absolute) and not _remove_tree(absolute): return false
    var error: Error = DirAccess.make_dir_recursive_absolute(absolute); return error == OK or error == ERR_ALREADY_EXISTS

static func _remove_tree(absolute_path: String) -> bool:
    var directory: DirAccess = DirAccess.open(absolute_path); if directory == null: return false
    directory.list_dir_begin()
    while true:
        var name: String = directory.get_next(); if name.is_empty(): break
        if name == "." or name == "..": continue
        var child: String = absolute_path.path_join(name)
        if directory.current_is_dir():
            if not _remove_tree(child): directory.list_dir_end(); return false
        elif DirAccess.remove_absolute(child) != OK: directory.list_dir_end(); return false
    directory.list_dir_end(); return DirAccess.remove_absolute(absolute_path) == OK

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
