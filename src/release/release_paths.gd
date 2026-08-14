class_name PlayWorldReleasePaths
extends RefCounted

const MAX_JSON_BYTES := 2 * 1024 * 1024

static func ensure_directory(path: String) -> Dictionary:
    var absolute := ProjectSettings.globalize_path(path)
    var error := DirAccess.make_dir_recursive_absolute(absolute)
    if error not in [OK, ERR_ALREADY_EXISTS]:
        return failure("Could not create directory: %s" % redact_path(absolute))
    return {"ok": true, "errors": [], "path": absolute}

static func read_json(path: String, maximum_bytes: int = MAX_JSON_BYTES) -> Dictionary:
    if not FileAccess.file_exists(path):
        return failure("JSON file does not exist: %s" % redact_path(path))
    var handle := FileAccess.open(path, FileAccess.READ)
    if handle == null:
        return failure("JSON file could not be opened: %s" % redact_path(path))
    var length := handle.get_length()
    if length < 0 or length > maximum_bytes:
        handle.close()
        return failure("JSON file exceeds the accepted size limit.")
    var text := handle.get_as_text()
    handle.close()
    var value: Variant = JSON.parse_string(text)
    if not value is Dictionary:
        return failure("JSON file is not an object: %s" % redact_path(path))
    return {"ok": true, "errors": [], "value": value, "text": text}

static func atomic_write_json(path: String, value: Dictionary) -> Dictionary:
    var absolute := ProjectSettings.globalize_path(path)
    var directory_result := ensure_directory(absolute.get_base_dir())
    if not directory_result.get("ok", false):
        return directory_result
    var nonce := "%d-%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
    var staged := "%s.phase19-%s.tmp" % [absolute, nonce]
    var previous := "%s.phase19-%s.previous" % [absolute, nonce]
    var handle := FileAccess.open(staged, FileAccess.WRITE)
    if handle == null:
        return failure("Could not stage JSON state: %s" % redact_path(path))
    handle.store_string(JSON.stringify(value, "  ", true) + "\n")
    handle.flush()
    handle.close()
    if FileAccess.file_exists(absolute):
        var move_previous := DirAccess.rename_absolute(absolute, previous)
        if move_previous != OK:
            DirAccess.remove_absolute(staged)
            return failure("Could not preserve the previous JSON state.")
    var promote := DirAccess.rename_absolute(staged, absolute)
    if promote != OK:
        if FileAccess.file_exists(previous):
            DirAccess.rename_absolute(previous, absolute)
        DirAccess.remove_absolute(staged)
        return failure("Could not promote staged JSON state.")
    if FileAccess.file_exists(previous):
        DirAccess.remove_absolute(previous)
    return {"ok": true, "errors": [], "path": absolute}

static func copy_file(source: String, target: String) -> Dictionary:
    if not FileAccess.file_exists(source):
        return failure("Source file does not exist: %s" % redact_path(source))
    var target_absolute := ProjectSettings.globalize_path(target)
    var directory_result := ensure_directory(target_absolute.get_base_dir())
    if not directory_result.get("ok", false):
        return directory_result
    var input := FileAccess.open(source, FileAccess.READ)
    var output := FileAccess.open(target_absolute, FileAccess.WRITE)
    if input == null or output == null:
        if input != null: input.close()
        if output != null: output.close()
        return failure("Could not copy release state file.")
    while not input.eof_reached():
        var chunk := input.get_buffer(1024 * 1024)
        if chunk.is_empty(): break
        output.store_buffer(chunk)
    output.flush()
    input.close()
    output.close()
    return {"ok": true, "errors": [], "path": target_absolute}

static func sha256_file(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return failure("File does not exist for SHA-256 verification.")
    var handle := FileAccess.open(path, FileAccess.READ)
    if handle == null:
        return failure("File could not be opened for SHA-256 verification.")
    var context := HashingContext.new()
    if context.start(HashingContext.HASH_SHA256) != OK:
        handle.close()
        return failure("SHA-256 hashing could not start.")
    var size := 0
    while not handle.eof_reached():
        var chunk := handle.get_buffer(1024 * 1024)
        if chunk.is_empty(): break
        size += chunk.size()
        if context.update(chunk) != OK:
            handle.close()
            return failure("SHA-256 hashing failed.")
    handle.close()
    return {"ok": true, "errors": [], "sha256": context.finish().hex_encode(), "size": size}

static func is_safe_filename(value: String) -> bool:
    if value.is_empty() or value.length() > 200 or value in [".", ".."]:
        return false
    if value.contains("..") or value.contains("/") or value.contains("\\"):
        return false
    if value.ends_with(".") or value.ends_with(" "):
        return false
    for index in range(value.length()):
        var code := value.unicode_at(index)
        var valid := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code in [45, 46, 95]
        if not valid: return false
    return true

static func is_descendant(candidate: String, root_path: String) -> bool:
    var normalized_candidate := ProjectSettings.globalize_path(candidate).replace("\\", "/").simplify_path().trim_suffix("/")
    var normalized_root := ProjectSettings.globalize_path(root_path).replace("\\", "/").simplify_path().trim_suffix("/")
    if normalized_candidate == normalized_root: return true
    return normalized_candidate.begins_with(normalized_root + "/")

static func application_root() -> String:
    return OS.get_executable_path().get_base_dir()

static func install_mode(root_path: String = "") -> String:
    var root := application_root() if root_path.is_empty() else root_path
    var marker := root.path_join("install_mode.txt")
    if not FileAccess.file_exists(marker):
        return "development"
    var value := FileAccess.get_file_as_string(marker).strip_edges().to_lower()
    return value if value in ["portable", "installed"] else "unknown"

static func redact_path(path: String) -> String:
    var normalized := ProjectSettings.globalize_path(path).replace("\\", "/")
    var user_root := ProjectSettings.globalize_path("user://").replace("\\", "/").trim_suffix("/")
    if normalized == user_root: return "user://"
    if normalized.begins_with(user_root + "/"):
        return "user://" + normalized.substr(user_root.length() + 1)
    var app_root := application_root().replace("\\", "/").trim_suffix("/")
    if normalized == app_root: return "application://"
    if normalized.begins_with(app_root + "/"):
        return "application://" + normalized.substr(app_root.length() + 1)
    return "<external>/%s" % normalized.get_file()

static func failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
