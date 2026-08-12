class_name PlayWorldEnvironmentRenderBridge
extends Node3D

var world_environment: WorldEnvironment
var environment: Environment
var sky: Sky
var sky_material: ProceduralSkyMaterial
var sun: DirectionalLight3D
var _rendering_enabled := true

func _init() -> void:
    name = "EnvironmentRenderBridge"
    environment = Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    sky = Sky.new()
    sky_material = ProceduralSkyMaterial.new()
    sky.sky_material = sky_material
    environment.sky = sky
    world_environment = WorldEnvironment.new()
    world_environment.name = "WorldEnvironment"
    world_environment.environment = environment
    add_child(world_environment)
    sun = DirectionalLight3D.new()
    sun.name = "EnvironmentSun"
    sun.shadow_enabled = true
    add_child(sun)

func apply_state(state: Dictionary) -> Dictionary:
    if not bool(state.get("ok", true)):
        return {"ok": false, "errors": state.get("errors", ["Environment render state is invalid."])}
    if environment == null or sky_material == null or sun == null:
        return {"ok": false, "errors": ["Environment render bridge is not initialized."]}
    sky_material.sky_top_color = state.get("sky_top_color", Color(0.1, 0.3, 0.6))
    sky_material.sky_horizon_color = state.get("sky_horizon_color", Color(0.5, 0.7, 0.9))
    sky_material.ground_horizon_color = state.get("sky_horizon_color", Color(0.5, 0.7, 0.9)).darkened(0.25)
    sky_material.ground_bottom_color = state.get("sky_top_color", Color(0.1, 0.3, 0.6)).darkened(0.7)
    environment.ambient_light_color = state.get("ambient_color", Color(0.7, 0.8, 0.9))
    environment.ambient_light_energy = max(0.0, float(state.get("ambient_energy", 0.5)))
    environment.fog_enabled = bool(state.get("fog_enabled", false))
    environment.fog_density = max(0.0, float(state.get("fog_density", 0.0)))
    environment.fog_light_color = state.get("fog_color", Color(0.7, 0.8, 0.9))
    sun.light_color = state.get("sun_color", Color.WHITE)
    sun.light_energy = max(0.0, float(state.get("sun_energy", 1.0)))
    var rotation_value: Variant = state.get("sun_rotation_degrees", Vector3(-45.0, 145.0, 0.0))
    if rotation_value is Vector3:
        sun.rotation_degrees = rotation_value
    return {"ok": true, "errors": []}

func set_rendering_enabled(value: bool) -> void:
    _rendering_enabled = value
    if world_environment != null:
        world_environment.environment = environment if value else null
    if sun != null:
        sun.visible = value
    _sync_viewport_transparency()

func is_rendering_enabled() -> bool:
    return _rendering_enabled

func get_snapshot() -> Dictionary:
    return {
        "rendering_enabled": _rendering_enabled,
        "fog_enabled": environment != null and environment.fog_enabled,
        "fog_density": 0.0 if environment == null else environment.fog_density,
        "ambient_energy": 0.0 if environment == null else environment.ambient_light_energy,
        "sun_energy": 0.0 if sun == null else sun.light_energy,
        "sun_rotation_degrees": Vector3.ZERO if sun == null else sun.rotation_degrees,
    }

func _sync_viewport_transparency() -> void:
    if not is_inside_tree():
        return
    var viewport := get_viewport()
    if viewport is SubViewport:
        (viewport as SubViewport).transparent_bg = not _rendering_enabled
