extends SceneTree

const ProductIdentity = preload("res://src/release/product_identity.gd")
const UserPreferences = preload("res://src/scale/user_preferences.gd")
const ProjectRepository = preload("res://src/world/project_repository.gd")

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var errors: Array[String] = []
    if ProductIdentity.version() != "0.1.0" or ProductIdentity.CHANNEL != "stable": errors.append("Runtime identity is not stable PlayWorld Studio 0.1.0.")
    if ProductIdentity.package_name() != "PlayWorld-Studio-0.1.0-Windows-x64": errors.append("Stable portable package name is invalid.")
    var product: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://config/release/product.json"))
    if not product is Dictionary or str(product.get("version", "")) != "0.1.0" or str(product.get("channel", "")) != "stable": errors.append("Authoritative stable product metadata is inconsistent.")
    var preset := FileAccess.get_file_as_string("res://export_presets.cfg")
    for required in ["stable_release", "application/product_version=\"0.1.0\"", "binary_format/architecture=\"x86_64\""]:
        if not preset.contains(required): errors.append("Stable creator export preset is missing metadata: %s" % required)
    if preset.contains("0.1.0-rc.1"): errors.append("Stable export preset still contains RC version identity.")
    var installer := FileAccess.get_file_as_string("res://tools/release/playworld-studio.iss")
    for required in ["PlayWorld-Studio-0.1.0-Windows-x64-Setup", "Uninstallable=yes", "DefaultGroupName=PlayWorld Studio", "install_mode.txt"]:
        if not installer.contains(required): errors.append("Windows installer contract is missing: %s" % required)
    var builder := FileAccess.get_file_as_string("res://tools/release/build_creator_release.py")
    if not builder.contains("user_data_policy") or not builder.contains("supported_upgrade_from") or not builder.contains("install_mode.txt"): errors.append("Stable package manifest does not describe productization/upgrade policy.")

    var malformed := "user://phase18-malformed-preferences.cfg"
    var handle := FileAccess.open(malformed, FileAccess.WRITE)
    if handle == null: errors.append("Could not create malformed preference fixture.")
    else:
        handle.store_string("[preferences\ninvalid"); handle.close()
        var loaded: Dictionary = UserPreferences.new(malformed).load_preferences()
        if loaded.get("ok", false) or loaded.get("settings", {}) != UserPreferences.defaults(): errors.append("Malformed preferences do not fail safely to defaults.")
        var backup := str(loaded.get("recovery_backup", ""))
        if backup.is_empty() or not FileAccess.file_exists(backup): errors.append("Malformed preferences are not preserved for recovery.")

    var maintenance := root.get_node_or_null("ReleaseMaintenance")
    if maintenance == null: errors.append("Phase 18 ReleaseMaintenance autoload is missing.")
    else:
        var migration1: Dictionary = maintenance.call("run_startup_migration")
        var migration2: Dictionary = maintenance.call("run_startup_migration")
        if not migration1.get("ok", false) or not migration2.get("ok", false) or not migration2.get("idempotent", false): errors.append("Stable startup migration is not safe and idempotent.")
        var report: Dictionary = maintenance.call("diagnostic_report")
        for key in ["product", "build_source_commit", "godot_runtime", "os", "rendering_backend", "gpu", "install_mode", "directories", "recent_application_errors", "exporter", "project_schema_version", "asset_library_health"]:
            if not report.has(key): errors.append("Diagnostic report is missing bounded field: %s" % key)
        var bundle: Dictionary = maintenance.call("create_support_bundle")
        if not bundle.get("ok", false) or not FileAccess.file_exists("user://support/PlayWorld-Support.json"): errors.append("Bounded support bundle could not be generated.")
        var bundle_text := FileAccess.get_file_as_string("user://support/PlayWorld-Support.json").to_lower()
        for forbidden in [".polyforkapi", "openai_api_key", "project.json\""]:
            if bundle_text.contains(forbidden): errors.append("Support bundle contains private/credential material: %s" % forbidden)

    var scene_resource := load("res://src/main/Main.tscn") as PackedScene
    if scene_resource == null: errors.append("Creator Main scene cannot load for stable contracts.")
    else:
        var main := scene_resource.instantiate()
        root.add_child(main)
        current_scene = main
        await process_frame
        await process_frame
        await process_frame
        var about := main.get_node_or_null("HomeScreen/SafeArea/Content/Header/HeaderActions/AboutButton")
        var support := main.get_node_or_null("HomeScreen/SafeArea/Content/Header/HeaderActions/SupportButton")
        if about == null: errors.append("Stable About/version surface is missing.")
        if support == null: errors.append("User-facing Support & Recovery surface is missing.")
        var accept_event := InputEventJoypadButton.new(); accept_event.button_index = JOY_BUTTON_A; accept_event.pressed = true
        if not accept_event.is_action("ui_accept"): errors.append("Gamepad A no longer maps to ui_accept.")
        current_scene = null
        main.queue_free(); await process_frame

    if errors.is_empty():
        print("PASS: Phase 18 stable release identity, migration, recovery, installer, and support contracts completed.")
        quit(0)
        return
    for error in errors: push_error(error)
    quit(1)