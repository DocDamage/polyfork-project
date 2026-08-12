extends SceneTree

const SharedAssets = preload("res://tests/integration/phase16_shared_asset_library_contracts.gd")

func _init() -> void: call_deferred("_run")

func _run() -> void:
    var errors: Array[String] = SharedAssets.run_checks()
    if errors.is_empty():
        print("PASS: Phase 16 shared universal Asset Library contract completed.")
        quit(0); return
    for item in errors: push_error(item)
    quit(1)
