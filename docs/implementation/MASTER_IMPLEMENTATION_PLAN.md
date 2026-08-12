# Master Implementation Plan

## Authoritative state
- The real project lives on `master`; repository default branch `main` is obsolete starter code and must not be used for development.
- Phase 16 authoritative base: `b4b5e88ef11ba514b1c8755e45e1a9de5cf04613`, the verified signed GitHub merge commit for PR #20.
- Phases 0 through 15 are historically merged, but Phase 16 source audit proved that several merged milestone claims were not fully integrated in the actual product.
- Phase 16 therefore became **Inherited Product Completeness and Integration Closure**, not release packaging.
- Phase 16 milestone branch: `dev/phase16-milestone`.

Historical `.polyforkAPI` credential material remains exposed in Git history and must be rotated/revoked separately. Never print, restore, copy, or reuse it.

## Phases 0–15 — HISTORICALLY MERGED
The repository includes the application shell, world/save foundation, placement editor, Asset Library, terrain/streaming, components/archetypes/prefabs/sockets, Instant Play/templates, Visual Scripting, foliage/procedural/splines, gameplay framework, Environment, AI Creation, project export, scale/polish, and multiplayer foundations.

Phase 16 does **not** treat those merge labels as proof of implementation completeness. The Phase 16 audit inspects and tests the actual source/runtime paths.

## Phase 16 — Inherited Product Completeness and Integration Closure

### Why this milestone replaced release packaging
A direct repository/source audit found concrete implementation gaps that canonical documentation had overstated or missed. Shipping/release packaging before closing those gaps would have packaged an incomplete creator.

### P16-T01 — Application creator routes and world creation — COMPLETE
- My Worlds, Templates, and Asset Library Home actions now open real surfaces.
- My Worlds uses the real project repository/open path.
- Templates uses the real template registry and New World selection path.
- New World now exposes and persists biome presets.
- initial terrain consumes the persisted biome selection.

### P16-T02 — Universal Asset Library closure — COMPLETE
- real application path uses a user-scoped universal managed catalog;
- legacy per-project source registrations can migrate to the shared catalog;
- semantic local ranking added;
- GLTF/GLB inspection deepened;
- placeholder hash thumbnails replaced by actual mesh-derived depiction with explicit fallback state;
- cross-project stable identity/source sharing is executable-tested.

### P16-T03 — Runtime placement editor closure — COMPLETE
- free-fly and orbit authoring cameras;
- drag marquee selection;
- visible transform-axis gizmo;
- real mesh vertex snapping;
- hit-normal orientation;
- authored Phase 6 socket-transform snapping;
- terrain/geometry-aware exact Drop-to-Ground;
- inherited XYZ grid-snapping contract retained for ordinary movement.

### P16-T04 — Template/gameplay integration closure — COMPLETE
- RPG consumes Phase 10 inventory/narrative runtime modules;
- Survival consumes Phase 10 inventory/health modules;
- Driving consumes the Phase 10 vehicle module;
- implemented runtime is no longer mislabeled as planned future functionality.

### P16-T05 — Environment water integration closure — COMPLETE
- real water-provider registry;
- project-owned basic water plane provider;
- imported PackedScene provider;
- transactional provider replacement and explicit non-destructive failure.

### P16-T06 — Focused verification — IMPLEMENTED
Repository-owned gates now cover:
- Phase 16 product contracts;
- Phase 16 integration-closure contracts;
- universal Asset Library cross-project contract;
- Godot Smoke.

Executed failures discovered during implementation were treated as product/test defects and repaired; they were not waived.

### P16-T07 — Inherited regression verification — IMPLEMENTED
`phase16-inherited-regressions.yml` executes discoverable Phase 4–15 suite runners plus Phase 7 playable and Phase 14 scale-stress runtime gates.

### P16-T08 — Windows/export evidence — IMPLEMENTED
`phase16-windows-export.yml` proves:
- Environment water-provider runtime dependency closure;
- clean standalone package launch;
- inherited Phase 14 profiled Windows exports;
- inherited Phase 15 concurrent host/client Windows export behavior.

### P16-T09 — Visual evidence — IMPLEMENTED
`phase16-visual.yml` captures actual running-app full/compact evidence for repaired Home creator routes, universal Asset Library, biome selection, and workspace authoring/gizmo state.

### P16-T10 — Documentation and completion PR — IN PROGRESS
Required closeout:
1. source-level QA record and implementation docs agree with actual code;
2. inspect all repository-owned Phase 16/inherited/Windows/visual checks on the live branch/PR head;
3. distinguish infrastructure setup failures from executed product failures;
4. open one Phase 16 completion PR targeting `master`;
5. do not merge without explicit user authorization.

## Deferred after Phase 16
Creator-application release packaging/distribution remains a future milestone. Also still out of current major-release scope: production matchmaking/relay/auth/voice/anti-cheat/rollback/dedicated-server fleets, production real-time collaborative mutation, cloud marketplace infrastructure, and arbitrary FBX repair.

## Architectural invariants retained
- existing `PlaySession` remains the disposable Build/Play boundary;
- authored mutation remains command/transaction owned with Undo/Redo;
- stable authored IDs remain authoritative;
- external Asset Library sources remain read-only;
- gameplay event/Visual Scripting boundaries are reused;
- project export architecture is reused;
- multiplayer remains opt-in and transient;
- no fake parallel editor/runtime was introduced.
