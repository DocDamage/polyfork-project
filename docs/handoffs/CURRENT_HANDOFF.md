# Current Handoff

## Status
OPEN

## Project state
Phase 0 is complete: repository structure, engineering/documentation rules, persistent ID/schema contracts, a Godot-native runtime smoke harness, and a strict canonical UI comparison workflow are all in place. Phase 1 UI foundation is now authorized.

## Canonical UI
`assets/reference/CANONICAL_UI_REFERENCE.png`

## Completed task
`P00-T05 — Add canonical UI visual reference and comparison checklist`

## P00-T05 implementation evidence
- Confirmed the canonical reference path remains `assets/reference/CANONICAL_UI_REFERENCE.png`.
- Expanded `docs/qa/UI_VISUAL_ACCEPTANCE.md` into a repeatable 16:9 capture protocol and scored checklist covering composition, surfaces/depth, typography, home cards, workspace shell, semantic tool accents, controller focus, advanced disclosure, and touch-friendly targets.
- Added automatic defect triggers for generic/dark-slate Godot/editor styling, dense enterprise layouts, tiny default cards, inconsistent rounding/colors, and hidden Build|Play state.
- Added a hard Phase 1 exit rule: P01-T09 cannot be marked complete without running-app screenshot comparison.

## Phase 0 status
P00-T01 through P00-T05 are complete.

## Known limitations
- Godot runtime execution and screenshot capture are still unavailable in the current agent environment unless a compatible Godot 4.7.x runtime can be provisioned later.

## Next authorized task
`P01-T01 — Implement theme/tokens`

## P01-T01 boundary
Implement reusable Godot theme/style/token resources only. Do not implement the Home screen or later Phase 1 screens in this task. Theme values must follow `docs/design/DESIGN_TOKENS.md` and the canonical UI direction.

## New-thread start prompt
Read `docs/design/DESIGN_TOKENS.md`, `docs/design/UI_UX_CANONICAL_SPEC.md`, `docs/qa/UI_VISUAL_ACCEPTANCE.md`, `docs/implementation/CODING_STANDARDS.md`, `docs/implementation/TASK_BACKLOG.md`, and this file. Implement only P01-T01 as reusable Godot theme/token resources suitable for the upcoming runtime UI. Then update the handoff and authorize only P01-T02.
