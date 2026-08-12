extends SceneTree

const Foundation = preload("res://tests/unit/phase11_environment_foundation_contracts.gd")
const Coupling = preload("res://tests/unit/phase11_environment_coupling_contracts.gd")
const PlayVisual = preload("res://tests/integration/phase11_play_visual_contracts.gd")
const PersistenceUndo = preload("res://tests/integration/phase11_environment_persistence_undo_contracts.gd")
const Workspace = preload("res://tests/integration/phase11_environment_workspace_contracts.gd")
const ScaleStreaming = preload("res://tests/integration/phase11_environment_scale_streaming_contracts.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := OS.get_environment("PHASE11_SUITE")
    var errors: Array[String] = []
    match suite:
        "foundation": errors.append_array(Foundation.run_checks())
        "coupling": errors.append_array(Coupling.run_checks())
        "play_visual": errors.append_array(PlayVisual.run_checks(root))
        "persistence_undo": errors.append_array(PersistenceUndo.run_checks(root))
        "workspace": errors.append_array(Workspace.run_checks(root))
        "scale_streaming": errors.append_array(ScaleStreaming.run_checks())
        _: errors.append("Unknown Phase 11 suite: %s" % suite)
    if errors.is_empty():
        print("PASS: Phase 11 %s contract suite completed." % suite)
        quit(0)
        return
    for item in errors:
        push_error(item)
    quit(1)
