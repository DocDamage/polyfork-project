class_name PlayWorldDataMigrationRegistry
extends Node

const ReleasePaths = preload("res://src/release/release_paths.gd")
const SemanticVersion = preload("res://src/release/semantic_version.gd")
const WorldProject = preload("res://src/world/world_project.gd")

const STATE_PATH := "user://release/migration_state.json"
const JOURNAL_PATH := "user://release/migration_journal.json"
const BACKUP_ROOT := "user://release/migration_backups"
const TARGET_APPLICATION_VERSION := "0.2.0"
const BASELINE_APPLICATION_VERSION := "0.1.0"

signal migration_started(step_id: String)
signal migration_completed(step_id: String)
signal migration_failed(step_id: String, errors: Array)

var startup_result: Dictionary = {}
var _application_steps: Array[Dictionary] = []
var _project_steps: Array[Dictionary] = []

func _ready() -> void:
    _register_builtin_steps()
    startup_result = run_startup_migrations()

func register_application_step(step_id: String, source_version: String, target_version: String, apply: Callable) -> Dictionary:
    if step_id.strip_edges().is_empty() or not apply.is_valid():
        return ReleasePaths.failure("Application migration registration is invalid.")
    if not SemanticVersion.parse(source_version).get("ok", false) or not SemanticVersion.parse(target_version).get("ok", false):
        return ReleasePaths.failure("Application migration version is invalid.")
    if SemanticVersion.compare(target_version, source_version) <= 0:
        return ReleasePaths.failure("Application migration must advance the version.")
    for existing in _application_steps:
        if str(existing.get("id", "")) == step_id or str(existing.get("from", "")) == source_version:
            return ReleasePaths.failure("Application migration registration is duplicated.")
    _application_steps.append({"id": step_id, "from": source_version, "to": target_version, "apply": apply})
    _application_steps.sort_custom(func(a: Dictionary, b: Dictionary): return SemanticVersion.compare(str(a.get("from", "")), str(b.get("from", ""))) < 0)
    return {"ok": true, "errors": []}

func register_project_step(step_id: String, source_schema: int, target_schema: int, apply: Callable) -> Dictionary:
    if step_id.strip_edges().is_empty() or source_schema < 0 or target_schema <= source_schema or not apply.is_valid():
        return ReleasePaths.failure("Project migration registration is invalid.")
    for existing in _project_steps:
        if str(existing.get("id", "")) == step_id or int(existing.get("from", -1)) == source_schema:
            return ReleasePaths.failure("Project migration registration is duplicated.")
    _project_steps.append({"id": step_id, "from": source_schema, "to": target_schema, "apply": apply})
    _project_steps.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.get("from", 0)) < int(b.get("from", 0)))
    return {"ok": true, "errors": []}

func run_startup_migrations() -> Dictionary:
    if _application_steps.is_empty(): _register_builtin_steps()
    var recovery := recover_interrupted_migration()
    if not recovery.get("ok", false): return recovery
    var state := _load_state()
    if not state.get("ok", false): return state
    var current := str((state.get("state", {}) as Dictionary).get("application_version", BASELINE_APPLICATION_VERSION))
    if SemanticVersion.compare(current, TARGET_APPLICATION_VERSION) > 0:
        return ReleasePaths.failure("Persisted migration state belongs to a newer application version.")
    var completed_steps: Array = (state.get("state", {}) as Dictionary).get("completed_steps", []).duplicate()
    var migration_backups: Array = []
    var migrated := false
    while SemanticVersion.compare(current, TARGET_APPLICATION_VERSION) < 0:
        var step := _find_application_step(current)
        if step.is_empty(): return ReleasePaths.failure("No registered application migration continues from %s." % current)
        var step_id := str(step.get("id", ""))
        migration_started.emit(step_id)
        var snapshot := _create_snapshot(step_id)
        if not snapshot.get("ok", false):
            migration_failed.emit(step_id, snapshot.get("errors", []))
            return snapshot
        migration_backups.append_array(snapshot.get("backups", []))
        var journal := {
            "schema_version": 1,
            "status": "in_progress",
            "step_id": step_id,
            "source_version": current,
            "target_version": str(step.get("to", "")),
            "started_at_unix": int(Time.get_unix_time_from_system()),
            "backups": snapshot.get("backups", []),
            "backup_root": str(snapshot.get("backup_root", "")),
        }
        var journal_write := ReleasePaths.atomic_write_json(JOURNAL_PATH, journal)
        if not journal_write.get("ok", false): return journal_write
        var apply: Callable = step.get("apply", Callable())
        var result: Dictionary = apply.call(snapshot)
        if not result.get("ok", false):
            var restored := _restore_backups(snapshot.get("backups", []))
            journal["status"] = "failed"
            journal["failed_at_unix"] = int(Time.get_unix_time_from_system())
            journal["errors"] = result.get("errors", [])
            journal["restored"] = restored.get("ok", false)
            ReleasePaths.atomic_write_json(JOURNAL_PATH, journal)
            migration_failed.emit(step_id, result.get("errors", []))
            return result
        current = str(step.get("to", ""))
        completed_steps.append(step_id)
        var saved := _save_state(current, completed_steps, migration_backups)
        if not saved.get("ok", false):
            var restored := _restore_backups(snapshot.get("backups", []))
            journal["status"] = "failed"
            journal["failed_at_unix"] = int(Time.get_unix_time_from_system())
            journal["errors"] = saved.get("errors", [])
            journal["restored"] = restored.get("ok", false)
            ReleasePaths.atomic_write_json(JOURNAL_PATH, journal)
            migration_failed.emit(step_id, saved.get("errors", []))
            return saved
        journal["status"] = "completed"
        journal["completed_at_unix"] = int(Time.get_unix_time_from_system())
        var completed_write := ReleasePaths.atomic_write_json(JOURNAL_PATH, journal)
        if not completed_write.get("ok", false): return completed_write
        migration_completed.emit(step_id)
        migrated = true
    var project_audit := migrate_supported_projects()
    if not project_audit.get("ok", false): return project_audit
    return {
        "ok": true,
        "errors": [],
        "migrated": migrated,
        "idempotent": not migrated,
        "source_version": BASELINE_APPLICATION_VERSION,
        "target_version": current,
        "completed_steps": completed_steps,
        "backups": migration_backups,
        "projects": project_audit,
    }

