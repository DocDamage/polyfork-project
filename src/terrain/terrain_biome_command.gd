class_name PlayWorldTerrainBiomeCommand
extends "res://src/commands/command.gd"

var _state
var _cell_id: String
var _biome_id: String
var _refresh_callback: Callable
var _before: Dictionary = {}
var _after: Dictionary = {}
var _captured := false


func _init(state, cell_id: String, biome_id: String, refresh_callback: Callable = Callable()) -> void:
    _state = state
    _cell_id = cell_id
    _biome_id = biome_id
    _refresh_callback = refresh_callback


func execute() -> bool:
    _clear_error()
    if _state == null or _state.get_biome(_biome_id).is_empty():
        _set_error("Biome assignment requires a valid terrain state and biome ID.")
        return false
    if not _captured:
        _before = _state.get_cell(_cell_id)
        if _before.is_empty():
            _set_error("Biome assignment target cell does not exist.")
            return false
        if str(_before.get("biome_id", "")) == _biome_id:
            _set_error("Terrain cell already uses the requested biome.")
            return false
        _after = _before.duplicate(true)
        _after["biome_id"] = _biome_id
        _after["revision"] = int(_before.get("revision", 0)) + 1
        _captured = true
    return _apply(_after)


func undo() -> bool:
    _clear_error()
    if not _captured:
        _set_error("Biome assignment has no captured state to undo.")
        return false
    return _apply(_before)


func _apply(record: Dictionary) -> bool:
    var result: Dictionary = _state.set_cell(record, true)
    if not result.get("ok", false):
        _set_error(str(result.get("errors", ["Biome state update failed."])[0]))
        return false
    if _refresh_callback.is_valid(): _refresh_callback.call(_cell_id)
    return true
