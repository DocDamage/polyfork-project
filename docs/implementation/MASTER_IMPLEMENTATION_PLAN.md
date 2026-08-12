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
- Merged by PR #12 at authoritative `master` commit `06df50b6ffb752731d21f1ced88eb2cf1191f542`.

## Phase 8 — Visual scripting — IMPLEMENTATION COMPLETE; MERGE-GATED
- Stable schema-v1 graph/node/connection/variable contracts and project-managed crash-safe graph persistence under `visual_scripting/graphs.json`.
- Command-backed graph authoring through the existing universal Undo/Redo history and project dirty-state path.
- Deterministic compiler with node/port/type/cardinality validation, macro reference validation, dependency-cycle rejection, and executable plans.
- Bounded interpreter for event, flow, value, math, logic, variable, entity-position, macro, and debug nodes.
- Reusable macro/function graphs with typed interfaces, nested calls, output propagation, compile-time cycle detection, and runtime recursion guards.
- Native Godot `GraphEdit`/`GraphNode` Logic workspace integrated into the existing dark playful Nintendo-forward / Apple-clean shell.
- Searchable node palette, graph creation, native connect/disconnect/delete/move, JSON property editing, keyboard/mouse, gamepad X/Y shortcuts, Back/Cancel behavior, and shared history.
- Debug toolbar with Validate, Run, Breakpoint, Resume, stable-node selection, paused/error state, and live trace/status.
- Phase 7 PlaySession integration: project-owned event graphs compile and execute at Play entry against disposable runtime state; graph failure rejects Play startup without mutating authored Build data.
- Stable project graph-reference validation for Phase 7 template `example_graph_references`.
- Representative 120-graph compile+execute regression workload, strict raw-log gates, baseline/inherited smoke, and rendered Logic/debugger evidence.

Phase 8 is complete on `dev/phase8-visual-scripting-milestone` and must merge through one completion PR to authoritative `master` before Phase 9 begins.

## Phase 9 — Foliage/procedural/splines — NOT STARTED / MERGE-GATED
- MultiMesh foliage sets.
- Scatter/paint/erase.
- Nondestructive procedural sets.
- Road/path/fence spline framework.

## Phase 10 — Gameplay framework breadth
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
