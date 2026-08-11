# System Architecture

## Architectural rule
The editor core operates on generic entities, assets, terrain cells, components, archetypes, prefabs, properties, graphs, transactions, resources, and stable IDs. It does not hard-code gameplay semantics such as "door", "enemy", or "car" into the scene editor.

Persistent relationships use stable UUIDs. Scene-tree paths, node names, filesystem paths, and array positions are runtime/location metadata only.

## Major modules
1. App Shell
2. Project/World Manager
3. Runtime Editor
4. Command + Transaction/Undo System
5. Asset Registry / Import / Thumbnail Pipeline
6. Terrain + World Partition
7. World Streaming
8. Entity/Component Runtime
9. Archetype + Prefab System
10. Visual Script Runtime + Editor
11. Foliage/Scatter
12. Spline/Road
13. Environment/Weather
14. Save/Serialization
15. Template System
16. AI Orchestrator
17. Export Pipeline
18. Input Abstraction
19. Diagnostics/Performance
20. Future Networking/Collaboration

## Commands and authored mutation
All authored mutations flow through reversible commands or transactions. Failed execution/undo/redo does not advance history. Persistence observes authored state; preview-only state does not dirty authored data.

Phase 3 entity placement/transforms and Phase 5 terrain sculpt/biome changes share the same editor command history. This means the global Undo/Redo path can restore entity transforms, entity owning cells, terrain height fields, and biome assignment without a second competing history stack.

## Runtime entity editor
`src/editor/editor_session.gd` coordinates project state, command history, selection, placement ghost, snapping, transform editing, and the dirty callback.

`src/editor/runtime_entity_bridge.gd` validates the complete persisted entity set before creating runtime nodes. In Large streamed worlds it may instantiate only entities whose stable `cell_id` is active. References are still validated against the full project record set, including unloaded entities.

A loaded child whose valid parent is temporarily unloaded attaches at the bridge root for runtime presentation. Its persisted `parent_entity_id` is never rewritten. A failed filtered rebuild preserves the previous known-good runtime mapping.

Placement ghosts and cross-cell move commands use the Phase 5 cell resolver. Moving/placing an entity across a partition boundary updates its transform and stable owning `cell_id` in the same reversible command; Undo/Redo restores both together.

## Universal Asset Library
Phase 4 remains owned by `src/assets`. External registered asset folders are strictly read-only. Derived imports, catalog metadata, licensing, favorites, collections, duplicate metadata, and thumbnails live under project-managed `asset_library/` storage.

Catalog selection still enters the Phase 3 placement ghost and `PlaceEntityCommand`. Terrain does not change Asset Library identity or source-folder guarantees.

## Phase 5 terrain + partition architecture
Phase 5 is owned primarily by `src/terrain`.

### Persistence/state boundary
`terrain_schema.gd` validates versioned terrain manifest, terrain cell, and biome registry documents.

`terrain_repository.gd` owns `<project>/terrain` storage. Terrain heights are persisted per cell rather than embedded in `project.json`, allowing one dirty cell to be saved without rewriting every terrain cell. `terrain_world_state.gd` is the in-memory canonical terrain state and tracks dirty/recovered cells.

Terrain cells are not ordinary placed `WorldEntity` records. They have their own schema and stable cell identity. Existing world entities continue to reference their owning cell through `WorldEntity.cell_id`.

### Profile topology
`world_partition.gd` derives deterministic centered topology from the existing world profile:
- Small: 1×1 1024m cell, non-streaming (~1 km²)
- Medium: 3×3 1024m cells, non-streaming (~9 km²)
- Large: 5×5 1024m cells, streamed (~25 km²)

The first pre-existing valid project cell ID is retained as the centered origin cell. Additional cells receive stable UUIDs. Position-to-cell resolution is deterministic.

### Runtime terrain
`terrain_mesh_builder.gd` deterministically converts the cell height array into a 17×17 grid mesh with UVs and generated normals.

`terrain_chunk_node.gd` owns each runtime mesh/collision chunk and biome material presentation. Runtime chunk nodes are disposable; the stable cell record is authoritative.

`terrain_runtime.gd` owns loaded chunks and refreshes only the affected runtime cell after sculpt/biome edits.

### Sculpting and biomes
`terrain_brush.gd` implements raise, lower, smooth, and flatten behavior over a radial falloff.

`terrain_sculpt_command.gd` captures before/after cell height state and revision. `terrain_biome_command.gd` changes the stable biome reference. Both mark their cell dirty, refresh runtime presentation, and use the shared command history.

Biome records are data-driven rule hooks: stable ID, display name, color, terrain material slots, and null future foliage/environment profile hooks. Phase 5 does not implement Phase 9 foliage scatter or Phase 11 weather/environment systems.

### Streaming
`terrain_streaming_policy.gd` returns deterministic active cell IDs. Small/Medium keep all cells active. Large uses a bounded radius-one cell set around the focus position.

`terrain_runtime.gd` refuses to unload a dirty cell that has not been safely persisted. After `terrain_repository.gd` successfully promotes the dirty cell, the next streaming update may unload it.

`terrain_controller.gd` coordinates repository/state/runtime/editor history, binds the entity cell resolver, synchronizes Large-world entity filtering, and performs incremental terrain autosave.

## Terrain workspace
`terrain_workspace_layer.gd` and `terrain_tool_panel.gd` add a compact contextual Terrain workflow to the existing workspace instead of a dashboard redesign.

Mouse clicking terrain can sculpt directly. Keyboard arrows/D-pad move the brush cursor; Enter/A applies; right shoulder cycles brush mode. Left shoulder remains the existing Phase 3 tool wheel. Terrain mode hides object-specific toolbars, preserves the Phase 4 Asset Library, and uses the canonical dark/playful Nintendo-forward / Apple-clean visual language.

## Crash safety
`PlayWorldSafeJsonWriter` remains the atomic JSON primitive: write temporary candidate, flush/close, parse, semantically validate, then promote.

Before rewriting a terrain cell, `terrain_repository.gd` writes the previous validated canonical cell to `<project>/terrain/recovery/<cell-id>.json`. A corrupt canonical cell can reopen from that known-good recovery record without silently replacing the corrupt file. Missing/corrupt canonical data with no valid recovery fails closed. A failed promotion leaves the previous canonical file untouched and keeps the cell dirty for retry.

## Performance boundary
The automated Phase 5 scale regression exercises nine Medium chunks, the Large streamed 3×3 active set, deterministic triangle counts, and repeated terrain brush operations under a generous CI time budget. This is a behavioral/performance regression proxy, not a fabricated RTX 3060 benchmark. The documented 1080p/60 FPS RTX 3060-class target remains a hardware performance target for later release-scale validation.

## Later-phase boundaries
Phase 5 does not implement component/prefab authoring, named prefab sockets, foliage/scatter, roads/splines, full environment/weather, gameplay semantics, or export stripping. Those remain later-phase responsibilities built on the stable entity/asset/terrain boundaries above.
