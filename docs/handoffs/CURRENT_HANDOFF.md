# Current Handoff

## Status
OPEN — P02-T07 implementation is complete and verified on its task branch; merge is still required before `master` reflects Phase 2 completion.

## Project state
Phase 0 and Phase 1 are complete on authoritative `master`.

PR #5 merged P02-T06 into `master` at merge commit `c6af112ef6044ef2bef1b4325206e6693fabb694`. P02-T07 was then implemented from that exact baseline on `dev/p02-t07-phase2-closeout`.

All Phase 2 tasks are complete on the P02-T07 branch. Phase 3 has not started. `master` becomes the completed Phase 2 baseline only after the P02-T07 PR is reviewed and merged.

The repository default branch remains the obsolete starter branch `main`; do not develop from it. The authoritative project branch remains `master`.

## Completed task
`P02-T07 — Complete Phase 2 integration tests and persistence hardening`

## Persistence hardening added
- `WorldProject` now persists an additive optional schema-v1 `entities` collection so the existing `WorldEntity`/`EntityRegistry` foundation actually survives save and reopen.
- Persisted entity records are validated for stable UUID identity, duplicate entity IDs, owning project cell membership, resolvable parent references, and self-parenting.
- `EntityRegistry` can serialize its stable-ID-sorted records and reconstruct itself from persisted dictionaries while rejecting duplicate and unresolved/self parent identities.
- A P02-T07 integration run exposed a real nullable-ID defect in `WorldEntity`: JSON `null` optional UUID fields were previously converted through `str(null)` during load, creating bogus non-empty runtime references. `WorldEntity` now maps persisted null optional IDs back to empty runtime references.
- Legacy schema-v1 project manifests without additive `entities` or millisecond timestamp fields remain supported.
- Unsupported future world-project schemas still fail explicitly and do not receive a hidden fallback.

## Integrated lifecycle verification
`tests/integration/phase2_lifecycle_contracts.gd` verifies realistic Phase 2 flows:
- create project -> create/register stable entities -> persist -> reopen -> reconstruct registry -> verify stable IDs, parent references, and authored transform state;
- execute a generic project mutation through command history -> save -> reopen;
- undo -> save -> reopen and verify the undone state;
- redo -> save -> reopen and verify the redone state;
- transaction with a later injected command failure -> rollback prior successful command -> verify failed transaction never enters history -> save/reopen known-good state;
- command-authored dirty state -> autosave checkpoint -> simulated repository restart -> recovery -> verify recovered command state and stable project identity;
- bounded history during realistic project mutation and persistence.

`tests/integration/phase2_persistence_hardening_contracts.gd` verifies:
- supported legacy schema-v1 manifests load through documented optional-field fallback;
- unsupported future world-project schema versions fail explicitly;
- unresolved `parent_entity_id` persistence is rejected while preserving the prior canonical manifest;
- duplicate persisted entity identities are rejected with actionable errors.

The existing P02-T06 contracts remain active and continue to cover corrupted checkpoints, unsupported checkpoint schema, interrupted temporary writes, failed canonical writes, failed checkpoint promotion, failed recovery promotion, bounded checkpoint retention, stable checkpoint/project identity, and scene-tree-path relationship regression.

## Real Home -> Continue verification
`tests/runtime/continue_reopen_smoke.gd` creates a project through the real app shell, constructs a fresh app instance against the same on-disk storage root, emits the Home `continue` route, and verifies that the persisted project reopens into the workspace with the expected title.

This closes the previous runtime evidence gap where New World creation was exercised but the actual restart/Continue path was not.

## Verification evidence
Initial P02-T07 implementation commit:
`722a530fba36e34a89ca70e43e35b5db72017897`

Workflow run `31506840432` correctly FAILED `runtime-smoke` while visual capture passed. The log exposed:
- typed-array fixture assignment errors; and
- the real nullable optional-UUID load defect described above.

The tests were not weakened.

Hardening fix commit:
`7e89d4a9d1323c1cd303433ca1cf7c83184a7dbd`

Workflow run `31507033430` then passed both:
- `runtime-smoke` — SUCCESS
- `phase1-visual-capture` — SUCCESS

Continue/restart verification commit:
`a70d016aff4050dcc73c369390d2263fea07b4da`

Workflow run `31507218527` used Godot `4.7.1.stable.official.a13da4feb` and passed both:
- `runtime-smoke` — SUCCESS
- `phase1-visual-capture` — SUCCESS

The runtime log contains `PASS: PlayWorld Studio test harness completed.` and contains no `SCRIPT ERROR:` or engine `ERROR:` output. The real Home -> Continue restart flow executed during that harness run.

The visual-capture workflow remains unchanged, including `--audio-driver Dummy`, `--disable-vsync`, strict script/engine error rejection, and the existing Phase 1 screenshot evidence path.

After this documentation closeout commit, require one final branch workflow run and record that run in the P02-T07 PR/completion report before treating the PR as ready to merge.

## Changed files
- `src/world/world_project.gd`
- `src/world/world_entity.gd`
- `src/world/entity_registry.gd`
- `tests/unit/fixtures/project_title_command.gd`
- `tests/integration/phase2_lifecycle_contracts.gd`
- `tests/integration/phase2_persistence_hardening_contracts.gd`
- `tests/runtime/continue_reopen_smoke.gd`
- `tests/test_runner.gd`
- `docs/architecture/DATA_MODEL.md`
- `docs/implementation/TASK_BACKLOG.md`
- `docs/handoffs/CURRENT_HANDOFF.md`

## Phase 2 acceptance state
The P02-T07 branch now demonstrates:
- stable project/world UUIDs and Small/Medium/Large profiles;
- project create/open/crash-safe save;
- persistent New World and real Continue/reopen;
- stable world entities and registry reconstruction across persistence;
- generic commands, grouped transactions, rollback, bounded undo/redo;
- save after commands, undo then save, redo then save;
- crash-safe autosave, checkpoints, recovery, retention and corruption handling;
- explicit supported/unsupported schema behavior;
- known-good canonical preservation across tested failure paths;
- strict real-Godot 4.7.1 execution with the existing UI visual capture intact.

## Known residual limitations
- Recovery detection/operation exists, but a dedicated user recovery-choice UI is still deferred; Phase 2 does not redesign the canonical UI.
- Dirty state remains explicit infrastructure. Future successful authoring commands must mark the active project dirty.
- Entity records are embedded in the Phase 2 project manifest. Later world-partition/streaming work may move large entity sets into cell-owned storage through a documented migration; no current identity depends on file location.
- The obsolete `main` versus authoritative `master` branch mismatch remains intentionally unresolved.

## Phase 3 decomposition
Phase 3 is decomposed in `docs/implementation/TASK_BACKLOG.md` as P03-T01 through P03-T09. Do not implement multiple tasks at once.

## Next authorized task
Only after the P02-T07 PR is merged into `master`, authorize only:

`P03-T01 — Implement runtime entity scene bridge and single-selection foundation`

Do not begin P03-T02 or any broader Phase 3 work in the same authorization step.

## New-thread start prompt
Verify the P02-T07 PR has been merged into authoritative `master`; never develop from stale default `main`. Read the standard project/architecture/implementation documents and this handoff. If Phase 2 completion is present on `master`, implement only `P03-T01 — Implement runtime entity scene bridge and single-selection foundation`. All authoring mutations must use the command/transaction framework, successful mutations must integrate dirty-state signaling, persisted relationships remain stable-ID based, and UI changes must preserve the canonical dark/playful Nintendo-forward visual direction. Do not begin P03-T02 until P03-T01 is verified, documented, and merged.
