# Current Handoff

## Status
OPEN

## Project state
Phase 0 and Phase 1 are complete on `master`. Phase 2 is complete through P02-T04. The merged code includes stable IDs/world profiles, atomic world-project persistence, real New World + Continue reopening, and stable world-entity/registry foundations. P02-T05 through P02-T07 are not implemented in the merged branch.

## Repository branch state
- PR #2 was merged into `master` at merge commit `464e34efda77cbf5d72edf20a8a30ed4cad25b60`.
- The repository's current default branch is `main`.
- `main` is still the starter branch and does not contain the implementation/docs currently present on `master`.
- Until that branch mismatch is intentionally resolved, implementation work must explicitly target `master` or a branch created from `master`.

## Completed task
`P02-T04 — Implement stable world-entity record and registry foundation`

## Evidence for P02-T03
- `src/main/main.gd` now creates `PlayWorldProjectRepository` from the configured projects root.
- New World creation calls the real repository before entering the workspace.
- The workspace receives persisted project data, including the stable project ID.
- Home/Continue resolves the most recently updated valid project through the repository and reopens it instead of using a hard-coded project label.
- New World surfaces repository creation failures rather than pretending a project was created.

## Evidence for P02-T04
- `src/world/world_entity.gd` defines a schema-versioned stable world-entity record with UUID identity, stable cell/asset/prefab/parent/component references, and serializable transform data.
- Entity persistence does not use scene-tree paths, node names, or array indexes as identity.
- `src/world/entity_registry.gd` enforces entity validation and unique stable IDs while supporting lookup, removal, enumeration, and clear operations.
- `tests/unit/entity_registry_contracts.gd` is present in the merged branch and covers the entity/registry contract.

## Existing persistence/CI foundation
- `src/world/world_project.gd` and `src/world/project_repository.gd` provide versioned project manifests and validated atomic replacement.
- `.github/workflows/godot-smoke.yml` runs the Godot test harness and is designed to reject script/engine errors instead of relying only on the process exit code.

## Not implemented yet
- P02-T05 command/transaction/undo/redo framework.
- P02-T06 crash-safe autosave/checkpoint recovery.
- P02-T07 Phase 2 lifecycle closeout and persistence hardening.
- Phase 3 runtime placement/editor behavior.

## Next authorized task
`P02-T05 — Implement command, transaction, undo, and redo framework`

## P02-T05 boundary
Implement only the generic mutation framework: command interface/base contract, grouped transactions, one history entry per successful transaction, rollback on partial transaction failure, undo/redo stacks, redo invalidation after a divergent edit, and bounded history. Do not implement autosave/checkpoint recovery or Phase 3 placement behavior in this task.

## New-thread start prompt
Work from `master` (not the stale `main` branch). Read `docs/implementation/CODEX_EXECUTION_RULES.md`, `docs/implementation/CODING_STANDARDS.md`, `docs/architecture/PERSISTENT_ID_SCHEMA_CONVENTIONS.md`, `docs/architecture/DATA_MODEL.md`, `docs/implementation/TASK_BACKLOG.md`, and this file. Implement only P02-T05 with real Godot tests for execute, grouped transaction success, rollback on failure, undo, redo, redo invalidation, and bounded history. Then update the handoff and authorize only P02-T06.
