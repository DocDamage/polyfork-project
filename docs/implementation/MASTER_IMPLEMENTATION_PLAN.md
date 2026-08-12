# Master Implementation Plan

## Authoritative state
- The real project lives on `master`; repository default branch `main` is obsolete starter code and must not be used for development.
- PR #19 — Phase 14 — Scale and Polish is merged.
- Authoritative `master`: `14085eb703b72d930f39121d3da18362d43cc77d`.
- This is the verified signed merge commit for PR #19.
- Phases 0 through 14 are complete and merged.
- Phase 15 — Multiplayer Foundations and Collaboration Roadmap is **implementation complete / PR ready** on `dev/phase15-multiplayer-collaboration-milestone`.
- Phase 15 is not merged yet. Phase 16 remains blocked.

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
Disposable Build → Play → Build lifecycle, semantic gameplay input, third-person/FPS foundations, starter templates, runtime-module resolution, persistence/performance/visual verification. Merged by PR #12.

## Phase 8 — Visual scripting — COMPLETE
Schema-v1 graph persistence, command-backed authoring, deterministic compiler/interpreter, macros/functions, GraphEdit workspace, debugger/breakpoints/trace, and PlaySession execution. Merged by PR #13.

## Phase 9 — Foliage / Procedural / Splines — COMPLETE
Persistent nondestructive procedural sources, MultiMesh foliage, deterministic scatter/paint/erase, terrain/biome/streaming integration, stable-ID splines, authoring UX, and rendered evidence. Merged by PR #14.

## Phase 10 — Gameplay Framework Breadth — COMPLETE
Reusable runtime gameplay state, inventory/containers, doors, health, NPC AI, dialogue, quests, vehicles, runtime save snapshots, Visual Scripting gameplay actions/events, Gameplay workspace, and strict verification. Merged by PR #15.

## Phase 11 — Environment — COMPLETE
Schema-v1 environment persistence, time/weather, rendering, wind, biome overrides, water hooks, disposable Play runtime, Visual Scripting Environment nodes, Environment workspace, and verification. Merged by PR #16.

## Phase 12 — AI Creation — COMPLETE
Local/cloud OpenAI-compatible providers, privacy/cloud consent, bounded read-only queries, Suggest, zero-mutation Preview, Preview-before-Execute, proposal validation, local persistent IDs, atomic Execute/rollback, universal Undo/Redo integration, history, native input UX, and strict evidence. Merged by PR #17.

Historical `.polyforkAPI` credential material remains exposed in Git history and must be rotated/revoked separately.

## Phase 13 — Export Pipeline — COMPLETE
Deterministic export/build manifests, runtime dependency closure, editor stripping/runtime-data preservation, Asset Library dependency resolution, licensing/attribution, Windows standalone export, repeat-export replacement, clean-package launch, scale verification, exported semantic-input checks, and canonical Export UX. Merged by PR #18.

## Phase 14 — Scale and Polish — COMPLETE / MERGED
Merged by PR #19 at signed authoritative `master` `14085eb703b72d930f39121d3da18362d43cc77d`.

Delivered deterministic Low/Balanced/High policy, Small/Medium/Large/Stress benchmarks, streaming/procedural hardening, accessibility/focus/input polish, adaptive full/compact layouts, Settings, preserved canonical visual language, performance-aware Play/export behavior, and strict contracts/stress/regression/rendered/Windows evidence.

## Phase 15 — Multiplayer Foundations and Collaboration Roadmap — COMPLETE / PR READY
Milestone branch:

`dev/phase15-multiplayer-collaboration-milestone`

Created from exactly authoritative Phase 14 `master`:

`14085eb703b72d930f39121d3da18362d43cc77d`

Verified implementation head before documentation-only closeout:

`93b67eb5e50ffe5b2b686027d6a400ee9ccff1f0`

Detailed plan:

`docs/implementation/PHASE15_MULTIPLAYER_COLLABORATION_PLAN.md`

Collaboration roadmap:

`docs/architecture/PHASE15_COLLABORATIVE_AUTHORING_ROADMAP.md`

### Delivered
- runtime-only versioned network/session identity layered over authored stable IDs;
- Offline/Host/Client session modes and project-owned Godot 4.7.1 ENet transport adapter;
- compatibility handshake, explicit failure paths, peer lifecycle, disconnect/reconnect cleanup, and no authored mutation from networking lifecycle;
- multiplayer-aware existing first/third-person controller spawning, local-input ownership, remote presence and movement replication;
- bounded host-authoritative Phase 10 damage/heal and interaction/door replication with spoof/direct-client-authority rejection;
- multiplayer template capability declarations, deterministic player limits, teams, spawn offsets, match score/objective state, and normalized capability persistence;
- bounded Visual Scripting integration through the existing gameplay event bus using namespaced multiplayer score/objective actions and session/peer events;
- canonical adaptive Multiplayer panel with Offline/Host/Join, address/port/player identity, peer/session status, keyboard/gamepad focus and input hints;
- host-only runtime save authority and repeated start/stop/rejoin/host-termination hardening;
- optional multiplayer export dependency closure: offline packages exclude networking, multiplayer packages include only required runtime dependencies and capability metadata;
- standalone environment-driven Host/Client startup for exported builds without changing normal offline export behavior;
- real two-process exported Windows host/client verification including local input enabled, remote input disabled, keyboard/mouse + gamepad semantic bindings, and match membership convergence;
- Small/Medium/Large bounded network-state verification plus inherited Phase 6–14 regressions;
- explicit future collaborative-authoring design covering durable identities/permissions, command-log integration, conflicts, asset revisions, presence, reconnect, audit/security, and hosted service boundaries while rejecting the false assumption that gameplay replication equals collaborative editing.

### Completion verification
- Phase 15 Contracts — `31635239746` — PASS — all 8 suites
- Phase 15 Inherited Regressions — `31634218734` — PASS
- Godot Smoke — `31635582701` — PASS on final implementation head
- Phase 15 Visual Evidence — `31634842058` — PASS; full and corrected compact UI evidence inspected
- Phase 15 Windows Multiplayer Export — `31635582699` — PASS; multiplayer/offline package checks plus concurrent exported host/client

A later contract run had an infrastructure-only Godot download failure in one shard before tests; the complete eight-suite run above is green and later final-head Smoke/Windows evidence is green.

### Phase 15 scope boundary retained
No production matchmaking, cloud relay/account system, NAT traversal service, voice chat, anti-cheat platform, rollback netcode, dedicated-server fleet, or real-time collaborative editor mutation is claimed.

## Phase 16 — BLOCKED
Do not begin Phase 16 until the Phase 15 completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.

## Release rule
At milestone boundaries, finish verification and documentation, then open one completion PR. Do not merge a completion PR without explicit user authorization.
