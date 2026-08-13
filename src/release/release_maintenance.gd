extends Node

const ProductIdentity = preload("res://src/release/product_identity.gd")
const ProjectRepository = preload("res://src/world/project_repository.gd")
const CheckpointStore = preload("res://src/world/checkpoint_store.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const StableId = preload("res://src/world/stable_id.gd")

const MIGRATION_DIR := "user://release"
const MIGRATION_STATE := "user://release/migration_state.json"
const SUPPORT_PATH := "user://support/PlayWorld-Support.json"
const TARGET_VERSION := "0.1.0"
const RC_VERSION := "0.1.0-rc.1"

var startup_result: Dictionary = {}
var _support_panel: PanelContainer
var _status_label: Label
var _recovery_list: VBoxContainer

func _ready() -> void:
    startup_result = run_startup_migration()
    call_deferred("_attach_support_surface")

func run_startup_migration() -> Dictionary:
    var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MIGRATION_DIR))
    if make_error not in [OK, ERR_ALREADY_EXISTS]: return _failure("Could not create release migration state directory.")
    if FileAccess.file_exists(MIGRATION_STATE):
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MIGRATION_STATE))
        if parsed is Dictionary and str(parsed.get("target_version", "")) == TARGET_VERSION:
            return {"ok": true, "errors": [], "migrated": false, "idempotent": true, "state": parsed}
    var backups: Array[String] = []
    for item in [
        {"path": "user://scale_polish.cfg", "name": "scale_polish.cfg"},
        {"path": "user://asset_library/library.json", "name": "asset-library.json"},
    ]:
        var path := str(item["path"])
        if FileAccess.file_exists(path):
            var backup := "%s/backups/%s.%d.bak" % [MIGRATION_DIR, str(item["name"]), Time.get_unix_time_from_system()]
            if _copy_file(path, backup): backups.append(backup)
    var state := {
        "schema_version": 1,
        "source_version": RC_VERSION,
        "target_version": TARGET_VERSION,
        "migrated_at_unix": int(Time.get_unix_time_from_system()),
        "non_destructive": true,
        "backups": backups,
    }
    var write := _write_json_atomic(MIGRATION_STATE, state)
    if not write.get("ok", false): return write
    return {"ok": true, "errors": [], "migrated": true, "idempotent": false, "state": state}

func project_health() -> Array[Dictionary]:
    var entries: Array[Dictionary] = []
    var root_path := str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects"))
    var directory := DirAccess.open(root_path)
    if directory == null: return entries
    var repository = ProjectRepository.new(root_path)
    var checkpoint_store = CheckpointStore.new(root_path)
    directory.list_dir_begin()
    var entry := directory.get_next()
    while not entry.is_empty():
        if directory.current_is_dir() and StableId.is_valid(entry):
            var opened: Dictionary = repository.open_project(entry)
            if opened.get("ok", false):
                var project = opened.get("project")
                entries.append({"project_id": entry, "status": "ok", "title": str(project.title), "errors": [], "recoverable": false})
            else:
                var checkpoints: Array = checkpoint_store.list_checkpoints(entry)
                entries.append({"project_id": entry, "status": "corrupted", "title": "Damaged world %s" % entry.substr(0, 8), "errors": opened.get("errors", []), "recoverable": not checkpoints.is_empty()})
        entry = directory.get_next()
    directory.list_dir_end()
    entries.sort_custom(func(a: Dictionary, b: Dictionary): return str(a.get("title", "")) < str(b.get("title", "")))
    return entries

func recover_project(project_id: String) -> Dictionary:
    if not StableId.is_valid(project_id): return _failure("Project ID is invalid; recovery was not attempted.")
    var root_path := str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects"))
    var store = CheckpointStore.new(root_path)
    var checkpoints: Array = store.list_checkpoints(project_id)
    if checkpoints.is_empty(): return _failure("No valid checkpoint is available for this project.")
    var canonical := "%s/%s/project.json" % [root_path.trim_suffix("/"), project_id]
    var backup := ""
    if FileAccess.file_exists(canonical):
        backup = "%s.corrupt-%d.bak" % [canonical, Time.get_unix_time_from_system()]
        if not _copy_file(canonical, backup): return _failure("The damaged project metadata could not be backed up; recovery stopped without changing it.")
    var record = checkpoints[0]["record"]
    var project = WorldProject.new()
    var errors: Array[String] = project.load_dictionary(record.project_state)
    if not errors.is_empty() or str(project.project_id) != project_id:
        return {"ok": false, "errors": errors + ["Checkpoint project identity does not match the damaged project."], "backup_path": backup}
    var saved: Dictionary = ProjectRepository.new(root_path).save_project(project)
    if not saved.get("ok", false): return {"ok": false, "errors": saved.get("errors", ["Recovered project could not be promoted."]), "backup_path": backup}
    saved["backup_path"] = backup
    saved["recovered_from"] = str(checkpoints[0]["path"])
    return saved

