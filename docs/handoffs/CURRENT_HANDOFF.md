# POLYFORK PROJECT — PHASE 14 HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## AUTHORITATIVE BRANCH
The real project lives on:

`master`

Current authoritative `master`:

`cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`

This is the verified signed merge commit for **PR #18 — Phase 13 — Export Pipeline**. PR #18 is confirmed merged.

The repository default branch `main` remains obsolete starter code. **Never develop from `main`.**

## COMPLETED PROJECT STATE
Phases **0 through 13 are complete and merged** into authoritative `master`.

Phase 13 delivered the Windows-first export pipeline, including:
- deterministic export/build manifests and package layout;
- exact runtime dependency closure;
- editor-only stripping with runtime-required authored-data preservation;
- Phase 4 Asset Library dependency resolution and missing-dependency failures;
- deterministic license/attribution reporting;
- standalone bootstrap reusing the existing Phase 7 `PlaySession` rather than a parallel runtime;
- repeat-export replacement/idempotency;
- Small/Medium/Large Windows package verification;
- clean-package standalone launch verification;
- keyboard/mouse and gamepad semantic-input verification;
- canonical Build → Export UX;
- strict Phase 13 contracts, inherited Phase 6–12 regressions, Godot Smoke, rendered UI evidence, and exported runtime evidence.

PR #18 finished with all triggered CI green. Several isolated legacy matrix jobs initially failed before tests ran because GitHub-hosted runners could not complete Godot 4.7.1 downloads; reruns succeeded and the actual contract suites passed without code changes.

## SECURITY REMINDER
The tracked `.polyforkAPI` file was removed during Phase 12, but historical credential material remains in Git history and must still be treated as exposed and rotated/revoked separately.

## PHASE 14 BRANCH
Phase 14 — Scale and Polish is now unblocked.

Milestone branch:

`dev/phase14-scale-polish-milestone`

The branch was created from exactly:

`cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`

Before any Phase 14 writes, GitHub compare verification reported:
- merge base exactly `cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`;
- 0 commits ahead;
- 0 commits behind;
- no obsolete `main` ancestry used.

The first writes on the branch are documentation-only post-merge corrections and Phase 14 planning. No Phase 14 implementation code has been added by this handoff update.

## NEXT MILESTONE
**Phase 14 — Scale and Polish**

Phase 14 is a hardening/polish milestone, not a new feature-architecture phase. Existing systems from Phases 0–13 remain authoritative and should be optimized, completed, and visually/accessibly hardened rather than replaced.

Required milestone outcomes include:
- reproducible performance telemetry and budgets;
- Low/Balanced/High quality-performance presets;
- Small/Medium/Large plus stress-scale profiling;
- terrain/streaming/entity/procedural/Environment/runtime performance hardening;
- large-project editor responsiveness and save/open/Build↔Play/export stress verification;
- accessibility scaling, contrast/focus, reduced-motion, and non-color-only status communication;
- persistent accessibility preferences;
- full controller navigation/focus/glyph/remapping coverage across existing workspaces and flows;
- touch-ready/adaptive layouts without a separate mobile architecture;
- canonical UI parity sweep against the approved dark playful Nintendo/Apple-inspired design language;
- removal of generic slate/enterprise visual drift;
- strict performance/accessibility/controller/adaptive-layout/UI regression gates;
- inherited Phase 6–13 regression coverage;
- strict Godot log gates and rendered evidence;
- documentation closeout.

Detailed internal checkpoints are defined in:

`docs/implementation/PHASE14_SCALE_POLISH_PLAN.md`

and:

`docs/implementation/TASK_BACKLOG.md`

## MILESTONE / PR RULE
Work Phase 14 continuously on `dev/phase14-scale-polish-milestone`. Intermediate commits and CI runs are expected.

Do **not** stop for task-by-task pull requests.

At Phase 14 completion:
1. finish the full milestone;
2. run all Phase 14 and inherited regression gates;
3. close implementation-plan/backlog/handoff documentation;
4. open **one** Phase 14 completion PR targeting authoritative `master`;
5. do not merge it without explicit user authorization.

Do not begin Phase 15 until that completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.