func migrate_supported_projects(projects_root: String = "") -> Dictionary:
    var root_path := projects_root
    if root_path.is_empty(): root_path = str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects"))
    var absolute_root := ProjectSettings.globalize_path(root_path)
    if not DirAccess.dir_exists_absolute(absolute_root):
        return {"ok": true, "errors": [], "migrated": [], "unchanged": [], "unsupported": []}
    var directory := DirAccess.open(absolute_root)
    if directory == null: return ReleasePaths.failure("Project migration root could not be opened.")
    var migrated: Array[String] = []
    var unchanged: Array[String] = []
    var unsupported: Array[String] = []
    directory.list_dir_begin()
    var entry := directory.get_next()
    while not entry.is_empty():
        if directory.current_is_dir():
            var manifest := absolute_root.path_join(entry).path_join("project.json")
            if FileAccess.file_exists(manifest):
                var result := migrate_project_file(manifest)
                if result.get("unsupported_future", false): unsupported.append(entry)
                elif not result.get("ok", false):
                    directory.list_dir_end()
                    return result
                elif result.get("migrated", false): migrated.append(entry)
                else: unchanged.append(entry)
        entry = directory.get_next()
    directory.list_dir_end()
    if not unsupported.is_empty():
        return {"ok": false, "errors": ["One or more projects use an unsupported future schema."], "migrated": migrated, "unchanged": unchanged, "unsupported": unsupported}
    return {"ok": true, "errors": [], "migrated": migrated, "unchanged": unchanged, "unsupported": []}

func migrate_project_file(path: String) -> Dictionary:
    var read := ReleasePaths.read_json(path, 64 * 1024 * 1024)
    if not read.get("ok", false): return read
    var document: Dictionary = read.get("value", {})
    var schema := int(document.get("schema_version", 0))
    if schema > WorldProject.SCHEMA_VERSION:
        return {"ok": false, "errors": ["Project schema %d is newer than supported schema %d." % [schema, WorldProject.SCHEMA_VERSION]], "unsupported_future": true}
    if schema == WorldProject.SCHEMA_VERSION:
        var errors := WorldProject.validate_dictionary(document)
        if not errors.is_empty(): return {"ok": false, "errors": errors}
        return {"ok": true, "errors": [], "migrated": false, "schema_version": schema}
    var backup := "%s.phase19-schema-%d.bak" % [path, schema]
    var copied := ReleasePaths.copy_file(path, backup)
    if not copied.get("ok", false): return copied
    var completed: Array[String] = []
    while schema < WorldProject.SCHEMA_VERSION:
        var step := _find_project_step(schema)
        if step.is_empty(): return ReleasePaths.failure("No registered project migration continues from schema %d." % schema)
        var apply: Callable = step.get("apply", Callable())
        var result: Dictionary = apply.call(document)
        if not result.get("ok", false): return result
        document = result.get("document", document)
        schema = int(step.get("to", schema))
        document["schema_version"] = schema
        completed.append(str(step.get("id", "")))
    var errors := WorldProject.validate_dictionary(document)
    if not errors.is_empty(): return {"ok": false, "errors": errors, "backup_path": backup}
    var write := ReleasePaths.atomic_write_json(path, document)
    if not write.get("ok", false): return write
    return {"ok": true, "errors": [], "migrated": true, "schema_version": schema, "completed_steps": completed, "backup_path": backup}

