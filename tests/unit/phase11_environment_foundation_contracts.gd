extends RefCounted

const WorldProject = preload("res://src/world/world_project.gd")
const Contracts = preload("res://src/environment/environment_contracts.gd")
const EnvironmentState = preload("res://src/environment/environment_state.gd")
const EnvironmentRepository = preload("res://src/environment/environment_repository.gd")
const EnvironmentSnapshotCommand = preload("res://src/environment/environment_snapshot_command.gd")
const EnvironmentEvaluator = preload("res://src/environment/environment_evaluator.gd")
const EnvironmentRenderBridge = preload("res://src/environment/environment_render_bridge.gd")
const EnvironmentRuntime = preload("res://src/environment/environment_runtime.gd")
const EnvironmentService = preload("res://src/environment/environment_service.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new()
    project.initialize_new("Phase 11 Foundation", &"small", "blank_sandbox")
    var document := Contracts.empty_document(str(project.project_id))
    var validation := Contracts.validate_document(document)
    if not validation.is_empty(): errors.append("Default environment document must validate: %s" % str(validation))
    var state = EnvironmentState.new()
    var load_errors := state.load_document(document)
    if not load_errors.is_empty(): errors.append("Environment state must load its default document: %s" % str(load_errors))
    if state.weather_profile_ids().size() != 1: errors.append("Default environment state must contain exactly one stable weather profile.")
    var round_trip := state.to_document()
    if Contracts.validate_document(round_trip).size() != 0: errors.append("Environment state round-trip must preserve schema validity.")
    var invalid := round_trip.duplicate(true)
    invalid["schema_version"] = 999
    if Contracts.validate_document(invalid).is_empty(): errors.append("Future environment schema versions must fail closed.")

    var profile: Dictionary = state.weather_profiles[0]
    var first := EnvironmentEvaluator.evaluate(profile, 12.0, state.authored_state, {})
    var second := EnvironmentEvaluator.evaluate(profile, 12.0, state.authored_state, {})
    if not first.get("ok", false) or first != second: errors.append("Environment evaluation must be deterministic for identical authored input.")
    if float(first.get("daylight", -1.0)) <= 0.5: errors.append("Midday environment evaluation must produce daylight.")

    var runtime = EnvironmentRuntime.new()
    var runtime_result := runtime.initialize(round_trip, null, null, false)
    if not runtime_result.get("ok", false): errors.append("Environment runtime must initialize from authored state: %s" % str(runtime_result.get("errors", [])))
    var before := runtime.get_evaluated_state()
    var time_result := runtime.set_time_of_day(22.0)
    if not time_result.get("ok", false): errors.append("Environment runtime must accept valid time-of-day changes.")
    elif runtime.get_evaluated_state() == before: errors.append("Environment time-of-day changes must update evaluated runtime state.")
    if runtime.set_time_of_day(24.0).get("ok", false): errors.append("Environment runtime must reject time values outside [0, 24).")
    runtime.clear()
    if not runtime.get_evaluated_state().is_empty(): errors.append("Environment runtime must be disposable.")
    runtime.free()

    if EnvironmentRepository == null or EnvironmentSnapshotCommand == null or EnvironmentRenderBridge == null or EnvironmentService == null:
        errors.append("Phase 11 environment implementation modules must all preload successfully.")
    return errors
