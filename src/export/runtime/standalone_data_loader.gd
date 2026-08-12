class_name PlayWorldStandaloneDataLoader
extends RefCounted

const WorldProject = preload("res://src/world/world_project.gd")
const GameplayState = preload("res://src/gameplay/gameplay_state.gd")
const VisualContracts = preload("res://src/visual_scripting/visual_graph_contracts.gd")
const VisualNodeLibrary = preload("res://src/visual_scripting/builtin_visual_node_library.gd")
const EnvironmentContracts = preload("res://src/environment/environment_contracts.gd")
const TerrainState = preload("res://src/terrain/terrain_world_state.gd")
const ProceduralState = preload("res://src/procedural/procedural_state.gd")

const GAMEPLAY_DOCS := {
    "definitions": ["definitions.json", "definitions"], "instances": ["instances.json", "instances"],
    "archetypes": ["archetypes.json", "archetypes"], "prefabs": ["prefabs.json", "prefabs"],
    "sockets": ["sockets.json", "sockets"], "attachments": ["attachments.json", "attachments"],
    "prefab_instances": ["prefab_instances.json", "prefab_instances"], "dialogues": ["dialogues.json", "dialogues"],
    "quests": ["quests.json", "quests"]
}

static func load_bundle(root: String = "res://runtime_data") -> Dictionary:
    var project_read: Dictionary = _read_json(root.path_join("project.json"))
    if not project_read.get("ok", false): return project_read
    var project_data: Dictionary = project_read.get("data", {})
    var project = WorldProject.new()
    var project_errors: Array[String] = project.load_dictionary(project_data)
    if not project_errors.is_empty(): return {"ok": false, "errors": project_errors}

    var gameplay = GameplayState.new()
    for section_value in GAMEPLAY_DOCS.keys():
        var section: String = str(section_value)
        var spec: Array = GAMEPLAY_DOCS[section]
        var read: Dictionary = _read_json(root.path_join("gameplay").path_join(str(spec[0])))
        if not read.get("ok", false): return read
        var records: Array[Dictionary] = _dictionary_array(read.get("data", {}).get(str(spec[1]), []))
        gameplay.set(section, records)
    var gameplay_errors: Array[String] = gameplay.validate(project)
    if not gameplay_errors.is_empty(): return {"ok": false, "errors": gameplay_errors}

    var graph_read: Dictionary = _read_json(root.path_join("visual_scripting/graphs.json"))
    if not graph_read.get("ok", false): return graph_read
    var graph_data: Dictionary = graph_read.get("data", {})
    var graph_errors: Array[String] = VisualContracts.validate_registry_document(graph_data, VisualNodeLibrary.keys())
    if not graph_errors.is_empty(): return {"ok": false, "errors": graph_errors}
    var graphs: Array[Dictionary] = _dictionary_array(graph_data.get("graphs", []))

    var environment_read: Dictionary = _read_json(root.path_join("environment/environment.json"))
    if not environment_read.get("ok", false): return environment_read
    var environment_document: Dictionary = environment_read.get("data", {})
    var environment_errors: Array[String] = EnvironmentContracts.validate_document(environment_document)
    if not environment_errors.is_empty(): return {"ok": false, "errors": environment_errors}

    var manifest_read: Dictionary = _read_json(root.path_join("terrain/manifest.json")); if not manifest_read.get("ok", false): return manifest_read
    var biomes_read: Dictionary = _read_json(root.path_join("terrain/biomes.json")); if not biomes_read.get("ok", false): return biomes_read
    var cell_records: Array[Dictionary] = []
    for cell_id in project.cell_ids:
        var cell_read: Dictionary = _read_json(root.path_join("terrain/cells/%s.json" % cell_id))
        if not cell_read.get("ok", false): return cell_read
        cell_records.append(cell_read.get("data", {}))
    var terrain = TerrainState.new()
    var terrain_errors: Array[String] = terrain.load_data(manifest_read.get("data", {}), biomes_read.get("data", {}), cell_records)
    if not terrain_errors.is_empty(): return {"ok": false, "errors": terrain_errors}

    var procedural_read: Dictionary = _read_json(root.path_join("procedural/procedural.json")); if not procedural_read.get("ok", false): return procedural_read
    var procedural = ProceduralState.new()
    var procedural_errors: Array[String] = procedural.load_document(procedural_read.get("data", {}))
    if not procedural_errors.is_empty(): return {"ok": false, "errors": procedural_errors}

    return {"ok": true, "errors": [], "project": project, "project_data": project_data, "gameplay_state": gameplay, "gameplay_snapshot": _runtime_snapshot(gameplay), "visual_graphs": graphs, "environment_document": environment_document, "terrain_state": terrain, "procedural_state": procedural}

static func _runtime_snapshot(gameplay) -> Dictionary:
    return {"definitions": gameplay.definitions.duplicate(true), "instances": gameplay.instances.duplicate(true), "sockets": gameplay.sockets.duplicate(true), "attachments": gameplay.attachments.duplicate(true), "dialogues": gameplay.dialogues.duplicate(true), "quests": gameplay.quests.duplicate(true)}

static func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path): return {"ok": false, "errors": ["Standalone runtime data is missing: %s" % path]}
    var text: String = FileAccess.get_file_as_string(path)
    var parsed: Variant = JSON.parse_string(text)
    if not parsed is Dictionary: return {"ok": false, "errors": ["Standalone runtime data is corrupt or invalid JSON: %s" % path]}
    return {"ok": true, "errors": [], "data": parsed}

static func _dictionary_array(value: Variant) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not value is Array: return result
    for item in value:
        if item is Dictionary: result.append(item.duplicate(true))
    return result
