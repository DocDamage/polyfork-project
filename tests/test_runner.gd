extends SceneTree

const WorldFoundationContracts = preload("res://tests/unit/world_foundation_contracts.gd")
const CommandHistoryContracts = preload("res://tests/unit/command_history_contracts.gd")
const RuntimeEntityBridgeContracts = preload("res://tests/unit/runtime_entity_bridge_contracts.gd")
const SnappingContracts = preload("res://tests/unit/snapping_contracts.gd")
const AssetLibraryContracts = preload("res://tests/unit/asset_library_contracts.gd")
const AssetFormatContracts = preload("res://tests/unit/asset_format_contracts.gd")
const TerrainContracts = preload("res://tests/unit/terrain_contracts.gd")
const TerrainRuntimeContracts = preload("res://tests/unit/terrain_runtime_contracts.gd")
const GameplayContracts = preload("res://tests/unit/gameplay_contracts.gd")
const ProjectRepositoryContracts = preload("res://tests/integration/project_repository_contracts.gd")
const AutosaveCheckpointContracts = preload("res://tests/integration/autosave_checkpoint_contracts.gd")
const Phase2LifecycleContracts = preload("res://tests/integration/phase2_lifecycle_contracts.gd")
const Phase2PersistenceHardeningContracts = preload("res://tests/integration/phase2_persistence_hardening_contracts.gd")
const Phase3EditorSessionContracts = preload("res://tests/integration/phase3_editor_session_contracts.gd")
const Phase3PlacementSnappingContracts = preload("res://tests/integration/phase3_placement_snapping_contracts.gd")
const Phase4PlacementContracts = preload("res://tests/integration/phase4_placement_contracts.gd")
const Phase5TerrainPersistenceContracts = preload("res://tests/integration/phase5_terrain_persistence_contracts.gd")
const Phase5SculptStreamingContracts = preload("res://tests/integration/phase5_sculpt_streaming_contracts.gd")
const Phase5EntityStreamingContracts = preload("res://tests/integration/phase5_entity_streaming_contracts.gd")
const Phase5EntityCellOwnershipContracts = preload("res://tests/integration/phase5_entity_cell_ownership_contracts.gd")
const Phase5ScalePerformanceContracts = preload("res://tests/integration/phase5_scale_performance_contracts.gd")
const Phase6ComponentArchetypeContracts = preload("res://tests/integration/phase6_component_archetype_contracts.gd")
const Phase6PrefabContracts = preload("res://tests/integration/phase6_prefab_contracts.gd")
const Phase6SocketAttachmentContracts = preload("res://tests/integration/phase6_socket_attachment_contracts.gd")
const ContinueReopenSmoke = preload("res://tests/runtime/continue_reopen_smoke.gd")
const Phase3EditorSmoke = preload("res://tests/runtime/phase3_editor_smoke.gd")
const Phase4AssetBrowserSmoke = preload("res://tests/runtime/phase4_asset_browser_smoke.gd")
const Phase5TerrainWorkspaceSmoke = preload("res://tests/runtime/phase5_terrain_workspace_smoke.gd")
const Phase6GameplayWorkspaceSmoke = preload("res://tests/runtime/phase6_gameplay_workspace_smoke.gd")
const RUNTIME_SMOKE_SCENE := "res://tests/runtime/RuntimeSmoke.tscn"

var _failures: Array[String] = []


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    _run_unit_checks()
    _run_integration_checks()
    await _run_runtime_smoke()
    _run_continue_reopen_smoke()
    _run_phase3_editor_smoke()
    _run_phase4_asset_browser_smoke()
    _run_phase5_terrain_workspace_smoke()
    _run_phase6_gameplay_workspace_smoke()
    if _failures.is_empty():
        print("PASS: PlayWorld Studio test harness completed.")
        quit(0)
        return
    for failure in _failures:
        push_error("FAIL: %s" % failure)
    quit(1)


