class_name PlayWorldAiStagingService
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const GameplayState = preload("res://src/gameplay/gameplay_state.gd")
const GameplayContracts = preload("res://src/gameplay/gameplay_contracts.gd")
const GraphState = preload("res://src/visual_scripting/visual_graph_state.gd")
const GraphCompiler = preload("res://src/visual_scripting/visual_graph_compiler.gd")
const GraphBuilder = preload("res://src/ai/ai_graph_builder.gd")
const ProceduralContracts = preload("res://src/procedural/procedural_contracts.gd")
const EnvironmentContracts = preload("res://src/environment/environment_contracts.gd")

var _project
var _terrain_controller
var _gameplay_service
var _visual_service
var _procedural_service
var _environment_service

func bind(project, terrain_controller = null, gameplay_service = null, visual_service = null, procedural_service = null, environment_service = null) -> Dictionary:
    if project == null: return _failure("AI staging service requires an active project.")
    _project = project
    _terrain_controller = terrain_controller
    _gameplay_service = gameplay_service
    _visual_service = visual_service
    _procedural_service = procedural_service
    _environment_service = environment_service
    return {"ok": true, "errors": []}

func stage(proposal: Dictionary) -> Dictionary:
    if _project == null: return _failure("AI staging service is not bound.")
    var before_project: Dictionary = _project.to_dictionary()
    var after_project: Dictionary = before_project.duplicate(true)
    var gameplay_before: Dictionary = _gameplay_snapshot()
    var gameplay_stage = _clone_gameplay_state()
    var visual_before: Array[Dictionary] = _visual_graphs()
    var visual_after: Array[Dictionary] = visual_before.duplicate(true)
    var procedural_before: Dictionary = _procedural_document()
    var procedural_after: Dictionary = procedural_before.duplicate(true)
    var environment_before: Dictionary = _environment_document()
    var environment_after: Dictionary = environment_before.duplicate(true)
    var changed: Dictionary = {"project": false, "gameplay": false, "visual": false, "procedural": false, "environment": false}
    var generated: Dictionary = {}
    var local_refs: Dictionary = {}
    for action_value in proposal.get("actions", []):
        if not action_value is Dictionary: return _failure("AI staged actions must be dictionaries.")
        var action: Dictionary = action_value
        var action_result: Dictionary = _stage_action(action, after_project, gameplay_stage, visual_after, procedural_after, environment_after, local_refs)
        if not action_result.get("ok", false): return action_result
        generated[str(action.get("action_id", ""))] = action_result.get("generated", {}).duplicate(true)
        for key_value in action_result.get("changed", []): changed[str(key_value)] = true
    _sync_registries(after_project, visual_after, procedural_after, environment_after)
    var validation: Array[String] = _validate_staged(after_project, gameplay_stage, visual_after, procedural_after, environment_after, changed)
    if not validation.is_empty(): return {"ok": false, "errors": validation}
    return {"ok": true, "errors": [], "before_project": before_project, "after_project": after_project, "gameplay_before": gameplay_before, "gameplay_after": _gameplay_snapshot(gameplay_stage), "visual_before": visual_before, "visual_after": visual_after, "procedural_before": procedural_before, "procedural_after": procedural_after, "environment_before": environment_before, "environment_after": environment_after, "changed": changed, "generated": generated, "local_refs": local_refs.duplicate(true)}

func _stage_action(action: Dictionary, project_after: Dictionary, gameplay_stage, visual_after: Array[Dictionary], procedural_after: Dictionary, environment_after: Dictionary, local_refs: Dictionary) -> Dictionary:
    var action_type: String = str(action.get("type", ""))
    var args: Dictionary = action.get("arguments", {})
    match action_type:
        "entity.place_asset": return _stage_entity_place(args, project_after, str(args.get("asset_id", "")), local_refs)
        "entity.place_proxy": return _stage_entity_place(args, project_after, "", local_refs)
        "entity.transform": return _stage_entity_transform(args, project_after, local_refs)
        "gameplay.add_component": return _stage_gameplay_component(args, project_after, gameplay_stage, local_refs)
        "visual.create_graph": return _stage_visual_graph(args, visual_after)
        "procedural.create_foliage_set": return _stage_foliage(args, procedural_after)
        "environment.configure": return _stage_environment(args, environment_after)
    return _failure("Unsupported staged AI action: %s" % action_type)

