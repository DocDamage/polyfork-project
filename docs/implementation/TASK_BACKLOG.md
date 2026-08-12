# Task Backlog

Task IDs use `P##-T##` as internal implementation checkpoints. Pull requests are milestone gates, not task gates, unless a handoff explicitly says otherwise.

## Completed phases 0–13
All Phase 0 through Phase 13 checkpoints are complete and merged on authoritative `master`. Historical task detail remains represented by merged repository history and phase handoffs/PRs.

- [x] Phase 0 — Repository and contracts
- [x] Phase 1 — App shell and canonical UI foundation
- [x] Phase 2 — World project + save foundation
- [x] Phase 3 — Runtime Placement Editor
- [x] Phase 4 — Universal Asset Library — PR #9
- [x] Phase 5 — Terrain + Streaming — PR #10
- [x] Phase 6 — Components, Archetypes, Prefabs — PR #11
- [x] Phase 7 — Instant Play + Templates — PR #12
- [x] Phase 8 — Visual Scripting — PR #13
- [x] Phase 9 — Foliage / Procedural / Splines — PR #14
- [x] Phase 10 — Gameplay Framework Breadth — PR #15
- [x] Phase 11 — Environment — PR #16
- [x] Phase 12 — AI Creation — PR #17
- [x] Phase 13 — Export Pipeline — PR #18 at `cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`

## Phase 13 — Export Pipeline — COMPLETE — MERGED
Phase 13 was completed on `dev/phase13-export-pipeline-milestone` and merged by PR #18.

Final Phase 13 branch head:

`2fd3c5e9516e6cd135d4b899ab8a2a3fb8ad3eac`

Verified signed merge commit / authoritative `master`:

`cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`

- [x] P13-T01 Define schema-v1 export/build manifest, deterministic package layout, runtime/editor classification contracts, validation limits, safe package paths, and export result/report contracts
- [x] P13-T02 Implement deterministic authored dependency discovery across world entities, runtime-module validation, gameplay/prefab sources, Visual Scripting, procedural sources, Environment hooks, and project-managed runtime data without treating editor state as a dependency source
- [x] P13-T03 Integrate Phase 4 Asset Library dependency resolution, deterministic project-managed staging copies, source lineage, missing/unavailable dependency hard failures, and safe read-only external-source behavior
- [x] P13-T04 Implement deterministic license/attribution aggregation and export reporting, preserving known metadata and explicitly reporting unknown/missing licenses without inventing grants or compatibility claims
- [x] P13-T05 Implement deterministic project assembly/staging using exact runtime dependency closure, stripping editor shell/workspaces/authoring-only data while preserving all runtime-required authored data and assets
- [x] P13-T06 Implement standalone runtime bootstrap through thin adapters that reuse the existing Phase 7 `PlaySession`, semantic input, terrain/streaming, gameplay, Visual Scripting, procedural, and Environment runtime paths with no parallel runtime architecture
- [x] P13-T07 Implement Windows standalone export orchestration/preset generation, safe output paths, deterministic package/report structure, actionable Godot export failures, and repeat-export replacement/idempotency behavior
- [x] P13-T08 Implement canonical Build → Export workspace integration with keyboard/mouse and gamepad reachability, deterministic status/output controls, and blocking during no-project, Play, transient placement, or invalid states
- [x] P13-T09 Add strict Phase 13 foundation/runtime/workspace tests for manifests, path safety, classification, runtime closure, dependencies/licenses, stripping/preservation, idempotent staging, semantic input, representative project sizes, and inherited behavior
- [x] P13-T10 Complete real Windows Build → Export → standalone launch smoke, clean-package copy/launch verification, Small/Medium/Large exports, repeat-export stale-file replacement, keyboard/mouse and gamepad runtime checks, strict Godot logs, inherited Phase 6–12 regressions, Godot Smoke, rendered/exported evidence, and documentation closeout

PR-triggered CI was green before merge. Transient Godot 4.7.1 download failures in isolated legacy matrix jobs passed on rerun without code changes.

## Phase 14 — Scale and Polish — UNBLOCKED / PLANNED
Phase 14 milestone branch:

`dev/phase14-scale-polish-milestone`

Base:

`cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`

The pre-write comparison was verified at 0 ahead / 0 behind with that exact merge base.

- [ ] P14-T01 Establish performance telemetry, reproducible benchmark fixtures, frame-time/memory/load-time budgets, and Low/Balanced/High quality-performance preset contracts
- [ ] P14-T02 Profile and harden terrain/streaming, entity visibility, procedural foliage/splines, Environment, and runtime-module paths under representative Small/Medium/Large and stress-scale worlds
- [ ] P14-T03 Harden editor and runtime responsiveness for large projects, including startup/open, save/reopen, autosave/checkpoint, Build↔Play transitions, dependency scans, and Windows export without weakening crash-safety contracts
- [ ] P14-T04 Implement accessibility foundations for UI scaling/readability, contrast and focus visibility, reduced-motion behavior, non-color-only status communication, and persistent accessibility preferences
- [ ] P14-T05 Complete controller coverage across existing workspaces and flows, including deterministic focus recovery, navigation traps, glyph consistency, remapping behavior, Build/Play/AI/Environment/Visual Scripting/Asset Library/Export reachability, and gamepad-only smoke paths
- [ ] P14-T06 Add touch-ready/adaptive layout behavior for major workspace surfaces and controls while preserving keyboard/mouse and gamepad parity and avoiding a separate mobile UI architecture
- [ ] P14-T07 Perform canonical visual-parity sweep against the approved dark playful Nintendo/Apple-inspired UI language, covering hierarchy, spacing, cards, typography, tool-context color, motion, density, empty/error/loading states, and removal of generic enterprise/slate drift
- [ ] P14-T08 Integrate user-facing performance preset controls and runtime/editor application of budgets with deterministic persistence, safe defaults, and no silent authored-data mutation
- [ ] P14-T09 Add strict Phase 14 performance/accessibility/controller/adaptive-layout/UI regression suites, inherited Phase 6–13 gates, representative hardware/project-size evidence, strict Godot logs, and rendered visual evidence
- [ ] P14-T10 Complete milestone stress verification, polish sweep, documentation closeout, and one Phase 14 completion PR targeting authoritative `master`

Detailed checkpoint contracts are in `docs/implementation/PHASE14_SCALE_POLISH_PLAN.md`.

## Later phases
Before beginning a later phase, decompose it into implementation-sized internal checkpoints. Use intermediate commits and CI runs inside the milestone, then open one PR at the milestone boundary.

Do not begin Phase 15 until the Phase 14 completion PR is explicitly merged into authoritative `master` and the resulting `master` SHA is verified.
