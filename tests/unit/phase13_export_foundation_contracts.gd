extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const Contracts = preload("res://src/export/export_contracts.gd")
const Scanner = preload("res://src/export/export_dependency_scanner.gd")
const AssetResolver = preload("res://src/export/export_asset_resolver.gd")
const LicenseReport = preload("res://src/export/export_license_report.gd")
const StagingPlan = preload("res://src/export/export_staging_plan.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project_id: String = StableId.generate(); var build_id: String = StableId.generate(); var entity_id: String = StableId.generate(); var cell_id: String = StableId.generate()
    var asset_a: String = StableId.generate(); var asset_b: String = StableId.generate(); var source_id: String = StableId.generate()
    var project: Dictionary = {"project_id": project_id, "title": "Export Test", "world_profile": "small", "template_id": "blank_sandbox", "cell_ids": [cell_id], "entities": [{"entity_id": entity_id, "asset_id": asset_a}], "dependencies": [asset_a]}

    var discovered: Dictionary = Scanner.discover(project, {"gameplay": {"prefabs": [{"nodes": [{"asset_id": asset_b}]}]}, "procedural": {"foliage_sets": [{"source": {"kind": "asset", "source_id": asset_a}}]}})
    if not discovered.get("ok", false): errors.append("Export dependency discovery must accept valid authored references.")
    elif discovered.get("asset_ids", []) != [asset_a, asset_b] and discovered.get("asset_ids", []) != [asset_b, asset_a]: errors.append("Export dependency discovery must de-duplicate world, gameplay, and procedural asset references.")

    var bad_project: Dictionary = project.duplicate(true); bad_project["entities"] = [{"entity_id": entity_id, "asset_id": "not-a-stable-id"}]
    if Scanner.discover(bad_project).get("ok", true): errors.append("Export dependency discovery must reject malformed authored asset references.")

    var source_root: String = "user://tests/phase13/assets-%s" % StableId.generate()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(source_root))
    var source_file: String = source_root.path_join("models/tree.glb")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(source_file.get_base_dir()))
    var handle: FileAccess = FileAccess.open(source_file, FileAccess.WRITE)
    if handle == null: errors.append("Phase 13 fixture source asset must be writable.")
    else: handle.store_string("fixture"); handle.close()
    var hash64: String = "a".repeat(64)
    var catalog: Array = [{"asset_id": asset_a, "source_id": source_id, "relative_path": "models/tree.glb", "asset_type": "glb", "content_hash": hash64, "size_bytes": 7, "missing": false, "license": {"spdx": "CC0-1.0", "author": "Fixture", "source_url": "", "notes": ""}}]
    var sources: Array = [{"source_id": source_id, "root_path": source_root}]
    var resolution: Dictionary = AssetResolver.resolve([asset_a], catalog, sources, true)
    if not resolution.get("ok", false): errors.append("Export dependency resolver must resolve an available Phase 4 Asset Library file.")
    else:
        var dependency: Dictionary = resolution.get("dependencies", [])[0]
        if not str(dependency.get("package_path", "")).begins_with("assets/%s/" % asset_a): errors.append("Resolved assets must use deterministic project-managed package paths.")
        var license_report: Dictionary = LicenseReport.build(resolution.get("dependencies", []))
        if not license_report.get("findings", []).is_empty() or not str(license_report.get("text", "")).contains("CC0-1.0"): errors.append("Known Asset Library license metadata must flow into attribution output.")
    var missing_catalog: Array = catalog.duplicate(true); missing_catalog[0]["missing"] = true
    if AssetResolver.resolve([asset_a], missing_catalog, sources, false).get("ok", true): errors.append("Missing required Asset Library dependencies must block export resolution.")
    var unknown_license: Array = resolution.get("dependencies", []).duplicate(true)
    if not unknown_license.is_empty(): unknown_license[0]["license"] = {"spdx": "", "author": "", "source_url": "", "notes": ""}
    if LicenseReport.build(unknown_license).get("findings", []).is_empty(): errors.append("Unknown asset licenses must be reported explicitly.")

    var runtime_paths: Dictionary = {"src/runtime/play_session.gd": true, "src/editor/runtime_entity_bridge.gd": true}
    if StagingPlan.classify_code_path("src/runtime/play_session.gd", runtime_paths) != Contracts.RUNTIME_REQUIRED: errors.append("Exact runtime dependency closure paths must classify runtime-required.")
    if StagingPlan.classify_code_path("src/app/app_shell.gd", runtime_paths) != Contracts.EDITOR_ONLY: errors.append("Files outside the runtime dependency closure must classify editor-only.")
    var data_plan: Dictionary = StagingPlan.build_project_data_plan(project)
    var serialized_plan: String = JSON.stringify(data_plan)
    if serialized_plan.contains("checkpoints/") or serialized_plan.contains("ai/") or serialized_plan.contains("terrain/recovery/"): errors.append("Export staging data plan must exclude checkpoints, AI history/configuration, and terrain recovery copies.")
    if not serialized_plan.contains("terrain/cells/%s.json" % cell_id): errors.append("Export staging must preserve canonical authored terrain cells.")

    var dependency_entries: Array = resolution.get("dependencies", []) if resolution.get("ok", false) else []
    var manifest: Dictionary = Contracts.new_manifest(project, build_id, "ExportTest", dependency_entries, [{"package_path": "runtime_data/project.json", "classification": Contracts.RUNTIME_REQUIRED}])
    if not Contracts.validate_manifest(manifest).is_empty(): errors.append("Valid schema-v1 Windows export manifest must pass validation.")
    var unsafe: Dictionary = manifest.duplicate(true); unsafe["files"] = [{"package_path": "../escape.txt", "classification": Contracts.RUNTIME_REQUIRED}]
    if Contracts.validate_manifest(unsafe).is_empty(): errors.append("Export manifests must reject traversal package paths.")
    var secret: Dictionary = manifest.duplicate(true); secret["api_key"] = "do-not-ship"
    if Contracts.validate_manifest(secret).is_empty(): errors.append("Export manifests must reject prohibited credential material.")
    return errors
