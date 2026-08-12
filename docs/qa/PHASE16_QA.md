# Phase 16 QA — Inherited Product Completeness and Integration Closure

## Purpose
Phase 16 was redirected after a source-level audit showed that merged documentation overstated the functional completeness of several earlier milestones. This QA record is based on actual implementation paths and executable evidence, not phase labels alone.

## Source-level defects closed

### Application shell / creator routes
- Home `My Worlds`, `Templates`, and `Asset Library` actions now open real creator surfaces instead of emitting unhandled route signals.
- My Worlds uses the real `ProjectRepository` and existing Main activation path.
- Templates uses the real `TemplateRegistry` and presets New World.
- Asset Library can be opened before a project exists.

### World creation / terrain
- New World exposes Meadow, Desert, and Alpine starting biome presets.
- `biome_preset` is persisted into project runtime configuration before activation.
- Newly created terrain applies the persisted starting biome to its initial cells.

### Universal Asset Library
- the application path uses one user-scoped managed catalog instead of a separate catalog per project;
- legacy per-project source registrations can be migrated into the shared catalog;
- external source files remain read-only;
- semantic-style deterministic local ranking supplements exact search;
- GLTF/GLB inspection includes real counts, names, bounds/dimensions, collision/LOD hints, and memory/source estimates;
- thumbnails are generated from actual imported mesh geometry when depiction is possible;
- fallback thumbnails are explicitly labeled as fallbacks and are not represented as asset depictions.

### Runtime placement editor
- authoring viewport supports free-fly and orbit/third-person-style authoring cameras;
- drag marquee selection selects runtime entities through the existing editor session;
- selected transform tools have a visible XYZ gizmo;
- vertex snapping consumes actual mesh vertices;
- surface snapping consumes hit normals for orientation;
- socket snapping consumes authored Phase 6 socket transforms when the gameplay service is bound;
- Drop-to-Ground consumes the terrain runtime height and actual runtime mesh bounds;
- Drop-to-Ground performs an exact command-backed translation rather than allowing grid quantization to move the object back off the surface;
- ordinary movement retains the inherited full XYZ grid-snapping contract.

### Template integration
- RPG requires the implemented Phase 10 inventory/narrative runtime modules;
- Survival requires implemented inventory/health runtime modules;
- Driving requires the implemented vehicle runtime module;
- implemented systems are no longer mislabeled as future `planned_modules`.

### Environment water
- authored water hooks are consumed by a real runtime provider registry;
- `basic_plane` produces a project-owned water surface;
- `imported_scene` instantiates an authored/imported `PackedScene` provider;
- provider changes are staged transactionally;
- an invalid provider fails explicitly without destroying the previous valid water runtime.

## Phase 16 evidence gates

### Phase 16 Contracts
Required suites:
- `product`: real Home routes, biome emission, semantic ranking, real mesh-derived thumbnail;
- `integration`: promoted template capabilities, vertex/normal snapping, authored socket transform use, terrain-aware grounding, basic/imported water providers and failure atomicity.

### Shared Asset Library
A separate cross-project contract proves that two projects resolve the same user-scoped managed catalog, retain the same stable asset ID, share source registration, and never mutate the external source file.

### Inherited regressions
`phase16-inherited-regressions.yml` dynamically executes every discoverable Phase 4–15 suite runner plus the Phase 7 playable smoke and Phase 14 Small/Medium/Large/Stress runtime gate. Godot Smoke remains an independent strict parser/runtime gate.

### Windows / export
`phase16-windows-export.yml` must:
1. prove the new Environment water provider runtime is present in standalone dependency closure;
2. copy and launch a clean Phase 16 standalone package;
3. rerun the inherited Phase 14 profiled Small/Medium/Large Windows export gate;
4. rerun the inherited Phase 15 real concurrent Windows host/client export gate.

Phase 16 does not change the user-project export architecture and does not package PlayWorld Studio itself; creator-app release distribution remains a later milestone.

### Visual evidence
`phase16-visual.yml` captures the actual running application at full and compact layouts for:
- My Worlds;
- Templates;
- universal Asset Library;
- New World biome selection;
- workspace selection/gizmo/orbit authoring state.

The canonical dark playful Nintendo/Apple visual language remains mandatory.

## CI interpretation
As in Phase 15, a Godot download/setup failure before tests execute is infrastructure failure, not product failure. Executed test failures remain authoritative and must be repaired rather than waived. Third-party GitHub App suites remain distinct from Polyfork-owned GitHub Actions.

## Remaining explicit non-goals
The following remain outside the current major-release scope and are not treated as inherited defects:
- production matchmaking/relay/NAT traversal/account/auth infrastructure;
- voice chat, anti-cheat, rollback netcode, dedicated-server fleets;
- production real-time collaborative editor mutation;
- fully automatic arbitrary FBX repair;
- cloud marketplace/asset hosting;
- creator-application release packaging, code signing, updater infrastructure, macOS/Linux release packages.

## Security reminder
Historical `.polyforkAPI` credential material remains exposed in Git history. Do not print, restore, copy, or reuse it. Rotation/revocation remains an external action.
