class_name PlayWorldExportAuthoredReader
extends RefCounted

const GAMEPLAY_FILES: Array[String] = ["definitions.json", "instances.json", "archetypes.json", "prefabs.json", "sockets.json", "attachments.json", "prefab_instances.json", "dialogues.json", "quests.json"]

static func read_documents(project_directory: String) -> Dictionary:
    var root: String = project_directory.trim_suffix("/")
    var gameplay: Dictionary = {}
    for file_name in GAMEPLAY_FILES:
        var read: Dictionary = _read_json(root.path_join("gameplay").path_join(file_name))
        if not read.get("ok", false): return read
        gameplay[file_name.get_basename()] = read.get("data", {})
    var visual: Dictionary = _read_json(root.path_join("visual_scripting/graphs.json")); if not visual.get("ok", false): return visual
    var procedural: Dictionary = _read_json(root.path_join("procedural/procedural.json")); if not procedural.get("ok", false): return procedural
    var environment: Dictionary = _read_json(root.path_join("environment/environment.json")); if not environment.get("ok", false): return environment
    return {"ok": true, "errors": [], "documents": {"gameplay": gameplay, "visual_scripting": visual.get("data", {}), "procedural": procedural.get("data", {}), "environment": environment.get("data", {})}}

static func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path): return {"ok": false, "errors": ["Required authored export document is missing: %s" % path]}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not parsed is Dictionary: return {"ok": false, "errors": ["Required authored export document is corrupt: %s" % path]}
    return {"ok": true, "errors": [], "data": parsed}
