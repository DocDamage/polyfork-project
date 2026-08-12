extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const ProjectRepository = preload("res://src/world/project_repository.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const GameplayService = preload("res://src/gameplay/gameplay_service.gd")
const TemplateRegistry = preload("res://src/templates/template_registry.gd")
const TemplateApplication = preload("res://src/templates/template_application_service.gd")
const ProjectModuleService = preload("res://src/templates/project_module_service.gd")
const BuiltinArchetypes = preload("res://src/gameplay/builtin_archetype_library.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var registry = TemplateRegistry.new(); var load_result: Dictionary = registry.load_builtin()
    if not load_result.get("ok", false): return ["Template application integration requires the built-in registry."]
    errors.append_array(_materialize_template(registry, "third_person_adventure"))
    errors.append_array(_materialize_template(registry, "fps"))
    errors.append_array(_materialize_template(registry, "driving"))
    errors.append_array(_module_editability(registry))
    return errors


static func _materialize_template(registry, template_id: String) -> Array[String]:
    var errors: Array[String] = []
    var root: String = "user://tests/phase7_apply_%s_%s" % [template_id, StableId.generate()]
    var repository = ProjectRepository.new(root)
    var create_result: Dictionary = repository.create_project("Phase 7 %s" % template_id, &"small", template_id)
    if not create_result.get("ok", false): return ["Project creation for %s must succeed: %s" % [template_id, create_result.get("errors", [])]]
    var project = create_result["project"]
    var cell_id: String = StableId.generate()
    var owned_cells: Array[String] = [cell_id]
    project.cell_ids = owned_cells
    var session = EditorSession.new(); var dirty: Array[int] = [0]
    var bind_result: Dictionary = session.bind_project(project, func() -> Dictionary: dirty[0] += 1; return {"ok": true, "errors": []})
    if not bind_result.get("ok", false): session.free(); return ["Editor fixture for %s could not bind." % template_id]
    var gameplay = GameplayService.new()
    var gameplay_result: Dictionary = gameplay.bind_project(project, repository.get_project_directory(project.project_id), session, func() -> Dictionary: dirty[0] += 1; return {"ok": true, "errors": []})
    if not gameplay_result.get("ok", false): session.free(); return ["Gameplay fixture for %s could not bind: %s" % [template_id, gameplay_result.get("errors", [])]]
    if gameplay.get_archetypes().size() != 10: errors.append("Phase 7 template initialization must preserve the nine Phase 6 archetypes plus the reusable Phase 7 player archetype.")
    var manifest: Dictionary = registry.get_manifest(template_id); var application = TemplateApplication.new()
    var materialize: Dictionary = application.materialize_starters(project, manifest, session, gameplay, func(_position: Vector3) -> String: return cell_id)
    if not materialize.get("ok", false): errors.append("Template %s starter materialization must succeed: %s" % [template_id, materialize.get("errors", [])]); session.free(); return errors
    if not bool(project.runtime_config.get("materialized", false)): errors.append("Template %s must persist materialized=true." % template_id)
    var starter_ids: Dictionary = project.runtime_config.get("starter_entity_ids", {})
    for starter_value in manifest.get("starter_entities", []):
        var starter: Dictionary = starter_value
        var key: String = str(starter.get("starter_key", "")); var expected: String = StableId.from_seed("template:%s:%s:%s" % [project.project_id, template_id, key])
        if str(starter_ids.get(key, "")) != expected: errors.append("Template %s starter %s must receive deterministic identity." % [template_id, key])
        var record: Dictionary = _find_entity(project.entity_records, expected)
        if record.is_empty() or str(record.get("cell_id", "")) != cell_id: errors.append("Template %s starter %s must be a real authored entity owned by a world cell." % [template_id, key])
    if template_id == "driving":
        var vehicle_id: String = str(starter_ids.get("vehicle_prototype", "")); var vehicle_components: Array[Dictionary] = gameplay.components_for_entity(vehicle_id)
        if vehicle_components.is_empty(): errors.append("Driving vehicle prototype must use the existing Phase 6 Vehicle archetype composition.")
        if gameplay.get_state().get_archetype(BuiltinArchetypes.id_for("vehicle")).is_empty(): errors.append("Driving must resolve the real Phase 6 Vehicle archetype.")
    if session.get_history_counts() != {"undo": 0, "redo": 0}: errors.append("Template starter initialization must leave a clean user Undo/Redo baseline.")
    var before_count: int = project.entity_records.size(); var second: Dictionary = application.materialize_starters(project, manifest, session, gameplay, func(_position: Vector3) -> String: return cell_id)
    if not second.get("ok", false) or bool(second.get("changed", true)): errors.append("Repeated template materialization must be a safe no-op.")
    if project.entity_records.size() != before_count: errors.append("Repeated template materialization must not duplicate runtime starter nodes.")
    var save_result: Dictionary = repository.save_project(project)
    if not save_result.get("ok", false): errors.append("Materialized template project must save: %s" % save_result.get("errors", []))
    else:
        var reopen: Dictionary = repository.open_project(project.project_id)
        if not reopen.get("ok", false): errors.append("Materialized template project must reopen: %s" % reopen.get("errors", []))
        else:
            var reopened = reopen["project"]
            if reopened.runtime_config != project.runtime_config: errors.append("Template runtime configuration must persist across reopen.")
            if reopened.entity_records != project.entity_records: errors.append("Template starter entity identity must persist across reopen.")
    session.free()
    return errors


static func _module_editability(registry) -> Array[String]:
    var errors: Array[String] = []
    var project_result: Dictionary = ProjectRepository.new("user://tests/phase7_modules_%s" % StableId.generate()).create_project("Modules", &"small", "third_person_adventure")
    if not project_result.get("ok", false): return ["Module editability fixture could not create a project."]
    var project = project_result["project"]; var service = ProjectModuleService.new(); var original_template: String = project.template_id
    var disable: Dictionary = service.set_enabled(project, "play.third_person", false)
    if not disable.get("ok", false) or project.runtime_config.get("resolved_modules", []).has("play.third_person"): errors.append("Projects must be able to remove a template runtime module after creation.")
    if str(project.runtime_config.get("camera_configuration", {}).get("controller", "")) != "none": errors.append("Removing the active controller module must fail safe to no controller.")
    var add: Dictionary = service.set_enabled(project, "play.first_person", true)
    if not add.get("ok", false) or not project.runtime_config.get("resolved_modules", []).has("play.first_person"): errors.append("Projects must be able to add another available runtime module after creation.")
    var controller: Dictionary = service.set_player_controller(project, "first_person")
    if not controller.get("ok", false): errors.append("A project must be able to change controller genre after enabling the module.")
    if project.template_id != original_template: errors.append("Runtime module changes must not rewrite or genre-lock project identity.")
    if service.set_enabled(project, "future.fake.module", true).get("ok", false): errors.append("Unknown module additions must reject clearly.")
    return errors


static func _find_entity(records: Array, entity_id: String) -> Dictionary:
    for record_value in records:
        var record: Dictionary = record_value
        if str(record.get("entity_id", "")) == entity_id: return record
    return {}