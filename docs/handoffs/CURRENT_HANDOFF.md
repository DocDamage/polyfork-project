# Current Handoff

## Status
OPEN

## Project state
Phase 0 and P01-T01 through P01-T06 are complete. The workspace now has the dominant viewport, Build | Play UI state, and a generic hidden-by-default right inspector with Basic-first and collapsed Advanced content. Object-selection semantics remain deferred.

## Canonical UI
`assets/reference/CANONICAL_UI_REFERENCE.png`

## Completed task
`P01-T06 — Implement right inspector shell`

## P01-T06 implementation evidence
- Added `src/app/workspace/InspectorPanel.tscn` and `src/app/workspace/inspector_panel.gd`.
- Inspector is hidden by default, mounted on the right side, driven by a generic context dictionary, and exposes Basic content before Advanced.
- Advanced content starts collapsed and expands only when requested.
- Workspace exposes neutral `show_inspector`, `hide_inspector`, and `is_inspector_open` methods without any object-selection or gameplay semantics.
- Runtime smoke behavior checks hidden-default behavior, generic context display, Advanced disclosure, and clear/hide behavior.

## Tests/commands run
- Static scene/script/reference review only; Godot runtime execution remains unavailable in the current environment.

## Known limitations
- Selection wiring and real property editors belong to later runtime-editor/component phases.
- Slide animation and final visual tuning remain pending screenshot parity work.

## Next authorized task
`P01-T07 — Implement bottom category dock and asset drawer shell`

## P01-T07 boundary
Implement the bottom contextual category dock with Terrain, Assets, Foliage, Roads, Water, Gameplay, AI, and More. Implement an Asset drawer/sheet shell with search, large-card default density, density toggle, and an empty state. Do not implement asset indexing/import behavior.

## New-thread start prompt
Read `docs/design/UI_UX_CANONICAL_SPEC.md`, `docs/systems/ASSET_LIBRARY_SYSTEM.md`, `src/app/workspace/`, `src/app/theme/`, `docs/implementation/TASK_BACKLOG.md`, and this file. Implement only P01-T07: the bottom category dock and Asset drawer shell, mounted in the reserved workspace layer. Keep asset data/indexing out of scope. Then update the handoff and authorize only P01-T08.
