# Current Handoff

## Status
OPEN

## Project state
Phase 0, Phase 1, P02-T01, and P02-T02 are complete. Versioned world-project manifests can now be created, validated, atomically saved, reopened, and safely rejected when malformed. The hardened Godot CI gate rejects script/engine errors even when Godot returns exit code zero.

## Completed task
`P02-T02 — Implement world-project model and atomic create/open/save repository`

## Evidence
- Added `src/world/world_project.gd` with schema-versioned project data, stable project ID, profile/template identity, registries, environment/editor/export data, and timestamps.
- Added `src/world/project_repository.gd` with create/open/save, validated sibling temporary writes, flush/re-read validation, and atomic replacement of `project.json`.
- Added `tests/integration/project_repository_contracts.gd` covering creation, reopening, update persistence, malformed ID rejection, malformed JSON rejection, rejected-save preservation, and temporary-file cleanup.
- Updated `schemas/world_project.example.json` with the implemented timestamp fields.
- Hardened `.github/workflows/godot-smoke.yml` so Godot `SCRIPT ERROR` or engine `ERROR` output fails CI even if the engine process exits zero.
- GitHub Actions run `31494765859`, runtime-smoke job `93789603111`: SUCCESS on Godot `4.7.1.stable.official.a13da4feb` with a clean log and explicit `PASS: PlayWorld Studio test harness completed.`

## Known limitations
The user-facing New World/Continue flows are not connected to this repository yet. World entities, commands, and recovery saves remain unimplemented.

## Next authorized task
`P02-T03 — Integrate New World creation with persistent projects and project reopening`

## Task boundary
Connect the existing New World UI to real project creation and make Continue reopen the most recently updated valid project. Add the minimum project-list/recent-project repository API needed for this flow. Do not implement a full project-management browser, entities, commands, or recovery saves.

## New-thread start prompt
Read the Home/New World/Workspace scripts, `src/world/project_repository.gd`, `src/world/world_project.gd`, and this file. Implement only P02-T03 with isolated test storage, real create/reopen flow coverage, and no fake project labels. Then authorize only P02-T04.
