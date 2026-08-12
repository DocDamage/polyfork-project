extends RefCounted

const WorldProject = preload("res://src/world/world_project.gd")
const TemplateRegistry = preload("res://src/templates/template_registry.gd")
const TemplateApplication = preload("res://src/templates/template_application_service.gd")
const RuntimeModules = preload("res://src/templates/runtime_module_registry.gd")
const TemplateContract = preload("res://src/network/multiplayer_template_contract.gd")
const MatchState = preload("res://src/network/network_match_state.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var registry = TemplateRegistry.new()
    var load_result: Dictionary = registry.load_builtin()
    if not load_result.get("ok", false):
        return ["Built-in templates must remain valid after Phase 15 capability additions: %s" % str(load_result.get("errors", []))]

    for template_id in ["third_person_adventure", "survival", "fps"]:
        var manifest: Dictionary = registry.get_manifest(template_id)
        if manifest.is_empty():
            errors.append("Phase 15 multiplayer template is missing: %s" % template_id)
            continue
        if not TemplateContract.supports_multiplayer(manifest): errors.append("Template must explicitly opt in to multiplayer: %s" % template_id)
        if not manifest.get("required_runtime_modules", []).has("phase15.multiplayer"): errors.append("Multiplayer template must require phase15.multiplayer: %s" % template_id)

    for template_id in ["blank_sandbox", "rpg", "driving", "walking_simulator"]:
        var manifest: Dictionary = registry.get_manifest(template_id)
        if TemplateContract.supports_multiplayer(manifest): errors.append("Legacy template must remain offline unless it explicitly opts in: %s" % template_id)

    var modules = RuntimeModules.new()
    if not modules.has_module("phase15.multiplayer"): errors.append("Phase 15 multiplayer runtime module must be registered.")

    var adventure: Dictionary = registry.get_manifest("third_person_adventure")
    var project = WorldProject.new()
    project.initialize_new("Phase 15 Template", &"small", "third_person_adventure")
    var apply_result: Dictionary = TemplateApplication.new().apply_to_project(project, adventure, modules)
    if not apply_result.get("ok", false):
        errors.append("Multiplayer-capable template must apply to a new project: %s" % str(apply_result.get("errors", [])))
    else:
        var runtime_multiplayer: Dictionary = project.runtime_config.get("multiplayer", {})
        if not bool(runtime_multiplayer.get("enabled", false)): errors.append("Applied multiplayer capability must persist in project runtime config.")
        if not project.dependencies.has("phase15.multiplayer"): errors.append("Applied multiplayer template must preserve the runtime dependency for export closure.")
        if int(runtime_multiplayer.get("max_players", 0)) != 4: errors.append("Third-person adventure template must preserve its four-player co-op limit.")

    var competitive: Dictionary = TemplateContract.normalize(registry.get_manifest("fps").get("multiplayer", {}))
    var match_state = MatchState.new()
    var configure_result: Dictionary = match_state.configure(competitive)
    if not configure_result.get("ok", false):
        errors.append("Competitive match contract must configure: %s" % str(configure_result.get("errors", [])))
    else:
        var host_result: Dictionary = match_state.add_player(1)
        var client_result: Dictionary = match_state.add_player(7)
        if not host_result.get("ok", false) or not client_result.get("ok", false): errors.append("Competitive match must accept players within its declared limit.")
        var host_team := str(match_state.get_player(1).get("team_id", ""))
        var client_team := str(match_state.get_player(7).get("team_id", ""))
        if host_team.is_empty() or client_team.is_empty(): errors.append("Competitive players must receive declared teams.")
        if host_team == client_team: errors.append("Least-populated-team assignment should balance the first two competitive peers.")
        if match_state.minimum_players_met() != true: errors.append("FPS competitive template minimum player count should be met at two peers.")
        var score_result: Dictionary = match_state.add_score(host_team, 3)
        if not score_result.get("ok", false) or match_state.get_score(host_team) != 3: errors.append("Team score state must update deterministically.")
        if match_state.add_score("undeclared", 1).get("ok", true): errors.append("Competitive team score must reject undeclared teams.")
        if match_state.spawn_offset_for_peer(7) == Vector3.ZERO: errors.append("Additional multiplayer peers must receive deterministic runtime spawn offsets.")

    var invalid := competitive.duplicate(true)
    invalid["teams"] = ["blue"]
    if TemplateContract.validate(invalid).is_empty(): errors.append("Competitive templates must reject configurations with fewer than two declared teams.")

    var disabled := TemplateContract.disabled()
    if bool(disabled.get("enabled", true)) or int(disabled.get("max_players", 0)) != 1: errors.append("Offline multiplayer capability defaults must remain single-player and disabled.")

    return errors
