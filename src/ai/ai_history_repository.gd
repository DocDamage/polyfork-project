class_name PlayWorldAiHistoryRepository
extends RefCounted

const SafeJsonWriter = preload("res://src/world/safe_json_writer.gd")
const Contracts = preload("res://src/ai/ai_contracts.gd")

var project_directory: String
var history_path: String
var writer
var _history: Dictionary = {}


func _init(project_dir: String, safe_writer = null) -> void:
    project_directory = project_dir.trim_suffix("/")
    history_path = project_directory.path_join("ai/history.json")
    writer = safe_writer if safe_writer != null else SafeJsonWriter.new()


func open_or_create(project_id: String) -> Dictionary:
    var parent: String = history_path.get_base_dir()
    var make_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(parent))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS:
        return _failure("Unable to create project AI history directory.")
    if FileAccess.file_exists(history_path):
        var read: Dictionary = writer.read_dictionary(history_path)
        if not read.get("ok", false): return _failure("AI execution history is corrupt or unreadable.")
        var data: Dictionary = read.get("data", {})
        if str(data.get("project_id", "")) != project_id: return _failure("AI execution history belongs to a different project.")
        var errors: Array[String] = Contracts.validate_history(data)
        if not errors.is_empty(): return {"ok": false, "errors": errors}
        _history = data.duplicate(true)
        return {"ok": true, "errors": [], "created": false, "entries": get_entries()}
    _history = Contracts.empty_history(project_id)
    var save_result: Dictionary = _flush()
    if not save_result.get("ok", false): return save_result
    return {"ok": true, "errors": [], "created": true, "entries": []}


func append(entry: Dictionary) -> Dictionary:
    if not get_entry(str(entry.get("execution_id", ""))).is_empty(): return _failure("AI execution history entry already exists.")
    return upsert(entry)


func upsert(entry: Dictionary) -> Dictionary:
    if _history.is_empty(): return _failure("AI execution history is not open.")
    var execution_id: String = str(entry.get("execution_id", ""))
    var staged: Dictionary = _history.duplicate(true)
    var entries: Array = staged.get("entries", []).duplicate(true)
    var replaced := false
    for index in range(entries.size()):
        if str(entries[index].get("execution_id", "")) == execution_id:
            entries[index] = entry.duplicate(true)
            replaced = true
            break
    if not replaced: entries.append(entry.duplicate(true))
    staged["entries"] = entries
    var errors: Array[String] = Contracts.validate_history(staged)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    var before: Dictionary = _history
    _history = staged
    var save_result: Dictionary = _flush()
    if not save_result.get("ok", false):
        _history = before
        return save_result
    return {"ok": true, "errors": [], "entry": entry.duplicate(true), "count": entries.size(), "replaced": replaced}


func get_entry(execution_id: String) -> Dictionary:
    for value in _history.get("entries", []):
        if value is Dictionary and str(value.get("execution_id", "")) == execution_id: return value.duplicate(true)
    return {}


func get_entries() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for value in _history.get("entries", []):
        if value is Dictionary: result.append(value.duplicate(true))
    return result


func get_path() -> String:
    return history_path


func _flush() -> Dictionary:
    var validator := func(value: Dictionary) -> Array[String]:
        return Contracts.validate_history(value)
    return writer.write_validated_dictionary(history_path, _history, validator)


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
