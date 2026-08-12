class_name PlayWorldAiActionRegistry
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/ai/ai_contracts.gd")

const SUPPORTED_TYPES := [
    "entity.place_asset",
    "entity.place_proxy",
    "entity.transform",
    "gameplay.add_component",
    "visual.create_graph",
    "procedural.create_foliage_set",
    "environment.configure",
]

var _query_service
var _gameplay_service


func bind(query_service, gameplay_service = null) -> Dictionary:
    if query_service == null: return _failure("AI action registry requires the bound query service.")
    _query_service = query_service
    _gameplay_service = gameplay_service
    return {"ok": true, "errors": []}


func action_catalog() -> Array[Dictionary]:
    return [
        {"type": "entity.place_asset", "description": "Place an existing real Asset Library asset.", "required": ["asset_id", "position"], "optional": ["display_name", "rotation_degrees", "scale"]},
        {"type": "entity.place_proxy", "description": "Place a proxy object without an asset.", "required": ["display_name", "position"], "optional": ["rotation_degrees", "scale"]},
        {"type": "entity.transform", "description": "Set transform fields on an existing authored entity.", "required": ["entity_id"], "optional": ["position", "rotation_degrees", "scale"]},
        {"type": "gameplay.add_component", "description": "Add an existing gameplay component definition to an existing entity.", "required": ["entity_id", "definition_id"], "optional": ["values"]},
        {"type": "visual.create_graph", "description": "Create a new Visual Scripting graph using supplied nodes/connections or an empty event graph.", "required": ["display_name"], "optional": ["kind", "nodes", "connections", "variables"]},
        {"type": "procedural.create_foliage_set", "description": "Create a foliage set using an existing Asset Library asset or a built-in primitive.", "required": ["display_name"], "optional": ["asset_id", "primitive"]},
        {"type": "environment.configure", "description": "Configure authored time/day/fog/wind/default weather fields through the existing Environment system.", "required": ["patch"], "optional": []},
    ]


func normalize_provider_proposal(request_id: String, raw: Dictionary) -> Dictionary:
    var actions: Array = []
    var raw_actions: Variant = raw.get("actions", [])
    if raw_actions is Array:
        for value in raw_actions:
            if not value is Dictionary: continue
            var action: Dictionary = value.duplicate(true)
            if not StableId.is_valid(str(action.get("action_id", ""))): action["action_id"] = StableId.generate()
            action["type"] = str(action.get("type", "")).strip_edges()
            if not action.get("arguments", {}) is Dictionary: action["arguments"] = {}
            action["reason"] = str(action.get("reason", "")).strip_edges()
            actions.append(action)
    return {
        "document_type": Contracts.PROPOSAL_TYPE,
        "schema_version": Contracts.SCHEMA_VERSION,
        "proposal_id": StableId.generate(),
        "request_id": request_id,
        "summary": str(raw.get("summary", "AI proposal")).strip_edges(),
        "actions": actions,
        "notes": raw.get("notes", []).duplicate(true) if raw.get("notes", []) is Array else [],
    }


func validate_proposal(proposal: Dictionary) -> Array[String]:
    var errors: Array[String] = Contracts.validate_proposal(proposal)
    if _query_service == null:
        errors.append("AI action registry is not bound.")
        return errors
    for action_value in proposal.get("actions", []):
        if action_value is Dictionary: errors.append_array(validate_action(action_value))
    return errors


