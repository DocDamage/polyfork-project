extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const AssetLibraryService = preload("res://src/assets/asset_library_service.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var test_root := "user://tests/phase4_formats_%s" % StableId.generate()
    var source_root := test_root.path_join("source")
    var project_root := test_root.path_join("project")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(source_root))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(project_root))

    _write_glb(source_root.path_join("minimal.glb"))
    _write_binary_scene(source_root.path_join("binary.scn"))
    _write_text(source_root.path_join("corrupt.scn"), "NOT_A_GODOT_BINARY_RESOURCE")
    _write_text(source_root.path_join("ignored.fbx"), "unsupported fixture")

    var library = AssetLibraryService.new(project_root)
    var load_result: Dictionary = library.load_library()
    if not load_result.get("ok", false):
        errors.append("Format test Asset Library must initialize.")
        return errors
    var register_result: Dictionary = library.register_source(source_root, "Format Fixtures")
    if not register_result.get("ok", false):
        errors.append("Format fixture source must scan without treating structural asset failures as scanner crashes: %s" % [register_result.get("errors", [])])
        return errors

    var glb: Dictionary = _record(library.get_records(), "minimal.glb")
    var binary_scene: Dictionary = _record(library.get_records(), "binary.scn")
    var corrupt_scene: Dictionary = _record(library.get_records(), "corrupt.scn")
    var ignored: Dictionary = _record(library.get_records(), "ignored.fbx")
    if glb.is_empty() or not bool(glb.get("analysis", {}).get("ok", false)):
        errors.append("A structurally valid GLB 2.0 fixture must pass analysis.")
    if binary_scene.is_empty() or not bool(binary_scene.get("analysis", {}).get("ok", false)):
        errors.append("A valid Godot binary scene must pass analysis.")
    if corrupt_scene.is_empty() or bool(corrupt_scene.get("analysis", {}).get("ok", true)):
        errors.append("A corrupt Godot binary scene must remain a safe failed catalog record.")
    if not ignored.is_empty():
        errors.append("Unsupported file extensions must be ignored rather than imported as fabricated asset types.")

    for record in [glb, binary_scene]:
        if record.is_empty(): continue
        var instantiate_result: Dictionary = library.instantiate_asset_scene(str(record.get("asset_id", "")))
        if not instantiate_result.get("ok", false):
            errors.append("Supported %s asset must instantiate through its managed import: %s" % [record.get("asset_type", "asset"), instantiate_result.get("errors", [])])
            continue
        var node_value: Variant = instantiate_result.get("node")
        if not node_value is Node3D:
            errors.append("Supported 3D asset formats must instantiate to Node3D for editor handoff.")
        elif is_instance_valid(node_value):
            node_value.free()

    if not corrupt_scene.is_empty():
        var corrupt_import: Dictionary = library.instantiate_asset_scene(str(corrupt_scene.get("asset_id", "")))
        if corrupt_import.get("ok", false):
            errors.append("Corrupt Godot binary input must be blocked before ResourceLoader instantiation.")

    return errors


static func _record(records: Array, relative_path: String) -> Dictionary:
    for record in records:
        if str(record.get("relative_path", "")) == relative_path and not bool(record.get("missing", false)): return record
    return {}


static func _write_binary_scene(path: String) -> void:
    var root := Node3D.new()
    root.name = "BinaryFixture"
    var packed := PackedScene.new()
    var pack_error: Error = packed.pack(root)
    root.free()
    if pack_error != OK: return
    ResourceSaver.save(packed, path)


static func _write_glb(path: String) -> void:
    var json_text := JSON.stringify({"asset": {"version": "2.0", "generator": "PlayWorld format fixture"}, "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [{"name": "Root"}]})
    var json_bytes := json_text.to_utf8_buffer()
    while json_bytes.size() % 4 != 0: json_bytes.append(0x20)
    var total_length := 20 + json_bytes.size()
    var bytes := PackedByteArray()
    bytes.resize(total_length)
    bytes.encode_u32(0, 0x46546c67)
    bytes.encode_u32(4, 2)
    bytes.encode_u32(8, total_length)
    bytes.encode_u32(12, json_bytes.size())
    bytes.encode_u32(16, 0x4E4F534A)
    for index in range(json_bytes.size()): bytes[20 + index] = json_bytes[index]
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_buffer(bytes)
    file.close()


static func _write_text(path: String, text: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(text)
    file.close()
