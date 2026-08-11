# Current Handoff

## Status
OPEN

## Project state
Phase 0 and P01-T01 through P01-T04 are complete. The app now routes Home → New World → a dominant-viewport runtime workspace using only in-memory configuration. The workspace includes compact top chrome and reserved overlay layers for later Phase 1 controls.

## Canonical UI
`assets/reference/CANONICAL_UI_REFERENCE.png`

## Completed task
`P01-T04 — Implement main workspace shell`

## P01-T04 implementation evidence
- Added `src/app/workspace/WorkspaceScreen.tscn` with a dominant central viewport area, compact rounded top bar, world context, and dedicated empty layers for inspector and bottom-dock features.
- Added `src/app/workspace/workspace_screen.gd` to receive/duplicate in-memory New World configuration and display world title/profile/template context.
- Updated `src/main/Main.tscn` and `src/main/main.gd` so Create World routes into the workspace without creating persistent project data.
- Workspace Home action returns to Home.
- Runtime smoke behavior now exercises Home → New World → Back and Home → New World → Workspace → Home, verifies world context reaches the workspace, and checks the reserved Phase 1 layers exist.

## Tests/commands run
- Static scene/script/reference review only; Godot runtime execution remains unavailable in the current environment.

## Known limitations
- The central viewport is a shell surface only; terrain/world rendering belongs to later phases.
- Build|Play, inspector, bottom dock, asset drawer, and controller navigation remain intentionally unimplemented.

## Next authorized task
`P01-T05 — Implement Build|Play switch UI`

## P01-T05 boundary
Implement the segmented Build | Play control and workspace mode state/signals only. Do not implement actual gameplay activation, player spawning, scene swapping, or Phase 7 instant-play behavior.

## New-thread start prompt
Read `docs/design/UI_UX_CANONICAL_SPEC.md`, `src/app/workspace/`, `src/app/theme/`, `docs/implementation/TASK_BACKLOG.md`, and this file. Implement only P01-T05 as a prominent top-center Build | Play segmented control with deterministic UI state and a mode-change signal. Do not implement gameplay transition behavior. Then update the handoff and authorize only P01-T06.
