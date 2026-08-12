class_name PlayWorldGameplayService
extends RefCounted

signal gameplay_changed
signal status_changed(message: String, is_error: bool)

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const GameplayState = preload("res://src/gameplay/gameplay_state.gd")
const GameplayRepository = preload("res://src/gameplay/gameplay_repository.gd")
const SnapshotCommand = preload("res://src/gameplay/gameplay_snapshot_command.gd")

var _project
var _editor_session
var _dirty_callback := Callable()
var _repository
var _state


func bind_project(project, project_directory: String, editor_session, dirty_callback: Callable) -> Dictionary:
    if project == null or editor_session == null: return _failure("Gameplay service requires a project and editor session.")
    if not dirty_callback.is_valid(): return _failure("Gameplay service requires a valid dirty-state callback.")
    _project = project; _editor_session = editor_session; _dirty_callback = dirty_callback
    _repository = GameplayRepository.new(project_directory)
    var result: Dictionary = _repository.open_or_create(project)
    if not result.get("ok", false): _clear(); return result
    _state = result.get("state")
    return {"ok": true, "errors": [], "definition_count": _state.definitions.size(), "archetype_count": _state.archetypes.size()}


func get_state(): return _state
func get_repository(): return _repository
func get_definitions() -> Array[Dictionary]: return [] if _state == null else _copy_array(_state.definitions)
func get_archetypes() -> Array[Dictionary]: return [] if _state == null else _copy_array(_state.archetypes)
func get_prefabs() -> Array[Dictionary]: return [] if _state == null else _copy_array(_state.prefabs)
func get_sockets() -> Array[Dictionary]: return [] if _state == null else _copy_array(_state.sockets)
func get_attachments() -> Array[Dictionary]: return [] if _state == null else _copy_array(_state.attachments)
func components_for_entity(entity_id: String) -> Array[Dictionary]: return [] if _state == null else _state.instances_for_entity(entity_id)
func sockets_for_entity(entity_id: String) -> Array[Dictionary]: return [] if _state == null else _state.sockets_for_owner("entity", entity_id)


func get_runtime_snapshot() -> Dictionary:
    if _state == null:
        return {"definitions": [], "instances": [], "sockets": [], "attachments": []}
    return {
        "definitions": _copy_array(_state.definitions),
        "instances": _copy_array(_state.instances),
        "sockets": _copy_array(_state.sockets),
        "attachments": _copy_array(_state.attachments),
    }


func add_component(entity_id: String, definition_id: String, values: Dictionary = {}) -> Dictionary:
    if not _is_bound(): return _failure("Gameplay service is not bound.")
    if not _entity_exists(entity_id): return _failure("Component target entity does not exist.")
    var stage = _clone_state()
    var project_after := _project_snapshot()
    var existing: Array[String] = stage.definition_ids_for_entity(entity_id)
    if existing.has(definition_id): return _failure("Entity already has this component.")
    var plan: Dictionary = stage.dependency_plan(definition_id, existing)
    if not plan.get("ok", false): return plan
    var current: Array[String] = existing.duplicate()
    var created: Array[String] = []
    for planned_id in plan.get("definition_ids", []):
        var conflict: Dictionary = stage.conflict_for(str(planned_id), current)
        if not conflict.get("ok", false): return conflict
        if conflict.get("conflict", false): return _failure("Component conflicts with an existing component and was not applied.")
        var patch := values if str(planned_id) == definition_id else {}
        var add_result := _stage_add_instance(stage, project_after, entity_id, str(planned_id), patch)
        if not add_result.get("ok", false): return add_result
        created.append(str(add_result.get("instance_id", ""))); current.append(str(planned_id))
    var execute := _execute(stage, project_after, ["instances"], "Add component")
    if execute.get("ok", false): execute["instance_ids"] = created
    return execute


