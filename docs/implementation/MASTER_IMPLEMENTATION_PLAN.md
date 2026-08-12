# Master Implementation Plan

## Authoritative state
- The real project lives on `master`; repository default branch `main` is obsolete starter code and must not be used for development.
- PR #17 — Phase 12 — AI Creation is merged.
- Authoritative pre-Phase-13 `master`: `b2a97a6cea52c6620f2b826a390a1d2d531ad81e`.
- Phases 0 through 12 are complete and merged.
- Phase 13 is unblocked and is developed continuously on `dev/phase13-export-pipeline-milestone` from exactly that authoritative commit.

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
Phase 12 was developed continuously on `dev/phase12-ai-creation-milestone` from authoritative Phase 11 master and merged by PR #17. The resulting authoritative `master` is `b2a97a6cea52c6620f2b826a390a1d2d531ad81e`.

Delivered milestone breadth:
- schema-v1 request/proposal/action/history contracts and bounded privacy/provider policy;
- local and HTTPS cloud OpenAI-compatible providers with environment-scoped credentials;
- explicit cloud-context consent and no credential persistence in projects/history;
- bounded read-only project and Phase 4 Asset Library queries;
- Suggest and zero-mutation Preview modes;
- strict provider-output validation, locally generated persistent IDs, and missing/unavailable asset rejection;
- Preview-before-Execute and atomic cross-system Execute through existing world/gameplay/Visual Scripting/procedural/Environment command surfaces;
- exactly one universal Undo/Redo entry, rollback on failure, and crash-safe `ai/history.json` lineage;
- native keyboard/mouse and gamepad AI workspace;
- strict Phase 12 contract/scale/history/rollback/workspace/orchestration tests, inherited Phase 6–11 regressions, Godot Smoke, and rendered evidence;
- tracked `.polyforkAPI` removed and ignored. Historical credential material remains exposed in Git history and must be rotated/revoked separately.

## Phase 13 — Export Pipeline — ACTIVE
Phase 13 is developed as one continuous milestone on `dev/phase13-export-pipeline-milestone`, created from exactly `b2a97a6cea52c6620f2b826a390a1d2d531ad81e`. The pre-write compare gate was verified as merge base exactly that commit, zero commits ahead, zero commits behind. No obsolete `main` ancestry is authorized.

Architecture rule: exported games reuse the existing Phase 7 Play/runtime foundation and authored systems delivered in Phases 2–12. Phase 13 must not introduce a parallel runtime architecture.

Phase 13 outcomes:
- schema-v1 export/build manifest with deterministic editor-only versus runtime-required classification;
- deterministic staging/assembly that strips editor workspace/UI/authoring-only code/data while retaining required authored world, gameplay, Visual Scripting, procedural, Environment, template/runtime, and asset data;
- Phase 7 template/runtime boot path for standalone builds;
- project dependency discovery and Phase 4 Asset Library dependency resolution with hard failure on missing required dependencies;
- license/attribution collection and deterministic export report;
- Windows standalone export first with deterministic package layout and repeat-export/idempotency guarantees;
- clean-machine-style launch verification plus Build → Export → standalone launch smoke;
- keyboard/mouse and gamepad verification in exported builds;
- representative Small/Medium/Large verification, strict Godot log gates, inherited Phase 6–12 regression gates, and rendered/exported runtime evidence;
- documentation closeout and exactly one Phase 13 completion PR targeting authoritative `master`.

Detailed internal checkpoints are defined in `docs/implementation/PHASE13_EXPORT_PIPELINE_PLAN.md` and `TASK_BACKLOG.md`.

## Phase 14 — Scale and polish
- Performance presets.
- Large-world stress passes.
- Accessibility, touch-ready layouts, controller completeness.
- UI visual parity sweep.

## Phase 15 — Multiplayer foundations and collaboration roadmap
- Network identity compatibility.
- Co-op prototype support.
- Competitive template hooks.
- Collaboration design; implementation may be deferred.

## Release rule
Work a phase continuously on its milestone branch. Intermediate commits and CI runs are expected; task-by-task PRs are not. At a milestone boundary, finish verification and documentation, then open one completion PR. Do not merge a completion PR without explicit user authorization, and do not start the next phase until the current completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.
