extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const AssetLibrary = preload("res://src/assets/asset_library_service.gd")
const SourceResolver = preload("res://src/procedural/procedural_source_resolver.gd")

class PrefabStateFixture:
    extends RefCounted
    var records: Dictionary = {}
    func get_prefab(prefab_id: String) -> Dictionary:
        var value: Variant = records.get(prefab_id, {})
        return value.duplicate(true) if value is Dictionary else {}
    func get_socket(_socket_id: String) -> Dictionary: return {}

class GameplayServiceFixture:
    extends RefCounted
    var state
    func _init(state_value) -> void: state = state_value
    func get_state(): return state


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var root: String = "user://tests/phase9_sources_%s" % StableId.generate()
    var source_root: String = root.path_join("external_source")
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(source_root))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS:
        return ["Phase 9 source fixture could not create source directory."]
    var scene_path: String = source_root.path_join("foliage_asset.tscn")
    var scene_text := "[gd_scene load_steps=2 format=3]\n\n[sub_resource type=\"BoxMesh\" id=\"BoxMesh_phase9\"]\nsize = Vector3(1.2, 2.0, 1.2)\n\n[node name=\"FoliageAsset\" type=\"Node3D\"]\n\n[node name=\"Mesh\" type=\"MeshInstance3D\" parent=\".\"]\nmesh = SubResource(\"BoxMesh_phase9\")\n"
    var file := FileAccess.open(scene_path, FileAccess.WRITE)
    if file == null:
        return ["Phase 9 source fixture could not write source scene."]
    file.store_string(scene_text)
    file.close()

    var library = AssetLibrary.new(root)
    var load_result: Dictionary = library.load_library()
    if not load_result.get("ok", false):
        return ["Phase 9 source fixture could not initialize Asset Library: %s" % str(load_result.get("errors", []))]
    var register: Dictionary = library.register_source(ProjectSettings.globalize_path(source_root), "Phase 9 External")
    if not register.get("ok", false):
        return ["Phase 9 source fixture could not scan external source: %s" % str(register.get("errors", []))]
    var records: Array[Dictionary] = library.get_records(false)
    if records.size() != 1:
        errors.append("External source scan must produce exactly one managed asset record for the fixture.")
        return errors
    var asset_id: String = str(records[0].get("asset_id", ""))
    if not StableId.is_valid(asset_id):
        errors.append("Asset Library source must expose stable asset identity.")

    var resolver = SourceResolver.new()
    resolver.bind(library, null)
    var asset_result: Dictionary = resolver.resolve_mesh({"kind": "asset", "source_id": asset_id})
    if not asset_result.get("ok", false) or not asset_result.get("mesh") is Mesh:
        errors.append("A real Asset Library scene containing MeshInstance3D must resolve into a procedural foliage mesh.")
    if not FileAccess.file_exists(scene_path):
        errors.append("Procedural asset resolution must leave the external source scene in place and read-only from the project's perspective.")

    var base_prefab_id: String = StableId.generate()
    var child_prefab_id: String = StableId.generate()
    var visual_node_id: String = StableId.generate()
    var prefab_state = PrefabStateFixture.new()
    prefab_state.records[base_prefab_id] = {
        "prefab_id": base_prefab_id,
        "display_name": "Base Foliage Prefab",
        "base_prefab_id": null,
        "nodes": [{"node_id": visual_node_id, "parent_node_id": null, "asset_id": asset_id}],
        "socket_ids": [],
        "node_overrides": {},
        "removed_node_ids": [],
        "removed_socket_ids": [],
    }
    prefab_state.records[child_prefab_id] = {
        "prefab_id": child_prefab_id,
        "display_name": "Derived Foliage Prefab",
        "base_prefab_id": base_prefab_id,
        "nodes": [],
        "socket_ids": [],
        "node_overrides": {},
        "removed_node_ids": [],
        "removed_socket_ids": [],
    }
    var gameplay_fixture = GameplayServiceFixture.new(prefab_state)
    resolver.bind(library, gameplay_fixture)
    var prefab_result: Dictionary = resolver.resolve_mesh({"kind": "prefab", "source_id": child_prefab_id})
    if not prefab_result.get("ok", false) or not prefab_result.get("mesh") is Mesh:
        errors.append("Derived Phase 6 prefab foliage source must resolve inherited Asset Library visual mesh data.")
    elif str(prefab_result.get("source_kind", "")) != "prefab":
        errors.append("Resolved prefab foliage must preserve prefab source provenance.")

    if resolver.resolve_mesh({"kind": "asset", "source_id": StableId.generate()}).get("ok", false):
        errors.append("Missing Asset Library foliage references must fail closed.")
    if resolver.resolve_mesh({"kind": "prefab", "source_id": StableId.generate()}).get("ok", false):
        errors.append("Missing prefab foliage references must fail closed.")
    return errors
