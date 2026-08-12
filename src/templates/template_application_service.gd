class_name PlayWorldTemplateApplicationService
extends RefCounted

const TemplateManifest = preload("res://src/templates/template_manifest.gd")
const RuntimeModuleRegistry = preload("res://src/templates/runtime_module_registry.gd")
const StableId = preload("res://src/world/stable_id.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const BuiltinArchetypes = preload("res://src/gameplay/builtin_archetype_library.gd")


func apply_to_project(project, manifest: Dictionary, module_registry = null) -> Dictionary:
    if project == null: return _failure("Template application requires a project.")
    var manifest_errors: Array[String] = TemplateManifest.validate_dictionary(manifest)
    if not manifest_errors.is_empty(): return {"ok": false, "errors": manifest_errors}
    var modules = module_registry if module_registry != null else RuntimeModuleRegistry.new()
    var module_result: Dictionary = modules.resolve(manifest.get("required_runtime_modules", []))
    if not module_result.get("ok", false): return module_result
    var runtime_config := {
        "schema_version": 1,
        "template_id": str(manifest.get("template_id", "")),
        "resolved_modules": module_result.get("resolved", []).duplicate(),
        "planned_modules": manifest.get("planned_modules", []).duplicate(),
        "starter_entities": manifest.get("starter_entities", []).duplicate(true),
        "starter_entity_ids": {},
        "materialized": false,
        "spawn_entity_id": null,
        "input_mapping": manifest.get("input_mapping", {}).duplicate(true),
        "default_player_archetype": manifest.get("default_player_archetype"),
        "camera_configuration": manifest.get("camera_configuration", {}).duplicate(true),
        "example_graph_references": manifest.get("example_graph_references", []).duplicate(),
        "ui_hud_packages": manifest.get("ui_hud_packages", []).duplicate(),
        "tutorial_steps": manifest.get("tutorial_steps", []).duplicate(true)
    }
    var multiplayer = manifest.get("multiplayer", null)
    if multiplayer is Dictionary: runtime_config["multiplayer"] = multiplayer.duplicate(true)
    project.template_id = str(manifest.get("template_id", ""))
    project.runtime_config = runtime_config
    project.export_settings = manifest.get("export_settings", {}).duplicate(true)
    project.dependencies = module_result.get("resolved", []).duplicate()
    return {"ok": true, "errors": [], "template_id": project.template_id, "runtime_config": runtime_config.duplicate(true), "resolved_modules": module_result.get("resolved", []).duplicate()}


func materialize_starters(project, manifest: Dictionary, editor_session, gameplay_service, cell_resolver: Callable = Callable()) -> Dictionary:
    if project == null or editor_session == null or gameplay_service == null: return _failure("Starter materialization requires project, editor, and gameplay services.")
    var validation: Dictionary = _validate_materialization(project, manifest, gameplay_service)
    if not validation.get("ok", false): return validation
    var runtime: Dictionary = project.runtime_config.duplicate(true)
    if bool(runtime.get("materialized", false)):
        return _verify_existing_materialization(project, runtime)

    var project_before: Dictionary = project.to_dictionary()
    var starter_ids: Dictionary = {}
    for starter_value in manifest.get("starter_entities", []):
        var starter: Dictionary = starter_value
        var starter_key := str(starter.get("starter_key", ""))
        var entity_id := StableId.from_seed("template:%s:%s:%s" % [project.project_id, project.template_id, starter_key])
        if entity_id.is_empty() or _entity_exists(project.entity_records, entity_id):
            return _failure("Template starter entity identity collides with authored data: %s" % starter_key)
        var transform: Dictionary = starter.get("transform", {}).duplicate(true)
        var cell_id := _resolve_cell(project, transform, cell_resolver)
        if cell_id.is_empty(): return _failure("Template starter is outside the authored world partition: %s" % starter_key)
        project.entity_records.append(_starter_record(entity_id, cell_id, starter))
        starter_ids[starter_key] = entity_id

    var refresh: Dictionary = editor_session.refresh_runtime(false)
    if not refresh.get("ok", false):
        project.load_dictionary(project_before); editor_session.refresh_runtime(false); return refresh

    var applied_commands := 0
    for starter_value in manifest.get("starter_entities", []):
        var starter: Dictionary = starter_value
        var archetype_key := str(starter.get("archetype_key", ""))
        if archetype_key.is_empty(): continue
        var entity_id := str(starter_ids.get(str(starter.get("starter_key", "")), ""))
        var apply_result: Dictionary = gameplay_service.apply_archetype(entity_id, BuiltinArchetypes.id_for(archetype_key))
        if not apply_result.get("ok", false):
            _rollback(project, project_before, editor_session, applied_commands)
            return _failure("Template starter archetype failed for %s: %s" % [archetype_key, str(apply_result.get("errors", []))])
        applied_commands += 1

    var spawn_id: Variant = null
    for starter_value in manifest.get("starter_entities", []):
        var starter: Dictionary = starter_value
        if str(starter.get("role", "")) == "player_spawn":
            spawn_id = starter_ids.get(str(starter.get("starter_key", "")))
            break
    runtime["starter_entity_ids"] = starter_ids.duplicate(true)
    runtime["spawn_entity_id"] = spawn_id
    runtime["materialized"] = true
    project.runtime_config = runtime
    editor_session.get_history().clear()
    refresh = editor_session.refresh_runtime(false)
    if not refresh.get("ok", false):
        _rollback(project, project_before, editor_session, 0)
        return refresh
    editor_session.emit_signal("project_changed", project.to_dictionary())
    return {"ok": true, "errors": [], "changed": true, "starter_entity_ids": starter_ids, "spawn_entity_id": spawn_id}


func _validate_materialization(project, manifest: Dictionary, gameplay_service) -> Dictionary:
    var manifest_errors: Array[String] = TemplateManifest.validate_dictionary(manifest)
    if not manifest_errors.is_empty(): return {"ok": false, "errors": manifest_errors}
    if str(manifest.get("template_id", "")) != project.template_id: return _failure("Template manifest does not match project template identity.")
    var runtime: Dictionary = project.runtime_config
    if str(runtime.get("template_id", "")) != project.template_id: return _failure("Project runtime template configuration is missing or mismatched.")
    for starter in manifest.get("starter_entities", []):
        var archetype_key := str(starter.get("archetype_key", ""))
        if archetype_key.is_empty(): continue
        var archetype_id := BuiltinArchetypes.id_for(archetype_key)
        if archetype_id.is_empty() or gameplay_service.get_state().get_archetype(archetype_id).is_empty(): return _failure("Template starter references an unavailable archetype: %s" % archetype_key)
    return {"ok": true, "errors": []}


func _verify_existing_materialization(project, runtime: Dictionary) -> Dictionary:
    var ids = runtime.get("starter_entity_ids", {})
    if not ids is Dictionary: return _failure("Persisted template starter identity map is corrupt.")
    for entity_id in ids.values():
        if not StableId.is_valid(str(entity_id)) or not _entity_exists(project.entity_records, str(entity_id)): return _failure("Persisted template starter entity is missing from authored project data.")
    return {"ok": true, "errors": [], "changed": false, "starter_entity_ids": ids.duplicate(true), "spawn_entity_id": runtime.get("spawn_entity_id")}


func _rollback(project, project_before: Dictionary, editor_session, command_count: int) -> void:
    for _index in range(command_count): editor_session.undo_edit()
    project.load_dictionary(project_before)
    editor_session.get_history().clear()
    editor_session.refresh_runtime(false)


func _resolve_cell(project, transform: Dictionary, cell_resolver: Callable) -> String:
    var position_array: Array = transform.get("position", [0.0, 0.0, 0.0])
    if cell_resolver.is_valid() and position_array.size() == 3:
        var value: Variant = cell_resolver.call(Vector3(float(position_array[0]), float(position_array[1]), float(position_array[2])))
        if value != null and not str(value).is_empty(): return str(value)
    return "" if project.cell_ids.is_empty() else str(project.cell_ids[0])


static func _starter_record(entity_id: String, cell_id: String, starter: Dictionary) -> Dictionary:
    return {"document_type": WorldEntity.DOCUMENT_TYPE, "schema_version": WorldEntity.SCHEMA_VERSION, "entity_id": entity_id, "display_name": str(starter.get("display_name", "Starter Entity")), "cell_id": cell_id, "asset_id": null, "prefab_id": null, "parent_entity_id": null, "component_instance_ids": [], "transform": starter.get("transform", {}).duplicate(true)}


static func _entity_exists(records: Array, entity_id: String) -> bool:
    for record in records:
        if str(record.get("entity_id", "")) == entity_id: return true
    return false


static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