func _run_unit_checks() -> void:
    for error in WorldFoundationContracts.run_checks(): _failures.append(error)
    for error in CommandHistoryContracts.run_checks(): _failures.append(error)
    for error in RuntimeEntityBridgeContracts.run_checks(): _failures.append(error)
    for error in SnappingContracts.run_checks(): _failures.append(error)
    for error in AssetLibraryContracts.run_checks(): _failures.append(error)
    for error in AssetFormatContracts.run_checks(): _failures.append(error)
    for error in TerrainContracts.run_checks(): _failures.append(error)
    for error in TerrainRuntimeContracts.run_checks(): _failures.append(error)
    for error in GameplayContracts.run_checks(): _failures.append(error)


func _run_integration_checks() -> void:
    for error in ProjectRepositoryContracts.run_checks(): _failures.append(error)
    for error in AutosaveCheckpointContracts.run_checks(): _failures.append(error)
    for error in Phase2LifecycleContracts.run_checks(): _failures.append(error)
    for error in Phase2PersistenceHardeningContracts.run_checks(): _failures.append(error)
    for error in Phase3EditorSessionContracts.run_checks(): _failures.append(error)
    for error in Phase3PlacementSnappingContracts.run_checks(): _failures.append(error)
    for error in Phase4PlacementContracts.run_checks(): _failures.append(error)
    for error in Phase5TerrainPersistenceContracts.run_checks(): _failures.append(error)
    for error in Phase5SculptStreamingContracts.run_checks(): _failures.append(error)
    for error in Phase5EntityStreamingContracts.run_checks(): _failures.append(error)
    for error in Phase5EntityCellOwnershipContracts.run_checks(): _failures.append(error)
    for error in Phase5ScalePerformanceContracts.run_checks(): _failures.append(error)
    for error in Phase6ComponentArchetypeContracts.run_checks(): _failures.append(error)
    for error in Phase6PrefabContracts.run_checks(): _failures.append(error)
    for error in Phase6SocketAttachmentContracts.run_checks(): _failures.append(error)


func _run_runtime_smoke() -> void:
    var packed := load(RUNTIME_SMOKE_SCENE) as PackedScene
    _expect(packed != null, "Runtime smoke scene must load.")
    if packed == null: return
    var instance := packed.instantiate()
    _expect(instance != null, "Runtime smoke scene must instantiate.")
    if instance == null: return
    root.add_child(instance)
    await process_frame
    if not instance.has_method("run_checks"):
        _failures.append("Runtime smoke scene must expose run_checks().")
    else:
        var result: Dictionary = instance.call("run_checks")
        for error in result.get("errors", []): _failures.append(str(error))
        _expect(bool(result.get("ok", false)), "Runtime smoke scene reported failure.")
    instance.queue_free()
    await process_frame


func _run_continue_reopen_smoke() -> void:
    var smoke := ContinueReopenSmoke.new()
    root.add_child(smoke)
    for error in smoke.run_checks(): _failures.append(error)
    smoke.queue_free()


func _run_phase3_editor_smoke() -> void:
    var smoke := Phase3EditorSmoke.new()
    root.add_child(smoke)
    for error in smoke.run_checks(): _failures.append(error)
    smoke.queue_free()


func _run_phase4_asset_browser_smoke() -> void:
    var smoke := Phase4AssetBrowserSmoke.new()
    root.add_child(smoke)
    for error in smoke.run_checks(): _failures.append(error)
    smoke.queue_free()


func _run_phase5_terrain_workspace_smoke() -> void:
    var smoke := Phase5TerrainWorkspaceSmoke.new()
    root.add_child(smoke)
    for error in smoke.run_checks(): _failures.append(error)
    smoke.queue_free()


func _run_phase6_gameplay_workspace_smoke() -> void:
    var smoke := Phase6GameplayWorkspaceSmoke.new()
    root.add_child(smoke)
    for error in smoke.run_checks(): _failures.append(error)
    smoke.queue_free()


func _expect(condition: bool, message: String) -> void:
    if not condition: _failures.append(message)