func diagnostic_report() -> Dictionary:
    var install_root := OS.get_executable_path().get_base_dir()
    var manifest := _read_release_manifest(install_root.path_join("release_manifest.json"))
    var bundled_godot := install_root.path_join("tools/godot/godot.exe")
    var bundled_template := install_root.path_join("tools/export_templates/4.7.1.stable/windows_release_x86_64.exe")
    var user_root := ProjectSettings.globalize_path("user://")
    return {
        "schema_version": 1,
        "product": ProductIdentity.summary(),
        "build_source_commit": str(manifest.get("source_commit", ProductIdentity.BASE_COMMIT)),
        "godot_runtime": Engine.get_version_info().get("string", "unknown"),
        "os": {"name": OS.get_name(), "version": OS.get_version()},
        "rendering_backend": RenderingServer.get_current_rendering_method(),
        "gpu": RenderingServer.get_video_adapter_name(),
        "install_mode": _install_mode(install_root),
        "directories": {
            "user_data": user_root,
            "projects": ProjectSettings.globalize_path(str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects"))),
            "asset_library": ProjectSettings.globalize_path(str(ProjectSettings.get_setting("playworld/assets/library_root", "user://asset_library"))),
        },
        "recent_application_errors": [],
        "exporter": {"bundled_godot_available": FileAccess.file_exists(bundled_godot), "windows_template_available": FileAccess.file_exists(bundled_template)},
        "project_schema_version": WorldProject.SCHEMA_VERSION,
        "asset_library_health": _asset_library_health(),
        "migration": startup_result.duplicate(true),
    }

func create_support_bundle() -> Dictionary:
    var report := diagnostic_report()
    var text := JSON.stringify(report, "  ", true)
    if _contains_secret_material(text): return _failure("Diagnostic report was blocked because credential-like material was detected.")
    var result := _write_json_atomic(SUPPORT_PATH, report)
    if not result.get("ok", false): return result
    result["path"] = ProjectSettings.globalize_path(SUPPORT_PATH)
    return result

func show_support_panel() -> void:
    if _support_panel == null: _build_support_panel()
    if _support_panel == null: return
    _refresh_support_panel()
    _support_panel.show()
    var first := _support_panel.find_child("CreateBundleButton", true, false) as Button
    if first != null: first.grab_focus()

func _attach_support_surface() -> void:
    for _frame in range(12):
        var main := get_tree().current_scene
        if main != null:
            var actions := main.get_node_or_null("HomeScreen/SafeArea/Content/Header/HeaderActions")
            if actions != null and actions.get_node_or_null("SupportButton") == null:
                var button := Button.new()
                button.name = "SupportButton"; button.text = "Support"; button.theme_type_variation = &"ToolButton"; button.custom_minimum_size = Vector2(104, 42)
                actions.add_child(button); button.pressed.connect(show_support_panel)
                _build_support_panel(); return
        await get_tree().process_frame

func _build_support_panel() -> void:
    var main := get_tree().current_scene
    if main == null: return
    var home := main.get_node_or_null("HomeScreen") as Control
    if home == null: return
    _support_panel = PanelContainer.new(); _support_panel.name = "StableSupportPanel"; _support_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); _support_panel.theme_type_variation = &"DrawerPanel"; home.add_child(_support_panel)
    var margin := MarginContainer.new(); for side in ["left","top","right","bottom"]: pass
    margin.add_theme_constant_override("margin_left", 72); margin.add_theme_constant_override("margin_top", 44); margin.add_theme_constant_override("margin_right", 72); margin.add_theme_constant_override("margin_bottom", 44); _support_panel.add_child(margin)
    var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 14); margin.add_child(column)
    var top := HBoxContainer.new(); column.add_child(top)
    var back := Button.new(); back.text = "Back"; back.theme_type_variation = &"ToolButton"; back.custom_minimum_size = Vector2(100, 46); top.add_child(back); back.pressed.connect(func(): _support_panel.hide())
    var title := Label.new(); title.text = "Support & Recovery"; title.theme_type_variation = &"TitleLabel"; title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(title)
    var identity := Label.new(); identity.name = "IdentityLabel"; identity.text = "PlayWorld Studio %s • stable • Windows x64" % ProductIdentity.version(); identity.theme_type_variation = &"SecondaryLabel"; column.add_child(identity)
    _status_label = Label.new(); _status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _status_label.theme_type_variation = &"SecondaryLabel"; column.add_child(_status_label)
    var create := Button.new(); create.name = "CreateBundleButton"; create.text = "Create Support Bundle"; create.theme_type_variation = &"PrimaryButton"; create.custom_minimum_size = Vector2(240, 48); column.add_child(create); create.pressed.connect(_on_create_bundle)
    var recovery_title := Label.new(); recovery_title.text = "World recovery"; recovery_title.theme_type_variation = &"SectionLabel"; column.add_child(recovery_title)
    var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; column.add_child(scroll)
    _recovery_list = VBoxContainer.new(); _recovery_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _recovery_list.add_theme_constant_override("separation", 10); scroll.add_child(_recovery_list)
    _support_panel.hide(); _refresh_support_panel()

