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
- Strictly read-only external source-folder registry.
- Deterministic incremental scanning, SHA-256 indexing, stable asset-ID reconciliation, derived project-managed imports, metadata/licensing, thumbnails, search/filter/favorites/collections, and real placement handoff.

## Phase 5 — Terrain + streaming — COMPLETE
- Runtime terrain sculpting, deterministic terrain meshes/collision, world partition cells, dirty-cell persistence/recovery, streaming manager, and biome data foundation.

## Phase 6 — Components, archetypes, prefabs — COMPLETE
- Component registry and initial component set.
- Archetype conversion flow.
- Prefab saving, inheritance and instance overrides.
- Named typed sockets and stable attachments.

## Phase 7 — Instant Play and templates — ACTIVE MILESTONE
- Third-person and FPS foundations.
- Build/Play state transition over the same loaded world with disposable runtime state.
- Semantic gameplay input separated from editor input.
- Versioned data-driven template manifest/registry and deterministic module resolution/application.
- Initial prototype templates: Blank Sandbox, Third-Person Adventure, FPS, Survival, RPG, Driving, Walking Simulator.
- One completion PR after full integration, regression, persistence, failure-path, performance-proxy, raw-log, and rendered visual verification.

## Phase 8 — Visual scripting
- Graph schema/editor.
- Initial runtime node set.
- Graph compiler/interpreter layer.
- Reusable macros/functions.
- Debugger/validation.

## Phase 9 — Foliage/procedural/splines
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
