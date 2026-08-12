# Master Implementation Plan

## Phase 0 — Repository and contracts — COMPLETE
- Project skeleton, coding rules, docs, CI, task IDs, test harness, canonical UI reference.
- Stable IDs, command interface, persistence versioning, and module boundaries.

## Phase 1 — App shell and canonical UI foundation — COMPLETE
- Home screen, New World flow, workspace shell, Build|Play switch, inspector, bottom tool dock, asset drawer shell, and gamepad navigation.
- Theme tokens and rendered screenshot-comparison workflow.

## Phase 2 — World project + save foundation — COMPLETE
- Create/open/save projects and Small/Medium/Large profiles.
- Stable entity IDs and command/undo/redo framework.
- Crash-safe autosave/checkpoints and recovery.

## Phase 3 — Runtime placement editor — COMPLETE
- Selection, transforms, duplicate/delete, multi-select, grouping.
- Grid/angle/surface/object/socket snapping and drop-to-ground.
- Ghost placement, contextual toolbar, controller tool wheel, rendered verification.

## Phase 4 — Universal asset library — COMPLETE
- Read-only external source registry, deterministic cataloging/import analysis, thumbnails/search/favorites/collections, and Phase 3 placement handoff.
- Merged by PR #9.

## Phase 5 — Terrain + streaming — COMPLETE
- Terrain sculpting, partition cells, dirty-cell persistence, deterministic streaming, biome hooks, and rendered verification.
- Merged by PR #10.

## Phase 6 — Components, archetypes, prefabs — COMPLETE
- Versioned gameplay composition, archetypes, prefab inheritance/overrides, sockets/attachments, gameplay workspace, and persistence/scale verification.
- Merged by PR #11.

## Phase 7 — Instant Play and templates — COMPLETE
- Disposable Build → Play → Build lifecycle, semantic gameplay input, third-person/FPS foundations, deterministic template system, seven starter templates, module editability, persistence/performance/visual verification.
- Merged by PR #12.

## Phase 8 — Visual scripting — COMPLETE
- Stable schema-v1 graph/node/connection/variable contracts and project-managed crash-safe graph persistence under `visual_scripting/graphs.json`.
- Command-backed graph authoring through the existing universal Undo/Redo history and project dirty-state path.
- Deterministic compiler, bounded interpreter, reusable macros/functions, native GraphEdit Logic workspace, debugger/breakpoints/trace, and Phase 7 PlaySession execution against disposable runtime state.
- Merged by PR #13 at authoritative `master` commit `6ea437f3d5ea1077773ef797e8f5895e84b5a7f1`.

## Phase 9 — Foliage / Procedural / Splines — COMPLETE
- Schema-v1 project-managed procedural registry persisted crash-safely under `procedural/procedural.json`, with stable foliage-set, scatter-layer, stroke, spline, and spline-point identities mirrored into project registries.
- Nondestructive procedural authoring: saved source records, settings, paint strokes, and erase masks are authoritative; generated foliage and spline runtime geometry is disposable derived state.
- Real `MultiMeshInstance3D` foliage batches with deterministic density/spacing/biome/height/slope/scale/yaw/normal rules, Phase 4 Asset Library and Phase 6 inherited-prefab source resolution, terrain coupling, streaming, and automatic regeneration after terrain edits.
- Stable-ID road/path/fence splines with command-backed point authoring, generated `ArrayMesh` road/path ribbons, MultiMesh fence segments, streamed geometry, keyboard/mouse and gamepad authoring, strict regression gates, and rendered evidence.
- Merged by PR #14 at authoritative `master` commit `953d8b500beb1b65485104c85ab9bd5c4ff8224b`.

## Phase 10 — Gameplay Framework Breadth — IMPLEMENTATION COMPLETE / MERGE-GATED
Phase 10 was developed as one continuous milestone on `dev/phase10-gameplay-framework-milestone`, created from exactly authoritative `master` commit `953d8b500beb1b65485104c85ab9bd5c4ff8224b`.

The milestone extends the existing Phase 6 gameplay-component contracts and Phase 7 disposable Play runtime rather than creating parallel gameplay systems. Authored Build data remains authoritative; mutable gameplay state is session/runtime state unless explicitly saved through the Phase 10 save-state layer.

Completed milestone breadth:
- stable-ID runtime gameplay-state service initialized from the existing Phase 6 gameplay registry, with validation, disposable Play lifecycle, runtime events, and safe missing-reference handling;
- reusable inventory/item/container operations with capacity, quantity, transfer, pickup, and interaction routing;
- reusable doors plus health/damage/healing/death state and event surfaces without genre-specific combat assumptions;
- basic NPC navigation/AI goals, destinations, waits/idle behavior, target interactions, and deterministic fallback behavior;
- dialogue scaffolding with stable dialogue/conversation/line/participant references, conditions, choices, and runtime progression;
- quest scaffolding with stable quest/objective IDs, progress, completion/failure state, and event-driven updates;
- reusable vehicle runtime state with stable vehicle/seat references, occupancy, enter/exit, throttle/steer/brake semantics, and semantic keyboard/gamepad input;
- explicit save-state components and project-managed runtime snapshots that restore opted-in Play fields without silently mutating authored Build data;
- Visual Scripting-facing gameplay actions/events integrated with the existing Phase 7 semantic input/runtime lifecycle;
- native Gameplay workspace integration with keyboard/mouse and gamepad authoring paths;
- strict Phase 10 contract gates, representative 256-entity/768-component scale regression coverage, Godot smoke coverage, and rendered Phase 10 visual evidence exercising real Gameplay authoring and disposable Play transitions.

Phase 10 is now completion-PR gated. The milestone completion PR targets authoritative `master`; do not merge it without explicit user authorization. Phase 11 remains blocked until that PR is explicitly merged and the resulting authoritative `master` SHA is verified.

## Phase 11 — Environment
- Day/night, weather profile framework, fog/wind, water integration hooks, biome-environment coupling.

## Phase 12 — AI creation
- Provider interface.
- Catalog/project query tools.
- Suggest/Preview/Execute.
- Transactional execution and history.

## Phase 13 — Export pipeline
- Strip editor-only systems.
- Standalone project/build export.
- Dependency/license checks.
- Smoke tests.

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
Do not start a new phase while critical acceptance criteria from the current phase are unresolved or its required milestone PR is unmerged unless an explicit handoff authorizes parallel work.