func _stage_entity_place(args: Dictionary, project_after: Dictionary, asset_id: String, local_refs: Dictionary) -> Dictionary:
    var position: Array = args.get("position", []).duplicate()
    var cell_id: String = _cell_for_position(position, project_after)
    if cell_id.is_empty(): return _failure("AI placement position is outside the authored world partition.")
    var entity_id: String = StableId.generate()
    var display_name: String = str(args.get("display_name", "")).strip_edges()
    if display_name.is_empty(): display_name = "AI Asset" if not asset_id.is_empty() else "AI Object"
    var record: Dictionary = {"document_type": WorldEntity.DOCUMENT_TYPE, "schema_version": WorldEntity.SCHEMA_VERSION, "entity_id": entity_id, "display_name": display_name, "cell_id": cell_id, "asset_id": asset_id if not asset_id.is_empty() else null, "prefab_id": null, "parent_entity_id": null, "component_instance_ids": [], "transform": {"position": _vector3_array(args.get("position", [0.0, 0.0, 0.0])), "rotation_degrees": _vector3_array(args.get("rotation_degrees", [0.0, 0.0, 0.0])), "scale": _vector3_array(args.get("scale", [1.0, 1.0, 1.0]))}}
    var record_errors: Array[String] = WorldEntity.validate_dictionary(record)
    if not record_errors.is_empty(): return {"ok": false, "errors": record_errors}
    var entities: Array = project_after.get("entities", []).duplicate(true)
    entities.append(record)
    project_after["entities"] = entities
    var result_ref: String = str(args.get("result_ref", "")).strip_edges()
    if not result_ref.is_empty(): local_refs[result_ref] = entity_id
    return {"ok": true, "errors": [], "changed": ["project"], "generated": {"entity_id": entity_id, "result_ref": result_ref}}

func _stage_entity_transform(args: Dictionary, project_after: Dictionary, local_refs: Dictionary) -> Dictionary:
    var entity_id: String = _resolve_entity_target(args, local_refs)
    var entities: Array = project_after.get("entities", []).duplicate(true)
    var index: int = _entity_index(entities, entity_id)
    if index < 0: return _failure("AI transform target disappeared during staging.")
    var record: Dictionary = entities[index].duplicate(true)
    var transform: Dictionary = record.get("transform", {}).duplicate(true)
    for key in ["position", "rotation_degrees", "scale"]:
        if args.has(key): transform[key] = _vector3_array(args.get(key))
    record["transform"] = transform
    if args.has("position"):
        var cell_id: String = _cell_for_position(transform.get("position", []), project_after)
        if cell_id.is_empty(): return _failure("AI transformed entity would leave the authored world partition.")
        record["cell_id"] = cell_id
    var record_errors: Array[String] = WorldEntity.validate_dictionary(record)
    if not record_errors.is_empty(): return {"ok": false, "errors": record_errors}
    entities[index] = record
    project_after["entities"] = entities
    return {"ok": true, "errors": [], "changed": ["project"], "generated": {"entity_id": entity_id}}

