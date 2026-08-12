extends RefCounted

const TemplateManifest = preload("res://src/templates/template_manifest.gd")
const TemplateRegistry = preload("res://src/templates/template_registry.gd")
const RuntimeModules = preload("res://src/templates/runtime_module_registry.gd")
const TemplateApplication = preload("res://src/templates/template_application_service.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const StableId = preload("res://src/world/stable_id.gd")
const BuiltinArchetypes = preload("res://src/gameplay/builtin_archetype_library.gd")

const EXPECTED_IDS := ["blank_sandbox", "third_person_adventure", "fps", "survival", "rpg", "driving", "walking_simulator"]
const PLAYABLE_PLAYER_TEMPLATES := ["third_person_adventure", "fps", "survival", "rpg", "driving", "walking_simulator"]


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var registry = TemplateRegistry.new()
    var load_result: Dictionary = registry.load_builtin()
    if not load_result.get("ok", false): return ["Built-in template registry must load: %s" % load_result.get("errors", [])]
    var ids: Array[String] = registry.template_ids()
    var expected: Array = EXPECTED_IDS.duplicate(); expected.sort()
    if ids != expected: errors.append("Template registry must expose exactly the seven documented template IDs.")
    var player_id: String = BuiltinArchetypes.id_for("player")
    if not StableId.is_valid(player_id): errors.append("Phase 7 must provide a stable reusable player archetype ID.")
    if BuiltinArchetypes.definitions().size() != 10: errors.append("Built-in archetypes must preserve the nine Phase 6 presets and add exactly one reusable Phase 7 player preset.")
    for template_id in EXPECTED_IDS:
        var manifest: Dictionary = registry.get_manifest(template_id)
        if manifest.is_empty(): errors.append("Template registry is missing %s." % template_id); continue
        var manifest_errors: Array[String] = TemplateManifest.validate_dictionary(manifest)
        if not manifest_errors.is_empty(): errors.append("Template %s must validate: %s" % [template_id, manifest_errors])
        var modules: Dictionary = RuntimeModules.new().resolve(manifest.get("required_runtime_modules", []))
        if not modules.get("ok", false): errors.append("Template %s may require only currently available Phase 7 modules: %s" % [template_id, modules.get("errors", [])])
        if PLAYABLE_PLAYER_TEMPLATES.has(template_id):
            if str(manifest.get("default_player_archetype", "")) != player_id: errors.append("Playable template %s must reference the reusable player archetype." % template_id)
            var has_player_start: bool = false
            for starter_value in manifest.get("starter_entities", []):
                var starter: Dictionary = starter_value
                if str(starter.get("role", "")) == "player_spawn":
                    has_player_start = true
                    if str(starter.get("archetype_key", "")) != "player": errors.append("Playable template %s player spawn must use the reusable player archetype composition." % template_id)
            if not has_player_start: errors.append("Playable template %s must provide a real player spawn starter." % template_id)
    errors.append_array(_failure_checks(registry))
    errors.append_array(_application_contract(registry))
    errors.append_array(_stable_id_contract())
    return errors


static func _failure_checks(registry) -> Array[String]:
    var errors: Array[String] = []
    var future: Dictionary = registry.get_manifest("fps"); future["schema_version"] = 999
    if TemplateManifest.validate_dictionary(future).is_empty(): errors.append("Future template schema versions must reject.")
    var corrupt: Dictionary = registry.get_manifest("fps"); corrupt["starter_entities"] = ["corrupt"]
    if TemplateManifest.validate_dictionary(corrupt).is_empty(): errors.append("Corrupt starter entity payloads must reject.")
    var incomplete: Dictionary = registry.get_manifest("fps"); incomplete.erase("input_mapping")
    if TemplateManifest.validate_dictionary(incomplete).is_empty(): errors.append("Incomplete template manifests must reject.")
    var unknown_modules: Dictionary = RuntimeModules.new().resolve(["module.that.does.not.exist"])
    if unknown_modules.get("ok", false) or unknown_modules.get("errors", []).is_empty(): errors.append("Unknown required runtime modules must reject clearly.")
    return errors


static func _application_contract(registry) -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new(); project.initialize_new("Template Contract", &"small", "fps")
    var before: Dictionary = project.to_dictionary()
    var manifest: Dictionary = registry.get_manifest("fps")
    var result: Dictionary = TemplateApplication.new().apply_to_project(project, manifest)
    if not result.get("ok", false): errors.append("Valid template application must succeed: %s" % result.get("errors", [])); return errors
    if project.template_id != "fps": errors.append("Template application must persist template identity.")
    if str(project.runtime_config.get("template_id", "")) != "fps": errors.append("Template application must persist runtime template configuration.")
    if str(project.runtime_config.get("default_player_archetype", "")) != BuiltinArchetypes.id_for("player"): errors.append("Template application must persist the reusable player archetype reference.")
    if project.dependencies != result.get("resolved_modules", []): errors.append("Template application must persist resolved runtime dependencies deterministically.")
    var invalid: Dictionary = manifest.duplicate(true); invalid["required_runtime_modules"] = ["missing.runtime.module"]
    var untouched = WorldProject.new(); untouched.initialize_new("Untouched", &"small", "fps"); var untouched_before: Dictionary = untouched.to_dictionary()
    var invalid_result: Dictionary = TemplateApplication.new().apply_to_project(untouched, invalid)
    if invalid_result.get("ok", false): errors.append("Template application must reject unavailable required modules.")
    if untouched.to_dictionary() != untouched_before: errors.append("Failed template application must not partially modify the project.")
    if before.get("project_id") != project.project_id: errors.append("Template application must preserve project stable identity.")
    return errors


static func _stable_id_contract() -> Array[String]:
    var errors: Array[String] = []
    var first: String = StableId.from_seed("phase7-template-starter")
    var second: String = StableId.from_seed("phase7-template-starter")
    var different: String = StableId.from_seed("phase7-template-starter-2")
    if first != second: errors.append("Seeded stable IDs must be deterministic.")
    if first == different: errors.append("Distinct deterministic seeds must not alias.")
    if not StableId.is_valid(first) or not StableId.is_valid(different): errors.append("Seeded stable IDs must remain valid persistent UUIDs.")
    return errors