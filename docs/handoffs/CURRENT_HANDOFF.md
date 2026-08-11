# Current Handoff

## Status
OPEN

## Project state
P00-T01 through P00-T04 are complete. The repository has the modular Godot scaffold, coding/documentation standards, persistent identity/schema contracts, and a dependency-free Godot-native runtime smoke harness. Phase 1 UI work has not started yet.

## Canonical UI
`assets/reference/CANONICAL_UI_REFERENCE.png`

## Completed task
`P00-T04 — Implement test harness and runtime smoke-test scene`

## P00-T04 implementation evidence
- Added `tests/test_runner.gd`, a Godot `SceneTree` test runner that loads the runtime smoke scene and exits `0` on success or `1` on failure.
- Added `tests/runtime/RuntimeSmoke.tscn` and `tests/runtime/runtime_smoke.gd`.
- The runtime smoke behavior loads and instantiates the actual `src/main/Main.tscn`, verifies the Phase 0 root remains a `Control`, verifies the `PlayWorld Studio` title, and checks the scaffold subtitle exists.
- Added `tests/README.md` documenting the exact headless command: `godot --headless --path . --script res://tests/test_runner.gd`.
- The harness performs real scene loading/instantiation rather than asserting constants or symbol existence only.

## Tests/commands run
- Godot CLI execution could not be run in the current agent environment because no Godot executable is installed.
- Repository structure and resource/script references were verified through the connected GitHub repository contents.

## Known limitations
- Runtime pass/fail remains unobserved until the documented command is run in an environment with Godot 4.7.x.
- Unit/integration suites remain intentionally empty until their owning feature tasks exist.

## Next authorized task
`P00-T05 — Add canonical UI visual reference and comparison checklist`

## P00-T05 boundary
Confirm the canonical image is committed and create a concrete visual comparison/checklist workflow. Do not implement Phase 1 UI yet.

## New-thread start prompt
Read `docs/design/UI_UX_CANONICAL_SPEC.md`, `docs/design/DESIGN_TOKENS.md`, `docs/qa/UI_VISUAL_ACCEPTANCE.md`, `assets/reference/CANONICAL_UI_REFERENCE.png`, `docs/implementation/TASK_BACKLOG.md`, and this file. Implement only P00-T05 by establishing a repeatable canonical UI comparison checklist/workflow without modifying the application UI. Then update the handoff and authorize only P01-T01.
