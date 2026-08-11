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
All mutations flow through commands. Examples: PlaceObject, DeleteObject, SetTransform, AddComponent, ChangeProperty, SculptTerrainStroke, GenerateScatter, ExecuteAIPlan. Commands produce inverse operations or snapshots as appropriate.

## Streaming
Large worlds use partition cells. World objects declare owning cell and optional cross-cell references through stable IDs. Streaming must never depend on parent node being currently loaded.

## Persistence
Use versioned JSON/resource metadata for editor-facing data and Godot resources/scenes where appropriate for runtime content. Every persisted structure carries schema/version information and migration path.