func remove_component(entity_id: String, instance_id: String) -> Dictionary:
    if not _is_bound(): return _failure("Gameplay service is not bound.")
    var target: Dictionary = _state.get_instance(instance_id)
    if target.is_empty() or str(target.get("owner_entity_id", "")) != entity_id: return _failure("Component instance does not belong to the target entity.")
    var target_definition := str(target.get("definition_id", ""))
    var no_existing: Array[String] = []
    for record in _state.instances_for_entity(entity_id):
        if str(record.get("instance_id", "")) == instance_id: continue
        var plan: Dictionary = _state.dependency_plan(str(record.get("definition_id", "")), no_existing)
        if plan.get("ok", false) and plan.get("definition_ids", []).has(target_definition): return _failure("Component is required by another component and cannot be removed independently.")
    var stage = _clone_state(); var project_after := _project_snapshot()
    var removed: Dictionary = stage.remove_instance(instance_id)
    if not removed.get("ok", false): return removed
    var entity_index := _entity_index(project_after["entities"], entity_id)
    if entity_index < 0: return _failure("Component target entity no longer exists.")
    var entity: Dictionary = project_after["entities"][entity_index].duplicate(true)
    var ids: Array = entity.get("component_instance_ids", []).duplicate(); ids.erase(instance_id)
    entity["component_instance_ids"] = ids; project_after["entities"][entity_index] = entity
    return _execute(stage, project_after, ["instances"], "Remove component")


func configure_component(instance_id: String, patch: Dictionary) -> Dictionary:
    if not _is_bound(): return _failure("Gameplay service is not bound.")
    var stage = _clone_state(); var record: Dictionary = stage.get_instance(instance_id)
    if record.is_empty(): return _failure("Component instance does not exist.")
    var definition: Dictionary = stage.get_definition(str(record.get("definition_id", "")))
    var patch_errors: Array[String] = Contracts.validate_values(patch, definition, true)
    if not patch_errors.is_empty(): return {"ok": false, "errors": patch_errors}
    var values: Dictionary = record.get("values", {}).duplicate(true)
    for key in patch.keys(): values[key] = patch[key]
    record["values"] = values
    var replace: Dictionary = stage.replace_instance(record)
    if not replace.get("ok", false): return replace
    return _execute(stage, _project_snapshot(), ["instances"], "Configure component")


func apply_archetype(entity_id: String, archetype_id: String) -> Dictionary:
    if not _is_bound(): return _failure("Gameplay service is not bound.")
    if not _entity_exists(entity_id): return _failure("Archetype target entity does not exist.")
    var stage = _clone_state(); var archetype: Dictionary = stage.get_archetype(archetype_id)
    if archetype.is_empty(): return _failure("Archetype does not exist.")
    var project_after := _project_snapshot(); var existing: Array[String] = stage.definition_ids_for_entity(entity_id)
    var required: Array = archetype.get("required_definition_ids", []).duplicate(); required.sort()
    for definition_id_value in required:
        var definition_id := str(definition_id_value)
        if existing.has(definition_id):
            var patch: Dictionary = archetype.get("component_defaults", {}).get(definition_id, {})
            if not patch.is_empty():
                var instance := _instance_for_definition(stage, entity_id, definition_id)
                var values: Dictionary = instance.get("values", {}).duplicate(true)
                for key in patch.keys(): values[key] = patch[key]
                instance["values"] = values
                var replace: Dictionary = stage.replace_instance(instance)
                if not replace.get("ok", false): return replace
            continue
        var plan: Dictionary = stage.dependency_plan(definition_id, existing)
        if not plan.get("ok", false): return plan
        for planned_id_value in plan.get("definition_ids", []):
            var planned_id := str(planned_id_value)
            if existing.has(planned_id): continue
            var conflict: Dictionary = stage.conflict_for(planned_id, existing)
            if conflict.get("conflict", false): return _failure("Archetype requires a component that conflicts with existing authored components.")
            var patch: Dictionary = archetype.get("component_defaults", {}).get(planned_id, {})
            var add_result := _stage_add_instance(stage, project_after, entity_id, planned_id, patch)
            if not add_result.get("ok", false): return add_result
            existing.append(planned_id)
    var result := _execute(stage, project_after, ["instances"], "Apply archetype")
    if result.get("ok", false): result["archetype_id"] = archetype_id
    return result


