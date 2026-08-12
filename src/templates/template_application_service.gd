class_name PlayWorldTemplateApplicationService
extends RefCounted

const TemplateManifest = preload("res://src/templates/template_manifest.gd")
const RuntimeModuleRegistry = preload("res://src/templates/runtime_module_registry.gd")


func apply_to_project(project, manifest: Dictionary, module_registry = null) -> Dictionary:
    if project == null:
        return _failure("Template application requires a project.")
    var manifest_errors: Array[String] = TemplateManifest.validate_dictionary(manifest)
    if not manifest_errors.is_empty():
        return {"ok": false, "errors": manifest_errors}

    var modules = module_registry if module_registry != null else RuntimeModuleRegistry.new()
    var module_result: Dictionary = modules.resolve(manifest.get("required_runtime_modules", []))
    if not module_result.get("ok", false):
        return module_result

    var runtime_config := {
        "schema_version": 1,
        "template_id": str(manifest.get("template_id", "")),
        "resolved_modules": module_result.get("resolved", []).duplicate(),
        "planned_modules": manifest.get("planned_modules", []).duplicate(),
        "starter_entities": manifest.get("starter_entities", []).duplicate(true),
        "input_mapping": manifest.get("input_mapping", {}).duplicate(true),
        "default_player_archetype": manifest.get("default_player_archetype"),
        "camera_configuration": manifest.get("camera_configuration", {}).duplicate(true),
        "example_graph_references": manifest.get("example_graph_references", []).duplicate(),
        "ui_hud_packages": manifest.get("ui_hud_packages", []).duplicate(),
        "tutorial_steps": manifest.get("tutorial_steps", []).duplicate(true)
    }

    project.template_id = str(manifest.get("template_id", ""))
    project.runtime_config = runtime_config
    project.export_settings = manifest.get("export_settings", {}).duplicate(true)
    return {
        "ok": true,
        "errors": [],
        "template_id": project.template_id,
        "runtime_config": runtime_config.duplicate(true),
        "resolved_modules": module_result.get("resolved", []).duplicate()
    }


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}
