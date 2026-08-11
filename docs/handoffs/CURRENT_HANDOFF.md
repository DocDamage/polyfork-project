# Current Handoff

## Status
OPEN

## Project state
Phase 0 and P01-T01 through P01-T05 are complete. The runtime workspace now includes a prominent top-center Build | Play segmented control with deterministic UI state and mode-change signaling. No gameplay transition behavior is implemented.

## Canonical UI
`assets/reference/CANONICAL_UI_REFERENCE.png`

## Completed task
`P01-T05 — Implement Build|Play switch UI`

## P01-T05 implementation evidence
- Added `src/app/workspace/ModeSwitch.tscn` and `src/app/workspace/mode_switch.gd`.
- The switch defaults to Build, uses a mutually exclusive button group, exposes `set_mode`, `get_mode`, and `mode_changed`, and provides focus entry for later gamepad navigation.
- Mounted the switch in the workspace's reserved top-center `ModeSlot`.
- Updated workspace UI state so the viewport badge reflects BUILD MODE / PLAY MODE without triggering gameplay behavior.
- Runtime smoke behavior now checks the segmented control exists, defaults to Build, and deterministically changes the UI state to Play.

## Tests/commands run
- Static scene/script/reference review only; Godot runtime execution remains unavailable in the current environment.

## Known limitations
- Play is UI state only. Actual Build ↔ Play runtime transition belongs to Phase 7.
- Visual tuning still requires running-app screenshot comparison.

## Next authorized task
`P01-T06 — Implement right inspector shell`

## P01-T06 boundary
Implement a right-side inspector panel shell with hidden-by-default behavior, Basic-first information, an Advanced disclosure area, close behavior, and a generic context API. Do not implement object selection or gameplay-specific properties.

## New-thread start prompt
Read `docs/design/UI_UX_CANONICAL_SPEC.md`, `src/app/workspace/`, `src/app/theme/`, `docs/implementation/TASK_BACKLOG.md`, and this file. Implement only P01-T06 as a generic right inspector shell with Basic-first and hidden Advanced content. Mount it in the reserved inspector layer without adding object-selection semantics. Then update the handoff and authorize only P01-T07.
