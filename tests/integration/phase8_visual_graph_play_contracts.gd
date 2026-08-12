extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const RuntimeState = preload("res://src/runtime/play_runtime_state.gd")
const Contracts = preload("res://src/visual_scripting/visual_graph_contracts.gd")
const VisualRuntime = preload("res://src/visual_scripting/visual_graph_runtime_session.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []; var project = WorldProject.new(); project.initialize_new("Phase 8 Play", &"small", "blank_sandbox"); var cell_id := StableId.generate(); var entity_id := StableId.generate(); var cells: Array[String] = [cell_id]; project.cell_ids = cells
    var records: Array[Dictionary] = [{"document_type": WorldEntity.DOCUMENT_TYPE, "schema_version": WorldEntity.SCHEMA_VERSION, "entity_id": entity_id, "display_name": "Runtime Target", "cell_id": cell_id, "asset_id": null, "prefab_id": null, "parent_entity_id": null, "component_instance_ids": [], "transform": {"position": [0.0, 0.0, 0.0], "rotation_degrees": [0.0, 0.0, 0.0], "scale": [1.0, 1.0, 1.0]}}]; project.entity_records = records
    var authored_before: Dictionary = project.to_dictionary(); var runtime = RuntimeState.new(); var loaded: Dictionary = runtime.load_authored_project(authored_before)
    if not loaded.get("ok", false): return ["Disposable runtime fixture must load."]
    var graph: Dictionary = _set_position_graph(entity_id); var graphs: Array[Dictionary] = [graph]; var result: Dictionary = VisualRuntime.new().execute_start(graphs, runtime)
    if not result.get("ok", false): errors.append("Visual event graph must execute in disposable Play state: %s" % str(result.get("errors", [])))
    var runtime_record: Dictionary = runtime.get_entity(entity_id)
    if runtime_record.get("transform", {}).get("position", []) != [9.0, 2.0, 4.0]: errors.append("Visual graph Set Position must mutate only the disposable runtime entity.")
    if project.to_dictionary() != authored_before: errors.append("Visual graph Play execution must not mutate authored Build project data.")
    var invalid: Dictionary = graph.duplicate(true); invalid["connections"][0]["from_port"] = "missing"; var invalid_graphs: Array[Dictionary] = [invalid]
    if VisualRuntime.new().execute_start(invalid_graphs, runtime).get("ok", false): errors.append("Invalid visual graphs must fail closed before Play runtime execution.")
    return errors

static func _set_position_graph(entity_id: String) -> Dictionary:
    var start := StableId.generate(); var entity_value := StableId.generate(); var position_value := StableId.generate(); var set_node := StableId.generate()
    return {"document_type": Contracts.GRAPH_DOCUMENT_TYPE, "schema_version": Contracts.SCHEMA_VERSION, "graph_id": StableId.generate(), "display_name": "Runtime Set Position", "kind": "event", "owner_entity_id": null, "enabled": true, "nodes": [_node(start, "event.start"), _node(entity_value, "value.literal", {"value": entity_id}), _node(position_value, "value.literal", {"value": [9.0, 2.0, 4.0]}), _node(set_node, "entity.set_position")], "connections": [_connection(start, "next", set_node, "in", "exec"), _connection(entity_value, "value", set_node, "entity_id", "data"), _connection(position_value, "value", set_node, "position", "data")], "variables": [], "interface": {"inputs": [], "outputs": []}, "editor": {}}
static func _node(id: String, key: String, properties: Dictionary = {}) -> Dictionary: return {"node_id": id, "type_key": key, "position": [0.0, 0.0], "properties": properties}
static func _connection(a: String, ap: String, b: String, bp: String, kind: String) -> Dictionary: return {"connection_id": StableId.generate(), "from_node_id": a, "from_port": ap, "to_node_id": b, "to_port": bp, "kind": kind}
