# Master Implementation Plan

## Authoritative state
- The real project lives on `master`; repository default branch `main` is obsolete starter code and must not be used for development.
- PR #18 — Phase 13 — Export Pipeline is merged.
- Authoritative `master`: `cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`.
- This is the verified signed merge commit for PR #18.
- Phases 0 through 13 are complete and merged.
- Phase 14 — Scale and Polish is implementation/verification complete and completion PR #19 is OPEN against authoritative `master`; it is not merged.
- Verified Phase 14 implementation head before documentation-only closeout: `b15439461cfae5d41d5951b5af808d20f2bb5f1b`.
- Phase 15 remains blocked until PR #19 is explicitly merged with user authorization and the resulting authoritative `master` SHA is verified.

## Phase 0 — Repository and contracts — COMPLETE
Project skeleton, coding rules, docs, CI, task IDs, test harness, canonical UI reference, stable IDs, command interface, persistence versioning, and module boundaries.

## Phase 1 — App shell and canonical UI foundation — COMPLETE
Home/New World, workspace shell, Build|Play, inspector, tool dock, Asset drawer, gamepad navigation, theme tokens, and rendered screenshot workflow.

## Phase 2 — World project + save foundation — COMPLETE
Small/Medium/Large projects, stable entity IDs, command/Undo/Redo, crash-safe saves, autosave/checkpoints, and recovery.

## Phase 3 — Runtime placement editor — COMPLETE
Selection, placement, transforms, duplicate/delete, multi-select/grouping, snapping, drop-to-ground, contextual controls, controller tool wheel, and rendered verification.

## Phase 4 — Universal Asset Library — COMPLETE
Read-only source registry, deterministic catalog/import analysis, metadata/licensing, thumbnails/search/favorites/collections, and placement handoff. Merged by PR #9.

## Phase 5 — Terrain + streaming — COMPLETE
Terrain sculpting, partition cells, dirty-cell persistence, deterministic streaming, biome hooks, and rendered verification. Merged by PR #10.

## Phase 6 — Components, archetypes, prefabs — COMPLETE
Versioned gameplay composition, archetypes, prefab inheritance/overrides, sockets/attachments, gameplay workspace, persistence/scale verification. Merged by PR #11.

## Phase 7 — Instant Play and templates — COMPLETE
Disposable Build → Play → Build lifecycle, semantic gameplay input, third-person/FPS foundations, seven starter templates, runtime-module resolution, persistence/performance/visual verification. Merged by PR #12.

## Phase 8 — Visual scripting — COMPLETE
Schema-v1 graph persistence, command-backed authoring, deterministic compiler/interpreter, macros/functions, GraphEdit workspace, debugger/breakpoints/trace, and Phase 7 PlaySession execution. Merged by PR #13 at `6ea437f3d5ea1077773ef797e8f5895e84b5a7f1`.

## Phase 9 — Foliage / Procedural / Splines — COMPLETE
Persistent nondestructive procedural sources, MultiMesh foliage, deterministic scatter/paint/erase, terrain/biome/streaming integration, stable-ID road/path/fence splines, authoring UX, and rendered evidence. Merged by PR #14 at `953d8b500beb1b65485104c85ab9bd5c4ff8224b`.

## Phase 10 — Gameplay Framework Breadth — COMPLETE
Reusable runtime gameplay state, inventory/containers, doors, health, NPC AI, dialogue, quests, vehicles, explicit runtime save-state snapshots, Visual Scripting gameplay actions/events, Gameplay workspace, scale/regression/visual verification. Merged by PR #15 at `ac2753f81c9c6be53abe89b102e1f9911a595944`.

## Phase 11 — Environment — COMPLETE
Schema-v1 environment persistence, time/weather, real Godot environment rendering, wind, biome overrides, water hooks, disposable Play runtime, Visual Scripting Environment nodes, Environment workspace, regression/visual verification. Merged by PR #16 at `d7245cad68b512fc5cbf9b897bce506ecbb9837d`.

