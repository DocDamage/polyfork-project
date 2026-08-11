extends Node

const MAIN_SCENE := "res://src/main/Main.tscn"


func run_checks() -> Dictionary:
    var errors: Array[String] = []
    var main_resource := load(MAIN_SCENE) as PackedScene

    if main_resource == null:
        errors.append("Main scene must load as a PackedScene.")
        return {"ok": false, "errors": errors}

    var main_instance := main_resource.instantiate()
    if main_instance == null:
        errors.append("Main scene must instantiate.")
        return {"ok": false, "errors": errors}

    add_child(main_instance)

    if not main_instance is Control:
        errors.append("Main scene root must remain a Control during the Phase 0 scaffold.")

    var title := main_instance.get_node_or_null("Center/VBox/Title") as Label
    if title == null:
        errors.append("Main scene title label is missing.")
    elif title.text != "PlayWorld Studio":
        errors.append("Main scene title must identify PlayWorld Studio.")

    var subtitle := main_instance.get_node_or_null("Center/VBox/Subtitle") as Label
    if subtitle == null:
        errors.append("Main scene scaffold subtitle is missing.")

    main_instance.queue_free()
    return {"ok": errors.is_empty(), "errors": errors}