func _stage_gameplay_component(args: Dictionary, project_after: Dictionary, stage, local_refs: Dictionary) -> Dictionary:
    if stage == null: return _failure("AI gameplay action requires the Gameplay subsystem.")
    var entity_id: String = _resolve_entity_target(args, local_refs)
    var definition_id: String = str(args.get("definition_id", ""))
    var entities: Array = project_after.get("entities", []).duplicate(true)
    var entity_index: int = _entity_index(entities, entity_id)
    if entity_index < 0: return _failure("AI gameplay component target disappeared during staging.")
    var existing: Array[String] = stage.definition_ids_for_entity(entity_id)
    if existing.has(definition_id): return _failure("AI gameplay action would add a duplicate component definition.")
    var plan: Dictionary = stage.dependency_plan(definition_id, existing)
    if not plan.get("ok", false): return plan
    var created: Array[String] = []
    for planned_value in plan.get("definition_ids", []):
        var planned_id: String = str(planned_value)
        if existing.has(planned_id): continue
        var conflict: Dictionary = stage.conflict_for(planned_id, existing)
        if not conflict.get("ok", false): return conflict
        if bool(conflict.get("conflict", false)): return _failure("AI gameplay action conflicts with existing authored components.")
        var definition: Dictionary = stage.get_definition(planned_id)
        var patch: Dictionary = args.get("values", {}).duplicate(true) if planned_id == definition_id else {}
        var value_errors: Array[String] = GameplayContracts.validate_values(patch, definition, true)
        if not value_errors.is_empty(): return {"ok": false, "errors": value_errors}
        var values: Dictionary = GameplayContracts.defaults_for(definition)
        for key_value in patch.keys(): values[key_value] = patch[key_value]
        var instance_id: String = StableId.generate()
        var instance: Dictionary = {"document_type": GameplayContracts.COMPONENT_INSTANCE, "schema_version": GameplayContracts.SCHEMA_VERSION, "instance_id": instance_id, "definition_id": planned_id, "owner_entity_id": entity_id, "values": values}
        var add_result: Dictionary = stage.add_instance(instance)
        if not add_result.get("ok", false): return add_result
        var entity: Dictionary = entities[entity_index].duplicate(true)
        var ids: Array = entity.get("component_instance_ids", []).duplicate()
        ids.append(instance_id)
        entity["component_instance_ids"] = ids
        entities[entity_index] = entity
        created.append(instance_id)
        existing.append(planned_id)
    project_after["entities"] = entities
    return {"ok": true, "errors": [], "changed": ["project", "gameplay"], "generated": {"entity_id": entity_id, "component_instance_ids": created}}

func _stage_visual_graph(args: Dictionary, visual_after: Array[Dictionary]) -> Dictionary:
    if _visual_service == null: return _failure("AI visual action requires Visual Scripting.")
    var build: Dictionary = GraphBuilder.new().build(args, visual_after)
    if not build.get("ok", false): return build
    visual_after.append(build.get("graph", {}).duplicate(true))
    return {"ok": true, "errors": [], "changed": ["visual", "project"], "generated": {"graph_id": str(build.get("graph_id", ""))}}

func _stage_foliage(args: Dictionary, procedural_after: Dictionary) -> Dictionary:
    if _procedural_service == null or procedural_after.is_empty(): return _failure("AI foliage action requires the Procedural subsystem.")
    var foliage_id: String = StableId.generate()
    var source: Dictionary = {"kind": "asset", "asset_id": str(args.get("asset_id", ""))} if not str(args.get("asset_id", "")).is_empty() else {"kind": "primitive", "primitive": str(args.get("primitive", "grass"))}
    var record: Dictionary = {"foliage_set_id": foliage_id, "display_name": str(args.get("display_name", "AI Foliage")).strip_edges(), "source": source, "scale_range": [0.8, 1.2], "random_yaw": true, "align_to_normal": true, "cast_shadows": false, "max_instances_per_cell": 4000}
    var errors: Array[String] = ProceduralContracts.validate_foliage_set(record)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    var records: Array = procedural_after.get("foliage_sets", []).duplicate(true)
    records.append(record)
    procedural_after["foliage_sets"] = records
    return {"ok": true, "errors": [], "changed": ["procedural", "project"], "generated": {"foliage_set_id": foliage_id}}

func _stage_environment(args: Dictionary, environment_after: Dictionary) -> Dictionary:
    if _environment_service == null or environment_after.is_empty(): return _failure("AI environment action requires the Environment subsystem.")
    var authored: Dictionary = environment_after.get("authored_state", {}).duplicate(true)
    for key_value in args.get("patch", {}).keys(): authored[key_value] = args["patch"][key_value]
    environment_after["authored_state"] = authored
    var errors: Array[String] = EnvironmentContracts.validate_document(environment_after)
    if not errors.is_empty(): return {"ok": false, "errors": errors}
    return {"ok": true, "errors": [], "changed": ["environment", "project"], "generated": {}}

