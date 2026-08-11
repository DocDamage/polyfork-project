extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const Repository = preload("res://src/world/project_repository.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const AssetLibraryService = preload("res://src/assets/asset_library_service.gd")
const AssetPlacementHandoff = preload("res://src/assets/asset_placement_handoff.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var test_root := "user://tests/phase4_placement_%s" % StableId.generate()
    var source_root := test_root.path_join("source")
    var project_storage := test_root.path_join("projects")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(source_root))
    _write_text(source_root.path_join("crate.tscn"), _crate_scene())
    _write_text(source_root.path_join("broken.gltf"), "{broken")

    var project = WorldProject.new()
    project.initialize_new("Phase 4 Placement", &"medium", "blank_sandbox")
    var repository = Repository.new(project_storage)
    var project_dir: String = repository.get_project_directory(project.project_id)
    var library = AssetLibraryService.new(project_dir)
    library.load_library()
    var register_result: Dictionary = library.register_source(source_root, "Placement Fixtures")
    if not register_result.get("ok", false):
        errors.append("Phase 4 placement fixture source must register: %s" % [register_result.get("errors", [])])
        return errors

    var crate: Dictionary = _record_by_relative(library.get_records(), "crate.tscn")
    var broken: Dictionary = _record_by_relative(library.get_records(), "broken.gltf")
    if crate.is_empty() or broken.is_empty():
        errors.append("Placement integration requires both valid and corrupt catalog records.")
        return errors

    var dirty_counter: Array[int] = [0]
    var session = EditorSession.new()
    var bind_result: Dictionary = session.bind_project(project, func() -> Dictionary:
        dirty_counter[0] += 1
        return {"ok": true, "errors": []}
    )
    if not bind_result.get("ok", false):
        errors.append("Phase 4 placement session must bind the project.")
        session.free()
        return errors

    var handoff = AssetPlacementHandoff.new()
    handoff.bind_runtime(session, library)
    var begin: Dictionary = handoff.begin(session, library, crate)
    if not begin.get("ok", false) or not session.is_placement_active() or not session.get_ghost().has_asset_visual():
        errors.append("Selecting a valid catalog asset must create a real visual ghost in the Phase 3 placement editor.")
    if not project.entity_records.is_empty() or dirty_counter[0] != 0:
        errors.append("Asset handoff preview must not bypass the Phase 3 command system or dirty the project before commit.")
    var preview_record: Dictionary = session.get_ghost().get_record()
    if str(preview_record.get("asset_id", "")) != str(crate.get("asset_id", "")):
        errors.append("Asset ghost records must carry the stable catalog asset ID.")

    session.update_placement_preview(Vector3(3.1, 0.5, 2.9))
    var commit: Dictionary = session.commit_placement()
    if not commit.get("ok", false) or project.entity_records.size() != 1 or dirty_counter[0] != 1:
        errors.append("Asset placement must commit exactly once through PlaceEntityCommand and dirty-state signaling.")
        session.free()
        return errors
    var entity_id: String = str(commit.get("entity_id", ""))
    var placed: Dictionary = _entity(project.entity_records, entity_id)
    if str(placed.get("asset_id", "")) != str(crate.get("asset_id", "")):
        errors.append("Committed world entities must persist their catalog asset ID without introducing prefab data.")
    var runtime_node: Variant = session.get_bridge().get_entity_node(entity_id)
    if runtime_node == null or not runtime_node.has_asset_visual():
        errors.append("Committed asset entities must resolve to the real managed scene visual at runtime.")

    var duplicate: Dictionary = session.duplicate_selected()
    if not duplicate.get("ok", false) or project.entity_records.size() != 2:
        errors.append("Command-backed duplicate must continue to work for asset-backed entities.")
    else:
        var duplicate_id := str(duplicate.get("entity_ids", [""])[0])
        if str(_entity(project.entity_records, duplicate_id).get("asset_id", "")) != str(crate.get("asset_id", "")):
            errors.append("Duplicating an asset-backed entity must preserve asset identity while allocating a new entity ID.")

    var entity_count_before_bad: int = project.entity_records.size()
    var bad_begin: Dictionary = handoff.begin(session, library, broken)
    if bad_begin.get("ok", false) or session.is_placement_active() or project.entity_records.size() != entity_count_before_bad:
        errors.append("Corrupt catalog assets must fail placement before engine loading or project mutation.")

    var save_result: Dictionary = repository.save_project(project)
    var reopen_result: Dictionary = repository.open_project(project.project_id)
    if not save_result.get("ok", false) or not reopen_result.get("ok", false):
        errors.append("Asset-backed world entities must survive canonical project persistence and reopen.")
    else:
        var reopened: Variant = reopen_result.get("project")
        var reopened_record: Dictionary = _entity(reopened.entity_records, entity_id)
        if str(reopened_record.get("asset_id", "")) != str(crate.get("asset_id", "")):
            errors.append("Reopened projects must retain stable catalog asset references on world entities.")

    var reloaded_library = AssetLibraryService.new(project_dir)
    reloaded_library.load_library()
    var reloaded_crate: Dictionary = _record_by_relative(reloaded_library.get_records(), "crate.tscn")
    if str(reloaded_crate.get("asset_id", "")) != str(crate.get("asset_id", "")):
        errors.append("Catalog restart must preserve the asset ID used by already-authored world entities.")

    var offline_root := source_root + "_offline"
    DirAccess.rename_absolute(ProjectSettings.globalize_path(source_root), ProjectSettings.globalize_path(offline_root))
    var refresh: Dictionary = session.refresh_runtime(false)
    var fallback_node: Variant = session.get_bridge().get_entity_node(entity_id)
    if not refresh.get("ok", false) or fallback_node == null or fallback_node.has_asset_visual():
        errors.append("Missing source assets must leave authored entities reopenable with a safe proxy fallback.")

    session.free()
    return errors


static func _record_by_relative(records: Array, relative_path: String) -> Dictionary:
    for record in records:
        if str(record.get("relative_path", "")) == relative_path and not bool(record.get("missing", false)): return record
    return {}


static func _entity(records: Array, entity_id: String) -> Dictionary:
    for record in records:
        if str(record.get("entity_id", "")) == entity_id: return record
    return {}


static func _write_text(path: String, text: String) -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(text)
    file.close()


static func _crate_scene() -> String:
    return "[gd_scene load_steps=2 format=3]\n\n[sub_resource type=\"BoxMesh\" id=\"BoxMesh_crate\"]\nsize = Vector3(1.4, 1.0, 1.2)\n\n[node name=\"Crate\" type=\"Node3D\"]\n\n[node name=\"Mesh\" type=\"MeshInstance3D\" parent=\".\"]\nmesh = SubResource(\"BoxMesh_crate\")\n"
