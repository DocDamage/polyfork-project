class_name Phase16IntegrationClosureContracts
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const SnappingService = preload("res://src/editor/snapping_service.gd")
const TemplateRegistry = preload("res://src/templates/template_registry.gd")
const RuntimeModules = preload("res://src/templates/runtime_module_registry.gd")
const EnvironmentContracts = preload("res://src/environment/environment_contracts.gd")
const EnvironmentRuntime = preload("res://src/environment/environment_runtime.gd")
const WaterProviders = preload("res://src/environment/water_provider_registry.gd")

class FakeTerrain:
    extends RefCounted
    var biome_id: String
    var cell_id: String
    func _init(p_biome_id: String) -> void:
        biome_id = p_biome_id
        cell_id = StableId.generate()
    func get_cell_at_position(_position: Vector3) -> Dictionary:
        return {"cell_id": cell_id, "biome_id": biome_id}
    func get_biome(requested_id: String) -> Dictionary:
        return {"biome_id": biome_id, "future_defaults": {}} if requested_id == biome_id else {}

class SocketResolver:
    extends RefCounted
    var entity_id: String
    var socket_id: String
    func _init(p_entity_id: String, p_socket_id: String) -> void:
        entity_id = p_entity_id
        socket_id = p_socket_id
    func sockets_for_entity(requested_id: String) -> Array[Dictionary]:
        if requested_id != entity_id: return []
        return [{"socket_id": socket_id, "local_transform": {"position": [1.0, 2.0, 0.0], "rotation_degrees": [0.0, 0.0, 0.0], "scale": [1.0, 1.0, 1.0]}}]

class GroundResolver:
    extends RefCounted
    func sample_height(_position: Vector3) -> float: return 3.0

static func run_checks(tree: SceneTree) -> Array[String]:
    var errors: Array[String] = []
    errors.append_array(_check_templates())
    errors.append_array(_check_snapping_and_resolvers())
    errors.append_array(await _check_water_runtime(tree))
    return errors

static func _check_templates() -> Array[String]:
    var errors: Array[String] = []
    var registry = TemplateRegistry.new()
    var load_result: Dictionary = registry.load_builtin()
    if not load_result.get("ok", false): return ["Phase 16 template registry failed: %s" % str(load_result.get("errors", []))]
    var expectations := {
        "rpg": ["phase10.inventory", "phase10.narrative"],
        "survival": ["phase10.inventory", "phase10.health"],
        "driving": ["phase10.vehicle"],
    }
    var module_registry = RuntimeModules.new()
    for template_id in expectations.keys():
        var manifest: Dictionary = registry.get_manifest(str(template_id))
        if manifest.is_empty(): errors.append("Missing promoted template: %s" % template_id); continue
        var required: Array = manifest.get("required_runtime_modules", [])
        for module_id in expectations[template_id]:
            if not required.has(module_id): errors.append("%s template omitted promoted module %s" % [template_id, module_id])
            elif not module_registry.has_module(module_id): errors.append("Promoted module is not registered: %s" % module_id)
        var planned: Array = manifest.get("planned_modules", [])
        for stale in ["inventory_runtime", "dialogue_runtime", "quest_runtime", "vehicle_runtime"]:
            if planned.has(stale): errors.append("%s still labels implemented runtime as planned: %s" % [template_id, stale])
    return errors

