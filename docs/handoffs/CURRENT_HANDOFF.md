# Current Handoff

## Status
OPEN

## Project state
Phase 0 and P01-T01 through P01-T08 are complete. Home, New World, and Workspace now have deterministic keyboard/gamepad focus entry and navigation. Workspace Back/Cancel priority closes the Asset drawer first, then inspector, then leaves the workspace. The real Godot 4.7.1 smoke workflow passes.

## Canonical UI
`assets/reference/CANONICAL_UI_REFERENCE.png`

## Completed task
`P01-T08 — Implement keyboard/mouse + gamepad navigation`

## P01-T08 implementation evidence
- Home has deterministic focus entry plus explicit directional and tab-order relationships across all five primary cards.
- New World has explicit focus relationships across Back, name, three size cards, template choice, and Create.
- Workspace links Home, Build | Play, and the bottom tool dock into one focus graph.
- Bottom dock supports deterministic horizontal traversal across all eight tool categories; opening Assets moves focus into Search.
- Inspector focuses its close control when opened and provides reachable Advanced disclosure controls.
- `src/main/main.gd` handles semantic `ui_cancel`: New World returns Home; Workspace closes Asset drawer first, inspector second, then returns Home.
- Updated `docs/systems/INPUT_GAMEPAD_TOUCH.md` with the Phase 1 navigation baseline.
- Added `.github/workflows/godot-smoke.yml` so the actual repository runs the Godot-native smoke harness on official Godot 4.7.1.

## Tests/commands run
- GitHub Actions run `31492160584`, job `93781001574`: SUCCESS.
- Engine reported `4.7.1.stable.official.a13da4feb`.
- Runtime log reached `PASS: PlayWorld Studio runtime smoke checks completed.` after loading the real app shell and exercising the Phase 1 routes and controls.

## Known limitations
- Input testing proves deterministic UI state/focus contracts and semantic `ui_cancel` behavior in the runtime harness; physical-device matrix testing can expand later.
- Visual parity is not yet accepted until running-app screenshots are compared against the canonical reference.

## Next authorized task
`P01-T09 — Screenshot parity review against canonical reference`

## P01-T09 boundary
Capture the real running Phase 1 application at the target aspect ratio, compare it against `assets/reference/CANONICAL_UI_REFERENCE.png` using `docs/qa/UI_VISUAL_ACCEPTANCE.md`, correct material Phase 1 visual defects, and preserve evidence. Do not begin Phase 2 until the Phase 1 visual gate is passed or explicitly documented as blocked.

## New-thread start prompt
Read `docs/qa/UI_VISUAL_ACCEPTANCE.md`, `docs/design/UI_UX_CANONICAL_SPEC.md`, `assets/reference/CANONICAL_UI_REFERENCE.png`, all Phase 1 UI scenes/theme resources, and this file. Implement only P01-T09: automate/capture running-app screenshots, compare against the canonical reference, correct Phase 1 visual defects, document evidence, and then authorize Phase 2 only if the visual gate is genuinely satisfied.
