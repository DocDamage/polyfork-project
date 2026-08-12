class_name PlayWorldAiQueryService
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")

var _project
var _editor_session
var _asset_library
var _terrain_controller
var _gameplay_service
var _visual_service
var _procedural_service
var _environment_service


func bind(project, editor_session, asset_library, terrain_controller = null, gameplay_service = null, visual_service = null, procedural_service = null, environment_service = null) -> Dictionary:
    if project == null or editor_session == null or asset_library == null:
        return _failure("AI query service requires project, editor session, and Asset Library.")
    _project = project
    _editor_session = editor_session
    _asset_library = asset_library
    _terrain_controller = terrain_controller
    _gameplay_service = gameplay_service
    _visual_service = visual_service
    _procedural_service = procedural_service
    _environment_service = environment_service
    return {"ok": true, "errors": []}


func tool_definitions() -> Array[Dictionary]:
    return [
        _tool("project_summary", "Read the active project summary and subsystem counts.", {}),
        _tool("entity_search", "Search authored world entities by display name or stable ID.", {"query": _string_prop(), "limit": _integer_prop(1, 100)}),
        _tool("asset_search", "Search the real local Asset Library. Returned asset_id values are the only valid IDs for asset placement.", {"query": _string_prop(), "limit": _integer_prop(1, 100)}),
        _tool("asset_get", "Read one real Asset Library record by stable asset_id.", {"asset_id": _string_prop()}),
        _tool("gameplay_catalog", "Read gameplay component definitions, archetypes, and prefabs available to authoring.", {"limit": _integer_prop(1, 200)}),
        _tool("biome_list", "Read Phase 5 terrain biome IDs and authored environment defaults.", {"limit": _integer_prop(1, 200)}),
        _tool("visual_graph_list", "Read authored Visual Scripting graph summaries.", {"limit": _integer_prop(1, 200)}),
        _tool("procedural_summary", "Read foliage, scatter, and spline authored summaries.", {"limit": _integer_prop(1, 200)}),
        _tool("environment_summary", "Read authored time, weather profiles, biome overrides, wind/fog flags, and water hooks.", {"limit": _integer_prop(1, 200)}),
    ]


func execute_tool(tool_name: String, arguments: Dictionary, max_items: int = 200) -> Dictionary:
    if _project == null: return _failure("AI query service is not bound.")
    var limit: int = clampi(int(arguments.get("limit", 50)), 1, max(1, max_items))
    match tool_name:
        "project_summary": return {"ok": true, "errors": [], "result": project_summary()}
        "entity_search": return {"ok": true, "errors": [], "result": entity_search(str(arguments.get("query", "")), limit)}
        "asset_search": return {"ok": true, "errors": [], "result": asset_search(str(arguments.get("query", "")), limit)}
        "asset_get":
            var asset: Dictionary = asset_get(str(arguments.get("asset_id", "")))
            if asset.is_empty(): return _failure("Asset Library does not contain the requested asset_id.")
            return {"ok": true, "errors": [], "result": asset}
        "gameplay_catalog": return {"ok": true, "errors": [], "result": gameplay_catalog(limit)}
        "biome_list": return {"ok": true, "errors": [], "result": biome_list(limit)}
        "visual_graph_list": return {"ok": true, "errors": [], "result": visual_graph_list(limit)}
        "procedural_summary": return {"ok": true, "errors": [], "result": procedural_summary(limit)}
        "environment_summary": return {"ok": true, "errors": [], "result": environment_summary(limit)}
    return _failure("Unsupported AI query tool: %s" % tool_name)


func context_snapshot(prompt: String, max_items: int = 200) -> Dictionary:
    var relevant_assets: Array[Dictionary] = asset_search(prompt, mini(16, max_items))
    var relevant_entities: Array[Dictionary] = entity_search(prompt, mini(16, max_items))
    return {
        "project": project_summary(),
        "relevant_assets": relevant_assets,
        "relevant_entities": relevant_entities,
        "gameplay": gameplay_catalog(mini(24, max_items)),
        "biomes": biome_list(mini(24, max_items)),
        "environment": environment_summary(mini(24, max_items)),
    }


func project_summary() -> Dictionary:
    var gameplay_count := 0
    if _gameplay_service != null and _gameplay_service.has_method("get_state") and _gameplay_service.get_state() != null:
        gameplay_count = _gameplay_service.get_state().instances.size()
    var graph_count := 0
    if _visual_service != null and _visual_service.has_method("get_graphs"): graph_count = _visual_service.get_graphs().size()
    return {
        "project_id": str(_project.project_id),
        "title": str(_project.title),
        "world_profile": str(_project.world_profile),
        "template_id": str(_project.template_id),
        "entity_count": _project.entity_records.size(),
        "asset_count": _asset_library.get_records(false).size(),
        "gameplay_component_instance_count": gameplay_count,
        "visual_graph_count": graph_count,
    }


func entity_search(query: String, limit: int = 50) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var needle: String = query.strip_edges().to_lower()
    for value in _project.entity_records:
        if not value is Dictionary: continue
        var entity_id: String = str(value.get("entity_id", ""))
        var display_name: String = str(value.get("display_name", "Entity"))
        if not needle.is_empty() and not display_name.to_lower().contains(needle) and not entity_id.to_lower().contains(needle): continue
        result.append({
            "entity_id": entity_id,
            "display_name": display_name,
            "cell_id": str(value.get("cell_id", "")),
            "asset_id": _optional_string(value.get("asset_id")),
            "prefab_id": _optional_string(value.get("prefab_id")),
            "parent_entity_id": _optional_string(value.get("parent_entity_id")),
            "component_instance_ids": value.get("component_instance_ids", []).duplicate(),
            "transform": value.get("transform", {}).duplicate(true),
        })
        if result.size() >= limit: break
    return result


