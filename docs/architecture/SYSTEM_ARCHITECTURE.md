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
Every world object, prefab, component instance, graph, asset registry entry, terrain cell, procedural generator, and transaction receives a stable UUID. Never use scene-tree paths as persistent identity.

## Commands
All authored mutations flow through commands. Examples: PlaceObject, DeleteObject, SetTransform, AddComponent, ChangeProperty, SculptTerrainStroke, GenerateScatter, ExecuteAIPlan. Gameplay-specific commands are implemented by the owning feature module on top of the generic command contract.

A command exposes deterministic `execute()` and `undo()` operations. Returning `false` means the requested operation did not commit; a failed command must leave authored state unchanged or restore its own partial work before returning. Commands surface recoverable failure details through their command error message instead of relying on scene-tree identity or editor-only node paths.

Commands may be grouped into a transaction. Each transaction receives a stable UUID, executes its commands in order, and becomes exactly one undoable history entry only after every command succeeds. If a later command fails, the transaction rolls back already-applied commands in reverse order. Undo reverses a committed transaction in reverse command order; redo executes it again in forward order. If an undo operation itself fails after earlier commands were reversed, the transaction attempts to restore those earlier commands so history is not advanced from a partially reversed entry.

The command history owns bounded undo and redo stacks. A successful new edit after an undo clears the redo stack. Failed execution, undo, or redo attempts do not advance the corresponding history stacks. P02-T05 history is in-memory editor infrastructure; crash-safe autosave/checkpoint persistence is a separate Phase 2 responsibility.

## Streaming
Large worlds use partition cells. World objects declare owning cell and optional cross-cell references through stable IDs. Streaming must never depend on parent node being currently loaded.

## Persistence
Use versioned JSON/resource metadata for editor-facing data and Godot resources/scenes where appropriate for runtime content. Every persisted structure carries schema/version information and migration path.