static func _check_snapping_and_resolvers() -> Array[String]:
    var errors: Array[String] = []
    var snapping = SnappingService.new()
    var vertex: Dictionary = snapping.snap_to_vertex(Vector3(1.1, 2.0, 3.0), [{"id": "v", "position": Vector3(1.0, 2.0, 3.0)}])
    if not vertex.get("snapped", false) or not (vertex.get("position", Vector3.ZERO) as Vector3).is_equal_approx(Vector3(1.0, 2.0, 3.0)):
        errors.append("Vertex snapping did not resolve the nearest real vertex candidate.")
    var normal := Vector3(0.0, 0.70710678, 0.70710678).normalized()
    var rotation_degrees: Vector3 = snapping.surface_rotation(normal)
    var basis := Basis.from_euler(rotation_degrees * (PI / 180.0))
    if basis.y.normalized().dot(normal) < 0.99: errors.append("Surface-normal snapping did not orient local up to the hit normal.")

    var project = WorldProject.new()
    project.initialize_new("Phase16 Editor", &"medium", "blank_sandbox")
    var cell_id := StableId.generate(); project.cell_ids = [cell_id]
    var entity_id := StableId.generate()
    project.entity_records = [{
        "document_type": WorldEntity.DOCUMENT_TYPE,
        "schema_version": WorldEntity.SCHEMA_VERSION,
        "entity_id": entity_id,
        "display_name": "Socket Host",
        "cell_id": cell_id,
        "asset_id": null,
        "prefab_id": null,
        "parent_entity_id": null,
        "component_instance_ids": [],
        "transform": {"position": [5.0, 1.0, 5.0], "rotation_degrees": [0.0, 0.0, 0.0], "scale": [1.0, 1.0, 1.0]},
    }]
    var session = EditorSession.new()
    var bind_result: Dictionary = session.bind_project(project, func(): return {"ok": true, "errors": []})
    if not bind_result.get("ok", false): return errors + ["Phase 16 editor fixture failed to bind: %s" % str(bind_result.get("errors", []))]
    var socket_id := StableId.generate(); var socket_resolver = SocketResolver.new(entity_id, socket_id)
    session.bind_socket_resolver(Callable(socket_resolver, "sockets_for_entity"))
    var socket_candidates: Array = session.call("_runtime_snap_candidates", true)
    var resolved_socket: Dictionary = {}
    for item in socket_candidates:
        if str(item.get("id", "")) == socket_id: resolved_socket = item; break
    if resolved_socket.is_empty() or not (resolved_socket.get("position", Vector3.ZERO) as Vector3).is_equal_approx(Vector3(6.0, 3.0, 5.0)):
        errors.append("Editor socket snapping did not consume the authored socket local transform.")
    var ground_resolver = GroundResolver.new(); session.bind_ground_resolver(Callable(ground_resolver, "sample_height"))
    session.select_entity(entity_id)
    var ground_result: Dictionary = session.drop_selection_to_ground()
    if not ground_result.get("ok", false): errors.append("Terrain-aware Drop-to-Ground failed: %s" % str(ground_result.get("errors", [])))
    else:
        var moved: Dictionary = project.entity_records[0]
        var position_value: Array = moved.get("transform", {}).get("position", [])
        if position_value.size() != 3 or not is_equal_approx(float(position_value[1]), 3.0): errors.append("Drop-to-Ground did not consume the bound terrain height resolver.")
    session.free()
    return errors

static func _check_water_runtime(tree: SceneTree) -> Array[String]:
    var errors: Array[String] = []
    var provider_registry = WaterProviders.new()
    var imported_root := Node3D.new(); imported_root.name = "ImportedWater"
    var packed := PackedScene.new(); var pack_error: Error = packed.pack(imported_root); imported_root.free()
    if pack_error != OK: errors.append("Could not pack imported water fixture.")
    var imported_path := "user://tests/phase16/imported-water-%s.tscn" % StableId.generate()
    if errors.is_empty() and ResourceSaver.save(packed, imported_path) != OK: errors.append("Could not save imported water fixture.")
    if errors.is_empty():
        var imported: Dictionary = provider_registry.instantiate_hook({"display_name": "Imported", "provider_key": "imported_scene", "settings": {"scene_path": imported_path}})
        if not imported.get("ok", false) or not imported.get("node") is Node3D: errors.append("Imported-scene water provider did not instantiate the PackedScene.")
        elif imported.get("node") != null: (imported.get("node") as Node).free()

    var project_id := StableId.generate(); var biome_id := StableId.generate(); var hook_id := StableId.generate(); var override_id := StableId.generate()
    var document: Dictionary = EnvironmentContracts.empty_document(project_id)
    document["water_hooks"] = [{"water_hook_id": hook_id, "display_name": "Lake", "provider_key": "basic_plane", "settings": {"size": 24.0, "height": 1.5}, "tags": ["lake"]}]
    document["biome_overrides"] = [{"override_id": override_id, "biome_id": biome_id, "weather_profile_id": "", "time_offset_hours": 0.0, "wind_multiplier": 1.0, "fog_density_multiplier": 1.0, "water_hook_ids": [hook_id]}]
    var runtime = EnvironmentRuntime.new(); tree.root.add_child(runtime); await tree.process_frame
    var initialize: Dictionary = runtime.initialize(document, FakeTerrain.new(biome_id), null, false)
    if not initialize.get("ok", false): errors.append("Environment runtime could not consume basic water hook: %s" % str(initialize.get("errors", [])))
    var snapshot: Dictionary = runtime.get_water_runtime_snapshot()
    if int(snapshot.get("count", 0)) != 1 or str(snapshot.get("providers", [])[0].get("provider_key", "")) != "basic_plane": errors.append("Environment runtime did not materialize the basic water provider.")
    var invalid: Dictionary = document.duplicate(true); invalid["water_hooks"][0]["provider_key"] = "missing_provider"
    var invalid_result: Dictionary = runtime.refresh_authored(invalid)
    if invalid_result.get("ok", false): errors.append("Unknown water provider did not fail explicitly.")
    if int(runtime.get_water_runtime_snapshot().get("count", 0)) != 1: errors.append("Failed water-provider refresh destructively removed the prior valid provider.")
    runtime.queue_free(); await tree.process_frame
    return errors
