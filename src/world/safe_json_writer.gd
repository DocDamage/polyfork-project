class_name PlayWorldSafeJsonWriter
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")

var fault_injector: Callable


func _init(injector: Callable = Callable()) -> void:
    fault_injector = injector


func write_validated_dictionary(final_path: String, data: Dictionary, validator: Callable) -> Dictionary:
    if final_path.strip_edges().is_empty():
        return _failure("Final persistence path is required.")
    if not validator.is_valid():
        return _failure("A persistence validator is required.")

    var temp_path := "%s.tmp-%s" % [final_path, StableId.generate()]
    var file := FileAccess.open(temp_path, FileAccess.WRITE)
    if file == null:
        return _failure("Unable to open temporary persistence file: %s" % FileAccess.get_open_error())

    var json_text := JSON.stringify(data, "  ") + "\n"
    if not file.store_string(json_text):
        file.close()
        _remove_if_present(temp_path)
        return _failure("Unable to write temporary persistence file.")
    file.flush()
    file.close()

    if _should_fail(&"after_temp_write"):
        _remove_if_present(temp_path)
        return _failure("Persistence write intentionally failed after temporary write.")

    var read_result := read_dictionary(temp_path)
    if not read_result.get("ok", false):
        _remove_if_present(temp_path)
        return _failure("Temporary persistence file failed JSON verification.")

    var validation_result: Variant = validator.call(read_result["data"])
    if not validation_result is Array:
        _remove_if_present(temp_path)
        return _failure("Persistence validator returned an invalid result.")
    var validation_errors: Array = validation_result
    if not validation_errors.is_empty():
        _remove_if_present(temp_path)
        return {"ok": false, "errors": validation_errors, "temp_path": temp_path}

    if _should_fail(&"before_promote"):
        _remove_if_present(temp_path)
        return _failure("Persistence write intentionally failed before promotion.")

    var rename_error := DirAccess.rename_absolute(
        ProjectSettings.globalize_path(temp_path),
        ProjectSettings.globalize_path(final_path)
    )
    if rename_error != OK:
        _remove_if_present(temp_path)
        return _failure("Unable to promote temporary persistence file: %s" % rename_error)

    return {"ok": true, "errors": [], "path": final_path, "temp_path": temp_path}


func read_dictionary(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return _failure("Persistence file does not exist.")
    var parser := JSON.new()
    var parse_error := parser.parse(FileAccess.get_file_as_string(path))
    if parse_error != OK or not parser.data is Dictionary:
        return _failure("Persistence file is not valid JSON.")
    return {"ok": true, "errors": [], "data": parser.data}


func _should_fail(stage: StringName) -> bool:
    return fault_injector.is_valid() and bool(fault_injector.call(stage))


func _remove_if_present(path: String) -> void:
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
