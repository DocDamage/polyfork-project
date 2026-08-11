# System Architecture

## Architectural rule
The editor must not hard-code world semantics such as "door", "car", or "enemy" into the core scene editor. The core understands entities, components, archetypes, prefabs, properties, events, graphs, resources, transactions, and stable IDs. Gameplay meaning is assembled above those primitives.

## Major modules
1. App Shell
2. Project/World Manager
3. Runtime Editor
4. Command + Transaction/Undo System
5. Asset Registry
6. Import/Analysis Pipeline
7. Thumbnail Service
8. Entity/Component Runtime
9. Archetype Registry
10. Prefab System
11. Visual Script Runtime + Editor
12. Terrain System
13. Foliage/Scatter System
14. Spline/Road System
15. Environment/Weather System
16. Save/Serialization
17. World Streaming
18. Template System
19. AI Orchestrator
20. Export Pipeline
21. Input Abstraction
22. Diagnostics/Performance
23. Future Networking/Collaboration Layer

## Data and identity boundaries
Editor metadata remains separable from runtime game data. Persistent relationships use stable UUIDs; scene-tree paths, node names, source filesystem paths, and array positions are never persistent identity.

Every world object, asset catalog record, prefab, component instance, graph, terrain cell, procedural generator, transaction, and retained checkpoint receives stable identity according to its owning schema.

## Commands and authored mutation
All authored world mutations flow through commands. A command exposes deterministic `execute()` and `undo()` operations. Failure must leave authored state unchanged or restore partial work before returning failure. Transactions commit to history only after every command succeeds and roll back in reverse order otherwise.

The command history owns bounded undo/redo stacks. A successful new edit after undo clears redo. Failed execution/undo/redo does not advance history. Persistence observes authored state rather than becoming an authoring mutation.

## Runtime placement editor
`src/editor/editor_session.gd` coordinates the bound project, command history, runtime bridge, multi-selection, placement ghost, snapping service, transform-tool state, and dirty-state callback.

`src/editor/runtime_entity_bridge.gd` rebuilds the runtime hierarchy from validated world entity records. Lookup and parent relationships are resolved through stable entity IDs. It rejects duplicate IDs, unresolved parents, self-parenting, and parent cycles.

`src/editor/runtime_entity_node.gd` is the generic `Node3D` wrapper for persisted `WorldEntity` state. Phase 4 allows the bridge to bind an Asset Library resolver. If an entity carries a valid catalog `asset_id`, the resolver attaches the real managed asset scene as the entity visual. If the catalog/source/import is unavailable, the node remains usable with its generic proxy instead of invalidating authored world state.

`src/editor/placement_ghost.gd` keeps preview placement transient. It can now display a real Asset Library `Node3D` while retaining the generic proxy fallback. Preview movement/cancel never dirties project state.

Placement commit still executes `PlayWorldPlaceEntityCommand`. Move/rotate/scale, duplicate, delete, grouping, drop-to-ground, and snapping continue through the Phase 3 command/session architecture. Phase 4 does not bypass command history or create a prefab system.

`src/editor/snapping_service.gd` provides deterministic grid, angle, surface, object, socket, and ground snapping. Generic entity origins remain temporary sockets until the later prefab/socket phase.

## Universal Asset Library
Phase 4 is owned by `src/assets` and is instantiated per world project. Its managed root is `<project-directory>/asset_library`.

### Source boundary
`asset_source.gd` and `source_folder_registry.gd` define registered source folders. A source contract always declares `read_only: true`. Managed Asset Library storage cannot overlap a source root. Scanner traversal does not follow linked directories. Source assets are never renamed, reorganized, deleted, or used as cache/output destinations.

### Incremental discovery and stable identity
`asset_scanner.gd` discovers supported source files in deterministic sorted order. It records source-relative path, supported type, file size, modification time, and SHA-256 content hash. When path, size, modification time, and an existing hash match, unchanged files reuse the prior hash rather than being rehashed.

`asset_catalog.gd` reconciles observations to stable `asset_id` values. Same source/path retains identity. A changed path may retain identity only when one unmatched record in that same source uniquely matches the content signature. Ambiguous duplicate content remains separate. Missing prior records stay in the catalog with `missing: true` so existing world references do not silently retarget another file.

Exact-content duplicate groups are informational/query state only. No duplicate workflow deletes or merges source files.

### Analysis and managed import
`asset_analyzer.gd` performs safe structural preflight for GLTF, GLB, Godot text scenes, and Godot binary scenes. Corrupt input is retained as a failed-analysis catalog record and blocked before engine loading/placement.

`asset_importer.gd` creates derived copies only under project-managed `asset_library/imports`. GLTF local dependencies are copied into that managed import tree. Remote dependency URIs and dependency paths escaping the registered source root fail safely. Runtime GLTF/GLB generation and PackedScene loading occur from managed copies.

### Catalog metadata and thumbnails
`asset_record.gd` owns stable record validation. `asset_catalog.gd` persists favorites, collections, licensing/source fields, user metadata, analysis state, derived-import metadata, and thumbnail metadata to managed `catalog.json`.

`thumbnail_cache.gd` creates deterministic per-content thumbnail entries under `asset_library/thumbnails`. Cache keys include stable asset identity plus source content hash. When content changes, obsolete thumbnail entries for that asset are invalidated. Thumbnail/cache failure is recoverable and never writes to a source root.

### Browser and input
`src/app/workspace/asset_browser.gd` fills the existing Phase 1 Asset drawer rather than introducing an enterprise/dashboard shell. Large cards are the default density; compact density remains available. Browser queries support search, source/type/collection filtering, favorites, exact duplicate groups, read-only source/license details, rescans, and collection assignment.

Cards use native focusable buttons so keyboard/mouse and gamepad activation enter the same placement path. While the drawer owns focus, world D-pad transform input does not leak through. Existing Phase 3 controller mappings, including the left-shoulder tool wheel, remain intact.

### Placement handoff
`asset_placement_handoff.gd` is the boundary between catalog selection and the Phase 3 editor. It requires a valid stable `asset_id`, successful analysis, and successful managed scene instantiation. It then starts the existing Phase 3 ghost, carries `asset_id` on the ghost's `WorldEntity` record, and leaves commit to the existing command-backed placement function.

No authored entity exists and no dirty-state signal fires before commit. After commit, bridge rebuild resolves the same catalog asset ID to its real visual. Duplicate preserves `asset_id` while allocating a new entity UUID. Save/reopen retains the asset reference. A later missing source safely falls back to the generic runtime proxy.

## Persistence and crash safety
Custom editor persistence is versioned. `PlayWorldSafeJsonWriter` writes unique temporary candidates, flushes/closes them, parses and semantically validates them, and only then promotes them to canonical paths. Failed writes/promotions do not intentionally replace prior known-good files.

World checkpoints remain owned by `src/world`. Asset Library source/catalog documents are project-managed sibling data with their own validation and crash-safe JSON writes. Authored `WorldEntity.asset_id` references remain stable across project persistence/reopen and Asset Library restart.

## Streaming
Large worlds use partition cells. World objects declare owning cells and optional cross-cell relationships through stable IDs. Streaming must never depend on a parent node currently being loaded.

## Later-phase boundaries
Phase 4 intentionally does not implement prefab inheritance, component systems, named prefab sockets, terrain/streaming, or gameplay semantics. Those remain owned by later phases and must build on the stable asset/entity boundaries rather than be backfilled into the Asset Library.
