extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const Contracts = preload("res://src/visual_scripting/visual_graph_contracts.gd")
const NodeLibrary = preload("res://src/visual_scripting/builtin_visual_node_library.gd")
const GraphRepository = preload("res://src/visual_scripting/visual_graph_repository.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var graph := _valid_graph()
    var document := {"document_type":Contracts.REGISTRY_DOCUMENT_TYPE,"schema_version":Contracts.SCHEMA_VERSION,"graphs":[graph]}
    if not Contracts.validate_registry_document(document, NodeLibrary.keys()).is_empty(): errors.append("Valid Phase 8 graph contract must pass validation.")
    var duplicate := document.duplicate(true); duplicate["graphs"].append(graph.duplicate(true))
    if Contracts.validate_registry_document(duplicate, NodeLibrary.keys()).is_empty(): errors.append("Duplicate graph IDs must reject.")
    var broken := graph.duplicate(true); broken["connections"][0]["to_node_id"] = StableId.generate()
    if Contracts.validate_graph(broken, NodeLibrary.keys()).is_empty(): errors.append("Unresolved connection endpoints must reject.")
    var future := document.duplicate(true); future["schema_version"] = Contracts.SCHEMA_VERSION + 1
    if Contracts.validate_registry_document(future, NodeLibrary.keys()).is_empty(): errors.append("Future visual graph schema versions must reject.")
    for key in ["event.start","flow.branch","flow.sequence","value.literal","math.add","logic.equal","variable.get","variable.set","entity.get_position","entity.set_position","macro.call","debug.print"]:
        if not NodeLibrary.has_key(key): errors.append("Built-in visual node catalog is missing %s." % key)
    errors.append_array(_repository_roundtrip(graph))
    return errors

static func _repository_roundtrip(graph: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new(); project.initialize_new("Phase 8", &"small", "blank_sandbox")
    var root := "user://tests/phase8_graphs_%s" % StableId.generate(); var repository = GraphRepository.new(root)
    var opened: Dictionary = repository.open_or_create(project)
    if not opened.get("ok", false): return ["Visual graph repository must create cleanly: %s" % opened.get("errors", [])]
    var state = opened["state"]; var records: Array[Dictionary] = [graph.duplicate(true)]
    var load_errors: Array[String] = state.replace_records(records)
    if not load_errors.is_empty(): return ["Visual graph state fixture must load: %s" % load_errors]
    var flush: Dictionary = repository.flush(state, project)
    if not flush.get("ok", false): return ["Visual graph registry must persist: %s" % flush.get("errors", [])]
    if project.registries.get("visual_graph_ids", []) != state.graph_ids(): errors.append("WorldProject visual_graph_ids must mirror project-owned graph IDs.")
    var reopened: Dictionary = repository.open_or_create(project)
    if not reopened.get("ok", false): errors.append("Visual graph registry must reopen after persistence.")
    elif reopened["state"].get_graph(str(graph["graph_id"])).is_empty(): errors.append("Visual graph identity must survive reopen.")
    FileAccess.open(repository.get_path(), FileAccess.WRITE).store_string("{not-json")
    if repository.open_or_create(project).get("ok", false): errors.append("Corrupt visual graph registry must fail closed.")
    return errors

static func _valid_graph() -> Dictionary:
    var start_id := StableId.generate(); var print_id := StableId.generate()
    return {
        "document_type":Contracts.GRAPH_DOCUMENT_TYPE,
        "schema_version":Contracts.SCHEMA_VERSION,
        "graph_id":StableId.generate(),
        "display_name":"Hello Graph",
        "kind":"event",
        "owner_entity_id":null,
        "enabled":true,
        "nodes":[
            {"node_id":start_id,"type_key":"event.start","position":[0.0,0.0],"properties":{}},
            {"node_id":print_id,"type_key":"debug.print","position":[280.0,0.0],"properties":{}}
        ],
        "connections":[{"connection_id":StableId.generate(),"from_node_id":start_id,"from_port":"next","to_node_id":print_id,"to_port":"in","kind":"exec"}],
        "variables":[{"variable_id":StableId.generate(),"name":"Counter","type":"int","default":0}],
        "interface":{"inputs":[],"outputs":[]},
        "editor":{"zoom":1.0,"scroll":[0.0,0.0]}
    }