## Phase 12 — AI Creation — COMPLETE
Merged by PR #17. Delivered local/cloud OpenAI-compatible providers, explicit privacy/cloud consent, bounded read-only project/Asset Library queries, Suggest, zero-mutation Preview, Preview-before-Execute, local persistent IDs, proposal validation, missing-asset rejection, atomic cross-system Execute, rollback, one universal Undo/Redo entry, crash-safe AI history, cross-system authoring actions, native keyboard/mouse/gamepad AI workspace, and strict evidence/regressions.

Historical `.polyforkAPI` credential material remains exposed in Git history and must be rotated/revoked separately.

## Phase 13 — Export Pipeline — COMPLETE — MERGED
Merged by PR #18. Resulting verified signed authoritative `master`:

`cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`

Delivered deterministic export/build manifests, runtime dependency closure, editor stripping/runtime-data preservation, Asset Library dependency resolution, licensing/attribution reports, Windows standalone export, repeat-export replacement, clean-package launch, Small/Medium/Large verification, exported keyboard/mouse/gamepad checks, canonical Build → Export UX, and strict inherited/runtime/rendered evidence while reusing the Phase 7 `PlaySession`.

## Phase 14 — Scale and Polish — COMPLETE / PR #19 OPEN — NOT MERGED
Phase 14 was developed continuously on `dev/phase14-scale-polish-milestone` from exactly authoritative Phase 13 `master`.

Architecture invariant retained: Phase 14 optimizes and polishes existing systems; it does not introduce a replacement editor/runtime architecture and does not permit quality policy to mutate authored project semantics.

Delivered Phase 14 outcomes:
- explicit Low/Balanced/High quality/performance policy with deterministic budgets;
- deterministic Small/Medium/Large/Stress benchmark fixtures and CI scale reports;
- terrain unchanged-target streaming fast path;
- incremental/no-op procedural streaming hardening;
- MultiMesh foliage visibility/shadow quality policy without authored scatter mutation;
- performance-aware Play streaming and Environment cadence with accumulated simulation delta;
- persistent user-only performance, UI-scale, reduced-motion, and density preferences;
- real Settings UI replacing the former Home placeholder;
- application-wide focusability/minimum-target accessibility policy and canonical visible focus styling;
- keyboard/gamepad input-context detection and consistent glyph/hint language;
- Home/Settings focus navigation and compact/adaptive layout behavior;
- compact workspace behavior and touch-ready interaction targets;
- canonical dark playful Nintendo/Apple-inspired visual parity preserved across new Phase 14 surfaces;
- effective preset inspection in Settings and Export;
- validated performance-profile propagation through editor Play, procedural rendering policy, Windows export, standalone loading, and the existing Phase 7 `PlaySession`;
- backward-compatible Balanced fallback for legacy packages without a packaged profile;
- dedicated Phase 14 contracts, scale stress, inherited Phase 6–13 regressions, Godot Smoke, rendered evidence, and real Windows profiled export/clean-package launch verification.

Verified green on implementation head `b15439461cfae5d41d5951b5af808d20f2bb5f1b`:
- Phase 14 Contracts — `31626516078`;
- Phase 14 Scale Stress — `31626516104`;
- Phase 14 Inherited Regressions — `31626516105`;
- Godot Smoke — `31626516120`;
- Phase 14 Visual Evidence — `31626516053`;
- Phase 14 Windows Export — `31626516187`.

The Windows gate launched Small/Low, Medium/Balanced, and Large/High clean packages, verified keyboard/mouse plus gamepad semantic input, reused the third-person Phase 7 controller, and passed repeat-export stale-file replacement.

All P14-T01 through P14-T10 checkpoints are complete. Completion PR #19 is open from `dev/phase14-scale-polish-milestone` to authoritative `master` and must not be merged without explicit user authorization.

## Phase 15 — Multiplayer foundations and collaboration roadmap — BLOCKED
Potential later scope:
- Network identity compatibility.
- Co-op prototype support.
- Competitive template hooks.
- Collaboration design; implementation may be deferred.

Do not begin Phase 15 until PR #19 is explicitly merged and the resulting authoritative `master` SHA is verified.

## Release rule
Work a phase continuously on its milestone branch. Intermediate commits and CI runs are expected; task-by-task PRs are not. At a milestone boundary, finish verification and documentation, then open one completion PR. Do not merge a completion PR without explicit user authorization, and do not start the next phase until the current completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.
