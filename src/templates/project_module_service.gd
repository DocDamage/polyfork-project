class_name PlayWorldProjectModuleService
extends RefCounted

const RuntimeModules = preload("res://src/templates/runtime_module_registry.gd")


func set_enabled(project, module_id: String, enabled: bool) -> Dictionary:
    if project == null: return _failure("Project module changes require a project.")
    var modules = RuntimeModules.new()
    if not modules.has_module(module_id): return _failure("Unknown runtime module: %s" % module_id)
    var runtime: Dictionary = project.runtime_config.duplicate(true)
    var resolved: Array = runtime.get("resolved_modules", []).duplicate()
    var changed := false
    if enabled and not resolved.has(module_id):
        resolved.append(module_id); changed = true
    elif not enabled and resolved.has(module_id):
        resolved.erase(module_id); changed = true
    resolved.sort()
    runtime["resolved_modules"] = resolved
    var camera: Dictionary = runtime.get("camera_configuration", {}).duplicate(true)
    var controller := str(camera.get("controller", "none"))
    if not enabled and ((module_id == "play.third_person" and controller == "third_person") or (module_id == "play.first_person" and controller == "first_person")):
        camera["controller"] = "none"
        runtime["camera_configuration"] = camera
        changed = true
    project.runtime_config = runtime
    project.dependencies = resolved.duplicate()
    return {"ok": true, "errors": [], "changed": changed, "enabled_modules": resolved.duplicate(), "controller": str(camera.get("controller", controller))}


func set_player_controller(project, controller: String) -> Dictionary:
    if project == null: return _failure("Player controller changes require a project.")
    var required_module := ""
    match controller:
        "none": required_module = ""
        "third_person": required_module = "play.third_person"
        "first_person": required_module = "play.first_person"
        _: return _failure("Unsupported player controller: %s" % controller)
    var runtime: Dictionary = project.runtime_config.duplicate(true)
    var resolved: Array = runtime.get("resolved_modules", [])
    if not required_module.is_empty() and not resolved.has(required_module): return _failure("Player controller module is not enabled: %s" % required_module)
    var camera: Dictionary = runtime.get("camera_configuration", {}).duplicate(true)
    camera["controller"] = controller
    runtime["camera_configuration"] = camera
    project.runtime_config = runtime
    return {"ok": true, "errors": [], "controller": controller}


static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}
