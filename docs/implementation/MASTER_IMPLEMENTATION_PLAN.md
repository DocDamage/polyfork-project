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

## Phase 9 — Foliage / Procedural / Splines — IMPLEMENTATION COMPLETE; MERGE-GATED
- Schema-v1 project-managed procedural registry persisted crash-safely under `procedural/procedural.json`, with stable foliage-set, scatter-layer, stroke, spline, and spline-point identities mirrored into project registries.
- Nondestructive procedural authoring: saved source records, settings, paint strokes, and erase masks are authoritative; generated foliage and spline runtime geometry is disposable derived state.
- Real `MultiMeshInstance3D` foliage batches, generated per scatter layer × active terrain cell, with deterministic seeds, density, minimum spacing, height, slope, biome, scale, yaw, surface-normal alignment, and per-cell instance caps.
- Built-in zero-asset foliage primitives plus real Phase 4 Asset Library scene resolution and Phase 6 inherited-prefab visual-source resolution through stable IDs; missing references fail closed.
- Command-backed foliage/scatter edits and paint/erase strokes using the existing universal Undo/Redo history, project dirty state, crash-safe persistence, and runtime rollback/refresh behavior.
- Terrain coupling through stable cell ownership, Phase 5 streaming, terrain height sampling, and `cell_refreshed` regeneration after terrain edits.
- Stable-ID road/path/fence splines with command-backed control-point create/move/delete/configure, open/closed path data, width, sampling, terrain conformance, and persistence.
- Road/path runtime ribbons generated as real `ArrayMesh` triangle geometry; fences generated as repeated source meshes in a `MultiMeshInstance3D`; derived spline geometry follows active terrain-cell streaming.
- Native Procedural contextual workspace integrated behind the existing Foliage and Roads dock entries with a terrain-conforming world cursor, paint/erase controls, density/radius controls, two-point road/path/fence creation, point extension, viewport interaction, keyboard/mouse, gamepad D-pad/A/X, contextual-tool switching, status, and Back/Cancel behavior.
- Real external Asset Library source + inherited prefab verification, large-world streaming verification, deterministic regeneration, terrain-refresh coupling, strict raw-log gates, baseline smoke, and rendered foliage/road/fence evidence.
- Representative large-world regression workload: 25 terrain focus transitions, peak 2,142 foliage instances, streamed road/fence regeneration in 2,792 ms against a broad 12,000 ms CI budget.

Phase 9 is complete on `dev/phase9-foliage-procedural-splines-milestone` and must merge through one completion PR to authoritative `master` before Phase 10 begins.

## Phase 10 — Gameplay framework breadth — NOT STARTED / MERGE-GATED
- Inventory, interactions, doors, pickups, health/damage, basic NPC navigation/AI, dialogue/quest scaffolding, vehicles, save-state components.

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
