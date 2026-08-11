extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const AssetLibraryService = preload("res://src/assets/asset_library_service.gd")
const AssetSource = preload("res://src/assets/asset_source.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var test_root := "user://tests/phase4_assets_%s" % StableId.generate()
    var source_root := test_root.path_join("external_source")
    var project_root := test_root.path_join("project")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(source_root))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(project_root))

    var tree_path := source_root.path_join("props/tree.tscn")
    var gltf_path := source_root.path_join("models/minimal.gltf")
    var corrupt_path := source_root.path_join("broken/corrupt.gltf")
    _write_text(tree_path, _tree_scene("Tree"))
    _write_text(gltf_path, _minimal_gltf())
    _write_text(corrupt_path, "not valid json")
    for index in range(128):
        _write_text(source_root.path_join("scale/item_%03d.tscn" % index), _tree_scene("Item%03d" % index))

    var before_snapshot := _snapshot(source_root)
    var library = AssetLibraryService.new(project_root)
    var load_result: Dictionary = library.load_library()
    if not load_result.get("ok", false):
        errors.append("Asset Library must initialize managed project storage: %s" % [load_result.get("errors", [])])
        return errors

    var overlap_result: Dictionary = library.register_source(project_root, "Invalid overlap")
    if overlap_result.get("ok", false):
        errors.append("Source registration must reject overlap with project-managed Asset Library storage.")

    var register_result: Dictionary = library.register_source(source_root, "Test Source")
    if not register_result.get("ok", false):
        errors.append("Readable external source folder must register and scan: %s" % [register_result.get("errors", [])])
        return errors
    var first_stats: Dictionary = register_result.get("stats", {})
    if int(first_stats.get("files", 0)) != 131 or int(first_stats.get("hashed", 0)) != 131:
        errors.append("Initial scan must deterministically hash every supported source asset exactly once.")
    if _snapshot(source_root) != before_snapshot:
        errors.append("Registering, scanning, analyzing, cataloging, and thumbnailing must not modify source files.")

    var second_scan: Dictionary = library.scan_all()
    var second_stats: Dictionary = second_scan.get("stats", {})
    if not second_scan.get("ok", false) or int(second_stats.get("hashed", -1)) != 0 or int(second_stats.get("reused", 0)) != 131:
        errors.append("Unchanged incremental rescans must reuse deterministic source hashes instead of reprocessing files.")

    var tree_record := _record_by_relative(library.get_records(), "props/tree.tscn")
    var gltf_record := _record_by_relative(library.get_records(), "models/minimal.gltf")
    var corrupt_record := _record_by_relative(library.get_records(), "broken/corrupt.gltf")
    if tree_record.is_empty() or not StableId.is_valid(str(tree_record.get("asset_id", ""))):
        errors.append("Cataloged assets must receive stable UUID asset identities.")
        return errors
    if not bool(tree_record.get("analysis", {}).get("ok", false)) or not bool(gltf_record.get("analysis", {}).get("ok", false)):
        errors.append("Supported Godot text scenes and GLTF 2.0 files must pass structural analysis.")
    if corrupt_record.is_empty() or bool(corrupt_record.get("analysis", {}).get("ok", true)):
        errors.append("Corrupt GLTF input must be cataloged as a safe analysis failure instead of crashing or loading it.")

    var tree_id := str(tree_record["asset_id"])
    library.set_favorite(tree_id, true)
    library.set_license(tree_id, {"spdx": "CC0-1.0", "author": "Fixture Author", "source_url": "https://example.invalid/source", "notes": "Test metadata"})
    library.add_to_collection(tree_id, "Nature")
    var reloaded = AssetLibraryService.new(project_root)
    var reload_result: Dictionary = reloaded.load_library()
    var persisted: Dictionary = reloaded.get_record(tree_id)
    if not reload_result.get("ok", false) or not bool(persisted.get("favorite", false)) or not persisted.get("collections", []).has("Nature") or str(persisted.get("license", {}).get("spdx", "")) != "CC0-1.0":
        errors.append("Favorites, collections, licensing, and catalog metadata must persist across library restart.")

    var thumbnail: Dictionary = persisted.get("thumbnail", {})
    var thumbnail_path := str(thumbnail.get("path", ""))
    if thumbnail_path.is_empty() or not FileAccess.file_exists(thumbnail_path) or not AssetSource.normalize_path(thumbnail_path).begins_with(AssetSource.normalize_path(project_root) + "/"):
        errors.append("Generated thumbnails must live only in project-managed storage.")

    var moved_path := source_root.path_join("props/moved_tree.tscn")
    DirAccess.rename_absolute(ProjectSettings.globalize_path(tree_path), ProjectSettings.globalize_path(moved_path))
    var move_scan: Dictionary = reloaded.scan_all()
    var moved_record: Dictionary = _record_by_relative(reloaded.get_records(), "props/moved_tree.tscn")
    if not move_scan.get("ok", false) or str(moved_record.get("asset_id", "")) != tree_id:
        errors.append("A uniquely provable in-source move must reconcile back to the original stable asset ID.")

    var duplicate_path := source_root.path_join("props/tree_copy.tscn")
    _copy_file(moved_path, duplicate_path)
    var duplicate_scan: Dictionary = reloaded.scan_all()
    var copy_record: Dictionary = _record_by_relative(reloaded.get_records(), "props/tree_copy.tscn")
    if not duplicate_scan.get("ok", false) or copy_record.is_empty() or str(copy_record.get("asset_id", "")) == tree_id:
        errors.append("Duplicate content must receive its own catalog identity rather than silently merging source files.")
    if reloaded.duplicate_groups().is_empty():
        errors.append("Duplicate detection must report exact-content groups without deleting or merging source assets.")

    var import_before := _snapshot(source_root)
    var import_result: Dictionary = reloaded.ensure_import(tree_id)
    var gltf_import: Dictionary = reloaded.ensure_import(str(gltf_record.get("asset_id", "")))
    if not import_result.get("ok", false) or not gltf_import.get("ok", false):
        errors.append("Supported Godot and GLTF assets must create project-managed derived imports.")
    for result in [import_result, gltf_import]:
        var imported_path := str(result.get("derived", {}).get("imported_path", ""))
        if imported_path.is_empty() or not FileAccess.file_exists(imported_path) or not AssetSource.normalize_path(imported_path).begins_with(AssetSource.normalize_path(project_root) + "/"):
            errors.append("Derived import files must be stored under project-managed storage.")
    if _snapshot(source_root) != import_before:
        errors.append("Managed import generation must never modify registered source assets.")

    var old_copy_thumbnail := str(copy_record.get("thumbnail", {}).get("path", ""))
    _write_text(duplicate_path, _tree_scene("TreeCopyChanged") + "\n# content changed with a different size\n")
    var changed_scan: Dictionary = reloaded.scan_all()
    var changed_copy: Dictionary = _record_by_relative(reloaded.get_records(), "props/tree_copy.tscn")
    var new_copy_thumbnail := str(changed_copy.get("thumbnail", {}).get("path", ""))
    if not changed_scan.get("ok", false) or old_copy_thumbnail == new_copy_thumbnail or new_copy_thumbnail.is_empty() or not FileAccess.file_exists(new_copy_thumbnail):
        errors.append("Content changes must invalidate and regenerate the asset thumbnail cache deterministically.")
    if not old_copy_thumbnail.is_empty() and FileAccess.file_exists(old_copy_thumbnail):
        errors.append("Stale thumbnail cache entries for a changed asset must be invalidated.")

    var corrupt_import: Dictionary = reloaded.ensure_import(str(corrupt_record.get("asset_id", "")))
    if corrupt_import.get("ok", false):
        errors.append("Corrupt analyzed assets must fail import before unsafe engine loading is attempted.")

    var missing_source_path := source_root + "_offline"
    DirAccess.rename_absolute(ProjectSettings.globalize_path(source_root), ProjectSettings.globalize_path(missing_source_path))
    var missing_scan: Dictionary = reloaded.scan_all()
    if missing_scan.get("ok", true):
        errors.append("Missing registered sources must surface a recoverable scan failure.")
    var missing_tree: Dictionary = reloaded.get_record(tree_id)
    if not bool(missing_tree.get("missing", false)):
        errors.append("Catalog records must be retained and marked missing when a registered source becomes unavailable.")

    return errors


