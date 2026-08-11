# Current Handoff

## Status
OPEN

## Project state
P00-T01 is complete. The Godot 4.7.x starter scaffold remains intentionally neutral, and the repository now contains the initial modular source and test directory structure required by `docs/implementation/REPO_STRUCTURE.md`. No gameplay or editor architecture has been prematurely implemented.

## Canonical UI
`assets/reference/CANONICAL_UI_REFERENCE.png`

## Completed task
`P00-T01 — Create Godot 4.7.x project and repository structure`

## P00-T01 implementation evidence
- `project.godot` exists and declares `res://src/main/Main.tscn` as the main scene.
- `src/main/Main.tscn` exists, references `res://src/main/main.gd`, and remains a minimal neutral scaffold.
- Required initial source roots are tracked: `src/app`, `src/editor`, `src/commands`, `src/world`, `src/assets`, `src/gameplay`, `src/visual_script`, `src/terrain`, `src/foliage`, `src/splines`, `src/environment`, `src/ai`, `src/export`, `src/input`, and `src/diagnostics`.
- Required test roots are tracked: `tests/unit`, `tests/integration`, and `tests/runtime`.
- GitHub comparison of `master...dev/p00-t01-project-structure` confirmed the implementation commit added only the 18 expected directory marker files before the backlog/handoff closeout updates; no unrelated production systems were added.
- Runtime launch verification could not be executed in the current agent environment because no Godot executable is installed. This limitation is recorded rather than reported as a pass.
- The automated test harness and runtime smoke-test scene remain explicitly scheduled for `P00-T04`; they were not pulled forward into P00-T01.

## Next authorized task
`P00-T02 — Add coding/documentation rules`

## P00-T02 boundary
Implement only P00-T02. Do not start P00-T03 or later work. Preserve the modular architecture and neutral main scene unless P00-T02 documentation rules explicitly require a documentation-only clarification.

## New-thread start prompt
Read `README.md`, `docs/PRODUCT_REQUIREMENTS.md`, `docs/implementation/MASTER_IMPLEMENTATION_PLAN.md`, `docs/implementation/CODEX_EXECUTION_RULES.md`, `docs/implementation/TASK_BACKLOG.md`, and this file. Implement only P00-T02. Verify the exact documentation/rule changes against the Phase 0 architecture constraints. Then update this handoff with evidence and authorize only P00-T03.
