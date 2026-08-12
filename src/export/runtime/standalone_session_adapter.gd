class_name PlayWorldStandaloneSessionAdapter
extends Node3D

const RuntimeEntityBridge = preload("res://src/editor/runtime_entity_bridge.gd")

var _project_data: Dictionary = {}
var _bridge

func _init() -> void:
    name = "StandaloneSessionAdapter"
    _bridge = RuntimeEntityBridge.new()
    _bridge.name = "RuntimeEntityBridge"
    add_child(_bridge)

func bind_project(project_data: Dictionary, asset_resolver: Callable) -> Dictionary:
    _project_data = project_data.duplicate(true)
    _bridge.bind_asset_resolver(asset_resolver)
    return _bridge.rebuild(_project_data.get("entities", []))

func set_active_cell_ids(cell_ids: Array[String]) -> Dictionary: return _bridge.set_active_cell_ids(cell_ids)
func get_project_data() -> Dictionary: return _project_data.duplicate(true)
func get_selected_ids() -> Array[String]: return []
func get_primary_entity_id() -> String: return ""
func clear_selection() -> Dictionary: return {"ok": true, "errors": [], "changed": false}
func restore_selection(_entity_ids: Array[String], _primary_entity_id: String = "") -> Dictionary: return {"ok": true, "errors": [], "changed": false}
func refresh_runtime(_preserve_selection: bool = false) -> Dictionary: return _bridge.rebuild(_project_data.get("entities", []))
func get_bridge(): return _bridge
