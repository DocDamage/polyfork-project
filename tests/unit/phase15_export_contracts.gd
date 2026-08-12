extends RefCounted

const WorldProject = preload("res://src/world/world_project.gd")
const Staging = preload("res://src/export/export_staging_service.gd")
const SourceClosure = preload("res://src/export/export_source_closure.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var offline = WorldProject.new()
    offline.initialize_new("Offline Export", &"small", "blank_sandbox")
    var offline_data: Dictionary = offline.to_dictionary()
    var offline_roots: Array[String] = Staging.runtime_roots_for_project(offline_data)
    if offline_roots.has("src/network/network_runtime_service.gd"): errors.append("Offline exports must not include the Phase 15 network runtime root.")
    var offline_closure: Dictionary = SourceClosure.resolve(offline_roots)
    if not offline_closure.get("ok", false): errors.append("Offline export source closure must remain valid: %s" % str(offline_closure.get("errors", [])))
    else:
        var paths: Array = offline_closure.get("paths", [])
        for forbidden in ["src/network/network_runtime_service.gd", "src/network/enet_session_adapter.gd", "src/app/workspace/multiplayer_workspace_layer.gd"]:
            if paths.has(forbidden): errors.append("Offline runtime source closure leaked multiplayer source: %s" % forbidden)

    var multiplayer = WorldProject.new()
    multiplayer.initialize_new("Multiplayer Export", &"small", "third_person_adventure")
    multiplayer.runtime_config = {
        "multiplayer": {
            "enabled": true,
            "mode": "coop",
            "min_players": 1,
            "max_players": 4,
            "spawn_strategy": "offset",
            "spawn_spacing": 2.5,
            "teams": [],
            "score_mode": "objective",
            "rejoin_allowed": true,
        }
    }
    var multiplayer_data: Dictionary = multiplayer.to_dictionary()
    var multiplayer_roots: Array[String] = Staging.runtime_roots_for_project(multiplayer_data)
    if not multiplayer_roots.has("src/network/network_runtime_service.gd"): errors.append("Multiplayer exports must include the Phase 15 network runtime root.")
    var multiplayer_closure: Dictionary = SourceClosure.resolve(multiplayer_roots)
    if not multiplayer_closure.get("ok", false): errors.append("Multiplayer export source closure must resolve: %s" % str(multiplayer_closure.get("errors", [])))
    else:
        var paths: Array = multiplayer_closure.get("paths", [])
        for required in [
            "src/network/network_runtime_service.gd",
            "src/network/network_session_contract.gd",
            "src/network/enet_session_adapter.gd",
            "src/network/network_identity_registry.gd",
            "src/network/player_replication_service.gd",
            "src/network/gameplay_replication_service.gd",
            "src/network/match_replication_service.gd",
            "src/network/network_match_state.gd",
        ]:
            if not paths.has(required): errors.append("Multiplayer runtime source closure omitted: %s" % required)
        for forbidden in ["src/app/workspace/multiplayer_workspace_layer.gd", "src/editor/editor_session.gd", "src/main/main.gd"]:
            if paths.has(forbidden): errors.append("Multiplayer export closure leaked editor-only source: %s" % forbidden)

    var capability: Dictionary = Staging.multiplayer_capability_for_project(multiplayer_data)
    if not bool(capability.get("enabled", false)) or int(capability.get("max_players", 0)) != 4: errors.append("Export staging must retain normalized multiplayer capability metadata.")
    if bool(Staging.multiplayer_capability_for_project(offline_data).get("enabled", true)): errors.append("Offline export capability must normalize to disabled.")
    return errors