func recover_interrupted_migration() -> Dictionary:
    if not FileAccess.file_exists(JOURNAL_PATH): return {"ok": true, "errors": [], "recovered": false}
    var read := ReleasePaths.read_json(JOURNAL_PATH)
    if not read.get("ok", false): return read
    var journal: Dictionary = read.get("value", {})
    if str(journal.get("status", "")) != "in_progress": return {"ok": true, "errors": [], "recovered": false}
    var state := _load_state()
    if not state.get("ok", false): return state
    var persisted: Dictionary = state.get("state", {})
    var step_id := str(journal.get("step_id", ""))
    var target_version := str(journal.get("target_version", ""))
    var completed_steps: Array = persisted.get("completed_steps", [])
    if str(persisted.get("application_version", "")) == target_version and completed_steps.has(step_id):
        journal["status"] = "completed_after_interruption"
        journal["reconciled_at_unix"] = int(Time.get_unix_time_from_system())
        var reconciled := ReleasePaths.atomic_write_json(JOURNAL_PATH, journal)
        if not reconciled.get("ok", false): return reconciled
        return {"ok": true, "errors": [], "recovered": true, "restored": false, "step_id": step_id}
    var restored := _restore_backups(journal.get("backups", []))
    if not restored.get("ok", false): return restored
    journal["status"] = "recovered"
    journal["recovered_at_unix"] = int(Time.get_unix_time_from_system())
    var write := ReleasePaths.atomic_write_json(JOURNAL_PATH, journal)
    if not write.get("ok", false): return write
    return {"ok": true, "errors": [], "recovered": true, "restored": true, "step_id": step_id}

func snapshot() -> Dictionary:
    var state := _load_state()
    var journal: Dictionary = {}
    if FileAccess.file_exists(JOURNAL_PATH):
        var read := ReleasePaths.read_json(JOURNAL_PATH)
        if read.get("ok", false): journal = read.get("value", {})
    return {
        "target_application_version": TARGET_APPLICATION_VERSION,
        "state": state.get("state", {}),
        "journal_status": str(journal.get("status", "none")),
        "journal_step": str(journal.get("step_id", "")),
    }

func _register_builtin_steps() -> void:
    if not _application_steps.is_empty(): return
    register_application_step("p19-app-0.1.0-to-0.2.0", "0.1.0", "0.2.0", Callable(self, "_apply_010_to_020"))
    register_project_step("project-schema-0-to-1", 0, 1, Callable(self, "_apply_project_schema_zero"))

func _apply_010_to_020(snapshot: Dictionary) -> Dictionary:
    var release_directory := ReleasePaths.ensure_directory("user://release")
    if not release_directory.get("ok", false): return release_directory
    var updates_directory := ReleasePaths.ensure_directory("user://updates")
    if not updates_directory.get("ok", false): return updates_directory
    var marker := {
        "schema_version": 1,
        "application_version": TARGET_APPLICATION_VERSION,
        "migrated_from": BASELINE_APPLICATION_VERSION,
        "migrated_at_unix": int(Time.get_unix_time_from_system()),
        "backup_root": str(snapshot.get("backup_root", "")),
        "user_data_preserved": true,
    }
    return ReleasePaths.atomic_write_json("user://release/phase19_migration_marker.json", marker)

func _apply_project_schema_zero(document: Dictionary) -> Dictionary:
    var migrated := document.duplicate(true)
    migrated["document_type"] = str(migrated.get("document_type", WorldProject.DOCUMENT_TYPE))
    migrated["schema_version"] = 1
    migrated["cell_ids"] = migrated.get("cell_ids", [])
    migrated["entities"] = migrated.get("entities", [])
    migrated["environment"] = migrated.get("environment", {"time_of_day": 12.75, "weather_profile_id": null})
    migrated["registries"] = migrated.get("registries", {"prefab_ids": [], "archetype_ids": [], "visual_graph_ids": []})
    migrated["runtime"] = migrated.get("runtime", {})
    migrated["editor"] = migrated.get("editor", {"last_mode": "build"})
    migrated["export"] = migrated.get("export", {"preset_id": null})
    migrated["dependencies"] = migrated.get("dependencies", [])
    var now := int(Time.get_unix_time_from_system())
    migrated["created_at_unix"] = int(migrated.get("created_at_unix", now))
    migrated["updated_at_unix"] = int(migrated.get("updated_at_unix", migrated["created_at_unix"]))
    migrated["created_at_msec"] = int(migrated.get("created_at_msec", int(migrated["created_at_unix"]) * 1000))
    migrated["updated_at_msec"] = int(migrated.get("updated_at_msec", int(migrated["updated_at_unix"]) * 1000))
    return {"ok": true, "errors": [], "document": migrated}