func _refresh_support_panel() -> void:
    if _status_label != null:
        _status_label.text = "Diagnostics are bounded and exclude API keys, environment secrets, and project content. User data: %s" % ProjectSettings.globalize_path("user://")
    if _recovery_list == null: return
    for child in _recovery_list.get_children(): child.queue_free()
    var damaged := 0
    for item in project_health():
        if str(item.get("status", "")) != "corrupted": continue
        damaged += 1
        var button := Button.new(); button.theme_type_variation = &"CardButton"; button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        var recoverable := bool(item.get("recoverable", false)); button.disabled = not recoverable
        button.text = "%s\n%s" % [str(item.get("title", "Damaged world")), "Recover from newest valid checkpoint" if recoverable else "No valid checkpoint available"]
        var id := str(item.get("project_id", "")); if recoverable: button.pressed.connect(_recover_from_panel.bind(id)); _recovery_list.add_child(button)
    if damaged == 0:
        var label := Label.new(); label.text = "No damaged project metadata detected."; label.theme_type_variation = &"SecondaryLabel"; _recovery_list.add_child(label)

func _recover_from_panel(project_id: String) -> void:
    var result := recover_project(project_id)
    _status_label.text = "Recovered project; damaged metadata backup: %s" % str(result.get("backup_path", "")) if result.get("ok", false) else "Recovery failed without deleting the original data: %s" % str(result.get("errors", []))
    _refresh_support_panel()

func _on_create_bundle() -> void:
    var result := create_support_bundle()
    _status_label.text = "Support bundle created: %s" % str(result.get("path", "")) if result.get("ok", false) else "Support bundle failed: %s" % str(result.get("errors", []))

func _asset_library_health() -> Dictionary:
    var root := str(ProjectSettings.get_setting("playworld/assets/library_root", "user://asset_library"))
    var absolute := ProjectSettings.globalize_path(root)
    return {"root_available": DirAccess.dir_exists_absolute(absolute), "configured_root": absolute}

func _install_mode(install_root: String) -> String:
    var marker := install_root.path_join("install_mode.txt")
    if not FileAccess.file_exists(marker): return "development"
    var value := FileAccess.get_file_as_string(marker).strip_edges().to_lower()
    return value if value in ["portable", "installed"] else "unknown"

func _read_release_manifest(path: String) -> Dictionary:
    if not FileAccess.file_exists(path): return {}
    var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    return value if value is Dictionary else {}

func _contains_secret_material(text: String) -> bool:
    var lower := text.to_lower()
    if lower.contains(".polyforkapi") or lower.contains("openai_api_key") or lower.contains("api_key="): return true
    var regex := RegEx.new(); regex.compile("(?i)sk-(?:proj-)?[a-z0-9_-]{24,}")
    return regex.search(text) != null

func _write_json_atomic(path: String, value: Dictionary) -> Dictionary:
    var absolute := ProjectSettings.globalize_path(path)
    var make_error := DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
    if make_error not in [OK, ERR_ALREADY_EXISTS]: return _failure("Could not create directory for %s" % path)
    var temp := "%s.phase18-tmp" % path
    var handle := FileAccess.open(temp, FileAccess.WRITE)
    if handle == null: return _failure("Could not stage %s" % path)
    handle.store_string(JSON.stringify(value, "  ", true) + "\n"); handle.close()
    var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), absolute)
    if rename_error != OK: DirAccess.remove_absolute(ProjectSettings.globalize_path(temp)); return _failure("Could not atomically replace %s" % path)
    return {"ok": true, "errors": []}

func _copy_file(source: String, target: String) -> bool:
    var absolute_target := ProjectSettings.globalize_path(target)
    if DirAccess.make_dir_recursive_absolute(absolute_target.get_base_dir()) not in [OK, ERR_ALREADY_EXISTS]: return false
    var data := FileAccess.get_file_as_bytes(source)
    var handle := FileAccess.open(target, FileAccess.WRITE)
    if handle == null: return false
    handle.store_buffer(data); handle.close(); return true

func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
