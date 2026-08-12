# Task Backlog

Task IDs use `P##-T##` as internal implementation checkpoints. Pull requests are milestone gates, not task gates, unless a handoff explicitly says otherwise.

## Completed phases 0–12
All Phase 0 through Phase 12 checkpoints are complete and merged on authoritative `master`. Historical task detail remains represented by merged repository history and phase handoffs/PRs.

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
- [x] Phase 12 — AI Creation — PR #17 at `b2a97a6cea52c6620f2b826a390a1d2d531ad81e`

## Phase 13 — Export Pipeline — COMPLETE — COMPLETION PR PENDING
Phase 13 implementation is complete on `dev/phase13-export-pipeline-milestone`, created from exactly authoritative `master` `b2a97a6cea52c6620f2b826a390a1d2d531ad81e`. The pre-write comparison was verified at 0 ahead / 0 behind with that exact merge base and no obsolete `main` ancestry.

Verified code-complete head before documentation closeout: `e8c939a4bc86ef011fcb42c0e8f4b197b470b4e2`.

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

### Verified Phase 13 gates on code-complete head
- [x] Godot Smoke — run `31617622730`
- [x] Phase 13 Windows Export — run `31617622756`
- [x] Phase 13 Visual Evidence — run `31617622776`
- [x] Phase 13 Inherited Regressions — run `31617622791`
- [x] Phase 13 Contracts — run `31617622792`

## Next authorized repository action
Open exactly one Phase 13 completion PR from `dev/phase13-export-pipeline-milestone` to authoritative `master`. Do not merge it without explicit user authorization.

## Later phases
Before beginning a later phase, decompose it into implementation-sized internal checkpoints. Use intermediate commits and CI runs inside the milestone, then open one PR at the milestone boundary.

**Phase 14 is blocked** until the Phase 13 completion PR is explicitly merged into authoritative `master` and the resulting `master` SHA is verified.
