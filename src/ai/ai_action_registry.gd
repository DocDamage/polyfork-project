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
        {"type": "entity.place_asset", "description": "Place an existing real Asset Library asset. result_ref is a temporary proposal-local alias for later actions; Polyfork generates the persisted entity ID.", "required": ["asset_id", "position"], "optional": ["display_name", "rotation_degrees", "scale", "result_ref"]},
        {"type": "entity.place_proxy", "description": "Place a proxy object. result_ref is a temporary proposal-local alias for later actions.", "required": ["display_name", "position"], "optional": ["rotation_degrees", "scale", "result_ref"]},
        {"type": "entity.transform", "description": "Set transform fields on an existing entity_id or a prior placement's entity_ref.", "required_one_of": ["entity_id", "entity_ref"], "optional": ["position", "rotation_degrees", "scale"]},
        {"type": "gameplay.add_component", "description": "Add an existing gameplay component definition to an existing entity_id or prior placement entity_ref.", "required": ["definition_id"], "required_one_of": ["entity_id", "entity_ref"], "optional": ["values"]},
        {"type": "visual.create_graph", "description": "Create a new Visual Scripting event or macro graph. Node/connection references are temporary proposal refs; persisted stable IDs are generated locally.", "required": ["display_name"], "optional": ["kind", "nodes", "connections", "variables"]},
        {"type": "procedural.create_foliage_set", "description": "Create a foliage set using an existing Asset Library asset or a supported built-in primitive.", "required": ["display_name"], "optional": ["asset_id", "primitive"]},
        {"type": "environment.configure", "description": "Configure authored time/day/fog/wind/default weather fields through the existing Environment system.", "required": ["patch"], "optional": []},
    ]


func normalize_provider_proposal(request_id: String, raw: Dictionary) -> Dictionary:
    var actions: Array = []
    var raw_actions: Variant = raw.get("actions", [])
    if raw_actions is Array:
        for value in raw_actions:
            if not value is Dictionary: continue
            var action: Dictionary = value.duplicate(true)
            action["action_id"] = StableId.generate()
            action["type"] = str(action.get("type", "")).strip_edges()
            if not action.get("arguments", {}) is Dictionary: action["arguments"] = {}
            action["reason"] = str(action.get("reason", "")).strip_edges()
            actions.append(action)
    return {"document_type": Contracts.PROPOSAL_TYPE, "schema_version": Contracts.SCHEMA_VERSION, "proposal_id": StableId.generate(), "request_id": request_id, "summary": str(raw.get("summary", "AI proposal")).strip_edges(), "actions": actions, "notes": raw.get("notes", []).duplicate(true) if raw.get("notes", []) is Array else []}


func validate_proposal(proposal: Dictionary) -> Array[String]:
    var errors: Array[String] = Contracts.validate_proposal(proposal)
    if _query_service == null:
        errors.append("AI action registry is not bound.")
        return errors
    var local_refs: Dictionary = {}
    for action_value in proposal.get("actions", []):
        if not action_value is Dictionary: continue
        var action: Dictionary = action_value
        errors.append_array(_validate_action(action, local_refs))
        if ["entity.place_asset", "entity.place_proxy"].has(str(action.get("type", ""))):
            var result_ref: String = str(action.get("arguments", {}).get("result_ref", "")).strip_edges()
            if not result_ref.is_empty():
                if local_refs.has(result_ref): errors.append("AI proposal result_ref values must be unique: %s" % result_ref)
                else: local_refs[result_ref] = true
    return errors


func validate_action(action: Dictionary) -> Array[String]:
    return _validate_action(action, {})


