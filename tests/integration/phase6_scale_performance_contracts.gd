extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const GameplayState = preload("res://src/gameplay/gameplay_state.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const Archetypes = preload("res://src/gameplay/builtin_archetype_library.gd")
const PrefabResolver = preload("res://src/gameplay/prefab_resolver.gd")

const CI_BUDGET_MSEC := 5000
const ENTITY_COUNT := 200
const DERIVED_PREFAB_COUNT := 50


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var started := Time.get_ticks_msec()
    var project = WorldProject.new()
    project.initialize_new("Phase 6 Scale", &"medium", "blank_sandbox")
    var test_cells: Array[String] = [StableId.generate()]
    project.cell_ids = test_cells
    var state = GameplayState.new()
    state.definitions = Components.definitions()
    state.archetypes = Archetypes.definitions()
    var cell_id: String = test_cells[0]
    var definition_ids: Array[String] = [
        Components.id_for("health"),
        Components.id_for("interactable"),
        Components.id_for("save_state")
    ]

    for index in range(ENTITY_COUNT):
        var entity = WorldEntity.new()
        entity.initialize_new("Scale Entity %03d" % index, cell_id)
        entity.transform["position"] = [float(index % 20) * 2.0, 0.0, float(index / 20) * 2.0]
        for definition_id in definition_ids:
            var definition: Dictionary = state.get_definition(definition_id)
            var instance_id := StableId.generate()
            var record := {
                "document_type": Contracts.COMPONENT_INSTANCE,
                "schema_version": Contracts.SCHEMA_VERSION,
                "instance_id": instance_id,
                "definition_id": definition_id,
                "owner_entity_id": entity.entity_id,
                "values": Contracts.defaults_for(definition)
            }
            state.instances.append(record)
            entity.component_instance_ids.append(instance_id)
        project.entity_records.append(entity.to_dictionary())

    for index in range(DERIVED_PREFAB_COUNT):
        var node_id := StableId.generate()
        var base_id := StableId.generate()
        var derived_id := StableId.generate()
        var base := {
            "document_type": Contracts.PREFAB,
            "schema_version": Contracts.SCHEMA_VERSION,
            "prefab_id": base_id,
            "display_name": "Base %02d" % index,
            "base_prefab_id": null,
            "nodes": [{
                "node_id": node_id,
                "parent_node_id": null,
                "display_name": "Root",
                "asset_id": null,
                "transform": _transform(),
                "components": {
                    Components.id_for("health"): Contracts.defaults_for(
                        state.get_definition(Components.id_for("health"))
                    )
                }
            }],
            "node_overrides": {},
            "removed_node_ids": [],
            "socket_ids": [],
            "socket_overrides": {},
            "removed_socket_ids": []
        }
        var derived := {
            "document_type": Contracts.PREFAB,
            "schema_version": Contracts.SCHEMA_VERSION,
            "prefab_id": derived_id,
            "display_name": "Derived %02d" % index,
            "base_prefab_id": base_id,
            "nodes": [],
            "node_overrides": {node_id: {"display_name": "Derived Root %02d" % index}},
            "removed_node_ids": [],
            "socket_ids": [],
            "socket_overrides": {},
            "removed_socket_ids": []
        }
        state.prefabs.append(base)
        state.prefabs.append(derived)

    var validation: Array[String] = state.validate(project)
    if not validation.is_empty():
        errors.append("Representative Phase 6 composition workload must cross-validate: %s" % [validation])
    var resolver = PrefabResolver.new(state)
    var resolved_count := 0
    for prefab in state.prefabs:
        if prefab.get("base_prefab_id") != null:
            var resolved: Dictionary = resolver.resolve(str(prefab.get("prefab_id", "")))
            if resolved.get("ok", false):
                resolved_count += 1
    if resolved_count != DERIVED_PREFAB_COUNT:
        errors.append("Scale workload must deterministically resolve all derived prefab inheritance chains.")
    if state.instances.size() != ENTITY_COUNT * 3:
        errors.append("Scale workload must retain all stable component instances.")
    var elapsed := Time.get_ticks_msec() - started
    if elapsed > CI_BUDGET_MSEC:
        errors.append(
            "Representative Phase 6 composition workload exceeded the %dms CI regression budget (%dms)." % [
                CI_BUDGET_MSEC,
                elapsed
            ]
        )
    return errors


static func _transform() -> Dictionary:
    return {
        "position": [0.0, 0.0, 0.0],
        "rotation_degrees": [0.0, 0.0, 0.0],
        "scale": [1.0, 1.0, 1.0]
    }
