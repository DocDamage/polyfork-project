class_name PlayWorldVisualGraphState
extends RefCounted

const Contracts = preload("res://src/visual_scripting/visual_graph_contracts.gd")
const NodeLibrary = preload("res://src/visual_scripting/builtin_visual_node_library.gd")

var graphs: Array[Dictionary] = []

func load_records(records: Array) -> Array[String]:
    var next: Array[Dictionary] = []
    for value in records:
        if value is Dictionary: next.append(value.duplicate(true))
    var errors: Array[String] = Contracts.validate_registry_document(to_document(next), NodeLibrary.keys())
    if errors.is_empty(): graphs = next
    return errors

func validate() -> Array[String]: return Contracts.validate_registry_document(to_document(graphs), NodeLibrary.keys())
func snapshot() -> Array[Dictionary]: return graphs.duplicate(true)
func to_document(records: Array[Dictionary] = graphs) -> Dictionary: return {"document_type":Contracts.REGISTRY_DOCUMENT_TYPE,"schema_version":Contracts.SCHEMA_VERSION,"graphs":records.duplicate(true)}

func get_graph(graph_id: String) -> Dictionary:
    for graph in graphs:
        if str(graph.get("graph_id", "")) == graph_id: return graph.duplicate(true)
    return {}

func graph_ids() -> Array[String]:
    var result: Array[String] = []
    for graph in graphs: result.append(str(graph.get("graph_id", "")))
    result.sort(); return result

func replace_records(records: Array[Dictionary]) -> Array[String]: return load_records(records)
