# System Architecture

## Architectural rule
The editor core operates on generic entities, assets, terrain cells, components, archetypes, prefabs, sockets, attachments, properties, graphs, transactions, resources, and stable IDs. It does not hard-code broad gameplay behavior into the scene editor.

Persistent relationships use stable UUIDs. Scene-tree paths, node names, source filesystem paths, runtime pointers, and array positions are never persistent identity.

## Major modules
1. App Shell
2. Project/World Manager
3. Runtime Editor
4. Command + Transaction/Undo System
5. Asset Registry / Import / Thumbnail Pipeline
6. Terrain + World Partition
7. World Streaming
8. Entity/Component Authoring
9. Archetype + Prefab System
10. Socket + Attachment System
11. Visual Script Runtime + Editor
12. Foliage/Scatter
13. Spline/Road
14. Environment/Weather
15. Save/Serialization
16. Template System
17. AI Orchestrator
18. Export Pipeline
19. Input Abstraction
20. Diagnostics/Performance
21. Future Networking/Collaboration

## Commands and authored mutation
All authored mutations flow through reversible commands or transactions. Failed execution/undo/redo does not advance history. Preview-only state does not dirty authored data.

Phase 3 entity placement/transforms, Phase 5 terrain sculpt/biome changes, and Phase 6 component/archetype/prefab/socket/attachment edits share the same editor command history. Phase 6 uses snapshot commands for coordinated world-project + gameplay-registry changes so Undo/Redo restores both sides of a composition edit atomically.

## Runtime entity editor
`src/editor/editor_session.gd` coordinates project state, command history, selection, placement ghost, snapping, transform editing, and dirty signaling.

`src/editor/runtime_entity_bridge.gd` validates the complete persisted world-entity set before constructing disposable runtime nodes. In streamed Large worlds it may instantiate only active-cell entities while preserving stable references to unloaded records.

Placement and cross-cell movement use the Phase 5 cell resolver. Transform + owning `cell_id` changes are authored together.

Raw Phase 3 duplication intentionally clears copied `component_instance_ids`; gameplay-bound identities are never aliased by a generic entity copy. Temporarily absent world owners do not cause gameplay registries to be silently destroyed, allowing delete/undo and streaming to recover stable authored records.

## Universal Asset Library
Phase 4 remains owned by `src/assets`. External registered source folders are strictly read-only. Derived imports, metadata, licensing, favorites, collections, duplicate metadata, and thumbnails remain under project-managed `asset_library/` storage.

Phase 6 prefabs are authored project content and never mutate Phase 4 source folders.

## Terrain + partition architecture
Phase 5 remains owned primarily by `src/terrain`.

`terrain_repository.gd` owns per-cell terrain persistence; `terrain_world_state.gd` owns in-memory authored terrain; `terrain_runtime.gd` owns disposable loaded chunks; `terrain_controller.gd` coordinates shared command history, cell resolution, streaming, and incremental autosave.

Small/Medium/Large partition topology remains deterministic. Large-world streaming never rewrites stable entity, parent, prefab, component, socket, attachment, or owning-cell identity merely because a referenced runtime node is unloaded.

## Phase 6 gameplay composition architecture
Phase 6 is owned primarily by `src/gameplay`.

### Contracts and repository
`gameplay_contracts.gd` defines schema-v1 validation for component definitions, component instances, archetypes, prefabs, prefab instances, sockets, and attachments. It validates stable IDs, typed property schemas, ranges/enums, transforms, and supported socket categories.

`gameplay_repository.gd` owns `<project>/gameplay` JSON registries and uses the existing crash-safe JSON writer. JSON arrays are explicitly reconstructed into typed `Array[Dictionary]` state on reopen so registry identity cannot silently collapse at the persistence boundary.

`gameplay_state.gd` is the canonical in-memory gameplay composition state. It resolves definitions, dependency plans, conflicts, archetypes, prefabs, sockets, attachments, and prefab instances using stable IDs.

Gameplay-internal reference validation remains strict. World-owner availability is treated separately so records can remain recoverable when an entity is temporarily deleted, undone, or streamed out.

### Components and archetypes
`builtin_component_library.gd` provides the 21 required initial component definitions with stable definition IDs, editor categories, typed defaults, dependencies, conflicts, and future runtime-hook metadata.

`builtin_archetype_library.gd` provides the initial nine data-driven archetype presets. Archetype application retains the target entity UUID, preserves unrelated components, applies deterministic dependency closure, and rejects unresolved conflicts.

`gameplay_service.gd` exposes add/remove/configure component and archetype operations. It stages changes, validates them, commits them through shared command history, persists the affected registries, refreshes runtime presentation, and marks project state dirty.

### Prefabs and inheritance
`prefab_authoring_service.gd` snapshots a real world-entity hierarchy, its configured components, assets, transforms, and sockets into project-managed prefab data.

Prefab instantiation allocates fresh world entity UUIDs, fresh component-instance UUIDs, fresh entity-owned socket UUIDs, and a stable prefab-instance record while retaining the prefab reference. Repeated instantiation never reuses world identity.

`prefab_resolver.gd` resolves base/derived inheritance deterministically. Derived prefabs store their own stable ID plus authored differences. Explicit instance overrides win over inherited values. Missing bases, invalid node/socket references, and inheritance cycles fail safely.

### Sockets and attachments
`sockets` are named, typed stable-ID records with local transforms. Supported built-in categories include Grip, Seat, Mount, DoorHandle, Light, LootSpawn, Wheel, Muzzle, Camera, and InteractionPoint, with Custom extension support.

`socket_attachment_service.gd` authors socket add/edit/remove and attachment/detach operations through shared command history. Attachments persist parent entity ID + parent socket ID + child entity ID + optional child socket ID + local offset data—never scene paths.

`runtime_attachment_resolver.gd` creates transient runtime anchor nodes from stable attachment data. Missing/unloaded runtime participants are reported as unresolved rather than corrupting persistent identity; resolution can recover when entities become available again.

### Gameplay workspace
`gameplay_workspace_layer.gd` and `gameplay_tool_panel.gd` extend the existing bottom Gameplay dock with a compact contextual composition surface. The panel exposes archetype application, component addition, prefab save/place, socket creation, and two-object attachment while preserving the existing inspector, Terrain tool, Asset Library, and Phase 3 tool wheel.

Keyboard/mouse controls remain native focusable Godot controls. Gamepad X adds the selected component, Y applies the selected archetype, A activates focused native controls, and Escape closes the contextual Gameplay layer before leaving the workspace.

## Crash safety
`PlayWorldSafeJsonWriter` remains the common atomic JSON primitive: temporary write, flush/close, parse, semantic validation, then promotion.

Phase 6 gameplay registry writes fail closed on corrupt JSON, reject unsupported future schema versions, and preserve prior canonical content when promotion fails. No source Asset Library directory is used for generated prefab/component content.

## Performance and verification boundary
Phase 6 has a dedicated six-suite diagnostic matrix covering components, prefabs, sockets/attachments, persistence failures, scale, and the real workspace. The representative scale workload validates hundreds of component instances plus derived prefab resolution under a generous CI regression budget.

This is a regression proxy, not a hardware FPS benchmark. Release-scale hardware performance validation remains separate.

Rendered Phase 6 evidence captures the real canonical workspace with component/archetype composition, a named socket, managed prefab state, repeated instance identity, and attachment controls.

## Later-phase boundaries
Phase 6 establishes composition data and editor foundations. It does not implement the broad gameplay semantics reserved for later phases, Visual Script behavior, foliage/scatter, roads/splines, full environment/weather, AI orchestration, or export behavior stripping.
