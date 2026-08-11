extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const Repository = preload("res://src/world/project_repository.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    _check_supported_legacy_schema(errors)
    _check_future_project_schema_rejected(errors)
    _check_unresolved_entity_reference_rejected(errors)
    _check_duplicate_entity_identity_rejected(errors)
    return errors


static func _check_supported_legacy_schema(errors: Array[String]) -> void:
    var repository = Repository.new(_root("legacy_schema"))
    var created: Dictionary = repository.create_project("Legacy Compatible", &"small", "blank_sandbox")
    if not created.get("ok", false):
        errors.append("Legacy-schema fixture project must be created.")
        return
    var project = created["project"]
    var path: String = created["manifest_path"]
    var data = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not data is Dictionary:
        errors.append("Legacy-schema fixture manifest must parse.")
        return
    data.erase("created_at_msec")
    data.erase("updated_at_msec")
    data.erase("entities")
    _write_dictionary(path, data, errors)
    var reopened: Dictionary = Repository.new(repository.root_path).open_project(project.project_id)
    if not reopened.get("ok", false):
        errors.append("Supported schema-v1 manifest without additive optional fields must load.")
    elif reopened["project"].updated_at_msec != reopened["project"].updated_at_unix * 1000:
        errors.append("Legacy schema-v1 timestamps must use the documented millisecond fallback.")
    elif not reopened["project"].entity_records.is_empty():
        errors.append("Legacy schema-v1 manifests must default missing entity records to empty.")


static func _check_future_project_schema_rejected(errors: Array[String]) -> void:
    var repository = Repository.new(_root("future_schema"))
    var created: Dictionary = repository.create_project("Future Schema", &"small", "blank_sandbox")
    if not created.get("ok", false):
        errors.append("Future-schema fixture project must be created.")
        return
    var project = created["project"]
    var path: String = created["manifest_path"]
    var canonical_text := FileAccess.get_file_as_string(path)
    var data = JSON.parse_string(canonical_text)
    data["schema_version"] = int(data["schema_version"]) + 1
    _write_dictionary(path, data, errors)
    var rejected: Dictionary = repository.open_project(project.project_id)
    if rejected.get("ok", false):
        errors.append("Unsupported future world-project schema must fail explicitly.")
    elif not str(rejected.get("errors", [])).contains("schema_version"):
        errors.append("Unsupported schema failure must report schema_version context.")
    _write_text(path, canonical_text, errors)
    if not repository.open_project(project.project_id).get("ok", false):
        errors.append("Rejecting unsupported schema data must not prevent restoration of known-good canonical data.")


static func _check_unresolved_entity_reference_rejected(errors: Array[String]) -> void:
    var repository = Repository.new(_root("entity_reference"))
    var created: Dictionary = repository.create_project("Entity Reference", &"small", "blank_sandbox")
    if not created.get("ok", false):
        errors.append("Entity-reference fixture project must be created.")
        return
    var project = created["project"]
    var cell_id := StableId.generate()
    project.cell_ids.append(cell_id)
    var entity = WorldEntity.new()
    entity.initialize_new("Broken Child", cell_id)
    entity.parent_entity_id = StableId.generate()
    project.entity_records.clear()
    project.entity_records.append(entity.to_dictionary())
    var canonical_text := FileAccess.get_file_as_string(created["manifest_path"])
    var result: Dictionary = repository.save_project(project)
    if result.get("ok", false):
        errors.append("World project must reject unresolved parent_entity_id references.")
    if FileAccess.get_file_as_string(created["manifest_path"]) != canonical_text:
        errors.append("Rejected entity reference must preserve the prior canonical manifest.")


static func _check_duplicate_entity_identity_rejected(errors: Array[String]) -> void:
    var repository = Repository.new(_root("duplicate_entity"))
    var created: Dictionary = repository.create_project("Duplicate Entity", &"small", "blank_sandbox")
    if not created.get("ok", false):
        errors.append("Duplicate-entity fixture project must be created.")
        return
    var project = created["project"]
    var cell_id := StableId.generate()
    project.cell_ids.append(cell_id)
    var entity = WorldEntity.new()
    entity.initialize_new("Duplicate", cell_id)
    var record: Dictionary = entity.to_dictionary()
    project.entity_records.clear()
    project.entity_records.append(record)
    project.entity_records.append(record.duplicate(true))
    var result: Dictionary = repository.save_project(project)
    if result.get("ok", false):
        errors.append("World project must reject duplicate persisted entity identities.")
    elif not str(result.get("errors", [])).contains("duplicate"):
        errors.append("Duplicate entity identity rejection must be actionable.")


static func _write_dictionary(path: String, data: Dictionary, errors: Array[String]) -> void:
    _write_text(path, JSON.stringify(data, "  ") + "\n", errors)


static func _write_text(path: String, text: String, errors: Array[String]) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        errors.append("Phase 2 hardening fixture could not write %s" % path)
        return
    file.store_string(text)
    file.flush()
    file.close()


static func _root(label: String) -> String:
    return "user://tests/phase2_%s_%s" % [label, StableId.generate()]
