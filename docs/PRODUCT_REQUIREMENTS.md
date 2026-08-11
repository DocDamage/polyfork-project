# Product Requirements

## Functional requirements

### World creation
- New World screen offers Small (1–2 km²), Medium (4–16 km²), and Large (streamed, 16+ km² starting profile).
- World size choice is made before terrain creation.
- Terrain is sculptable at runtime.
- Large worlds are partitioned into streamable cells/chunks.
- Optional biome presets configure terrain material sets, foliage rules, sky/environment, and procedural defaults.

### Runtime editor
- Free-fly camera and third-person authoring camera, switchable instantly.
- Build and Play modes operate in the same loaded world.
- Selection, box-selection, multi-select, groups, parenting, duplicate, delete.
- Move/rotate/scale gizmos.
- Grid, angle, surface, normal, object, vertex/socket snapping.
- Drop-to-ground.
- Random rotation/scale.
- Scatter/paint/erase/replace tools.
- Universal undo/redo.

### Asset library
- Register multiple external folders anywhere on disk.
- Never mutate original source folders.
- Index GLB/GLTF and Godot scenes first; extensible adapters for FBX, OBJ, textures, audio, and animations.
- Generate stable IDs, hashes, thumbnails, dimensions, material/texture info, animation metadata, skeleton info, LOD/collision status, memory estimates, source/license metadata.
- Duplicate detection.
- Search, semantic search, filters, tags, favorites, collections, custom categories.
- Large-card default view with density toggle.

### Gameplay object model
- Any placed object can stay scenery or become a gameplay object.
- Reusable components are composable.
- Archetypes bundle expected components and defaults.
- Prefabs save reusable configured objects.
- Prefab inheritance supports base/derived relationships and overrides.
- Sockets/attachment points support vehicles, weapons, handles, seats, mounts, lights, loot, and custom extension points.

### Visual scripting
- Full-screen node workspace.
- Events, conditions, actions, variables, branching, timers, sequences, reusable functions/macros.
- Custom GDScript node extensions.
- Graph validation and debugging.
- Graphs are serializable and versionable.

### Prototype templates
Initial templates: Blank Sandbox, Third-Person Adventure, FPS, Survival, RPG, Driving, Walking Simulator. Additional templates are data-driven.

### AI assistance
- Provider-agnostic adapter layer: cloud and local providers.
- AI can query the actual local asset catalog.
- Modes: Suggest, Preview, Execute.
- AI edits run as transactions so one Undo can revert the complete command.
- AI may not silently invent unavailable assets when fulfilling asset-based build requests.

### Environment and world systems
- Day/night.
- Weather profiles.
- Fog/wind/environment profiles.
- Water integration layer supporting owned/imported water assets and future procedural water tools.
- Foliage is a dedicated instanced system, not ordinary object spam.
- Biomes are rule sets, not baked art dependencies.

### Export
- Project can be exported as a standalone Godot game.
- Exported game excludes editor-only UI and tooling.
- Runtime components and authored gameplay remain functional.

## Non-functional requirements
- 60 FPS target on RTX 3060-class desktop at 1080p using the standard preset in representative medium worlds.
- Predictable degradation via quality presets rather than hard-coded assumptions.
- Autosave must be crash-resistant.
- Authoring operations must be deterministic enough for undo/redo and future collaboration.
- Files should remain modular; prefer <=300 LOC per code file where practical.
- No fake tests, stubs represented as complete features, or pass conditions that only verify that a function exists.
