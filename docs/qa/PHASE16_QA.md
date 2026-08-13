# Phase 16 QA — Inherited Product Completeness and Integration Closure

## Status
**Branch implementation and required executable evidence are complete and passing.**

Authoritative base: `master` `b4b5e88ef11ba514b1c8755e45e1a9de5cf04613`.

Verified implementation/evidence head: `bfdef3e5cb1699268cc23be5c9f4c9b4a9631f93`.

Phase 16 was redirected after a source-level audit showed that merged documentation overstated the functional completeness of several earlier milestones. This QA record is based on actual implementation paths and executable evidence, not phase labels alone.

## Source-level defects closed

### Application shell / creator routes
- Home `My Worlds`, `Templates`, and `Asset Library` actions open real creator surfaces instead of emitting unhandled route signals.
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
- deterministic local concept/synonym ranking supplements exact search;
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
- Drop-to-Ground consumes terrain runtime height and actual runtime mesh bounds;
- Drop-to-Ground performs an exact command-backed translation rather than allowing grid quantization to move the object back off the surface;
- ordinary movement retains the inherited full XYZ grid-snapping contract.

### Template integration
- RPG requires implemented Phase 10 inventory/narrative runtime modules;
- Survival requires implemented inventory/health runtime modules;
- Driving requires implemented vehicle runtime;
- implemented systems are no longer mislabeled as future `planned_modules`.

### Environment water
- authored water hooks are consumed by a real runtime provider registry;
- `basic_plane` produces a project-owned water surface;
- `imported_scene` instantiates an authored/imported `PackedScene` provider;
- provider changes are staged transactionally;
- an invalid provider fails explicitly without destroying the previous valid water runtime.

## Executable evidence — PASS
- Phase 16 Contracts — run `31653938946`
- Phase 16 Shared Asset Library — run `31653938953`
- Godot Smoke — run `31653938984`
- Phase 16 Visual Evidence — run `31653938948`
- Phase 16 Inherited Regressions — run `31653938981`
- Phase 16 Windows Export — run `31653938952`

### Focused contracts
`product` verifies real Home routes, biome emission, semantic ranking, and real mesh-derived thumbnail behavior.

`integration` verifies promoted template capabilities, vertex/normal snapping, authored socket transform use, terrain-aware exact grounding, basic/imported water providers, and provider-failure atomicity.

### Shared Asset Library
The cross-project contract proves two projects resolve the same user-scoped managed catalog, retain the same stable asset ID, share source registration, and do not mutate the external source file.

### Inherited regressions
`phase16-inherited-regressions.yml` executes discoverable Phase 4–15 suites plus relevant playable/scale runtime gates. Phase 4/5 remain independently covered by strict Godot Smoke where no dedicated phase runner exists.

The old Phase 11 coupling fixture used a fake metadata-only `test.water` provider. It was updated to the real supported `basic_plane` provider and now also proves materialization. Production unknown-provider rejection remains strict and is separately tested by Phase 16.

### Windows / export
The Phase 16 Windows workflow passed all of the following:
1. Environment water-provider runtime dependency closure;
2. clean Phase 16 standalone package launch;
3. inherited Phase 14 Small/Medium/Large profiled Windows export and clean-package launches;
4. inherited Phase 15 multiplayer/offline package verification;
5. real concurrent exported Windows host/client connection with expected ownership/input markers.

Phase 16 does not change user-project export architecture and does not package PlayWorld Studio itself; creator-app release distribution remains a later milestone.

### Visual evidence
The real running application was captured at full and compact layouts for My Worlds, Templates, universal Asset Library, New World biome selection, and workspace selection/gizmo/orbit authoring state. The canonical dark playful Nintendo/Apple visual language remains mandatory.

## CI interpretation
Godot download/setup failure before tests execute is infrastructure failure, not product failure. Executed test failures remain authoritative and must be repaired rather than waived. Third-party GitHub App suites remain distinct from Polyfork-owned GitHub Actions.

## Remaining explicit non-goals
- production matchmaking/relay/NAT traversal/account/auth infrastructure;
- voice chat, anti-cheat, rollback netcode, dedicated-server fleets;
- production real-time collaborative editor mutation;
- fully automatic arbitrary FBX repair;
- cloud marketplace/asset hosting;
- creator-application release packaging, code signing, updater infrastructure, macOS/Linux release packages.

## Security reminder
Historical `.polyforkAPI` credential material remains exposed in Git history. Do not print, restore, copy, or reuse it. Rotation/revocation remains an external action.
