# POLYFORK PROJECT — PHASE 13 ACTIVE HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authoritative branch
The real project lives on `master`.

Authoritative pre-Phase-13 `master`:

`b2a97a6cea52c6620f2b826a390a1d2d531ad81e`

This is the verified merge commit for PR #17 — Phase 12 — AI Creation. PR #17 is merged. Phases 0 through 12 are complete.

The repository default branch `main` remains obsolete starter code. **Never develop from `main`.**

## Active milestone
Phase 13 — Export Pipeline is authorized and active on:

`dev/phase13-export-pipeline-milestone`

The branch was created from exactly:

`b2a97a6cea52c6620f2b826a390a1d2d531ad81e`

Before Phase 13 writes, GitHub compare verification reported:
- merge base exactly `b2a97a6cea52c6620f2b826a390a1d2d531ad81e`;
- 0 commits ahead;
- 0 commits behind;
- no obsolete `main` ancestry used.

## Phase 12 closeout correction
The prior handoff/implementation-plan gate language was stale after PR #17 merged. Phase 12 is now recorded as complete and Phase 13 is unblocked.

Phase 12 delivered local/cloud OpenAI-compatible providers, privacy/cloud consent, bounded read-only project/catalog queries, Suggest, zero-mutation Preview, Preview-before-Execute, structured validation, locally generated IDs, missing-asset rejection, atomic cross-system Execute, one universal Undo/Redo entry, rollback, crash-safe execution history, cross-system AI actions, native keyboard/mouse/gamepad AI workspace, strict tests/regressions/Godot Smoke/rendered evidence, and removal of the tracked `.polyforkAPI` file.

Historical `.polyforkAPI` credential material remains exposed in Git history and should be rotated/revoked separately.

## Phase 13 architecture rule
Do not create a parallel runtime architecture. Standalone exports must reuse the Phase 7 Play/runtime foundation and existing authored/runtime systems from Phases 2–12.

## Phase 13 internal checkpoints
The milestone is decomposed before implementation in `docs/implementation/PHASE13_EXPORT_PIPELINE_PLAN.md` and `TASK_BACKLOG.md`.

Required coverage includes:
- export/build manifest and schema;
- deterministic editor-only/runtime-required classification;
- dependency discovery and Phase 4 Asset Library resolution;
- missing-dependency failure handling;
- license/attribution collection and export report;
- deterministic staging and editor stripping while preserving runtime-required authored data;
- Phase 7 runtime bootstrap reuse;
- Windows standalone export first;
- deterministic package layout and repeat-export idempotency;
- Build → Export → standalone launch smoke;
- clean-machine-style launch/package verification;
- keyboard/mouse and gamepad runtime verification;
- Small/Medium/Large project verification;
- strict Godot logs, inherited Phase 6–12 regressions, and rendered/exported runtime evidence;
- documentation closeout.

## Milestone / PR rule
Work Phase 13 continuously on the milestone branch. Intermediate commits and CI runs are expected. Do not stop for task-by-task pull requests.

At Phase 13 completion:
1. finish the full milestone;
2. run all Phase 13 and inherited regression gates;
3. close implementation-plan/backlog/handoff documentation;
4. open one Phase 13 completion PR targeting authoritative `master`;
5. do not merge it without explicit user authorization.

Do not begin Phase 14 until that completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.
