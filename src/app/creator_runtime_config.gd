extends Node

func _ready() -> void:
    call_deferred("_configure_creator_runtime")

func _configure_creator_runtime() -> void:
    var tree := get_tree()
    if tree == null:
        return
    var scene := tree.current_scene
    if scene == null or scene.name != "Main":
        return
    ProjectSettings.set_setting("playworld/assets/use_shared_library", true)
    if str(ProjectSettings.get_setting("playworld/assets/library_root", "")).strip_edges().is_empty():
        ProjectSettings.set_setting("playworld/assets/library_root", "user://asset_library")
