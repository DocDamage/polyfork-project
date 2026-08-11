extends Node

const StableId = preload("res://src/world/stable_id.gd")
const MAIN_SCENE := preload("res://src/main/Main.tscn")
const STORAGE_SETTING := "playworld/storage/projects_root"


func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var storage_root := "user://tests/continue_reopen_%s" % StableId.generate()
    ProjectSettings.set_setting(STORAGE_SETTING, storage_root)

    var first = MAIN_SCENE.instantiate()
    add_child(first)
    first.call("_on_new_world_create_requested", {
        "title": "Continue Lifecycle",
        "world_profile": "medium",
        "template_id": "blank_sandbox"
    })
    var first_workspace := first.get_node_or_null("WorkspaceScreen") as Control
    if first_workspace == null or not first_workspace.visible:
        errors.append("Runtime Continue fixture must create and open a persisted project first.")
        first.queue_free()
        return errors
    first.queue_free()

    var restarted = MAIN_SCENE.instantiate()
    add_child(restarted)
    var home := restarted.get_node_or_null("HomeScreen") as Control
    var workspace := restarted.get_node_or_null("WorkspaceScreen") as Control
    if home == null or workspace == null or not home.visible:
        errors.append("Fresh app instance must start on Home before Continue.")
        restarted.queue_free()
        return errors

    home.emit_signal("route_requested", &"continue")
    if home.visible or not workspace.visible:
        errors.append("Home Continue must reopen the most recent valid persisted project.")
    var title := workspace.find_child("WorldTitle", true, false) as Label
    if title == null or title.text != "Continue Lifecycle":
        errors.append("Continue must restore the persisted project title after app restart.")

    restarted.queue_free()
    return errors
