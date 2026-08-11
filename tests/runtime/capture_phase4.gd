extends SceneTree

const MAIN_SCENE := "res://src/main/Main.tscn"
const OUTPUT_DIR := "res://artifacts/phase4"
const SOURCE_DIR := "user://phase4_visual_source"

var _app: Control


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var make_dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
    if make_dir_error != OK and make_dir_error != ERR_ALREADY_EXISTS:
        push_error("Unable to create Phase 4 screenshot directory: %s" % make_dir_error)
        quit(1)
        return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SOURCE_DIR))
    _write_visual_fixtures()

    var main_resource := load(MAIN_SCENE) as PackedScene
    if main_resource == null:
        push_error("Unable to load Main.tscn for Phase 4 capture.")
        quit(1)
        return
    _app = main_resource.instantiate() as Control
    if _app == null:
        push_error("Unable to instantiate Main.tscn for Phase 4 capture.")
        quit(1)
        return
    root.add_child(_app)
    root.size = Vector2i(1600, 900)
    await _settle()

    var home := _app.get_node("HomeScreen") as Control
    var new_world := _app.get_node("NewWorldScreen") as Control
    var workspace := _app.get_node("WorkspaceScreen") as Control
    home.emit_signal("route_requested", &"new_world")
    await _settle()
    new_world.emit_signal("create_requested", {"title": "Aurora Playground", "world_profile": "large", "template_id": "third_person_adventure"})
    await _settle()

    var register_result: Dictionary = workspace.call("register_asset_source", SOURCE_DIR, "Creative Kit")
    if not register_result.get("ok", false):
        push_error("Unable to register Phase 4 visual source: %s" % register_result.get("errors", []))
        quit(1)
        return
    var library: Variant = workspace.call("get_asset_library")
    var records: Array[Dictionary] = library.get_records()
    if records.size() < 10:
        push_error("Phase 4 visual capture expected at least ten catalog records.")
        quit(1)
        return
    library.set_favorite(str(records[0].get("asset_id", "")), true)
    library.set_favorite(str(records[3].get("asset_id", "")), true)
    library.add_to_collection(str(records[0].get("asset_id", "")), "Town Kit")
    library.add_to_collection(str(records[1].get("asset_id", "")), "Town Kit")
    library.set_license(str(records[0].get("asset_id", "")), {"spdx": "CC0-1.0", "author": "Polyfork Fixture Studio", "source_url": "", "notes": "Visual evidence fixture"})
    workspace.call("open_asset_drawer")
    var browser: Variant = workspace.call("get_asset_browser")
    browser.refresh()
    await _settle()
    await _capture("01-asset-library-large")

    var density_button := workspace.find_child("DensityButton", true, false) as Button
    if density_button == null:
        push_error("Unable to find Asset Library density control.")
        quit(1)
        return
    density_button.emit_signal("pressed")
    await _settle()
    await _capture("02-asset-library-compact")

    print("PASS: Phase 4 rendered screenshots captured.")
    quit(0)


func _write_visual_fixtures() -> void:
    var names := ["Copper Cottage", "Cherry Tree", "Sky Bridge", "Mossy Ruin", "Lantern Post", "Market Stall", "Cloud Fountain", "Adventure Crate", "Garden Arch", "Windmill", "Stone Bench", "Festival Gate"]
    for index in range(names.size()):
        var safe_name := str(names[index]).replace(" ", "_")
        var path := SOURCE_DIR.path_join("%02d_%s.tscn" % [index + 1, safe_name])
        var text := "[gd_scene load_steps=2 format=3]\n\n[sub_resource type=\"BoxMesh\" id=\"BoxMesh_visual\"]\nsize = Vector3(%.2f, %.2f, %.2f)\n\n[node name=\"%s\" type=\"Node3D\"]\n\n[node name=\"Mesh\" type=\"MeshInstance3D\" parent=\".\"]\nmesh = SubResource(\"BoxMesh_visual\")\n" % [1.0 + index * 0.04, 0.8 + index * 0.03, 1.0 + index * 0.02, names[index]]
        var file := FileAccess.open(path, FileAccess.WRITE)
        file.store_string(text)
        file.close()


func _settle() -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw


func _capture(file_stem: String) -> void:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        push_error("Rendered Phase 4 image is empty for %s." % file_stem)
        quit(1)
        return
    var output_file := "%s/%s.png" % [OUTPUT_DIR, file_stem]
    var save_error := image.save_png(ProjectSettings.globalize_path(output_file))
    if save_error != OK:
        push_error("Unable to save %s: %s" % [output_file, save_error])
        quit(1)