static func _record_by_relative(records: Array, relative_path: String) -> Dictionary:
    for record in records:
        if str(record.get("relative_path", "")) == relative_path and not bool(record.get("missing", false)):
            return record
    return {}


static func _tree_scene(root_name: String) -> String:
    return "[gd_scene load_steps=2 format=3]\n\n[sub_resource type=\"BoxMesh\" id=\"BoxMesh_fixture\"]\n\n[node name=\"%s\" type=\"Node3D\"]\n\n[node name=\"Mesh\" type=\"MeshInstance3D\" parent=\".\"]\nmesh = SubResource(\"BoxMesh_fixture\")\n" % root_name


static func _minimal_gltf() -> String:
    return JSON.stringify({"asset": {"version": "2.0", "generator": "PlayWorld Phase 4 test"}, "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [{"name": "Root"}]})


static func _write_text(path: String, text: String) -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(text)
    file.flush()
    file.close()


static func _copy_file(source_path: String, target_path: String) -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_path.get_base_dir()))
    var source := FileAccess.open(source_path, FileAccess.READ)
    var bytes := source.get_buffer(source.get_length())
    source.close()
    var target := FileAccess.open(target_path, FileAccess.WRITE)
    target.store_buffer(bytes)
    target.close()


static func _snapshot(root: String) -> Dictionary:
    var result: Dictionary = {}
    _snapshot_dir(root, "", result)
    return result


static func _snapshot_dir(root: String, relative: String, result: Dictionary) -> void:
    var path := root if relative.is_empty() else root.path_join(relative)
    var directory := DirAccess.open(path)
    if directory == null: return
    directory.list_dir_begin()
    var entry := directory.get_next()
    while not entry.is_empty():
        var child_relative := entry if relative.is_empty() else relative.path_join(entry)
        if directory.current_is_dir():
            if not directory.is_link(entry): _snapshot_dir(root, child_relative, result)
        else:
            result[child_relative.replace("\\", "/")] = FileAccess.get_sha256(root.path_join(child_relative))
        entry = directory.get_next()
    directory.list_dir_end()