func _stage_add_instance(stage, project_after: Dictionary, entity_id: String, definition_id: String, patch: Dictionary) -> Dictionary:
    var definition: Dictionary = stage.get_definition(definition_id)
    if definition.is_empty(): return _failure("Component definition does not exist.")
    var patch_errors: Array[String] = Contracts.validate_values(patch, definition, true)
    if not patch_errors.is_empty(): return {"ok": false, "errors": patch_errors}
    var values: Dictionary = Contracts.defaults_for(definition)
    for key in patch.keys(): values[key] = patch[key]
    var instance_id := StableId.generate()
    var record := {"document_type": Contracts.COMPONENT_INSTANCE, "schema_version": Contracts.SCHEMA_VERSION, "instance_id": instance_id, "definition_id": definition_id, "owner_entity_id": entity_id, "values": values}
    var add_result: Dictionary = stage.add_instance(record)
    if not add_result.get("ok", false): return add_result
    var entity_index := _entity_index(project_after["entities"], entity_id)
    if entity_index < 0: return _failure("Component target entity no longer exists.")
    var entity: Dictionary = project_after["entities"][entity_index].duplicate(true)
    var ids: Array = entity.get("component_instance_ids", []).duplicate(); ids.append(instance_id)
    entity["component_instance_ids"] = ids; project_after["entities"][entity_index] = entity
    return {"ok": true, "errors": [], "instance_id": instance_id}


func _execute(stage, project_after: Dictionary, sections: Array[String], label: String) -> Dictionary:
    var command = SnapshotCommand.new(_project, _state, _repository, _project_snapshot(), project_after, _state_snapshot(_state), _state_snapshot(stage), sections)
    var history_result: Dictionary = _editor_session.get_history().execute_command(command, label)
    if not history_result.get("ok", false): return _failure(str(history_result.get("error", history_result.get("errors", ["Gameplay command failed."]))))
    var refresh: Dictionary = _editor_session.refresh_runtime(true)
    if not refresh.get("ok", false): return refresh
    var dirty_result: Variant = _dirty_callback.call()
    if dirty_result is Dictionary and not dirty_result.get("ok", false): return _failure("Gameplay edit succeeded but project dirty-state signaling failed.")
    _editor_session.emit_signal("project_changed", _project.to_dictionary())
    gameplay_changed.emit(); status_changed.emit(label, false)
    return {"ok": true, "errors": [], "project_data": _project.to_dictionary()}


func _clone_state():
    var clone = GameplayState.new()
    for section in ["definitions", "instances", "archetypes", "prefabs", "sockets", "attachments", "prefab_instances"]: clone.set(section, _copy_array(_state.get(section)))
    return clone


func _state_snapshot(value) -> Dictionary:
    var result: Dictionary = {}
    for section in ["definitions", "instances", "archetypes", "prefabs", "sockets", "attachments", "prefab_instances"]: result[section] = _copy_array(value.get(section))
    return result


func _project_snapshot() -> Dictionary: return {"entities": _copy_array(_project.entity_records), "registries": _project.registries.duplicate(true)}
func _entity_exists(entity_id: String) -> bool: return _entity_index(_project.entity_records, entity_id) >= 0


static func _instance_for_definition(state, entity_id: String, definition_id: String) -> Dictionary:
    for record in state.instances_for_entity(entity_id):
        if str(record.get("definition_id", "")) == definition_id: return record
    return {}


static func _entity_index(records: Array, entity_id: String) -> int:
    for index in range(records.size()):
        if str(records[index].get("entity_id", "")) == entity_id: return index
    return -1


static func _copy_array(records: Array) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for record in records: result.append(record.duplicate(true))
    return result


func _is_bound() -> bool: return _project != null and _editor_session != null and _state != null and _repository != null
func _clear() -> void: _project = null; _editor_session = null; _state = null; _repository = null; _dirty_callback = Callable()
static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
