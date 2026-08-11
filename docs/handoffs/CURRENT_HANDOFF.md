# Current Handoff

## Status
OPEN

## Project state
Phase 0 and P01-T01 through P01-T07 are complete. The workspace now includes the themed shell, Build | Play state, right inspector shell, eight-category bottom dock, and an Asset drawer with search, large-card default density, density toggle, and empty state. Asset indexing remains deferred.

## Canonical UI
`assets/reference/CANONICAL_UI_REFERENCE.png`

## Completed task
`P01-T07 — Implement bottom category dock and asset drawer shell`

## P01-T07 implementation evidence
- Added `src/app/workspace/BottomToolDock.tscn` and `src/app/workspace/bottom_tool_dock.gd`.
- Bottom dock exposes Terrain, Assets, Foliage, Roads, Water, Gameplay, AI, and More with semantic accent colors.
- Asset drawer starts closed, opens above the dock, includes search, defaults to Large Cards, includes a density toggle, and has a non-destructive external-library empty state.
- Workspace exposes neutral drawer state/focus methods and re-emits tool selection without implementing asset indexing or placement.
- Runtime smoke behavior checks all eight tools, drawer closed default, Assets open/close toggle, search presence, large-card default, and density toggle state.

## Tests/commands run
- Static scene/script/reference review only; Godot runtime execution remains unavailable in the current environment.

## Known limitations
- Asset folders, indexing, cards, filtering, thumbnails, and placement belong to Phase 4 and later editor tasks.
- Final layout density and drawer proportions still require runtime screenshot comparison.

## Next authorized task
`P01-T08 — Implement keyboard/mouse + gamepad navigation`

## P01-T08 boundary
Implement deterministic focus entry, directional focus relationships for core Phase 1 screens, standard `ui_*` keyboard/gamepad navigation, and prioritized Back/Cancel behavior for transient workspace panels and routes. Do not add gameplay controls or controller-only feature shortcuts beyond Phase 1 UI navigation.

## New-thread start prompt
Read `docs/systems/INPUT_GAMEPAD_TOUCH.md`, `docs/design/UI_SCREEN_INVENTORY.md`, all Phase 1 UI scripts/scenes, `src/main/main.gd`, and this file. Implement only P01-T08: deterministic keyboard/mouse/gamepad UI focus/navigation and Back/Cancel handling across Home, New World, and Workspace, including inspector/drawer priority. Then update the handoff and authorize only P01-T09.