func _validate_action(action: Dictionary, local_refs: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    var action_type: String = str(action.get("type", ""))
    var args: Dictionary = action.get("arguments", {})
    if not SUPPORTED_TYPES.has(action_type): return ["Unsupported AI action type: %s" % action_type]
    match action_type:
        "entity.place_asset":
            _require_vector3(args, "position", errors); _optional_vector3(args, "rotation_degrees", errors); _optional_vector3(args, "scale", errors); _validate_result_ref(args, errors)
            var asset_id: String = str(args.get("asset_id", "")); var asset: Dictionary = _query_service.asset_get(asset_id)
            if asset.is_empty(): errors.append("AI asset placement references an unavailable asset_id: %s" % asset_id)
            elif bool(asset.get("missing", false)): errors.append("AI asset placement references a missing source asset: %s" % asset_id)
            elif not bool(asset.get("analysis", {}).get("ok", false)): errors.append("AI asset placement references an asset that failed analysis: %s" % asset_id)
        "entity.place_proxy":
            if str(args.get("display_name", "")).strip_edges().is_empty(): errors.append("AI proxy placement requires display_name.")
            _require_vector3(args, "position", errors); _optional_vector3(args, "rotation_degrees", errors); _optional_vector3(args, "scale", errors); _validate_result_ref(args, errors)
        "entity.transform":
            _validate_entity_target(args, local_refs, errors)
            if not args.has("position") and not args.has("rotation_degrees") and not args.has("scale"): errors.append("AI transform requires at least one transform field.")
            _optional_vector3(args, "position", errors); _optional_vector3(args, "rotation_degrees", errors); _optional_vector3(args, "scale", errors)
        "gameplay.add_component":
            _validate_entity_target(args, local_refs, errors)
            var definition_id: String = str(args.get("definition_id", ""))
            if not _has_gameplay_definition(definition_id): errors.append("AI gameplay action references an unavailable definition_id: %s" % definition_id)
            if args.has("values") and not args.get("values") is Dictionary: errors.append("AI gameplay values must be a dictionary.")
        "visual.create_graph":
            if str(args.get("display_name", "")).strip_edges().is_empty(): errors.append("AI visual graph creation requires display_name.")
            var kind: String = str(args.get("kind", "event"))
            if not ["event", "macro"].has(kind): errors.append("AI visual graph kind must be event or macro.")
            for key in ["nodes", "connections", "variables"]:
                if args.has(key) and not args.get(key) is Array: errors.append("AI visual graph %s must be an array." % key)
        "procedural.create_foliage_set":
            if str(args.get("display_name", "")).strip_edges().is_empty(): errors.append("AI foliage creation requires display_name.")
            var has_asset: bool = not str(args.get("asset_id", "")).is_empty(); var has_primitive: bool = not str(args.get("primitive", "")).is_empty()
            if has_asset == has_primitive: errors.append("AI foliage creation requires exactly one of asset_id or primitive.")
            if has_asset:
                var asset_id: String = str(args.get("asset_id", "")); var asset: Dictionary = _query_service.asset_get(asset_id)
                if asset.is_empty() or bool(asset.get("missing", false)) or not bool(asset.get("analysis", {}).get("ok", false)): errors.append("AI foliage creation references an unavailable asset_id: %s" % asset_id)
            if has_primitive and not ["grass", "shrub", "tree", "post"].has(str(args.get("primitive", ""))): errors.append("Unsupported built-in foliage primitive.")
        "environment.configure":
            var patch_value: Variant = args.get("patch", {})
            if not patch_value is Dictionary or patch_value.is_empty(): errors.append("AI environment configure requires a non-empty patch.")
            else:
                var allowed: Array[String] = ["time_of_day_hours", "day_length_seconds", "progress_time_in_play", "default_weather_profile_id", "default_transition_seconds", "fog_enabled", "wind_enabled"]
                for key_value in patch_value.keys():
                    if not allowed.has(str(key_value)): errors.append("Unsupported AI environment property: %s" % str(key_value))
    return errors


func source_asset_ids(proposal: Dictionary) -> Array[String]:
    var seen: Dictionary = {}; var result: Array[String] = []
    for action_value in proposal.get("actions", []):
        if not action_value is Dictionary: continue
        var asset_id: String = str(action_value.get("arguments", {}).get("asset_id", ""))
        if StableId.is_valid(asset_id) and not seen.has(asset_id): seen[asset_id] = true; result.append(asset_id)
    result.sort(); return result


func _validate_entity_target(args: Dictionary, local_refs: Dictionary, errors: Array[String]) -> void:
    var entity_id: String = str(args.get("entity_id", "")).strip_edges(); var entity_ref: String = str(args.get("entity_ref", "")).strip_edges()
    if entity_id.is_empty() == entity_ref.is_empty(): errors.append("AI entity target requires exactly one of entity_id or entity_ref."); return
    if not entity_ref.is_empty():
        if not local_refs.has(entity_ref): errors.append("AI entity_ref does not resolve to an earlier placement: %s" % entity_ref)
        return
    if not StableId.is_valid(entity_id) or _query_service.entity_search(entity_id, 1).is_empty(): errors.append("AI action references an unavailable entity_id: %s" % entity_id)


func _validate_result_ref(args: Dictionary, errors: Array[String]) -> void:
    if not args.has("result_ref"): return
    var value: String = str(args.get("result_ref", "")).strip_edges()
    if value.is_empty() or value.length() > 80 or not value.is_valid_identifier(): errors.append("AI result_ref must be a non-empty identifier up to 80 characters.")


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
    if not value is Array or value.size() != 3: errors.append("AI action %s must be a three-number array." % key); return
    for component in value:
        if not component is int and not component is float: errors.append("AI action %s must contain only numbers." % key); return
static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
