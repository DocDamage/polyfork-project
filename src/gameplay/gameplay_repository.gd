class_name PlayWorldGameplayRepository
extends RefCounted

const SafeJsonWriter = preload("res://src/world/safe_json_writer.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const GameplayState = preload("res://src/gameplay/gameplay_state.gd")
const BuiltinComponents = preload("res://src/gameplay/builtin_component_library.gd")
const BuiltinArchetypes = preload("res://src/gameplay/builtin_archetype_library.gd")

const DOCUMENTS := {
    "definitions": ["definitions.json", "component_registry", "definitions"],
    "instances": ["instances.json", "component_instance_registry", "instances"],
    "archetypes": ["archetypes.json", "archetype_registry", "archetypes"],
    "prefabs": ["prefabs.json", "prefab_registry", "prefabs"],
    "sockets": ["sockets.json", "socket_registry", "sockets"],
    "attachments": ["attachments.json", "attachment_registry", "attachments"],
    "prefab_instances": ["prefab_instances.json", "prefab_instance_registry", "prefab_instances"]
}

var project_directory: String
var root_directory: String
var writer
var _write_counts: Dictionary = {}


func _init(project_dir: String, safe_writer = null) -> void:
    project_directory = project_dir.trim_suffix("/")
    root_directory = project_directory.path_join("gameplay")
    writer = safe_writer if safe_writer != null else SafeJsonWriter.new()


func open_or_create(project) -> Dictionary:
    if project == null: return _failure("Gameplay repository requires a world project.")
    var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_directory))
    if make_error != OK and make_error != ERR_ALREADY_EXISTS: return _failure("Unable to create gameplay storage directory.")
    var state = GameplayState.new()
    var created: Array[String] = []
    for section_value in DOCUMENTS.keys():
        var section := str(section_value)
        var load_result: Dictionary = _load_or_seed(section)
        if not load_result.get("ok", false): return load_result
        _assign_section(state, section, _dictionary_array(load_result.get("records", [])))
        if load_result.get("created", false): created.append(section)
    var errors: Array[String] = state.validate(project)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    return {"ok": true, "errors": [], "state": state, "created_sections": created, "root": root_directory}


func flush_sections(state, sections: Array[String]) -> Dictionary:
    if state == null: return _failure("Gameplay state is required for persistence.")
    var unique: Dictionary = {}
    for section in sections:
        if not DOCUMENTS.has(section): return _failure("Unknown gameplay persistence section: %s" % section)
        unique[section] = true
    var saved: Array[String] = []
    var ordered: Array = unique.keys(); ordered.sort()
    for section_value in ordered:
        var section := str(section_value)
        var result := _write_section(section, state.get(section))
        if not result.get("ok", false): return {"ok": false, "errors": result.get("errors", []), "saved_sections": saved}
        saved.append(section)
    return {"ok": true, "errors": [], "saved_sections": saved}


func flush_all(state) -> Dictionary:
    var sections: Array[String] = []
    for section in DOCUMENTS.keys(): sections.append(str(section))
    return flush_sections(state, sections)


func get_path(section: String) -> String:
    if not DOCUMENTS.has(section): return ""
    return root_directory.path_join(str(DOCUMENTS[section][0]))


func get_write_counts() -> Dictionary: return _write_counts.duplicate(true)


func _load_or_seed(section: String) -> Dictionary:
    var path := get_path(section)
    if FileAccess.file_exists(path):
        var read: Dictionary = writer.read_dictionary(path)
        if not read.get("ok", false): return _failure("Gameplay %s document is corrupt or unreadable." % section)
        var errors: Array[String] = _validate_document(section, read.get("data", {}))
        if not errors.is_empty(): return {"ok": false, "errors": errors}
        return {"ok": true, "errors": [], "records": _dictionary_array(read["data"].get(str(DOCUMENTS[section][2]), [])), "created": false}
    var records: Array[Dictionary] = _dictionary_array(_seed_records(section))
    var write: Dictionary = _write_section(section, records)
    if not write.get("ok", false): return write
    return {"ok": true, "errors": [], "records": records.duplicate(true), "created": true}


func _write_section(section: String, records: Array) -> Dictionary:
    var spec: Array = DOCUMENTS[section]
    var data := {
        "document_type": str(spec[1]),
        "schema_version": Contracts.SCHEMA_VERSION,
        str(spec[2]): records.duplicate(true)
    }
    var validator := func(value: Dictionary) -> Array[String]: return _validate_document(section, value)
    var result: Dictionary = writer.write_validated_dictionary(get_path(section), data, validator)
    if result.get("ok", false): _write_counts[section] = int(_write_counts.get(section, 0)) + 1
    return result


func _validate_document(section: String, data: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    var spec: Array = DOCUMENTS[section]
    if data.get("document_type") != spec[1]: errors.append("Gameplay %s document_type is invalid." % section)
    if int(data.get("schema_version", 0)) != Contracts.SCHEMA_VERSION: errors.append("Gameplay %s schema_version is unsupported." % section)
    var records = data.get(str(spec[2]), [])
    if not records is Array: errors.append("Gameplay %s records must be an array." % section); return errors
    var validator := _record_validator(section)
    var id_field := _id_field(section)
    var seen: Dictionary = {}
    for item in records:
        if not item is Dictionary: errors.append("Gameplay %s registry must contain dictionaries only." % section); continue
        errors.append_array(validator.call(item))
        var id := str(item.get(id_field, ""))
        if seen.has(id): errors.append("Gameplay %s registry contains duplicate IDs." % section)
        seen[id] = true
    return errors


func _assign_section(state, section: String, records: Array[Dictionary]) -> void:
    match section:
        "definitions": state.definitions = records
        "instances": state.instances = records
        "archetypes": state.archetypes = records
        "prefabs": state.prefabs = records
        "sockets": state.sockets = records
        "attachments": state.attachments = records
        "prefab_instances": state.prefab_instances = records


func _record_validator(section: String) -> Callable:
    match section:
        "definitions": return Callable(Contracts, "validate_component_definition")
        "instances": return Callable(Contracts, "validate_component_instance")
        "archetypes": return Callable(Contracts, "validate_archetype")
        "prefabs": return Callable(Contracts, "validate_prefab")
        "sockets": return Callable(Contracts, "validate_socket")
        "attachments": return Callable(Contracts, "validate_attachment")
        "prefab_instances": return Callable(Contracts, "validate_prefab_instance")
    return Callable()


func _id_field(section: String) -> String:
    match section:
        "definitions": return "definition_id"
        "instances": return "instance_id"
        "archetypes": return "archetype_id"
        "prefabs": return "prefab_id"
        "sockets": return "socket_id"
        "attachments": return "attachment_id"
        "prefab_instances": return "instance_id"
    return "id"


func _seed_records(section: String) -> Array:
    if section == "definitions": return BuiltinComponents.definitions()
    if section == "archetypes": return BuiltinArchetypes.definitions()
    return []


static func _dictionary_array(records: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for record in records:
        if record is Dictionary: result.append(record.duplicate(true))
    return result


static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
