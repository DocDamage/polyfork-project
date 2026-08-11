extends SceneTree

const RUNTIME_SMOKE_SCENE := "res://tests/runtime/RuntimeSmoke.tscn"

var _failures: Array[String] = []


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var smoke_resource := load(RUNTIME_SMOKE_SCENE) as PackedScene
    _expect(smoke_resource != null, "Runtime smoke scene must load.")

    if smoke_resource != null:
        var smoke_instance := smoke_resource.instantiate()
        _expect(smoke_instance != null, "Runtime smoke scene must instantiate.")

        if smoke_instance != null:
            root.add_child(smoke_instance)
            await process_frame
            _run_smoke_checks(smoke_instance)
            smoke_instance.queue_free()
            await process_frame

    if _failures.is_empty():
        print("PASS: PlayWorld Studio runtime smoke checks completed.")
        quit(0)
        return

    for failure in _failures:
        push_error("FAIL: %s" % failure)
    quit(1)


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
