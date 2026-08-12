class_name PlayWorldExportStagingService
extends RefCounted

const Contracts = preload("res://src/export/export_contracts.gd")
const StagingPlan = preload("res://src/export/export_staging_plan.gd")
const SourceClosure = preload("res://src/export/export_source_closure.gd")
const WorldProject = preload("res://src/world/world_project.gd")

const RUNTIME_ROOTS: Array[String] = ["src/export/runtime/StandaloneRuntime.tscn"]

func assemble(project_directory: String, stage_root: String, project_data: Dictionary, dependencies: Array, build_id: String, package_name: String) -> Dictionary:
    var errors: Array[String] = []
    if project_directory.strip_edges().is_empty(): return _failure("Export staging requires a project directory.")
    if stage_root.strip_edges().is_empty(): return _failure("Export staging requires a destination directory.")
    if not Contracts.valid_package_segment(package_name): return _failure("Export package name is unsafe or invalid.")
    if not _reset_directory(stage_root): return _failure("Unable to reset deterministic export staging directory.")

    var closure: Dictionary = SourceClosure.resolve(RUNTIME_ROOTS)
    if not closure.get("ok", false): return closure
    var manifest_files: Array[Dictionary] = []
    for source_path_value in closure.get("paths", []):
        var source_path: String = str(source_path_value)
        var copy_result: Dictionary = _copy_file("res://%s" % source_path, stage_root.path_join(source_path))
        if not copy_result.get("ok", false): errors.append_array(copy_result.get("errors", [])); break
        manifest_files.append({"package_path": source_path, "classification": Contracts.RUNTIME_REQUIRED})
    if not errors.is_empty(): return {"ok": false, "errors": errors}

    var sanitized_project: Dictionary = project_data.duplicate(true)
    sanitized_project.erase("editor")
    sanitized_project.erase("export")
    var project_errors: Array[String] = WorldProject.validate_dictionary(sanitized_project)
    if not project_errors.is_empty(): return {"ok": false, "errors": project_errors}

    var data_plan: Dictionary = StagingPlan.build_project_data_plan(project_data)
    for item_value in data_plan.get("files", []):
        var item: Dictionary = item_value
        var relative_path: String = str(item.get("source_path", ""))
        if StagingPlan.is_prohibited_project_data_path(relative_path): return _failure("Authoring-only project data entered the runtime staging plan: %s" % relative_path)
        var target_path: String = stage_root.path_join(str(item.get("package_path", "")))
        if relative_path == "project.json":
            var write_result: Dictionary = _write_json(target_path, sanitized_project)
            if not write_result.get("ok", false): return write_result
        else:
            var source_path: String = project_directory.trim_suffix("/").path_join(relative_path)
            if not FileAccess.file_exists(source_path): return _failure("Required authored runtime data is missing: %s" % relative_path)
            var copy_result: Dictionary = _copy_file(source_path, target_path)
            if not copy_result.get("ok", false): return copy_result
        manifest_files.append({"package_path": str(item.get("package_path", "")), "classification": Contracts.RUNTIME_REQUIRED})

    var ordered_dependencies: Array = dependencies.duplicate(true)
    ordered_dependencies.sort_custom(func(a, b): return str(a.get("asset_id", "")) < str(b.get("asset_id", "")))
    for dependency_value in ordered_dependencies:
        if not dependency_value is Dictionary: return _failure("Resolved export dependencies must be dictionaries.")
        var dependency: Dictionary = dependency_value
        var package_path: String = str(dependency.get("package_path", ""))
        if not Contracts.valid_package_path(package_path): return _failure("Resolved export dependency has an unsafe package path.")
        var copy_result: Dictionary = _copy_file(str(dependency.get("source_path", "")), stage_root.path_join(package_path))
        if not copy_result.get("ok", false): return copy_result
        manifest_files.append({"package_path": package_path, "classification": Contracts.RUNTIME_REQUIRED})

    var project_file_result: Dictionary = _write_text(stage_root.path_join("project.godot"), _standalone_project_file(package_name))
    if not project_file_result.get("ok", false): return project_file_result
    manifest_files.append({"package_path": "project.godot", "classification": Contracts.RUNTIME_REQUIRED})

    var manifest: Dictionary = Contracts.new_manifest(sanitized_project, build_id, package_name, ordered_dependencies, manifest_files)
    var manifest_errors: Array[String] = Contracts.validate_manifest(manifest)
    if not manifest_errors.is_empty(): return {"ok": false, "errors": manifest_errors}
    var manifest_result: Dictionary = _write_json(stage_root.path_join("export_manifest.json"), manifest)
    if not manifest_result.get("ok", false): return manifest_result
    return {"ok": true, "errors": [], "stage_root": stage_root, "manifest": manifest, "runtime_source_paths": closure.get("paths", []), "file_count": manifest_files.size() + 1}

static func _standalone_project_file(package_name: String) -> String:
    return """config_version=5

[application]
config/name=\"%s\"
run/main_scene=\"res://src/export/runtime/StandaloneRuntime.tscn\"

[display]
window/size/viewport_width=1600
window/size/viewport_height=900
window/size/window_width_override=1600
window/size/window_height_override=900
window/stretch/mode=\"canvas_items\"

[rendering]
renderer/rendering_method=\"gl_compatibility\"
renderer/rendering_method.mobile=\"gl_compatibility\"
textures/default_filters/use_nearest_mipmap_filter=false
""" % package_name

static func _copy_file(source_path: String, destination_path: String) -> Dictionary:
    if source_path.strip_edges().is_empty() or not FileAccess.file_exists(source_path): return _failure("Export staging source file is unavailable: %s" % source_path)
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination_path.get_base_dir()))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS: return _failure("Unable to create export staging directory for %s" % destination_path)
    var bytes: PackedByteArray = FileAccess.get_file_as_bytes(source_path)
    var handle: FileAccess = FileAccess.open(destination_path, FileAccess.WRITE)
    if handle == null: return _failure("Unable to write staged export file: %s" % destination_path)
    handle.store_buffer(bytes); handle.close()
    return {"ok": true, "errors": []}

static func _write_json(path: String, data: Dictionary) -> Dictionary: return _write_text(path, JSON.stringify(data, "  ", true) + "\n")

static func _write_text(path: String, text: String) -> Dictionary:
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS: return _failure("Unable to create export staging directory.")
    var handle: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if handle == null: return _failure("Unable to write export staging file: %s" % path)
    handle.store_string(text); handle.close()
    return {"ok": true, "errors": []}

static func _reset_directory(path: String) -> bool:
    var absolute: String = ProjectSettings.globalize_path(path)
    if DirAccess.dir_exists_absolute(absolute) and not _remove_tree(absolute): return false
    var error: Error = DirAccess.make_dir_recursive_absolute(absolute)
    return error == OK or error == ERR_ALREADY_EXISTS

static func _remove_tree(absolute_path: String) -> bool:
    var directory: DirAccess = DirAccess.open(absolute_path)
    if directory == null: return false
    directory.list_dir_begin()
    while true:
        var name: String = directory.get_next()
        if name.is_empty(): break
        if name == "." or name == "..": continue
        var child: String = absolute_path.path_join(name)
        if directory.current_is_dir():
            if not _remove_tree(child): directory.list_dir_end(); return false
        elif DirAccess.remove_absolute(child) != OK:
            directory.list_dir_end(); return false
    directory.list_dir_end()
    return DirAccess.remove_absolute(absolute_path) == OK

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
