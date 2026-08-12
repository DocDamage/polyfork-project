class_name PlayWorldAiPreviewService
extends RefCounted

var _query_service
var _action_registry


func bind(query_service, action_registry) -> Dictionary:
    if query_service == null or action_registry == null: return _failure("AI preview service requires query and action registry services.")
    _query_service = query_service
    _action_registry = action_registry
    return {"ok": true, "errors": []}


func preview(proposal: Dictionary) -> Dictionary:
    if _query_service == null or _action_registry == null: return _failure("AI preview service is not bound.")
    var errors: Array[String] = _action_registry.validate_proposal(proposal)
    if not errors.is_empty(): return {"ok": false, "errors": errors, "proposal": proposal.duplicate(true)}
    var impacts: Array[Dictionary] = []
    for action_value in proposal.get("actions", []):
        if action_value is Dictionary: impacts.append(_impact(action_value))
    return {
        "ok": true,
        "errors": [],
        "proposal": proposal.duplicate(true),
        "summary": str(proposal.get("summary", "")),
        "action_count": impacts.size(),
        "impacts": impacts,
        "source_asset_ids": _action_registry.source_asset_ids(proposal),
        "mutates_authored_state": false,
    }


func _impact(action: Dictionary) -> Dictionary:
    var action_type: String = str(action.get("type", ""))
    var args: Dictionary = action.get("arguments", {})
    var impact: Dictionary = {"action_id": str(action.get("action_id", "")), "type": action_type, "reason": str(action.get("reason", "")), "before": {}, "after": {}}
    match action_type:
        "entity.place_asset":
            var asset: Dictionary = _query_service.asset_get(str(args.get("asset_id", "")))
            impact["before"] = {"entity_exists": false}
            impact["after"] = {"new_entity": str(args.get("display_name", asset.get("display_name", "Asset"))), "asset_id": str(args.get("asset_id", "")), "position": args.get("position", []).duplicate()}
        "entity.place_proxy":
            impact["before"] = {"entity_exists": false}
            impact["after"] = {"new_entity": str(args.get("display_name", "Entity")), "asset_id": "", "position": args.get("position", []).duplicate()}
        "entity.transform":
            var entities: Array[Dictionary] = _query_service.entity_search(str(args.get("entity_id", "")), 1)
            var before: Dictionary = entities[0].get("transform", {}).duplicate(true) if not entities.is_empty() else {}
            var after: Dictionary = before.duplicate(true)
            for key in ["position", "rotation_degrees", "scale"]:
                if args.has(key): after[key] = args.get(key).duplicate()
            impact["before"] = before
            impact["after"] = after
        "gameplay.add_component":
            impact["before"] = {"entity_id": str(args.get("entity_id", "")), "definition_id": str(args.get("definition_id", "")), "present": false}
            impact["after"] = {"entity_id": str(args.get("entity_id", "")), "definition_id": str(args.get("definition_id", "")), "present": true, "values": args.get("values", {}).duplicate(true)}
        "visual.create_graph":
            impact["before"] = {"graph_exists": false}
            impact["after"] = {"display_name": str(args.get("display_name", "Graph")), "kind": str(args.get("kind", "event")), "node_count": args.get("nodes", []).size(), "connection_count": args.get("connections", []).size()}
        "procedural.create_foliage_set":
            impact["before"] = {"foliage_set_exists": false}
            impact["after"] = {"display_name": str(args.get("display_name", "Foliage")), "asset_id": str(args.get("asset_id", "")), "primitive": str(args.get("primitive", ""))}
        "environment.configure":
            impact["before"] = _query_service.environment_summary(1).get("authored_state", {}).duplicate(true)
            var environment_after: Dictionary = impact["before"].duplicate(true)
            for key_value in args.get("patch", {}).keys(): environment_after[key_value] = args["patch"][key_value]
            impact["after"] = environment_after
    return impact


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
