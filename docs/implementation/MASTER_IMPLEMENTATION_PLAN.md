# Master Implementation Plan

## Authoritative state
- The real project lives on `master`; repository default branch `main` is obsolete starter code and must not be used for development.
- PR #18 — Phase 13 — Export Pipeline is merged.
- Authoritative `master`: `cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`.
- This is the verified signed merge commit for PR #18.
- Phases 0 through 13 are complete and merged.
- Phase 14 — Scale and Polish is unblocked.
- Phase 14 milestone branch: `dev/phase14-scale-polish-milestone`, created from exactly `cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`.
- Pre-write Phase 14 compare gate: exact merge base, 0 commits ahead, 0 commits behind.

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
Phase 12 was developed continuously on `dev/phase12-ai-creation-milestone` and merged by PR #17. The resulting authoritative master after Phase 12 was `b2a97a6cea52c6620f2b826a390a1d2d531ad81e`.

Delivered milestone breadth includes local/cloud OpenAI-compatible providers, privacy/cloud consent, bounded read-only project and Asset Library queries, Suggest, zero-mutation Preview, Preview-before-Execute, local persistent-ID generation, strict proposal validation, missing-asset rejection, atomic cross-system Execute, one universal Undo/Redo entry, rollback, crash-safe AI history, cross-system authoring actions, native keyboard/mouse/gamepad AI workspace, strict tests/regressions/Godot Smoke/rendered evidence, and removal of the tracked `.polyforkAPI` file.

Historical `.polyforkAPI` credential material remains exposed in Git history and must be rotated/revoked separately.

## Phase 13 — Export Pipeline — COMPLETE — MERGED
Phase 13 was developed continuously on `dev/phase13-export-pipeline-milestone` from authoritative Phase 12 master and merged by PR #18.

Final Phase 13 branch head:

`2fd3c5e9516e6cd135d4b899ab8a2a3fb8ad3eac`

Resulting verified signed authoritative `master`:

`cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`

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

PR-triggered CI was fully green before merge. Initial isolated failures in several legacy contract matrices were GitHub-hosted runner failures while downloading Godot 4.7.1; those jobs passed on rerun without repository changes.

Detailed completed checkpoints are recorded in `docs/implementation/PHASE13_EXPORT_PIPELINE_PLAN.md` and `docs/implementation/TASK_BACKLOG.md`.

## Phase 14 — Scale and Polish — UNBLOCKED
Phase 14 is the next milestone. It must improve scale, responsiveness, accessibility, input completeness, and canonical visual quality without broadening into a new feature-architecture phase.

Primary outcomes:
- measurable performance budgets and quality/performance presets;
- representative Small/Medium/Large and stress-scale profiling for editor, Play, streaming, procedural systems, save/load, and export;
- large-world memory, frame-time, streaming, and responsiveness hardening;
- accessibility pass covering readable scaling, contrast/focus, reduced-motion behavior, and non-color-only state communication;
- controller completeness across all existing authoring/runtime surfaces, including focus recovery, glyph consistency, and remapping behavior;
- touch-ready/adaptive layout foundations without compromising keyboard/mouse or gamepad use;
- canonical UI visual-parity sweep against the approved dark playful Nintendo/Apple-inspired design language;
- strict performance/accessibility/controller/UI regression gates, rendered evidence, and documentation closeout.

Detailed internal checkpoints are defined in `docs/implementation/PHASE14_SCALE_POLISH_PLAN.md` and `TASK_BACKLOG.md`.

## Phase 15 — Multiplayer foundations and collaboration roadmap
- Network identity compatibility.
- Co-op prototype support.
- Competitive template hooks.
- Collaboration design; implementation may be deferred.

## Release rule
Work a phase continuously on its milestone branch. Intermediate commits and CI runs are expected; task-by-task PRs are not. At a milestone boundary, finish verification and documentation, then open one completion PR. Do not merge a completion PR without explicit user authorization, and do not start the next phase until the current completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.
