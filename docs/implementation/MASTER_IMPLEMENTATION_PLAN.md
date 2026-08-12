# Master Implementation Plan

## Authoritative state
- The real project lives on `master`; repository default branch `main` is obsolete starter code and must not be used for development.
- PR #19 — Phase 14 — Scale and Polish is merged.
- Authoritative `master`: `14085eb703b72d930f39121d3da18362d43cc77d`.
- This is the verified signed merge commit for PR #19.
- Phases 0 through 14 are complete and merged.
- Phase 15 — Multiplayer Foundations and Collaboration Roadmap is active on `dev/phase15-multiplayer-collaboration-milestone`, created from exactly authoritative Phase 14 `master`.

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
Schema-v1 graph persistence, command-backed authoring, deterministic compiler/interpreter, macros/functions, GraphEdit workspace, debugger/breakpoints/trace, and Phase 7 PlaySession execution. Merged by PR #13.

## Phase 9 — Foliage / Procedural / Splines — COMPLETE
Persistent nondestructive procedural sources, MultiMesh foliage, deterministic scatter/paint/erase, terrain/biome/streaming integration, stable-ID road/path/fence splines, authoring UX, and rendered evidence. Merged by PR #14.

## Phase 10 — Gameplay Framework Breadth — COMPLETE
Reusable runtime gameplay state, inventory/containers, doors, health, NPC AI, dialogue, quests, vehicles, explicit runtime save-state snapshots, Visual Scripting gameplay actions/events, Gameplay workspace, scale/regression/visual verification. Merged by PR #15.

## Phase 11 — Environment — COMPLETE
Schema-v1 environment persistence, time/weather, real Godot environment rendering, wind, biome overrides, water hooks, disposable Play runtime, Visual Scripting Environment nodes, Environment workspace, regression/visual verification. Merged by PR #16.

## Phase 12 — AI Creation — COMPLETE
Merged by PR #17. Delivered local/cloud OpenAI-compatible providers, explicit privacy/cloud consent, bounded read-only project/Asset Library queries, Suggest, zero-mutation Preview, Preview-before-Execute, local persistent IDs, proposal validation, missing-asset rejection, atomic cross-system Execute, rollback, one universal Undo/Redo entry, crash-safe AI history, cross-system authoring actions, native keyboard/mouse/gamepad AI workspace, and strict evidence/regressions.

Historical `.polyforkAPI` credential material remains exposed in Git history and must be rotated/revoked separately.

## Phase 13 — Export Pipeline — COMPLETE
Merged by PR #18 at `cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`.

Delivered deterministic export/build manifests, runtime dependency closure, editor stripping/runtime-data preservation, Asset Library dependency resolution, licensing/attribution reports, Windows standalone export, repeat-export replacement, clean-package launch, Small/Medium/Large verification, exported keyboard/mouse/gamepad checks, canonical Build → Export UX, and strict inherited/runtime/rendered evidence while reusing the Phase 7 `PlaySession`.

## Phase 14 — Scale and Polish — COMPLETE — MERGED
Merged by PR #19. Resulting verified signed authoritative `master`:

`14085eb703b72d930f39121d3da18362d43cc77d`

Architecture invariant retained: Phase 14 optimized and polished existing systems without introducing a replacement editor/runtime architecture or allowing quality policy to mutate authored project semantics.

Delivered:
- Low/Balanced/High deterministic performance profiles and explicit budgets;
- Small/Medium/Large/Stress benchmark fixtures and scale reports;
- terrain unchanged-target streaming fast path;
- incremental/no-op procedural streaming hardening;
- foliage visibility/shadow quality policy without authored scatter mutation;
- performance-aware Play streaming and Environment cadence with accumulated simulation delta;
- persistent user-only performance, UI-scale, reduced-motion, and density preferences;
- real Settings UI;
- application-wide focusability/minimum-target accessibility policy and visible focus styling;
- keyboard/gamepad input-context detection and consistent hints;
- adaptive full/compact Home, Settings, and workspace behavior;
- preserved dark playful Nintendo/Apple-inspired visual language;
- performance-aware Export integration;
- validated preset propagation through editor Play, procedural rendering policy, Windows export, standalone loading, and the existing Phase 7 `PlaySession`;
- dedicated contracts, scale stress, inherited regressions, Godot Smoke, rendered evidence, and Windows profiled export/launch verification.

Verified implementation head before documentation-only closeout: `b15439461cfae5d41d5951b5af808d20f2bb5f1b`.

## Phase 15 — Multiplayer Foundations and Collaboration Roadmap — ACTIVE
Milestone branch:

`dev/phase15-multiplayer-collaboration-milestone`

Created from exactly:

`14085eb703b72d930f39121d3da18362d43cc77d`

Detailed implementation plan:

`docs/implementation/PHASE15_MULTIPLAYER_COLLABORATION_PLAN.md`

### Phase 15 goals
- runtime-only network/session identity compatible with authored stable IDs;
- host-authoritative offline/host/client PlaySession modes;
- project-owned Godot 4.7.1 networking adapter with ENet host/join prototype path;
- two-peer co-op player spawn, ownership, presence, and movement replication through existing template/controller runtime;
- bounded host-authoritative replication for generic Phase 10 gameplay state;
- multiplayer capability declarations, player-count/team/spawn/session/score-objective hooks, and bounded Visual Scripting multiplayer events/actions;
- accessible Offline/Host/Join UX integrated into the existing Build → Play flow;
- robust join/leave/rejoin, host termination, save authority, identity validation, and teardown behavior;
- multiplayer-aware Phase 13/14 export closure plus Windows two-process host/client verification;
- a concrete future collaborative-authoring roadmap covering identity/permissions, operation/conflict model, asset sync, presence, history, security, reconnect, and hosted-service boundaries.

### Phase 15 scope guard
Phase 15 does not require production matchmaking, cloud relay/account services, NAT traversal infrastructure, voice chat, anti-cheat platform integration, rollback netcode, dedicated-server fleet orchestration, or real-time collaborative editor mutation.

### Internal checkpoints
P15-T01 through P15-T10 are defined in the Phase 15 plan and backlog. Work continuously on the milestone branch; do not create task-by-task PRs.

### Verification requirement
At completion, Phase 15 must pass dedicated identity/session, transport/lifecycle, replication/authority, templates/Visual Scripting, UX/accessibility/export contracts; deterministic two-peer runtime tests; join/leave/rejoin and host-failure paths; inherited Phase 6–14 regressions; Godot Smoke; rendered evidence; and Windows exported two-process host/client verification.

## Release rule
Work a phase continuously on its milestone branch. Intermediate commits and CI runs are expected; task-by-task PRs are not. At a milestone boundary, finish verification and documentation, then open one completion PR. Do not merge a completion PR without explicit user authorization, and do not start the next phase until the current completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.
