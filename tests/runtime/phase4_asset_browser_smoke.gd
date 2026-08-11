extends Node

const StableId = preload("res://src/world/stable_id.gd")
const AssetLibraryService = preload("res://src/assets/asset_library_service.gd")
const AssetBrowser = preload("res://src/app/workspace/asset_browser.gd")


func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var test_root := "user://tests/phase4_browser_%s" % StableId.generate()
    var source_root := test_root.path_join("source")
    var project_root := test_root.path_join("project")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(source_root))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(project_root))
    _write_text(source_root.path_join("Crate.tscn"), _scene_text("Crate"))
    _write_text(source_root.path_join("Crate_Copy.tscn"), _scene_text("Crate"))
    _write_text(source_root.path_join("Tree.tscn"), _scene_text("Tree"))

    var library = AssetLibraryService.new(project_root)
    library.load_library()
    var register_result: Dictionary = library.register_source(source_root, "Browser Fixtures")
    if not register_result.get("ok", false):
        errors.append("Asset browser fixture source must register.")
        return errors
    var crate := _record(library.get_records(), "Crate.tscn")
    var tree := _record(library.get_records(), "Tree.tscn")
    library.set_favorite(str(crate.get("asset_id", "")), true)
    library.add_to_collection(str(tree.get("asset_id", "")), "Nature")

    var browser = AssetBrowser.new()
    add_child(browser)
    browser.bind_library(library)
    if browser.get_density() != &"large" or browser.get_visible_asset_ids().size() != 3:
        errors.append("Asset browser must default to large cards and show all indexed fixtures.")

    browser.set_search_text("Tree")
    if browser.get_visible_asset_ids() != [str(tree.get("asset_id", ""))]:
        errors.append("Asset browser search must narrow cards by display name/path.")
    browser.set_search_text("")
    browser.set_filter_state({"favorites_only": true})
    if browser.get_visible_asset_ids() != [str(crate.get("asset_id", ""))]:
        errors.append("Favorites filter must show only favorited catalog records.")
    browser.set_filter_state({"collection": "Nature"})
    if browser.get_visible_asset_ids() != [str(tree.get("asset_id", ""))]:
        errors.append("Collection filter must show collection membership without moving source files.")
    browser.set_filter_state({"duplicates_only": true})
    if browser.get_visible_asset_ids().size() != 2:
        errors.append("Duplicate filter must surface exact-content duplicates as separate asset cards.")

    browser.set_filter_state({})
    browser.set_density(&"compact")
    if browser.get_density() != &"compact" or browser.get_visible_asset_ids().size() != 3:
        errors.append("Compact density must remain available while large cards are the default.")
    browser.set_density(&"large")
    if not browser.focus_first_card():
        errors.append("Asset cards must expose a controller/keyboard focus entry point.")

    var selected_id := browser.get_selected_asset_id()
    var selected_before: Dictionary = library.get_record(selected_id)
    var gamepad_favorite := InputEventJoypadButton.new()
    gamepad_favorite.button_index = JOY_BUTTON_Y
    gamepad_favorite.pressed = true
    if not browser.handle_shortcut(gamepad_favorite):
        errors.append("Gamepad Y must operate the selected Asset Library favorite shortcut.")
    var selected_after_gamepad: Dictionary = library.get_record(selected_id)
    if bool(selected_before.get("favorite", false)) == bool(selected_after_gamepad.get("favorite", false)):
        errors.append("Gamepad favorite shortcut must persistently toggle catalog favorite state.")

    var keyboard_favorite := InputEventKey.new()
    keyboard_favorite.keycode = KEY_F
    keyboard_favorite.physical_keycode = KEY_F
    keyboard_favorite.pressed = true
    if not browser.handle_shortcut(keyboard_favorite):
        errors.append("Keyboard F must operate the selected Asset Library favorite shortcut.")

    var placement_ids: Array[String] = []
    browser.placement_requested.connect(func(record: Dictionary): placement_ids.append(str(record.get("asset_id", ""))))
    var selected_button := browser.find_child("Asset_%s" % selected_id.substr(0, 8), true, false) as Button
    if selected_button == null or selected_button.focus_mode != Control.FOCUS_ALL:
        errors.append("Asset card activation must remain native focusable Button behavior for keyboard/gamepad accept.")
    else:
        selected_button.emit_signal("pressed")
        if placement_ids != [selected_id]:
            errors.append("Activating an asset card must emit exactly one placement handoff request.")

    var details := browser.find_child("AssetDetails", true, false) as Label
    if details == null or details.text.find("Read-only source:") == -1:
        errors.append("Selected asset details must expose its read-only source and license context.")

    browser.queue_free()
    return errors


static func _record(records: Array, relative_path: String) -> Dictionary:
    for record in records:
        if str(record.get("relative_path", "")) == relative_path: return record
    return {}


static func _write_text(path: String, text: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(text)
    file.close()


static func _scene_text(root_name: String) -> String:
    return "[gd_scene load_steps=2 format=3]\n\n[sub_resource type=\"BoxMesh\" id=\"BoxMesh_fixture\"]\n\n[node name=\"%s\" type=\"Node3D\"]\n\n[node name=\"Mesh\" type=\"MeshInstance3D\" parent=\".\"]\nmesh = SubResource(\"BoxMesh_fixture\")\n" % root_name
