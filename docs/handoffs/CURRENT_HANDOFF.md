# Current Handoff

## Status
OPEN

## Project state
Phase 0 and Phase 1 are complete. P02-T05 is merged into `master` through PR #4 at merge commit `e0d9efa91f29d55279a127f82e5d8a5f6b92fb9e`. P02-T06 is complete and verified on `dev/p02-t06-autosave-recovery`, but is not merged into `master` yet. Therefore the current merged `master` baseline remains complete through P02-T05 until the P02-T06 PR is reviewed and merged. P02-T07 remains incomplete. Phase 3 has not started.

## Repository branch state
- Authoritative project branch: `master`.
- Current P02-T06 baseline: `master` at `e0d9efa91f29d55279a127f82e5d8a5f6b92fb9e`.
- P02-T06 implementation branch: `dev/p02-t06-autosave-recovery`, created directly from that `master` baseline.
- The repository default branch remains `main`; it is still the obsolete starter branch and was not used for this work.
- The default branch was intentionally not changed.
- Do not merge the P02-T06 PR unless explicitly instructed by the user.

## Completed task on the implementation branch
`P02-T06 — Implement crash-safe autosave and checkpoint recovery`

## P02-T06 architecture added
- `src/world/safe_json_writer.gd` centralizes crash-safe JSON writes: unique temporary file, flush/close, read-back parse, semantic validation, and promotion only after validation succeeds. Failed writes/promotions remove the candidate and preserve the prior final file.
- `src/world/checkpoint_record.gd` defines schema-v1 `world_checkpoint` documents with a stable checkpoint UUID, owning stable `project_id`, millisecond creation timestamp, and validated `WorldProject` snapshot.
- `src/world/checkpoint_store.gd` owns checkpoint persistence, deterministic newest-first selection, project association, recovery-state classification, and bounded retention. Recovery inspection distinguishes valid newer checkpoints, corrupted checkpoints, unsupported future schemas, incomplete temporary writes, non-newer checkpoints, and missing checkpoints.
- `src/world/autosave_service.gd` owns autosave timing and explicit dirty state. Clean projects are not rewritten merely because the timer fires, and dirty state is cleared only after a successful checkpoint.
- `src/world/project_repository.gd` now uses the shared safe writer for canonical saves, exposes checkpoint/recovery operations, preserves canonical state on failed recovery, and reports recovery availability when projects are opened.
- `src/world/world_project.gd` adds backward-compatible optional millisecond timestamps under schema v1 so canonical saves and checkpoints created in the same Unix second can still be ordered deterministically. Legacy schema-v1 manifests without the millisecond fields remain loadable through Unix timestamp fallback.
- `src/main/main.gd` attaches the autosave service to the active project and advances its timer. It exposes `mark_project_dirty()` for future command-driven dirty tracking and reports detected recovery availability without silently overwriting canonical state.
- Autosave remains persistence infrastructure rather than an authoring mutation; no Phase 3 placement or gameplay-specific commands were introduced.

## Behavioral tests added
`tests/integration/autosave_checkpoint_contracts.gd` verifies real persistence behavior, including:
- dirty checkpoint creation after the configured interval;
- clean-state suppression and no redundant checkpoint creation;
- checkpoint reload across a fresh repository instance;
- stable checkpoint UUID and stable project association;
- canonical project data remaining unchanged by ordinary autosave/checkpoint creation;
- valid newer recovery detection;
- valid recovery restoring intended state while preserving `project_id`;
- recovered state surviving a fresh reopen;
- injected explicit-save failure before promotion preserving the prior canonical manifest;
- injected checkpoint promotion failure preserving the previous known-good checkpoint;
- injected recovery promotion failure preserving canonical data;
- corrupted checkpoint rejection;
- unsupported future checkpoint schema rejection;
- incomplete temporary checkpoint detection without canonical replacement;
- deterministic bounded retention keeping the newest valid checkpoints;
- regression coverage preventing scene-tree-path relationships from entering checkpoint persistence.

`tests/test_runner.gd` runs these contracts together with the existing world foundation, repository, command-history, and runtime smoke tests.

