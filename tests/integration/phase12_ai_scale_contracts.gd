extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const AssetLibrary = preload("res://src/assets/asset_library_service.gd")
const QueryService = preload("res://src/ai/ai_query_service.gd")
const ActionRegistry = preload("res://src/ai/ai_action_registry.gd")
const StagingService = preload("res://src/ai/ai_staging_service.gd")
const Contracts = preload("res://src/ai/ai_contracts.gd")

static func run_checks(tree_root: Node) -> Array[String]:
    var errors: Array[String] = []
    var project_dir: String = "user://tests/phase12/scale-%s" % StableId.generate(); DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(project_dir))
    var project = WorldProject.new(); project.initialize_new("Phase 12 Scale", &"small", "blank_sandbox")
    var cell_id: String = StableId.generate(); var cells: Array[String] = [cell_id]; project.cell_ids = cells
    var records: Array[Dictionary] = []
    for index in range(256):
        records.append({"document_type": WorldEntity.DOCUMENT_TYPE, "schema_version": WorldEntity.SCHEMA_VERSION, "entity_id": StableId.generate(), "display_name": "Scale Entity %03d" % index, "cell_id": cell_id, "asset_id": null, "prefab_id": null, "parent_entity_id": null, "component_instance_ids": [], "transform": {"position": [float(index % 16) * 2.0, 0.5, float(index / 16) * 2.0], "rotation_degrees": [0.0, 0.0, 0.0], "scale": [1.0, 1.0, 1.0]}})
    project.entity_records = records
    var fixture := Node3D.new(); tree_root.add_child(fixture)
    var editor = EditorSession.new(); fixture.add_child(editor)
    if not editor.bind_project(project, func() -> Dictionary: return {"ok": true, "errors": []}).get("ok", false): fixture.queue_free(); return ["Phase 12 scale fixture could not bind 256 authored entities."]
    var assets = AssetLibrary.new(project_dir); if not assets.load_library().get("ok", false): fixture.queue_free(); return ["Phase 12 scale fixture could not load Asset Library."]
    var query = QueryService.new(); query.bind(project, editor, assets)
    var action_registry = ActionRegistry.new(); action_registry.bind(query)
    var staging = StagingService.new(); staging.bind(project)

    var query_start: int = Time.get_ticks_msec(); var found: Array[Dictionary] = query.entity_search("Scale Entity", 40); var query_ms: int = Time.get_ticks_msec() - query_start
    if found.size() != 40: errors.append("AI entity query limits must bound a 256-entity project to the requested result count.")
    if query_ms > 2000: errors.append("AI 256-entity bounded query exceeded the 2000 ms CI budget: %d ms" % query_ms)

    var actions: Array = []
    for index in range(Contracts.MAX_ACTIONS):
        actions.append(_action("entity.transform", {"entity_id": str(records[index].get("entity_id", "")), "position": [float(index), 0.5, float(index)]}))
    var proposal: Dictionary = Contracts.new_proposal(StableId.generate(), "Scale transform batch", actions)
    var validation_start: int = Time.get_ticks_msec(); var validation: Array[String] = action_registry.validate_proposal(proposal); var validation_ms: int = Time.get_ticks_msec() - validation_start
    if not validation.is_empty(): errors.append("Maximum-size 64-action AI proposal must validate against a 256-entity project: %s" % validation)
    if validation_ms > 3000: errors.append("AI maximum proposal validation exceeded the 3000 ms CI budget: %d ms" % validation_ms)
    var before: Dictionary = project.to_dictionary(); var stage_start: int = Time.get_ticks_msec(); var staged: Dictionary = staging.stage(proposal); var stage_ms: int = Time.get_ticks_msec() - stage_start
    if not staged.get("ok", false): errors.append("Maximum-size AI transform proposal must stage successfully: %s" % staged.get("errors", []))
    if project.to_dictionary() != before: errors.append("AI staging at maximum action count must remain read-only.")
    if stage_ms > 5000: errors.append("AI maximum proposal staging exceeded the 5000 ms CI budget: %d ms" % stage_ms)

    var too_many: Array = actions.duplicate(true); too_many.append(_action("entity.transform", {"entity_id": str(records[64].get("entity_id", "")), "position": [65.0, 0.5, 65.0]}))
    var overflow: Dictionary = Contracts.new_proposal(StableId.generate(), "Overflow", too_many)
    if action_registry.validate_proposal(overflow).is_empty(): errors.append("AI proposal validation must reject action counts above the Phase 12 maximum.")
    fixture.queue_free(); return errors

static func _action(type_name: String, arguments: Dictionary) -> Dictionary:
    return {"action_id": StableId.generate(), "type": type_name, "arguments": arguments, "reason": "Scale regression"}
