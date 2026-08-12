extends RefCounted

const TemplateManifest = preload("res://src/templates/template_manifest.gd")
const TemplateRegistry = preload("res://src/templates/template_registry.gd")
const RuntimeModules = preload("res://src/templates/runtime_module_registry.gd")
const TemplateApplication = preload("res://src/templates/template_application_service.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const StableId = preload("res://src/world/stable_id.gd")

const EXPECTED_IDS := ["blank_sandbox", "third_person_adventure", "fps", "survival", "rpg", "driving", "walking_simulator"]


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var registry = TemplateRegistry.new()
    var load_result: Dictionary = registry.load_builtin()
    if not load_result.get("ok", false): return ["Built-in template registry must load: %s" % load_result.get("errors", [])]
    var summaries: Array[Dictionary] = registry.summaries()
    var ids: Array[String] = []
    for summary in summaries: ids.append(str(summary.get("template_id", "")))
    ids.sort()
    var expected := EXPECTED_IDS.duplicate(); expected.sort()
    if ids != expected: errors.append("Template registry must expose exactly the seven documented template IDs.")
    for template_id in EXPECTED_IDS:
        var manifest := registry.get_manifest(template_id)
        if manifest.is_empty(): errors.append("Template registry is missing %s." % template_id); continue
        var manifest_errors := TemplateManifest.validate_dictionary(manifest)
        if not manifest_errors.is_empty(): errors.append("Template %s must validate: %s" % [template_id, manifest_errors])
        var modules := RuntimeModules.new().resolve(manifest.get("required_runtime_modules", []))
        if not modules.get("ok", false): errors.append("Template %s may require only currently available Phase 7 modules: %s" % [template_id, modules.get("errors", [])])
    errors.append_array(_failure_checks(registry))
    errors.append_array(_application_contract(registry))
    errors.append_array(_stable_id_contract())
    return errors


static func _failure_checks(registry) -> Array[String]:
    var errors: Array[String] = []
    var future := registry.get_manifest("fps"); future["schema_version"] = 999
    if TemplateManifest.validate_dictionary(future).is_empty(): errors.append("Future template schema versions must reject.")
    var corrupt := registry.get_manifest("fps"); corrupt["starter_entities"] = ["corrupt"]
    if TemplateManifest.validate_dictionary(corrupt).is_empty(): errors.append("Corrupt starter entity payloads must reject.")
    var incomplete := registry.get_manifest("fps"); incomplete.erase("input_mapping")
    if TemplateManifest.validate_dictionary(incomplete).is_empty(): errors.append("Incomplete template manifests must reject.")
    var unknown_modules := RuntimeModules.new().resolve(["module.that.does.not.exist"])
    if unknown_modules.get("ok", false) or unknown_modules.get("errors", []).is_empty(): errors.append("Unknown required runtime modules must reject clearly.")
    return errors


static func _application_contract(registry) -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new(); project.initialize_new("Template Contract", &"small", "fps")
    var before := project.to_dictionary()
    var manifest := registry.get_manifest("fps")
    var result: Dictionary = TemplateApplication.new().apply_to_project(project, manifest)
    if not result.get("ok", false): errors.append("Valid template application must succeed: %s" % result.get("errors", [])); return errors
    if project.template_id != "fps": errors.append("Template application must persist template identity.")
    if str(project.runtime_config.get("template_id", "")) != "fps": errors.append("Template application must persist runtime template configuration.")
    if project.dependencies != result.get("resolved_modules", []): errors.append("Template application must persist resolved runtime dependencies deterministically.")
    var invalid := manifest.duplicate(true); invalid["required_runtime_modules"] = ["missing.runtime.module"]
    var untouched = WorldProject.new(); untouched.initialize_new("Untouched", &"small", "fps"); var untouched_before := untouched.to_dictionary()
    var invalid_result: Dictionary = TemplateApplication.new().apply_to_project(untouched, invalid)
    if invalid_result.get("ok", false): errors.append("Template application must reject unavailable required modules.")
    if untouched.to_dictionary() != untouched_before: errors.append("Failed template application must not partially modify the project.")
    if before.get("project_id") != project.project_id: errors.append("Template application must preserve project stable identity.")
    return errors


static func _stable_id_contract() -> Array[String]:
    var errors: Array[String] = []
    var first := StableId.from_seed("phase7-template-starter")
    var second := StableId.from_seed("phase7-template-starter")
    var different := StableId.from_seed("phase7-template-starter-2")
    if first != second: errors.append("Seeded stable IDs must be deterministic.")
    if first == different: errors.append("Distinct deterministic seeds must not alias.")
    if not StableId.is_valid(first) or not StableId.is_valid(different): errors.append("Seeded stable IDs must remain valid persistent UUIDs.")
    return errors
