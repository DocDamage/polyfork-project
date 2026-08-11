class_name PlayWorldTerrainSculptCommand
extends "res://src/commands/command.gd"

const TerrainBrush = preload("res://src/terrain/terrain_brush.gd")

var _state
var _cell_id: String
var _brush: Dictionary
var _refresh_callback: Callable
var _before: Dictionary = {}
var _after: Dictionary = {}
var _captured := false


func _init(state, cell_id: String, brush: Dictionary, refresh_callback: Callable = Callable()) -> void:
    _state = state
    _cell_id = cell_id
    _brush = brush.duplicate(true)
    _refresh_callback = refresh_callback


func execute() -> bool:
    _clear_error()
    if _state == null or _cell_id.is_empty():
        _set_error("Terrain sculpt requires a bound state and cell ID.")
        return false
    if not _captured:
        _before = _state.get_cell(_cell_id)
        if _before.is_empty():
            _set_error("Terrain sculpt target cell does not exist.")
            return false
        var brush_result: Dictionary = TerrainBrush.apply(_before, _brush)
        if not brush_result.get("ok", false):
            _set_error(str(brush_result.get("errors", ["Terrain brush failed."])[0]))
            return false
        _after = _before.duplicate(true)
        _after["heights"] = brush_result["heights"].duplicate()
        _after["revision"] = int(_before.get("revision", 0)) + 1
        _captured = true
    return _apply(_after)


func undo() -> bool:
    _clear_error()
    if not _captured:
        _set_error("Terrain sculpt has no captured state to undo.")
        return false
    return _apply(_before)


func cell_id() -> String: return _cell_id


func _apply(record: Dictionary) -> bool:
    var result: Dictionary = _state.set_cell(record, true)
    if not result.get("ok", false):
        _set_error(str(result.get("errors", ["Terrain state update failed."])[0]))
        return false
    if _refresh_callback.is_valid(): _refresh_callback.call(_cell_id)
    return true
