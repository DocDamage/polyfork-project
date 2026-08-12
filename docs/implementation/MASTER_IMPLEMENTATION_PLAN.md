# Master Implementation Plan

## Authoritative state
- The real project lives on `master`; repository default branch `main` is obsolete starter code and must not be used for development.
- PR #17 — Phase 12 — AI Creation is merged.
- Authoritative pre-Phase-13 `master`: `b2a97a6cea52c6620f2b826a390a1d2d531ad81e`.
- Phases 0 through 12 are complete and merged.
- Phase 13 implementation is complete on `dev/phase13-export-pipeline-milestone`; its completion PR is the only authorized next repository action.
- Verified Phase 13 code-complete head before documentation closeout: `e8c939a4bc86ef011fcb42c0e8f4b197b470b4e2`.

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
Phase 12 was developed continuously on `dev/phase12-ai-creation-milestone` and merged by PR #17. The resulting authoritative `master` is `b2a97a6cea52c6620f2b826a390a1d2d531ad81e`.

Delivered milestone breadth includes local/cloud OpenAI-compatible providers, privacy/cloud consent, bounded read-only project and Asset Library queries, Suggest, zero-mutation Preview, Preview-before-Execute, local persistent-ID generation, strict proposal validation, missing-asset rejection, atomic cross-system Execute, one universal Undo/Redo entry, rollback, crash-safe AI history, cross-system authoring actions, native keyboard/mouse/gamepad AI workspace, strict tests/regressions/Godot Smoke/rendered evidence, and removal of the tracked `.polyforkAPI` file.

Historical `.polyforkAPI` credential material remains exposed in Git history and must be rotated/revoked separately.

## Phase 13 — Export Pipeline — COMPLETE — COMPLETION PR PENDING
Phase 13 was developed as one continuous milestone on `dev/phase13-export-pipeline-milestone`, created from exactly `b2a97a6cea52c6620f2b826a390a1d2d531ad81e`. The pre-write compare gate was verified as that exact merge base, 0 commits ahead, 0 commits behind, with no obsolete `main` ancestry.

Architecture invariant retained: exported games reuse the existing Phase 7 `PlaySession` and existing authored/runtime systems. Phase 13 did not introduce a parallel runtime engine.

Delivered Phase 13 outcomes:
- schema-v1 export/build manifest, safe package-path validation, and deterministic runtime/editor classification;
- exact runtime source dependency closure and deterministic project staging;
- editor shell/workspace/authoring data stripping while preserving runtime-required world, terrain, gameplay, Visual Scripting, procedural, Environment, template/module, and asset data;
- standalone runtime bootstrap through thin adapters into the existing Phase 7 `PlaySession`;
- deterministic authored Asset Library dependency discovery and Phase 4 resolution, with hard failure for missing/unavailable dependencies;
- Phase 7 runtime module validation kept separate from Asset Library UUID dependency resolution;
- deterministic license/attribution collection with explicit unknown-license findings and no invented license compatibility claims;
- Windows standalone export orchestration, generated preset, safe output handling, deterministic package/report layout, and repeat-export stale-file replacement;
- clean-package launch verification outside the editor project;
- Small/Medium/Large Windows export verification;
- semantic keyboard/mouse and gamepad verification in exported builds;
- compact Build-mode Export UI integrated into the canonical workspace, blocked during invalid/transient/Play states;
- strict Phase 13 foundation/runtime/workspace contracts, inherited Phase 6–12 regressions, Godot Smoke, rendered Export UI evidence, and exported runtime evidence.

Verified code-complete head `e8c939a4bc86ef011fcb42c0e8f4b197b470b4e2` passed all five Phase 13 branch workflows:
- Godot Smoke — run `31617622730`;
- Phase 13 Windows Export — run `31617622756`;
- Phase 13 Visual Evidence — run `31617622776`;
- Phase 13 Inherited Regressions — run `31617622791`;
- Phase 13 Contracts — run `31617622792`.

Detailed completed checkpoints are recorded in `docs/implementation/PHASE13_EXPORT_PIPELINE_PLAN.md` and `docs/implementation/TASK_BACKLOG.md`.

### Phase 13 completion gate
Open exactly one completion PR from `dev/phase13-export-pipeline-milestone` to authoritative `master`. Do not merge it without explicit user authorization.

## Phase 14 — Scale and polish — BLOCKED
- Performance presets.
- Large-world stress passes.
- Accessibility, touch-ready layouts, controller completeness.
- UI visual parity sweep.

Phase 14 must not begin until the Phase 13 completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.

## Phase 15 — Multiplayer foundations and collaboration roadmap
- Network identity compatibility.
- Co-op prototype support.
- Competitive template hooks.
- Collaboration design; implementation may be deferred.

## Release rule
Work a phase continuously on its milestone branch. Intermediate commits and CI runs are expected; task-by-task PRs are not. At a milestone boundary, finish verification and documentation, then open one completion PR. Do not merge a completion PR without explicit user authorization, and do not start the next phase until the current completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.