## Changed files
- `src/main/main.gd`
- `src/world/autosave_service.gd`
- `src/world/checkpoint_record.gd`
- `src/world/checkpoint_store.gd`
- `src/world/project_repository.gd`
- `src/world/safe_json_writer.gd`
- `src/world/world_project.gd`
- `tests/integration/autosave_checkpoint_contracts.gd`
- `tests/test_runner.gd`
- `docs/architecture/SYSTEM_ARCHITECTURE.md`
- `docs/architecture/DATA_MODEL.md`
- `docs/implementation/TASK_BACKLOG.md`
- `docs/handoffs/CURRENT_HANDOFF.md`

## Verification evidence
Implementation commit before documentation closeout: `be45e9a1d7db88e9ae78c6c86c135a794a3a860f`.

GitHub Actions workflow run `31505363692` executed the implementation with Godot `4.7.1.stable.official.a13da4feb` and completed successfully:
- `runtime-smoke` — SUCCESS;
- `phase1-visual-capture` — SUCCESS.

The runtime log contains `PASS: PlayWorld Studio test harness completed.` and no `SCRIPT ERROR:` or engine `ERROR:` output. The workflow's strict log rejection remained unchanged.

The visual-capture job retained `--audio-driver Dummy` and `--disable-vsync`, produced the existing five Phase 1 evidence images, and contains `PASS: Phase 1 rendered screenshots captured.` with no `SCRIPT ERROR:` or engine `ERROR:` output. A graphics-driver V-Sync warning remains a warning, not an engine error.

The branch must receive one final Godot 4.7.1 workflow verification after this documentation closeout commit before the PR is treated as ready for review. Record that final run in the PR/completion report.

## Failure-path evidence
The test suite injects failures immediately before promotion rather than pretending a write succeeded. It proves that failed canonical saves preserve the prior manifest, failed checkpoint writes preserve the prior recoverable checkpoint set, and failed recovery promotion preserves canonical data. Corrupted, unsupported, and incomplete recovery candidates are classified and rejected instead of being silently loaded.

## Known limitations and residual risks
- P02-T06 provides recovery detection and a deterministic recovery operation, but does not add a new recovery-choice UI. The existing app shell only reports that a recoverable checkpoint is available; UI expansion is not required for the persistence foundation and no canonical UI redesign was introduced.
- Dirty state is explicit infrastructure. Future authoring commands must call the dirty-state entrypoint after successful mutations; P02-T06 deliberately does not invent Phase 3 authoring commands to exercise that wiring.
- Checkpoint retention defaults to five valid snapshots. Failure to remove an expired checkpoint is surfaced as a warning rather than invalidating a newly proven valid checkpoint.
- The obsolete `main`/authoritative `master` branch mismatch remains intentionally unresolved.

## Next authorized task
Only after the P02-T06 PR is merged into `master`, authorize:

`P02-T07 — Complete Phase 2 integration tests and persistence hardening`

Do not stack P02-T07 on the unmerged P02-T06 branch. Do not begin Phase 3.

## New-thread start prompt
Work from `master` only after the P02-T06 PR has been merged there; never use the stale default `main` branch. Read `README.md`, `docs/PRODUCT_REQUIREMENTS.md`, `docs/PROJECT_CHARTER.md`, `docs/design/UI_UX_CANONICAL_SPEC.md`, `docs/architecture/SYSTEM_ARCHITECTURE.md`, `docs/architecture/PERSISTENT_ID_SCHEMA_CONVENTIONS.md`, `docs/architecture/DATA_MODEL.md`, `docs/implementation/MASTER_IMPLEMENTATION_PLAN.md`, `docs/implementation/CODEX_EXECUTION_RULES.md`, `docs/implementation/CODING_STANDARDS.md`, `docs/implementation/TASK_BACKLOG.md`, and this file. Verify the merged P02-T06 baseline, then implement only P02-T07 with realistic lifecycle integration and persistence hardening. Do not begin Phase 3. At Phase 2 completion, update the backlog/handoff with final Godot 4.7.1 evidence and authorize only the first decomposed Phase 3 task.
