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
        errors.append("Main scene root must be a Control.")

    var home := main_instance.get_node_or_null("HomeScreen") as Control
    if home == null:
        errors.append("Home screen must be the initial application view.")
    else:
        _check_home(home, errors)

    main_instance.queue_free()
    return {"ok": errors.is_empty(), "errors": errors}


func _check_home(home: Control, errors: Array[String]) -> void:
    var title := home.get_node_or_null("SafeArea/Content/Header/TitleStack/Title") as Label
    if title == null or title.text != "PlayWorld Studio":
        errors.append("Home screen must display the PlayWorld Studio title.")

    var required_buttons := {
        "CreateButton": "Create New World",
        "ContinueButton": "Continue",
        "WorldsButton": "My Worlds",
        "TemplatesButton": "Templates",
        "AssetLibraryButton": "Asset Library"
    }

    for node_name in required_buttons:
        var button := home.find_child(node_name, true, false) as Button
        if button == null:
            errors.append("Home screen is missing %s." % required_buttons[node_name])
        elif not button.text.contains(required_buttons[node_name]):
            errors.append("Home action %s has unexpected text." % required_buttons[node_name])
