# Current Handoff

## Status
OPEN

## Project state
Phase 0 and P01-T01 through P01-T03 are complete. The app starts on Home, routes to a themed Create New World screen, supports Small/Medium/Large world profile choice, all seven initial templates, Back behavior, and emits a configuration-only create request. World persistence remains deferred to Phase 2.

## Canonical UI
`assets/reference/CANONICAL_UI_REFERENCE.png`

## Completed task
`P01-T03 — Implement Create New World flow`

## P01-T03 implementation evidence
- Added `src/app/screens/new_world/NewWorldScreen.tscn` with world name input, Small (1–2 km²), Medium (4–16 km²), Large/streamed (16+ km²) cards, template selection, Back, and Create World.
- Added `src/app/screens/new_world/new_world_screen.gd` with smart defaults (Medium + Third-Person Adventure), all seven documented initial templates, explicit size selection, validation for an empty world name, and a `create_requested(configuration)` signal.
- Updated `src/main/Main.tscn` and `src/main/main.gd` for Home ↔ New World routing and forwarding of configuration-only create requests.
- Updated runtime smoke behavior to exercise Home → New World → Back and verify required size/template/create controls exist.
- No project files, terrain, template modules, or persistent state are created in this task.

## Tests/commands run
- Static scene/script/reference review only; Godot runtime execution remains unavailable in the current environment.

## Known limitations
- Actual Create World transition is intentionally not connected to persistence; P01-T04 will connect it to the workspace shell only, and Phase 2 will own project creation/save behavior.
- Visual tuning still requires runtime screenshots.

## Next authorized task
`P01-T04 — Implement main workspace shell`

## P01-T04 boundary
Implement the central runtime workspace shell and route a New World create request into it using the in-memory configuration only. The viewport must dominate. Do not implement Build|Play switching, inspector behavior, or bottom tool/asset drawers beyond structural placeholders owned by their later tasks.

## New-thread start prompt
Read `docs/design/UI_UX_CANONICAL_SPEC.md`, `src/main/main.gd`, `src/app/screens/new_world/`, `src/app/theme/`, and this file. Implement only P01-T04 as the dominant-viewport workspace shell and route in-memory New World configuration into it. Keep later Phase 1 controls structurally separate and unimplemented. Then update the handoff and authorize only P01-T05.