func _create_snapshot(step_id: String) -> Dictionary:
    var stamp := "%d-%s" % [Time.get_unix_time_from_system(), step_id]
    var backup_root := BACKUP_ROOT.path_join(stamp)
    var directory := ReleasePaths.ensure_directory(backup_root)
    if not directory.get("ok", false): return directory
    var backups: Array[Dictionary] = []
    var known_files := [
        "user://scale_polish.cfg",
        "user://asset_library/library.json",
        "user://release/update_preferences.cfg",
        "user://release/migration_state.json",
    ]
    for source in known_files:
        if not FileAccess.file_exists(source): continue
        var relative: String = source.replace("user://", "").replace("/", "__")
        var target := backup_root.path_join(relative + ".bak")
        var copied := ReleasePaths.copy_file(source, target)
        if not copied.get("ok", false): return copied
        backups.append({"source": source, "backup": target})
    var projects_root := str(ProjectSettings.get_setting("playworld/storage/projects_root", "user://projects"))
    var projects_absolute := ProjectSettings.globalize_path(projects_root)
    var projects_directory := DirAccess.open(projects_absolute)
    if projects_directory != null:
        projects_directory.list_dir_begin()
        var entry := projects_directory.get_next()
        while not entry.is_empty():
            if projects_directory.current_is_dir():
                var source := projects_absolute.path_join(entry).path_join("project.json")
                if FileAccess.file_exists(source):
                    var target := backup_root.path_join("project-%s.json.bak" % entry)
                    var copied := ReleasePaths.copy_file(source, target)
                    if not copied.get("ok", false): projects_directory.list_dir_end(); return copied
                    backups.append({"source": source, "backup": target})
            entry = projects_directory.get_next()
        projects_directory.list_dir_end()
    return {"ok": true, "errors": [], "backup_root": backup_root, "backups": backups}

func _restore_backups(backups: Array) -> Dictionary:
    var errors: Array[String] = []
    for value in backups:
        if not value is Dictionary: continue
        var record: Dictionary = value
        var source := str(record.get("source", ""))
        var backup := str(record.get("backup", ""))
        if source.is_empty() or backup.is_empty() or not FileAccess.file_exists(backup):
            errors.append("Migration backup record is incomplete.")
            continue
        var restored := ReleasePaths.copy_file(backup, source)
        if not restored.get("ok", false): errors.append_array(restored.get("errors", []))
    return {"ok": errors.is_empty(), "errors": errors}

func _load_state() -> Dictionary:
    if not FileAccess.file_exists(STATE_PATH):
        return {"ok": true, "errors": [], "state": {"schema_version": 1, "application_version": TARGET_APPLICATION_VERSION, "completed_steps": [], "backups": [], "clean_install": true}}
    var read := ReleasePaths.read_json(STATE_PATH)
    if not read.get("ok", false): return read
    var state: Dictionary = read.get("value", {})
    if int(state.get("schema_version", -1)) != 1:
        return ReleasePaths.failure("Migration state schema is unsupported.")
    if not state.has("application_version") and state.has("target_version"):
        state = {
            "schema_version": 1,
            "application_version": str(state.get("target_version", BASELINE_APPLICATION_VERSION)),
            "completed_steps": ["phase18-legacy-migration"],
            "backups": state.get("backups", []),
            "imported_legacy_state": true,
        }
    if not SemanticVersion.parse(str(state.get("application_version", ""))).get("ok", false):
        return ReleasePaths.failure("Migration state application version is invalid.")
    return {"ok": true, "errors": [], "state": state}

func _save_state(version: String, completed_steps: Array, backups: Array) -> Dictionary:
    return ReleasePaths.atomic_write_json(STATE_PATH, {
        "schema_version": 1,
        "application_version": version,
        "completed_steps": completed_steps.duplicate(),
        "backups": backups.duplicate(true),
        "updated_at_unix": int(Time.get_unix_time_from_system()),
    })

func _find_application_step(source_version: String) -> Dictionary:
    for step in _application_steps:
        if str(step.get("from", "")) == source_version: return step
    return {}

func _find_project_step(source_schema: int) -> Dictionary:
    for step in _project_steps:
        if int(step.get("from", -1)) == source_schema: return step
    return {}
