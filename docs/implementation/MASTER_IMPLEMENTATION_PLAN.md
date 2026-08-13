# Master Implementation Plan

## Authoritative state
- The real project lives on `master`; repository default branch `main` is obsolete starter code and must not be used for development.
- Authoritative `master`: `b4b5e88ef11ba514b1c8755e45e1a9de5cf04613`, the verified signed GitHub merge commit for PR #20 / Phase 15.
- Phases 0 through 15 are historically merged, but the Phase 16 source audit proved that several earlier milestone claims were not fully integrated in the actual product.
- Phase 16 therefore became **Inherited Product Completeness and Integration Closure**, not release packaging.
- Phase 16 milestone branch: `dev/phase16-milestone`.
- Verified Phase 16 implementation/evidence head: `bfdef3e5cb1699268cc23be5c9f4c9b4a9631f93`.

Historical `.polyforkAPI` credential material remains exposed in Git history and must be rotated/revoked separately. Never print, restore, copy, or reuse it.

## Phases 0–15 — HISTORICALLY MERGED
The repository includes the application shell, world/save foundation, placement editor, Asset Library, terrain/streaming, components/archetypes/prefabs/sockets, Instant Play/templates, Visual Scripting, foliage/procedural/splines, gameplay framework, Environment, AI Creation, project export, scale/polish, and multiplayer foundations.

Phase 16 does **not** treat those merge labels as proof of implementation completeness. The Phase 16 audit inspected and tested actual source/runtime paths and repaired the verified gaps.

## Phase 16 — Inherited Product Completeness and Integration Closure — BRANCH VERIFIED

### Why this milestone replaced release packaging
A direct repository/source audit found concrete implementation gaps that canonical documentation had overstated or missed. Shipping/release packaging before closing those gaps would have packaged an incomplete creator.

### P16-T01 — Application creator routes and world creation — COMPLETE
- My Worlds, Templates, and Asset Library Home actions open real creator surfaces.
- My Worlds uses the real project repository/open path.
- Templates uses the real template registry and New World selection path.
- New World exposes and persists biome presets.
- Initial terrain consumes the persisted biome selection.

### P16-T02 — Universal Asset Library closure — COMPLETE
- real application path uses a user-scoped universal managed catalog;
- legacy per-project source registrations migrate to the shared catalog;
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

### P16-T06 — Focused verification — VERIFIED
- Phase 16 Contracts — `31653938946` — PASS;
- Phase 16 Shared Asset Library — `31653938953` — PASS;
- Godot Smoke — `31653938984` — PASS.

### P16-T07 — Inherited regression verification — VERIFIED
- Phase 16 Inherited Regressions — `31653938981` — PASS.
- The matrix executes discoverable Phase 4–15 suites, with Phase 4/5 independently covered by Godot Smoke where no standalone phase runner exists.
- The stale Phase 11 metadata-only water fixture was promoted to the real `basic_plane` provider rather than weakening provider validation.

### P16-T08 — Windows/export evidence — VERIFIED
- Phase 16 Windows Export — `31653938952` — PASS.
- Verified Environment water-provider dependency closure and clean package launch.
- Re-ran inherited Phase 14 Small/Medium/Large profiled Windows exports.
- Rebuilt inherited Phase 15 multiplayer/offline packages and launched the exported host/client concurrently with ownership/input assertions.

### P16-T09 — Visual evidence — VERIFIED
- Phase 16 Visual Evidence — `31653938948` — PASS.
- Captures actual running-app full/compact evidence for repaired Home creator routes, universal Asset Library, biome selection, and workspace authoring/gizmo state.

### P16-T10 — Documentation and completion PR — READY
Canonical QA/implementation/handoff/backlog documentation now reflects the source-verified milestone. The only remaining milestone-boundary action is one completion PR from `dev/phase16-milestone` to authoritative `master`, followed by review of the PR-triggered checks.

Do not merge the completion PR without explicit user authorization.

## Deferred after Phase 16
Creator-application release packaging/distribution remains a future milestone and is not authorized until the Phase 16 completion PR is merged and authoritative `master` is reconciled. Also still outside the current major-release scope: production matchmaking/relay/auth/voice/anti-cheat/rollback/dedicated-server fleets, production real-time collaborative mutation, cloud marketplace infrastructure, and arbitrary FBX repair.

## Architectural invariants retained
- existing `PlaySession` remains the disposable Build/Play boundary;
- authored mutation remains command/transaction owned with Undo/Redo;
- stable authored IDs remain authoritative;
- external Asset Library sources remain read-only;
- gameplay event/Visual Scripting boundaries are reused;
- project export architecture is reused;
- multiplayer remains opt-in and transient;
- no fake parallel editor/runtime was introduced.
