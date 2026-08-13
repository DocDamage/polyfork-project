extends SceneTree

const ProductIdentity = preload("res://src/release/product_identity.gd")
const ExportPipeline = preload("res://src/export/export_pipeline.gd")
const SourceClosure = preload("res://src/export/export_source_closure.gd")
const UserPreferences = preload("res://src/scale/user_preferences.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var errors: Array[String] = []
    if ProductIdentity.version() != "0.1.0-rc.1": errors.append("Runtime semantic version is not the Phase 17 RC version.")
    if ProductIdentity.package_name() != "PlayWorld-Studio-0.1.0-rc.1-Windows-x64": errors.append("Deterministic creator release package naming is invalid.")
    if str(ProjectSettings.get_setting("application/config/icon", "")).is_empty(): errors.append("Application icon is not configured.")
    if not FileAccess.file_exists("res://assets/branding/playworld-studio-icon.svg"): errors.append("Configured application icon is missing.")
    var preset := FileAccess.get_file_as_string("res://export_presets.cfg")
    for required in ["PlayWorld Studio Windows x64", "application/product_name=\"PlayWorld Studio\"", "application/product_version=\"0.1.0-rc.1\"", "binary_format/architecture=\"x86_64\""]:
        if not preset.contains(required): errors.append("Creator export preset is missing release metadata: %s" % required)
    for excluded in ["tests/*", ".github/*", "downloads/*", "tools/*", "artifacts/*"]:
        if not preset.contains(excluded): errors.append("Creator export preset does not exclude development material: %s" % excluded)

    var external_root := ProjectSettings.globalize_path("user://phase17-runtime-source-contract-%d" % Time.get_ticks_usec())
    var external_runtime := external_root.path_join("runtime")
    if DirAccess.make_dir_recursive_absolute(external_runtime) not in [OK, ERR_ALREADY_EXISTS]:
        errors.append("Could not prepare external runtime source closure fixture.")
    else:
        var root_handle := FileAccess.open(external_runtime.path_join("root.gd"), FileAccess.WRITE)
        var dep_handle := FileAccess.open(external_runtime.path_join("dep.gd"), FileAccess.WRITE)
        if root_handle == null or dep_handle == null:
            errors.append("Could not create external runtime source closure fixture files.")
        else:
            root_handle.store_string("extends RefCounted\nconst Dep = preload(\"res://runtime/dep.gd\")\n"); root_handle.close()
            dep_handle.store_string("extends RefCounted\n"); dep_handle.close()
            var external_closure: Dictionary = SourceClosure.resolve(["runtime/root.gd"], external_root)
            var expected_paths: Array[String] = ["runtime/dep.gd", "runtime/root.gd"]
            if not external_closure.get("ok", false) or external_closure.get("paths", []) != expected_paths:
                errors.append("Runtime source closure cannot resolve raw dependencies from an external packaged source root.")

    var original_tool := str(ProjectSettings.get_setting("playworld/export/godot_executable", ""))
    ProjectSettings.set_setting("playworld/export/godot_executable", "Z:/phase17-intentionally-missing/godot.exe")
    var missing_tool: Dictionary = ExportPipeline._resolve_export_tooling()
    ProjectSettings.set_setting("playworld/export/godot_executable", original_tool)
    if missing_tool.get("ok", false) or not str(missing_tool.get("errors", [])).to_lower().contains("missing"):
        errors.append("Missing configured export tooling does not fail explicitly.")

    var original_appdata := OS.get_environment("APPDATA")
    OS.set_environment("APPDATA", ProjectSettings.globalize_path("user://phase17-empty-appdata-%d" % Time.get_ticks_usec()))
    var missing_template: Dictionary = ExportPipeline._ensure_windows_export_templates()
    OS.set_environment("APPDATA", original_appdata)
    if missing_template.get("ok", false) or not str(missing_template.get("errors", [])).to_lower().contains("missing"):
        errors.append("Missing Windows export templates do not fail explicitly.")

    var malformed := "user://phase17-contract-malformed.cfg"
    var handle := FileAccess.open(malformed, FileAccess.WRITE)
    if handle == null: errors.append("Could not create malformed preference contract fixture.")
    else:
        handle.store_string("[preferences\ninvalid"); handle.close()
        var loaded: Dictionary = UserPreferences.new(malformed).load_preferences()
        if loaded.get("ok", false) or loaded.get("settings", {}) != UserPreferences.defaults(): errors.append("Malformed preferences do not fail with safe defaults.")

    var user_projects := ProjectSettings.globalize_path("user://projects").replace("\\", "/").simplify_path()
    var install_root := ProjectSettings.globalize_path("res://").replace("\\", "/").simplify_path().trim_suffix("/")
    if user_projects == install_root or user_projects.begins_with(install_root + "/"): errors.append("User projects resolve into the application install/source root.")

    var scene_resource := load("res://src/main/Main.tscn") as PackedScene
    if scene_resource == null: errors.append("Creator Main scene cannot load for release contracts.")
    else:
        var main := scene_resource.instantiate()
        root.add_child(main)
        await process_frame
        var about := main.get_node_or_null("HomeScreen/SafeArea/Content/Header/HeaderActions/AboutButton")
        if about == null: errors.append("Home About/version surface is missing.")
        main.queue_free(); await process_frame

    if errors.is_empty():
        print("PASS: Phase 17 release identity, packaging, user-data, and failure contracts completed.")
        quit(0); return
    for error in errors: push_error(error)
    quit(1)