func _validate_staged(project_after: Dictionary, gameplay_stage, visual_after: Array[Dictionary], procedural_after: Dictionary, environment_after: Dictionary, changed: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    var staged_project = WorldProject.new()
    errors.append_array(staged_project.load_dictionary(project_after))
    if not errors.is_empty(): return errors
    if bool(changed.get("gameplay", false)) and gameplay_stage != null: errors.append_array(gameplay_stage.validate(staged_project))
    if bool(changed.get("visual", false)):
        var graph_state = GraphState.new()
        errors.append_array(graph_state.replace_records(visual_after))
        if errors.is_empty():
            var compiled: Dictionary = GraphCompiler.new().compile_registry(visual_after)
            if not compiled.get("ok", false): errors.append_array(compiled.get("errors", []))
    if bool(changed.get("procedural", false)): errors.append_array(ProceduralContracts.validate_document(procedural_after))
    if bool(changed.get("environment", false)): errors.append_array(EnvironmentContracts.validate_document(environment_after))
    return errors

func _sync_registries(project_after: Dictionary, visual_after: Array[Dictionary], procedural_after: Dictionary, environment_after: Dictionary) -> void:
    var registries: Dictionary = project_after.get("registries", {}).duplicate(true)
    registries["visual_graph_ids"] = _ids(visual_after, "graph_id")
    if not procedural_after.is_empty():
        registries["procedural_foliage_set_ids"] = _ids(procedural_after.get("foliage_sets", []), "foliage_set_id")
        registries["procedural_scatter_layer_ids"] = _ids(procedural_after.get("scatter_layers", []), "scatter_layer_id")
        registries["procedural_spline_ids"] = _ids(procedural_after.get("splines", []), "spline_id")
    if not environment_after.is_empty():
        registries["environment_weather_profile_ids"] = _ids(environment_after.get("weather_profiles", []), "weather_profile_id")
        registries["environment_biome_override_ids"] = _ids(environment_after.get("biome_overrides", []), "override_id")
        registries["environment_water_hook_ids"] = _ids(environment_after.get("water_hooks", []), "water_hook_id")
    project_after["registries"] = registries

func _cell_for_position(position: Array, project_after: Dictionary) -> String:
    if position.size() != 3: return ""
    if _terrain_controller != null and _terrain_controller.has_method("get_state"):
        var state = _terrain_controller.get_state()
        if state != null:
            var cell_id: String = state.cell_id_at_position(Vector3(float(position[0]), float(position[1]), float(position[2])))
            if not cell_id.is_empty(): return cell_id
    var cells: Array = project_after.get("cell_ids", [])
    return str(cells[0]) if not cells.is_empty() else ""

func _resolve_entity_target(args: Dictionary, local_refs: Dictionary) -> String:
    var ref: String = str(args.get("entity_ref", "")).strip_edges()
    return str(local_refs.get(ref, "")) if not ref.is_empty() else str(args.get("entity_id", ""))

func _gameplay_snapshot(value = null) -> Dictionary:
    var state = value if value != null else (_gameplay_service.get_state() if _gameplay_service != null else null)
    if state == null: return {}
    var result: Dictionary = {}
    for section in ["definitions", "instances", "archetypes", "prefabs", "sockets", "attachments", "prefab_instances", "dialogues", "quests"]: result[section] = state.get(section).duplicate(true)
    return result

func _clone_gameplay_state():
    if _gameplay_service == null or _gameplay_service.get_state() == null: return null
    var clone = GameplayState.new()
    var snapshot: Dictionary = _gameplay_snapshot()
    for section in snapshot.keys(): clone.set(str(section), snapshot[section].duplicate(true))
    return clone

func _visual_graphs() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if _visual_service == null: return result
    for graph in _visual_service.get_graphs():
        if graph is Dictionary: result.append(graph.duplicate(true))
    return result

func _procedural_document() -> Dictionary: return {} if _procedural_service == null or _procedural_service.get_state() == null else _procedural_service.get_state().to_document()
func _environment_document() -> Dictionary: return {} if _environment_service == null or _environment_service.get_state() == null else _environment_service.get_state().to_document()

static func _entity_index(entities: Array, entity_id: String) -> int:
    for index in range(entities.size()):
        if entities[index] is Dictionary and str(entities[index].get("entity_id", "")) == entity_id: return index
    return -1

static func _vector3_array(value: Variant) -> Array:
    if not value is Array or value.size() != 3: return []
    return [float(value[0]), float(value[1]), float(value[2])]

static func _ids(records: Array, key: String) -> Array[String]:
    var result: Array[String] = []
    for record in records:
        if record is Dictionary: result.append(str(record.get(key, "")))
    result.sort()
    return result

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
