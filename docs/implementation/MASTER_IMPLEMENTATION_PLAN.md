# Master Implementation Plan

## Phase 0 — Repository and contracts
- Create project skeleton, coding rules, docs, CI, task IDs, test harness, canonical UI reference.
- Define stable IDs, command interface, persistence versioning, module boundaries.

## Phase 1 — App shell and canonical UI foundation
- Home screen, New World flow, main workspace shell, Build|Play switch, right inspector, bottom tool dock, asset drawer shell, settings, gamepad navigation.
- Establish theme tokens and screenshot-comparison workflow.

## Phase 2 — World project + save foundation
- Create/open/save projects.
- Small/Medium/Large profiles.
- Stable entity IDs.
- Command + undo/redo framework.
- Crash-safe autosave/checkpoints.

## Phase 3 — Runtime placement editor
- Selection, transforms, duplicate/delete, multi-select, grouping.
- Grid/angle/surface/object/socket snapping.
- Ghost placement.
- Context toolbar and controller tool wheel.

## Phase 4 — Universal asset library
- Folder registration.
- Incremental scanner/hash index.
- GLB/GLTF + Godot scene support.
- Thumbnails and metadata.
- Large-card browser, filters, favorites, collections, duplicate detection, licensing fields.

## Phase 5 — Terrain + streaming
- Runtime terrain sculpting.
- World partition cells.
- Save dirty cells.
- Streaming manager.
- Biome data model.

## Phase 6 — Components, archetypes, prefabs
- Component registry.
- Initial component set.
- Archetype conversion flow.
- Prefab saving and inheritance.
- Socket editor and attachments.

## Phase 7 — Instant Play and templates
- Third-person and FPS foundations.
- Build/Play state transition.
- Template manifest system.
- Initial prototype templates.

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
Do not start a new phase while critical acceptance criteria from the current phase are unresolved unless the handoff explicitly documents the dependency and authorizes parallel work.
