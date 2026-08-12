class_name Phase16ProductCompletenessContracts
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const AssetLibrary = preload("res://src/assets/asset_library_service.gd")
const SemanticSearch = preload("res://src/assets/asset_semantic_search.gd")
const NewWorldScene = preload("res://src/app/screens/new_world/NewWorldScreen.tscn")
const MainScene = preload("res://src/main/Main.tscn")

static func run_checks(tree: SceneTree) -> Array[String]:
    var errors: Array[String] = []
    errors.append_array(await _check_shell_and_biome(tree))
    errors.append_array(_check_semantic_search())
    errors.append_array(_check_real_thumbnail())
    return errors

static func _check_shell_and_biome(tree: SceneTree) -> Array[String]:
    var errors: Array[String] = []
    var storage_root: String = "user://tests/phase16/shell-%s" % StableId.generate()
    ProjectSettings.set_setting("playworld/storage/projects_root", storage_root)
    var app: Control = MainScene.instantiate() as Control
    if app == null: return ["Phase 16 could not instantiate Main.tscn."]
    tree.root.add_child(app)
    await tree.process_frame
    await tree.process_frame
    var home: Node = app.get_node_or_null("HomeScreen")
    if home == null: errors.append("Home screen is missing from Main.tscn.")
    else:
        for button_name in ["WorldsButton", "TemplatesButton", "AssetLibraryButton"]:
            var button: Button = home.find_child(button_name, true, false) as Button
            if button == null: errors.append("Home creator route button is missing: %s" % button_name)
            elif button.disabled: errors.append("Home creator route button is unexpectedly disabled: %s" % button_name)
        var worlds: Button = home.find_child("WorldsButton", true, false) as Button
        if worlds != null:
            worlds.pressed.emit(); await tree.process_frame
            var worlds_overlay: Control = home.get_node_or_null("HomeCreatorOverlay") as Control
            if worlds_overlay == null or not worlds_overlay.visible: errors.append("My Worlds did not open a real creator surface.")
            if worlds_overlay != null: worlds_overlay.call("close")
        var templates: Button = home.find_child("TemplatesButton", true, false) as Button
        if templates != null:
            templates.pressed.emit(); await tree.process_frame
            var templates_overlay: Control = home.get_node_or_null("HomeCreatorOverlay") as Control
            if templates_overlay == null or not templates_overlay.visible: errors.append("Templates did not open a real creator surface.")
            if templates_overlay != null: templates_overlay.call("close")
    var new_world: Control = NewWorldScene.instantiate() as Control
    tree.root.add_child(new_world); await tree.process_frame
    var biome: OptionButton = new_world.find_child("BiomeOption", true, false) as OptionButton
    if biome == null or biome.item_count < 3: errors.append("New World does not expose the required biome presets.")
    var capture: Dictionary = {"value": {}}
    new_world.create_requested.connect(func(value: Dictionary): capture["value"] = value.duplicate(true))
    new_world.call("_request_create")
    var captured: Dictionary = capture.get("value", {})
    if str(captured.get("biome_preset", "")).is_empty(): errors.append("New World creation request omitted biome_preset.")
    new_world.queue_free(); app.queue_free(); await tree.process_frame
    return errors

static func _check_semantic_search() -> Array[String]:
    var records: Array[Dictionary] = [
        {"display_name": "Old Sedan", "relative_path": "vehicles/sedan.tscn", "asset_type": "godot_text_scene", "collections": [], "analysis": {"metadata": {}}},
        {"display_name": "Pine Tree", "relative_path": "nature/pine.tscn", "asset_type": "godot_text_scene", "collections": [], "analysis": {"metadata": {}}},
    ]
    var ranked: Array[Dictionary] = SemanticSearch.new().rank(records, "car")
    if ranked.is_empty() or str(ranked[0].get("display_name", "")) != "Old Sedan": return ["Semantic asset search did not rank the vehicle synonym deterministically."]
    return []

static func _check_real_thumbnail() -> Array[String]:
    var errors: Array[String] = []
    var root_path: String = "user://tests/phase16/assets-%s" % StableId.generate()
    var source: String = root_path.path_join("source")
    var project: String = root_path.path_join("project")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(source))
    var scene_text: String = "[gd_scene load_steps=2 format=3]\n\n[sub_resource type=\"BoxMesh\" id=\"BoxMesh_test\"]\nsize = Vector3(2, 3, 4)\n\n[node name=\"PreviewBox\" type=\"Node3D\"]\n\n[node name=\"MeshInstance3D\" type=\"MeshInstance3D\" parent=\".\"]\nmesh = SubResource(\"BoxMesh_test\")\n"
    var scene_path: String = source.path_join("preview_box.tscn")
    var file := FileAccess.open(scene_path, FileAccess.WRITE)
    if file == null: return ["Phase 16 could not create thumbnail fixture scene."]
    file.store_string(scene_text); file.close()
    var library = AssetLibrary.new(project)
    var load_result: Dictionary = library.load_library()
    if not load_result.get("ok", false): return ["Phase 16 Asset Library fixture failed to load: %s" % str(load_result.get("errors", []))]
    var register: Dictionary = library.register_source(source, "Phase16 fixture")
    if not register.get("ok", false): return ["Phase 16 Asset Library fixture scan failed: %s" % str(register.get("errors", []))]
    var records: Array[Dictionary] = library.get_records(false)
    if records.size() != 1: return ["Phase 16 Asset Library fixture expected one indexed asset."]
    var thumbnail: Dictionary = records[0].get("thumbnail", {})
    if not bool(thumbnail.get("depicts_asset", false)): errors.append("Thumbnail fixture was not generated from actual asset geometry.")
    if str(thumbnail.get("kind", "")) != "geometry_projection": errors.append("Thumbnail fixture used an unexpected placeholder/fallback kind.")
    if int(thumbnail.get("vertex_count", 0)) <= 0: errors.append("Thumbnail fixture did not consume mesh vertices.")
    var image: Image = Image.load_from_file(str(thumbnail.get("path", "")))
    if image == null or image.is_empty(): errors.append("Generated real thumbnail image could not be decoded.")
    return errors
