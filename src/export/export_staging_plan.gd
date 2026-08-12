class_name PlayWorldExportStagingPlan
extends RefCounted

const Contracts = preload("res://src/export/export_contracts.gd")

const CANONICAL_DATA_FILES: Array[String] = [
    "project.json",
    "gameplay/definitions.json", "gameplay/instances.json", "gameplay/archetypes.json", "gameplay/prefabs.json",
    "gameplay/sockets.json", "gameplay/attachments.json", "gameplay/prefab_instances.json", "gameplay/dialogues.json", "gameplay/quests.json",
    "visual_scripting/graphs.json",
    "procedural/procedural.json",
    "environment/environment.json",
    "terrain/manifest.json", "terrain/biomes.json",
]

const PROHIBITED_DATA_PREFIXES: Array[String] = ["checkpoints/", "ai/", "terrain/recovery/"]

static func classify_code_path(path: String, runtime_paths: Dictionary) -> String:
    var normalized := path.replace("\\", "/").trim_prefix("./")
    return Contracts.RUNTIME_REQUIRED if runtime_paths.has(normalized) else Contracts.EDITOR_ONLY

static func build_project_data_plan(project_data: Dictionary) -> Dictionary:
    var files: Array[Dictionary] = []
    for relative_path in CANONICAL_DATA_FILES:
        files.append(_entry(relative_path))
    var cell_ids: Array[String] = []
    for value in project_data.get("cell_ids", []): cell_ids.append(str(value))
    cell_ids.sort()
    for cell_id in cell_ids: files.append(_entry("terrain/cells/%s.json" % cell_id))
    files.sort_custom(func(a, b): return str(a.get("source_path", "")) < str(b.get("source_path", "")))
    return {"ok": true, "errors": [], "files": files}

static func is_prohibited_project_data_path(path: String) -> bool:
    var normalized := path.replace("\\", "/").trim_prefix("./")
    for prefix in PROHIBITED_DATA_PREFIXES:
        if normalized.begins_with(prefix): return true
    return false

static func _entry(relative_path: String) -> Dictionary:
    return {"source_path": relative_path, "package_path": "runtime_data/%s" % relative_path, "classification": Contracts.RUNTIME_REQUIRED}
