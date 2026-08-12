class_name PlayWorldExportSourceClosure
extends RefCounted

const Contracts = preload("res://src/export/export_contracts.gd")
const TEXT_EXTENSIONS: Array[String] = ["gd", "tscn", "tres", "gdshader", "cfg", "godot"]
const GENERATED_RUNTIME_PATHS: Array[String] = ["export_manifest.json"]
const GENERATED_RUNTIME_PREFIXES: Array[String] = ["runtime_data/"]

static func resolve(root_paths: Array[String]) -> Dictionary:
    var errors: Array[String] = []
    var queued: Array[String] = []
    var seen: Dictionary = {}
    for root_path in root_paths:
        var normalized: String = _normalize(root_path)
        if not Contracts.valid_package_path(normalized):
            errors.append("Runtime source root path is unsafe: %s" % root_path)
        elif not queued.has(normalized):
            queued.append(normalized)
    queued.sort()
    while not queued.is_empty() and errors.is_empty():
        var path: String = queued.pop_front()
        if seen.has(path): continue
        var resource_path: String = "res://%s" % path
        if not FileAccess.file_exists(resource_path):
            errors.append("Runtime source dependency is missing: %s" % path)
            continue
        seen[path] = true
        if not TEXT_EXTENSIONS.has(path.get_extension().to_lower()): continue
        var text: String = FileAccess.get_file_as_string(resource_path)
        for dependency in _resource_references(text):
            if _is_generated_runtime_path(dependency): continue
            if seen.has(dependency) or queued.has(dependency): continue
            queued.append(dependency)
        queued.sort()
    var paths: Array[String] = []
    for value in seen.keys(): paths.append(str(value))
    paths.sort()
    return {"ok": errors.is_empty(), "errors": errors, "paths": paths}

static func _resource_references(text: String) -> Array[String]:
    var result: Array[String] = []
    var regex := RegEx.new()
    var compile_error: Error = regex.compile("res://[A-Za-z0-9_./\\-]+\\.[A-Za-z0-9_]+")
    if compile_error != OK: return result
    for match_value in regex.search_all(text):
        var match_result: RegExMatch = match_value
        var normalized: String = _normalize(match_result.get_string())
        if Contracts.valid_package_path(normalized) and not result.has(normalized): result.append(normalized)
    result.sort()
    return result

static func _is_generated_runtime_path(path: String) -> bool:
    if GENERATED_RUNTIME_PATHS.has(path): return true
    for prefix in GENERATED_RUNTIME_PREFIXES:
        if path.begins_with(prefix): return true
    return false

static func _normalize(path: String) -> String:
    var value: String = path.strip_edges().replace("\\", "/")
    if value.begins_with("res://"): value = value.trim_prefix("res://")
    return value.trim_prefix("./")
