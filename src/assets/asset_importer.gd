class_name PlayWorldAssetImporter
extends RefCounted

const AssetRecord = preload("res://src/assets/asset_record.gd")

var imports_root: String


func _init(root: String) -> void:
    imports_root = root.trim_suffix("/")


func ensure_import(record: Dictionary, source_root: String) -> Dictionary:
    var errors := AssetRecord.validate_dictionary(record)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    if bool(record.get("missing", false)): return _failure("Missing source assets cannot be imported.")
    var analysis: Dictionary = record.get("analysis", {})
    if not bool(analysis.get("ok", false)):
        return _failure("Asset analysis did not pass; import is blocked safely.")
    var relative_path := str(record.get("relative_path", ""))
    var source_path := source_root.path_join(relative_path)
    if not FileAccess.file_exists(source_path): return _failure("Asset source file is missing.")
    var hash_text := str(record.get("content_hash", ""))
    var target_dir := imports_root.path_join(str(record.get("asset_id", ""))).path_join(hash_text.substr(0, 16))
    var target_path := target_dir.path_join(relative_path.get_file())
    if FileAccess.file_exists(target_path):
        return {"ok": true, "errors": [], "derived": _derived(record, target_path, target_dir), "reused": true}
    var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_dir))
    if make_error != OK: return _failure("Unable to create managed import directory: %s" % make_error)
    var copy_result := _copy_file(source_path, target_path)
    if not copy_result.get("ok", false): return copy_result
    if str(record.get("asset_type", "")) == "gltf":
        var dependency_result := _copy_gltf_dependencies(source_path, target_dir, source_root)
        if not dependency_result.get("ok", false):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(target_path))
            return dependency_result
    return {"ok": true, "errors": [], "derived": _derived(record, target_path, target_dir), "reused": false}


func instantiate(record: Dictionary, source_root: String) -> Dictionary:
    var import_result := ensure_import(record, source_root)
    if not import_result.get("ok", false): return import_result
    var derived: Dictionary = import_result["derived"]
    var path := str(derived.get("imported_path", ""))
    match str(record.get("asset_type", "")):
        "gltf", "glb":
            var document := GLTFDocument.new()
            var state := GLTFState.new()
            var append_error := document.append_from_file(path, state)
            if append_error != OK: return _failure("Godot could not import the GLTF asset: %s" % append_error)
            var node := document.generate_scene(state)
            if node == null: return _failure("Godot could not generate a scene from the GLTF asset.")
            return {"ok": true, "errors": [], "node": node, "derived": derived}
        "godot_text_scene", "godot_binary_scene":
            var resource := ResourceLoader.load(path)
            if resource == null or not resource is PackedScene:
                return _failure("Godot scene asset could not be loaded as a PackedScene.")
            var node := resource.instantiate()
            if node == null: return _failure("Godot scene asset could not be instantiated.")
            return {"ok": true, "errors": [], "node": node, "derived": derived}
    return _failure("Asset type cannot be instantiated.")


func _copy_gltf_dependencies(source_path: String, target_dir: String, source_root: String) -> Dictionary:
    var parser := JSON.new()
    if parser.parse(FileAccess.get_file_as_string(source_path)) != OK or not parser.data is Dictionary:
        return _failure("GLTF dependency copy requires valid JSON.")
    var uris: Array[String] = []
    for section_name in ["buffers", "images"]:
        var section = parser.data.get(section_name, [])
        if not section is Array: continue
        for item in section:
            if not item is Dictionary: continue
            var uri := str(item.get("uri", ""))
            if uri.is_empty() or uri.begins_with("data:"): continue
            if uri.contains("://"): return _failure("Remote GLTF dependencies are not imported automatically.")
            uris.append(uri)
    uris.sort()
    var source_dir := source_path.get_base_dir()
    var normalized_root := ProjectSettings.globalize_path(source_root).replace("\\", "/").simplify_path().trim_suffix("/")
    for uri in uris:
        var dependency_source := source_dir.path_join(uri).replace("\\", "/").simplify_path()
        var normalized_source := ProjectSettings.globalize_path(dependency_source).replace("\\", "/").simplify_path()
        if normalized_source != normalized_root and not normalized_source.begins_with(normalized_root + "/"):
            return _failure("GLTF dependency escapes the registered read-only source folder.")
        if not FileAccess.file_exists(dependency_source): return _failure("GLTF dependency is missing: %s" % uri)
        var dependency_target := target_dir.path_join(uri).replace("\\", "/").simplify_path()
        var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dependency_target.get_base_dir()))
        if make_error != OK: return _failure("Unable to create managed GLTF dependency folder.")
        var copy_result := _copy_file(dependency_source, dependency_target)
        if not copy_result.get("ok", false): return copy_result
    return {"ok": true, "errors": []}


static func _copy_file(source_path: String, target_path: String) -> Dictionary:
    var source := FileAccess.open(source_path, FileAccess.READ)
    if source == null: return _failure("Unable to read source asset for managed import.")
    var bytes := source.get_buffer(source.get_length())
    source.close()
    var target := FileAccess.open(target_path, FileAccess.WRITE)
    if target == null: return _failure("Unable to write managed import copy.")
    target.store_buffer(bytes)
    target.flush()
    target.close()
    return {"ok": true, "errors": []}


static func _derived(record: Dictionary, target_path: String, target_dir: String) -> Dictionary:
    return {"source_hash": str(record.get("content_hash", "")), "imported_path": target_path, "import_root": target_dir}


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
