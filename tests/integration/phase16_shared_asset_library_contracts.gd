class_name Phase16SharedAssetLibraryContracts
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const AssetLibrary = preload("res://src/assets/asset_library_service.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var root := "user://tests/phase16/shared-assets-%s" % StableId.generate()
    var shared_root := root.path_join("universal-library")
    var source_root := root.path_join("external-source")
    var project_a := root.path_join("project-a")
    var project_b := root.path_join("project-b")
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(source_root))
    if make_error not in [OK, ERR_ALREADY_EXISTS]: return ["Could not create universal-library source fixture."]
    var source_path := source_root.path_join("shared_box.tscn")
    var source_text := "[gd_scene load_steps=2 format=3]\n\n[sub_resource type=\"BoxMesh\" id=\"BoxMesh_shared\"]\nsize = Vector3(2, 2, 2)\n\n[node name=\"SharedBox\" type=\"Node3D\"]\n\n[node name=\"MeshInstance3D\" type=\"MeshInstance3D\" parent=\".\"]\nmesh = SubResource(\"BoxMesh_shared\")\n"
    var file := FileAccess.open(source_path, FileAccess.WRITE)
    if file == null: return ["Could not write universal-library source fixture."]
    file.store_string(source_text); file.close()
    var original_hash := FileAccess.get_sha256(source_path)

    var library_a = AssetLibrary.new(project_a, shared_root)
    var load_a: Dictionary = library_a.load_library()
    if not load_a.get("ok", false): return ["Project A could not open shared Asset Library: %s" % str(load_a.get("errors", []))]
    var registered: Dictionary = library_a.register_source(source_root, "Shared Fixture")
    if not registered.get("ok", false): return ["Project A could not register shared source: %s" % str(registered.get("errors", []))]
    var records_a: Array[Dictionary] = library_a.get_records(false)
    if records_a.size() != 1: errors.append("Project A did not index exactly one shared asset.")

    var library_b = AssetLibrary.new(project_b, shared_root)
    var load_b: Dictionary = library_b.load_library()
    if not load_b.get("ok", false): return errors + ["Project B could not open shared Asset Library: %s" % str(load_b.get("errors", []))]
    var records_b: Array[Dictionary] = library_b.get_records(false)
    if records_b.size() != 1: errors.append("Project B could not see the asset indexed by Project A.")
    elif not records_a.is_empty() and str(records_a[0].get("asset_id", "")) != str(records_b[0].get("asset_id", "")):
        errors.append("Shared Asset Library changed stable asset identity between projects.")
    if library_b.get_sources(false).size() != 1: errors.append("Shared source registration was not visible across projects.")
    if FileAccess.get_sha256(source_path) != original_hash: errors.append("Shared Asset Library mutated the external source file.")
    if library_a.managed_root != library_b.managed_root or library_a.managed_root != shared_root:
        errors.append("Shared Asset Library instances did not resolve the same user-scoped managed root.")
    return errors
