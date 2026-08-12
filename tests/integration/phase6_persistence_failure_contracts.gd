extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const SafeJsonWriter = preload("res://src/world/safe_json_writer.gd")
const GameplayRepository = preload("res://src/gameplay/gameplay_repository.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var root := "user://tests/phase6_failure_%s" % StableId.generate()
    var project = WorldProject.new(); project.initialize_new("Phase 6 Failure", &"small", "blank_sandbox")
    var test_cells: Array[String] = [StableId.generate()]
    project.cell_ids = test_cells
    var repository = GameplayRepository.new(root.path_join("project"))
    var opened: Dictionary = repository.open_or_create(project)
    if not opened.get("ok", false):
        errors.append("Phase 6 failure fixture must seed gameplay storage.")
        return errors

    var definitions_path := repository.get_path("definitions")
    var canonical_definitions := FileAccess.get_file_as_string(definitions_path)
    _write_text(definitions_path, "{corrupt")
    var corrupt: Dictionary = GameplayRepository.new(root.path_join("project")).open_or_create(project)
    if corrupt.get("ok", false) or FileAccess.get_file_as_string(definitions_path) != "{corrupt":
        errors.append("Corrupt gameplay registry JSON must fail closed without silent replacement.")
    _write_text(definitions_path, canonical_definitions)

    var parsed: Variant = JSON.parse_string(canonical_definitions)
    if parsed is Dictionary:
        parsed["schema_version"] = 99
        _write_text(definitions_path, JSON.stringify(parsed, "  ") + "\n")
        var future: Dictionary = GameplayRepository.new(root.path_join("project")).open_or_create(project)
        if future.get("ok", false): errors.append("Future gameplay document schema versions must reject safely.")
    _write_text(definitions_path, canonical_definitions)

    var state: Variant = opened.get("state")
    var entity = WorldEntity.new(); entity.initialize_new("Fault Owner", test_cells[0]); project.entity_records.append(entity.to_dictionary())
    var health: Dictionary = state.get_definition(Components.id_for("health"))
    var instance_id := StableId.generate()
    var instance := {"document_type": Contracts.COMPONENT_INSTANCE, "schema_version": Contracts.SCHEMA_VERSION, "instance_id": instance_id, "definition_id": Components.id_for("health"), "owner_entity_id": entity.entity_id, "values": Contracts.defaults_for(health)}
    var add: Dictionary = state.add_instance(instance)
    if not add.get("ok", false): errors.append("Fault-injection fixture must stage a valid component instance.")
    var instances_path := repository.get_path("instances")
    var prior_instances := FileAccess.get_file_as_string(instances_path)
    var failing_writer = SafeJsonWriter.new(func(stage: StringName) -> bool: return stage == &"before_promote")
    var failing_repo = GameplayRepository.new(root.path_join("project"), failing_writer)
    var sections: Array[String] = ["instances"]
    var failed: Dictionary = failing_repo.flush_sections(state, sections)
    if failed.get("ok", true): errors.append("Gameplay persistence must surface atomic promotion failure.")
    if FileAccess.get_file_as_string(instances_path) != prior_instances:
        errors.append("Failed gameplay promotion must preserve the prior canonical document.")

    var missing_base := {"document_type": Contracts.PREFAB, "schema_version": Contracts.SCHEMA_VERSION, "prefab_id": StableId.generate(), "display_name": "Missing Base", "base_prefab_id": StableId.generate(), "nodes": [], "node_overrides": {}, "removed_node_ids": [], "socket_ids": [], "socket_overrides": {}, "removed_socket_ids": []}
    state.prefabs.append(missing_base)
    var state_errors: Array[String] = state.validate(null)
    if not state_errors.any(func(message: String) -> bool: return message.find("base_prefab_id") >= 0):
        errors.append("Missing prefab base references must fail gameplay-state validation.")
    return errors


static func _write_text(path: String, text: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file != null: file.store_string(text); file.close()