func asset_search(query: String, limit: int = 50) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for record in _asset_library.query(query, {}):
        result.append(_sanitize_asset(record))
        if result.size() >= limit: break
    return result


func asset_get(asset_id: String) -> Dictionary:
    if not StableId.is_valid(asset_id): return {}
    var record: Dictionary = _asset_library.get_record(asset_id)
    return {} if record.is_empty() else _sanitize_asset(record)


func gameplay_catalog(limit: int = 100) -> Dictionary:
    if _gameplay_service == null: return {"definitions": [], "archetypes": [], "prefabs": []}
    return {
        "definitions": _summarize_named(_gameplay_service.get_definitions(), "definition_id", limit),
        "archetypes": _summarize_named(_gameplay_service.get_archetypes(), "archetype_id", limit),
        "prefabs": _summarize_named(_gameplay_service.get_prefabs(), "prefab_id", limit),
    }


func biome_list(limit: int = 100) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if _terrain_controller == null or not _terrain_controller.has_method("get_state"): return result
    var state = _terrain_controller.get_state()
    if state == null: return result
    for biome_id in state.biome_ids():
        var record: Dictionary = state.get_biome(biome_id)
        result.append({
            "biome_id": biome_id,
            "display_name": str(record.get("display_name", "Biome")),
            "future_defaults": record.get("future_defaults", {}).duplicate(true),
        })
        if result.size() >= limit: break
    return result


func visual_graph_list(limit: int = 100) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if _visual_service == null or not _visual_service.has_method("get_graphs"): return result
    for graph in _visual_service.get_graphs():
        if not graph is Dictionary: continue
        result.append({"graph_id": str(graph.get("graph_id", "")), "display_name": str(graph.get("display_name", "Graph")), "kind": str(graph.get("kind", "")), "enabled": bool(graph.get("enabled", true)), "node_count": graph.get("nodes", []).size()})
        if result.size() >= limit: break
    return result


func procedural_summary(limit: int = 100) -> Dictionary:
    if _procedural_service == null: return {"foliage_sets": [], "scatter_layers": [], "splines": []}
    return {
        "foliage_sets": _summarize_named(_procedural_service.get_foliage_sets(), "foliage_set_id", limit),
        "scatter_layers": _summarize_named(_procedural_service.get_scatter_layers(), "scatter_layer_id", limit),
        "splines": _summarize_named(_procedural_service.get_splines(), "spline_id", limit),
    }


func environment_summary(limit: int = 100) -> Dictionary:
    if _environment_service == null or not _environment_service.has_method("get_state"): return {}
    var state = _environment_service.get_state()
    if state == null: return {}
    return {
        "authored_state": state.authored_state.duplicate(true),
        "weather_profiles": _summarize_named(_environment_service.get_weather_profiles(), "weather_profile_id", limit),
        "biome_overrides": _limit_records(_environment_service.get_biome_overrides(), limit),
        "water_hooks": _summarize_named(_environment_service.get_water_hooks(), "water_hook_id", limit),
    }


static func _sanitize_asset(record: Dictionary) -> Dictionary:
    var analysis: Dictionary = record.get("analysis", {}) if record.get("analysis", {}) is Dictionary else {}
    var license: Dictionary = record.get("license", {}) if record.get("license", {}) is Dictionary else {}
    return {
        "asset_id": str(record.get("asset_id", "")),
        "display_name": str(record.get("display_name", "Asset")),
        "extension": str(record.get("extension", "")),
        "missing": bool(record.get("missing", false)),
        "favorite": bool(record.get("favorite", false)),
        "collections": record.get("collections", []).duplicate(),
        "analysis": {"ok": bool(analysis.get("ok", false)), "kind": str(analysis.get("kind", analysis.get("type", ""))), "dimensions": analysis.get("dimensions", null), "animations": analysis.get("animations", []).size()},
        "license": {"name": str(license.get("name", license.get("license", ""))), "commercial_use": license.get("commercial_use", null), "attribution_required": license.get("attribution_required", null), "author": str(license.get("author", ""))},
    }


static func _summarize_named(values: Array, id_key: String, limit: int) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for value in values:
        if not value is Dictionary: continue
        var item: Dictionary = {id_key: str(value.get(id_key, "")), "display_name": str(value.get("display_name", ""))}
        if value.has("kind"): item["kind"] = value.get("kind")
        if value.has("category"): item["category"] = value.get("category")
        if value.has("settings"): item["settings"] = value.get("settings", {}).duplicate(true)
        result.append(item)
        if result.size() >= limit: break
    return result


static func _limit_records(values: Array, limit: int) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for value in values:
        if value is Dictionary: result.append(value.duplicate(true))
        if result.size() >= limit: break
    return result


static func _tool(name: String, description: String, properties: Dictionary) -> Dictionary:
    return {"type": "function", "function": {"name": name, "description": description, "parameters": {"type": "object", "properties": properties, "additionalProperties": false}}}


static func _string_prop() -> Dictionary: return {"type": "string"}
static func _integer_prop(minimum: int, maximum: int) -> Dictionary: return {"type": "integer", "minimum": minimum, "maximum": maximum}
static func _optional_string(value: Variant) -> String: return "" if value == null else str(value)
static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
