# System Architecture

## Architectural rule
The editor must not hard-code world semantics such as "door", "car", or "enemy" into the core scene editor. The core understands **entities, components, archetypes, prefabs, properties, events, graphs, resources, transactions, and IDs**. Gameplay meaning is assembled above those primitives.

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

## Data boundaries
Editor metadata must be separable from runtime game data. Export builds strip editor-only metadata where possible while preserving gameplay state and authored resources.

## IDs
Every world object, prefab, component instance, graph, asset registry entry, terrain cell, procedural generator, transaction, and retained checkpoint receives a stable UUID. Never use scene-tree paths as persistent identity.

## Commands
All authored mutations flow through commands. Examples: PlaceObject, DeleteObject, SetTransform, AddComponent, ChangeProperty, SculptTerrainStroke, GenerateScatter, ExecuteAIPlan. Gameplay-specific commands are implemented by the owning feature module on top of the generic command contract.

A command exposes deterministic `execute()` and `undo()` operations. Returning `false` means the requested operation did not commit; a failed command must leave authored state unchanged or restore its own partial work before returning. Commands surface recoverable failure details through their command error message instead of relying on scene-tree identity or editor-only node paths.

Commands may be grouped into a transaction. Each transaction receives a stable UUID, executes its commands in order, and becomes exactly one undoable history entry only after every command succeeds. If a later command fails, the transaction rolls back already-applied commands in reverse order. Undo reverses a committed transaction in reverse command order; redo executes it again in forward order. If an undo operation itself fails after earlier commands were reversed, the transaction attempts to restore those earlier commands so history is not advanced from a partially reversed entry.

The command history owns bounded undo and redo stacks. A successful new edit after an undo clears the redo stack. Failed execution, undo, or redo attempts do not advance the corresponding history stacks. Command history is in-memory editor infrastructure; persistence observes authored state rather than becoming an authoring mutation.

## Runtime entity scene bridge and selection
`src/editor/runtime_entity_node.gd` is the generic runtime `Node3D` wrapper for a persisted `WorldEntity`. It copies the stable entity UUID into runtime metadata and applies persisted position, rotation, and scale. The wrapper is an anchor for later asset/prefab scene content; P03-T01 does not invent asset loading before the asset-library phase exists.

`src/editor/runtime_entity_bridge.gd` rebuilds the runtime entity hierarchy from validated entity records. Runtime node names and tree locations are disposable implementation details; lookup and parent relationships are resolved only through stable entity IDs. The bridge rejects duplicate IDs, unresolved parents, self-parenting, and parent cycles. A rejected rebuild leaves the previous known-good runtime mapping intact.

The bridge can resolve any descendant runtime node back to the owning stable entity ID by walking runtime metadata. This gives future raycast/picking code a stable boundary without persisting scene-tree paths.

`src/editor/single_selection.gd` owns exactly one editor selection at a time. Selection may be requested by stable entity ID or by a descendant runtime node resolved through the bridge. Switching selection clears the prior runtime selected state; invalid selection attempts preserve the current selection. Selection state is editor-only and does not mutate persistent project data, enter command history, or mark the project dirty.

The workspace binds this selection model to the existing right inspector. Selecting a bridged entity shows its display name, stable identity, ownership cell, parent reference, and persisted transform values. Closing the inspector clears entity selection. P03-T01 intentionally does not implement placement, ghost preview, transform authoring, duplicate/delete, multi-select, snapping, or gameplay-specific semantics.

## Streaming
Large worlds use partition cells. World objects declare owning cell and optional cross-cell references through stable IDs. Streaming must never depend on parent node being currently loaded.

## Persistence
Use versioned JSON/resource metadata for editor-facing data and Godot resources/scenes where appropriate for runtime content. Every persisted structure carries schema/version information and migration responsibility.

P02-T06 centralizes crash-safe JSON promotion in `PlayWorldSafeJsonWriter`. Canonical project manifests and checkpoints are serialized to unique temporary files, flushed and closed, parsed back, semantically validated, and only then promoted to the requested final path. A failed write or failed promotion removes the temporary candidate and leaves the prior canonical file untouched.

Project checkpoints are owned by `src/world`, stored under the stable project directory, and represented by versioned `world_checkpoint` documents. Each retained checkpoint has its own stable UUID, the owning `project_id`, a millisecond creation timestamp, and a validated `WorldProject` snapshot. Checkpoint retention is bounded and deterministic; pruning occurs only after a newer checkpoint has been successfully written and validated.

Recovery inspection distinguishes a valid newer checkpoint from corrupted checkpoint data, unsupported checkpoint schemas, incomplete temporary writes, older/equal checkpoints, and missing checkpoints. Recovery never replaces canonical project state until the selected checkpoint has been loaded and validated and the normal crash-safe project-save path succeeds.

`PlayWorldAutosaveService` coordinates checkpoint timing separately from UI and repository internals. It requires an explicit dirty signal, does not rewrite unchanged projects simply because its timer elapsed, and clears dirty state only after checkpoint creation succeeds. This is intentionally compatible with future command-driven dirty tracking without introducing Phase 3 authoring commands.
