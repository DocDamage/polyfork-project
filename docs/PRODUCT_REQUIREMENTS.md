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
- Universal undo/redo for authored changes.

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
- Dedicated node workspace.
- Events, conditions, actions, variables, branching, timers/sequences as supported by the evolving node library, and reusable functions/macros.
- Custom GDScript node extensions remain possible.
- Graph validation and debugging.
- Graphs are serializable and versionable.
- Multiplayer score/objective requests and session/peer lifecycle integration must use the existing gameplay-event boundary rather than a second graph runtime.

### Prototype templates
Initial templates: Blank Sandbox, Third-Person Adventure, FPS, Survival, RPG, Driving, Walking Simulator. Additional templates are data-driven.

Templates may opt into a normalized multiplayer capability declaring enabled state, co-op/competitive mode, bounded player limits, spawn strategy/spacing, teams, score mode, and rejoin policy. Templates without that capability remain offline-compatible.

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

### Multiplayer Play
- Multiplayer is opt-in per template/project capability; offline single-player remains first-class.
- Supported runtime roles are Offline, Host, and Client/Join.
- Direct-connect transport uses project-owned Godot ENet integration with a versioned compatibility handshake.
- Authored entity/component/project IDs are never replaced by session or peer IDs.
- Host is authoritative for replicated gameplay mutations and runtime save authority.
- Remote players use existing first/third-person controller foundations with local input disabled; local player input remains enabled.
- Generic health/damage/heal and door/interaction state can converge through bounded host-authoritative replication.
- Match state supports deterministic membership, team assignment, spawn offsets/strategies, score, and objective state according to the declared capability.
- Disconnect, host termination, reconnect/rejoin, repeated Play start/stop, and cleanup must not mutate authored Build data.
- Phase 15 does not claim production matchmaking, relay/NAT traversal, account/auth service, voice chat, anti-cheat, rollback netcode, or dedicated-server orchestration.

### Collaborative authoring
- Gameplay networking is not the collaborative-editing protocol.
- Future collaboration must use durable author/session/operation identity, permission checks, command/history-aware operations, conflict handling, asset revisioning, presence, reconnect/rebase, and audit/history.
- The universal command/Undo model is the intended source for future collaboration operations.

### Export
- Project can be exported as a standalone Godot game.
- Exported game excludes editor-only UI and tooling.
- Runtime components and authored gameplay remain functional.
- Offline export dependency closure must omit Phase 15 networking runtime when multiplayer is disabled.
- Multiplayer-enabled exports include required networking runtime dependencies and generated `runtime_data/multiplayer_profile.json` capability metadata.
- Exported Windows verification for multiplayer-capable builds must be able to exercise real concurrent host/client processes.

## Non-functional requirements
- Balanced preset targets 60 FPS on RTX 3060-class desktop at 1080p in representative medium-world workloads; CI scale tests are regression proxies, not hardware FPS claims.
- Predictable degradation via Low/Balanced/High performance profiles rather than hard-coded assumptions.
- Autosave must be crash-resistant.
- Authoring operations must be deterministic enough for undo/redo and future collaboration.
- Files should remain modular; prefer <=300 LOC per code file where practical.
- No fake tests, stubs represented as complete features, or pass conditions that only verify that a function exists.
- Multiplayer tests must distinguish transport/setup infrastructure failures from actual executed contract/runtime failures.
