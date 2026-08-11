# Current Handoff

## Status
OPEN

## Project state
Phase 0 and Phase 1 are complete. The application has a verified Godot 4.7.1 runtime shell with Home, New World configuration, a canonical-styled runtime workspace, Build | Play UI state, inspector/dock/drawer shells, transform toolbar shell, deterministic keyboard/gamepad navigation, and reproducible rendered visual evidence. Persistent world projects do not exist yet; Phase 2 is now authorized.

## Canonical UI
`assets/reference/CANONICAL_UI_REFERENCE.png`

## Completed task
`P01-T09 — Screenshot parity review against canonical reference`

## P01-T09 implementation evidence
- Added `tests/runtime/capture_phase1.gd` and the `phase1-visual-capture` GitHub Actions job to render the actual Godot application at the target aspect ratio.
- Preserved the canonical image alongside each evidence artifact for direct comparison.
- First rendered pass was rejected as too flat, gray/blue, spacious, and generic; Phase 1-owned UI was retuned rather than accepted from static scene files.
- Added/tuned canonical dark surface hierarchy, purple creation emphasis, lime active/focus states, floating workspace chrome, compact Build | Play, compact transform strip, semantic bottom dock, large-card asset drawer shell, structured right inspector, and compact status strip.
- Corrected accent panels to remain dark with lime edging rather than solid green fills.
- Added `docs/qa/PHASE1_VISUAL_REVIEW.md` documenting the comparison, corrections, accepted Phase 1 elements, and later-phase items explicitly marked Not Yet Applicable.

## Tests/commands run
- GitHub Actions run `31493367487`: SUCCESS for both `runtime-smoke` and `phase1-visual-capture`.
- Runtime smoke executes on Godot `4.7.1.stable.official.a13da4feb` and passes the real app routes, Build | Play state, inspector/drawer behavior, transform-shell presence, focus graph, and Cancel priority.
- Final visual evidence artifact: `phase1-visual-evidence`, artifact ID `9101929849`, digest `sha256:89d7c9df439f9814a9ac129e43fcbdab1e2c5aa9b1a5166c16fb2afffc1fa639`.

## Phase 1 exit decision
PASS for Phase 1-owned UI foundation. Later-phase production systems depicted in the composite canonical board remain Not Yet Applicable and must replace honest shells as they are implemented.

## Phase 2 decomposition
- P02-T01 Stable ID utility + Small/Medium/Large profile contracts.
- P02-T02 World-project model + atomic create/open/save repository.
- P02-T03 Persistent New World integration + project reopening.
- P02-T04 Stable world-entity record + registry.
- P02-T05 Command/transaction + undo/redo framework.
- P02-T06 Crash-safe autosave/checkpoint recovery.
- P02-T07 Phase 2 integration tests + persistence hardening.

## Next authorized task
`P02-T01 — Implement stable ID utility and Small/Medium/Large world-profile contracts`

## P02-T01 boundary
Implement only reusable stable UUID generation/validation plus concrete runtime world-profile data for Small, Medium, and Large/streamed. Do not create/save project files, entity registries, command history, or autosave yet.

## New-thread start prompt
Read `docs/architecture/PERSISTENT_ID_SCHEMA_CONVENTIONS.md`, `docs/PRODUCT_REQUIREMENTS.md`, `config/project_defaults.json`, `docs/implementation/CODING_STANDARDS.md`, `docs/implementation/TASK_BACKLOG.md`, and this file. Implement only P02-T01 with deterministic validation tests. Then update this handoff and authorize only P02-T02.
