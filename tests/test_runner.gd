extends SceneTree

const WorldFoundationContracts = preload("res://tests/unit/world_foundation_contracts.gd")
const CommandHistoryContracts = preload("res://tests/unit/command_history_contracts.gd")
const ProjectRepositoryContracts = preload("res://tests/integration/project_repository_contracts.gd")
const AutosaveCheckpointContracts = preload("res://tests/integration/autosave_checkpoint_contracts.gd")
const Phase2LifecycleContracts = preload("res://tests/integration/phase2_lifecycle_contracts.gd")
const Phase2PersistenceHardeningContracts = preload("res://tests/integration/phase2_persistence_hardening_contracts.gd")
const RUNTIME_SMOKE_SCENE := "res://tests/runtime/RuntimeSmoke.tscn"

var _failures: Array[String] = []


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    _run_unit_checks()
    _run_integration_checks()
    await _run_runtime_smoke()

    if _failures.is_empty():
        print("PASS: PlayWorld Studio test harness completed.")
        quit(0)
        return

    for failure in _failures:
        push_error("FAIL: %s" % failure)
    quit(1)


func _run_unit_checks() -> void:
    for error in WorldFoundationContracts.run_checks():
        _failures.append(error)
    for error in CommandHistoryContracts.run_checks():
        _failures.append(error)


func _run_integration_checks() -> void:
    for error in ProjectRepositoryContracts.run_checks():
        _failures.append(error)
    for error in AutosaveCheckpointContracts.run_checks():
        _failures.append(error)
    for error in Phase2LifecycleContracts.run_checks():
        _failures.append(error)
    for error in Phase2PersistenceHardeningContracts.run_checks():
        _failures.append(error)


func _run_runtime_smoke() -> void:
    var smoke_resource := load(RUNTIME_SMOKE_SCENE) as PackedScene
    _expect(smoke_resource != null, "Runtime smoke scene must load.")
    if smoke_resource == null:
        return

    var smoke_instance := smoke_resource.instantiate()
    _expect(smoke_instance != null, "Runtime smoke scene must instantiate.")
    if smoke_instance == null:
        return

    root.add_child(smoke_instance)
    await process_frame
    _run_smoke_checks(smoke_instance)
    smoke_instance.queue_free()
    await process_frame


func _run_smoke_checks(smoke_instance: Node) -> void:
    _expect(smoke_instance.has_method("run_checks"), "Runtime smoke scene must expose run_checks().")
    if not smoke_instance.has_method("run_checks"):
        return

    var result: Dictionary = smoke_instance.call("run_checks")
    var errors: Array = result.get("errors", [])
    for error in errors:
        _failures.append(str(error))
    _expect(bool(result.get("ok", false)), "Runtime smoke scene reported failure.")


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
