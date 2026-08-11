# Current Handoff

## Status
OPEN

## Project state
Phase 0, P01-T01, and P01-T02 are complete. The application now starts on a themed Home/Project Hub with all five required large-card actions and route-intent signals. Destination flows beyond Home are not implemented yet.

## Canonical UI
`assets/reference/CANONICAL_UI_REFERENCE.png`

## Completed task
`P01-T02 — Implement Home screen`

## P01-T02 implementation evidence
- Added `src/app/screens/home/HomeScreen.tscn` with a dark, spacious, rounded large-card layout for Create New World, Continue, My Worlds, Templates, and Asset Library.
- Added `src/app/screens/home/home_screen.gd` with explicit route constants/signals and initial focus on Create New World.
- Replaced the Phase 0 placeholder main view with the real Home screen in `src/main/Main.tscn`.
- Updated `src/main/main.gd` to apply the shared theme and forward route intents without implementing future destination screens prematurely.
- Updated the runtime smoke test to validate that Home is the startup view and that all five required actions exist with expected labels.

## Tests/commands run
- Static scene/script/reference review only; Godot runtime execution remains unavailable in the current environment.

## Known limitations
- Home visual tuning still requires running-app screenshot comparison.
- Continue, My Worlds, Templates, and Asset Library route destinations remain future tasks.

## Next authorized task
`P01-T03 — Implement Create New World flow`

## P01-T03 boundary
Implement the New World screen and routing from Home/back to Home. The flow must offer Small, Medium, and Large/streamed choices before creation plus the initial template choices. Do not create/save actual world project files yet; Phase 2 owns project persistence.

## New-thread start prompt
Read `docs/PRODUCT_REQUIREMENTS.md`, `docs/design/UI_UX_CANONICAL_SPEC.md`, `docs/systems/TEMPLATE_SYSTEM.md`, `src/main/main.gd`, `src/app/screens/home/`, and this file. Implement only P01-T03: themed New World configuration UI, world-size selection, template selection, back behavior, and a create request signal carrying configuration data without Phase 2 persistence. Then update the handoff and authorize only P01-T04.