func validate_action(action: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    var action_type: String = str(action.get("type", ""))
    var args: Dictionary = action.get("arguments", {})
    if not SUPPORTED_TYPES.has(action_type): return ["Unsupported AI action type: %s" % action_type]
    match action_type:
        "entity.place_asset":
            _require_vector3(args, "position", errors)
            _optional_vector3(args, "rotation_degrees", errors)
            _optional_vector3(args, "scale", errors)
            var asset_id: String = str(args.get("asset_id", ""))
            var asset: Dictionary = _query_service.asset_get(asset_id)
            if asset.is_empty(): errors.append("AI asset placement references an unavailable asset_id: %s" % asset_id)
            elif bool(asset.get("missing", false)): errors.append("AI asset placement references a missing source asset: %s" % asset_id)
            elif not bool(asset.get("analysis", {}).get("ok", false)): errors.append("AI asset placement references an asset that failed analysis: %s" % asset_id)
        "entity.place_proxy":
            if str(args.get("display_name", "")).strip_edges().is_empty(): errors.append("AI proxy placement requires display_name.")
            _require_vector3(args, "position", errors)
            _optional_vector3(args, "rotation_degrees", errors)
            _optional_vector3(args, "scale", errors)
        "entity.transform":
            var entity_id: String = str(args.get("entity_id", ""))
            if _query_service.entity_search(entity_id, 1).is_empty(): errors.append("AI transform references an unavailable entity_id: %s" % entity_id)
            if not args.has("position") and not args.has("rotation_degrees") and not args.has("scale"): errors.append("AI transform requires at least one transform field.")
            _optional_vector3(args, "position", errors)
            _optional_vector3(args, "rotation_degrees", errors)
            _optional_vector3(args, "scale", errors)
        "gameplay.add_component":
            var entity_id: String = str(args.get("entity_id", ""))
            if _query_service.entity_search(entity_id, 1).is_empty(): errors.append("AI gameplay action references an unavailable entity_id: %s" % entity_id)
            var definition_id: String = str(args.get("definition_id", ""))
            if not _has_gameplay_definition(definition_id): errors.append("AI gameplay action references an unavailable definition_id: %s" % definition_id)
            if args.has("values") and not args.get("values") is Dictionary: errors.append("AI gameplay values must be a dictionary.")
        "visual.create_graph":
            if str(args.get("display_name", "")).strip_edges().is_empty(): errors.append("AI visual graph creation requires display_name.")
            var kind: String = str(args.get("kind", "event"))
            if not ["event", "function", "macro"].has(kind): errors.append("AI visual graph kind must be event, function, or macro.")
            for key in ["nodes", "connections", "variables"]:
                if args.has(key) and not args.get(key) is Array: errors.append("AI visual graph %s must be an array." % key)
        "procedural.create_foliage_set":
            if str(args.get("display_name", "")).strip_edges().is_empty(): errors.append("AI foliage creation requires display_name.")
            var has_asset: bool = not str(args.get("asset_id", "")).is_empty()
            var has_primitive: bool = not str(args.get("primitive", "")).is_empty()
            if has_asset == has_primitive: errors.append("AI foliage creation requires exactly one of asset_id or primitive.")
            if has_asset:
                var asset_id: String = str(args.get("asset_id", ""))
                var asset: Dictionary = _query_service.asset_get(asset_id)
                if asset.is_empty() or bool(asset.get("missing", false)) or not bool(asset.get("analysis", {}).get("ok", false)):
                    errors.append("AI foliage creation references an unavailable asset_id: %s" % asset_id)
            if has_primitive and not ["grass", "post", "cube"].has(str(args.get("primitive", ""))): errors.append("Unsupported built-in foliage primitive.")
        "environment.configure":
            var patch_value: Variant = args.get("patch", {})
            if not patch_value is Dictionary or patch_value.is_empty(): errors.append("AI environment configure requires a non-empty patch.")
            else:
                var allowed: Array[String] = ["time_of_day_hours", "day_length_seconds", "progress_time_in_play", "default_weather_profile_id", "default_transition_seconds", "fog_enabled", "wind_enabled"]
                for key_value in patch_value.keys():
                    if not allowed.has(str(key_value)): errors.append("Unsupported AI environment property: %s" % str(key_value))
    return errors


func source_asset_ids(proposal: Dictionary) -> Array[String]:
    var seen: Dictionary = {}
    var result: Array[String] = []
    for action_value in proposal.get("actions", []):
        if not action_value is Dictionary: continue
        var args: Dictionary = action_value.get("arguments", {})
        var asset_id: String = str(args.get("asset_id", ""))
        if StableId.is_valid(asset_id) and not seen.has(asset_id):
            seen[asset_id] = true
            result.append(asset_id)
    result.sort()
    return result


func _has_gameplay_definition(definition_id: String) -> bool:
    if _gameplay_service == null: return false
    for definition in _gameplay_service.get_definitions():
        if definition is Dictionary and str(definition.get("definition_id", "")) == definition_id: return true
    return false


static func _require_vector3(args: Dictionary, key: String, errors: Array[String]) -> void:
    if not args.has(key): errors.append("AI action requires %s." % key); return
    _validate_vector3(args.get(key), key, errors)


static func _optional_vector3(args: Dictionary, key: String, errors: Array[String]) -> void:
    if args.has(key): _validate_vector3(args.get(key), key, errors)


static func _validate_vector3(value: Variant, key: String, errors: Array[String]) -> void:
    if not value is Array or value.size() != 3:
        errors.append("AI action %s must be a three-number array." % key)
        return
    for component in value:
        if not component is int and not component is float:
            errors.append("AI action %s must contain only numbers." % key)
            return


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
