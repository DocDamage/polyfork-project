class_name PlayWorldTemplateRegistry
extends RefCounted

const TemplateManifest = preload("res://src/templates/template_manifest.gd")

const BUILTIN_PATHS := [
    "res://templates/manifests/blank_sandbox.json",
    "res://templates/manifests/third_person_adventure.json",
    "res://templates/manifests/fps.json",
    "res://templates/manifests/survival.json",
    "res://templates/manifests/rpg.json",
    "res://templates/manifests/driving.json",
    "res://templates/manifests/walking_simulator.json"
]

var _templates: Dictionary = {}


func load_builtin() -> Dictionary:
    return load_paths(BUILTIN_PATHS)


func load_paths(paths: Array) -> Dictionary:
    var staged: Dictionary = {}
    for path_value in paths:
        var path := str(path_value)
        var load_result: Dictionary = _load_manifest(path)
        if not load_result.get("ok", false):
            return load_result
        var manifest: Dictionary = load_result["manifest"]
        var template_id := str(manifest.get("template_id", ""))
        if staged.has(template_id):
            return _failure("Duplicate template ID: %s" % template_id)
        staged[template_id] = manifest.duplicate(true)
    _templates = staged
    return {"ok": true, "errors": [], "count": _templates.size(), "template_ids": template_ids()}


func register_manifest(manifest: Dictionary) -> Dictionary:
    var errors: Array[String] = TemplateManifest.validate_dictionary(manifest)
    if not errors.is_empty():
        return {"ok": false, "errors": errors}
    var template_id := str(manifest.get("template_id", ""))
    if _templates.has(template_id):
        return _failure("Template ID is already registered: %s" % template_id)
    _templates[template_id] = manifest.duplicate(true)
    return {"ok": true, "errors": [], "template_id": template_id}


func get_manifest(template_id: String) -> Dictionary:
    if not _templates.has(template_id):
        return {}
    return _templates[template_id].duplicate(true)


func require_manifest(template_id: String) -> Dictionary:
    var manifest := get_manifest(template_id)
    if manifest.is_empty():
        return _failure("Unknown template ID: %s" % template_id)
    return {"ok": true, "errors": [], "manifest": manifest}


func list_manifests() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for template_id in template_ids():
        result.append(get_manifest(template_id))
    return result


func template_ids() -> Array[String]:
    var result: Array[String] = []
    for template_id in _templates.keys():
        result.append(str(template_id))
    result.sort()
    return result


func _load_manifest(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return _failure("Template manifest does not exist: %s" % path)
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return _failure("Template manifest could not be opened: %s" % path)
    var parser := JSON.new()
    var parse_error := parser.parse(file.get_as_text())
    if parse_error != OK:
        return _failure("Template manifest is not valid JSON: %s" % path)
    if not parser.data is Dictionary:
        return _failure("Template manifest root must be a dictionary: %s" % path)
    var manifest: Dictionary = parser.data
    var errors: Array[String] = TemplateManifest.validate_dictionary(manifest)
    if not errors.is_empty():
        return {"ok": false, "errors": errors, "path": path}
    return {"ok": true, "errors": [], "manifest": manifest, "path": path}


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
