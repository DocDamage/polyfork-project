# Codex Execution Rules

## Purpose
Keep implementation grounded, verifiable, resumable across threads, and efficient enough to make meaningful progress before review gates.

## Repository authority
The repository default branch and real project source of truth is `master`. The historical `main` branch contains obsolete starter code and must not be used as a development base. Before branching, compare the live `master` SHA with `docs/handoffs/CURRENT_HANDOFF.md`.

## Milestone workflow
A **task** is an implementation checkpoint such as `P03-T04`. A **milestone** is the larger authorized delivery range that may contain several consecutive tasks, usually a complete implementation phase or an explicitly grouped subset of one.

Pull requests are milestone gates, not task gates. Internal task boundaries remain useful for scope, commits, tests, and debugging, but they do not require stopping development or opening a PR unless the current handoff explicitly says otherwise.

## Rules
1. Read `README.md`, `docs/PRODUCT_REQUIREMENTS.md`, `docs/implementation/MASTER_IMPLEMENTATION_PLAN.md`, and `docs/handoffs/CURRENT_HANDOFF.md` before modifying code.
2. Verify the live repository default/authoritative `master` branch and never substitute historical `main`.
3. Implement only the milestone or task range explicitly authorized by `CURRENT_HANDOFF.md`. The handoff may authorize multiple consecutive task IDs when they belong to one milestone.
4. Work continuously through the authorized milestone on one focused branch. Do not stop merely because an internal task ID is complete.
5. Commit at sensible internal checkpoints and run real verification throughout the milestone. Intermediate CI failures are evidence to investigate, not a reason to weaken tests or prematurely open a PR.
6. Open a PR only when the authorized milestone is complete and verified, or when a genuine external blocker requires review/decision before safe progress can continue.
7. Do not merge PRs unless the user explicitly authorizes the merge.
8. Prefer code files <=300 LOC where practical. Split by responsibility, not arbitrary line count.
9. No stubs presented as finished work.
10. Never weaken tests to make broken behavior pass.
11. Every authored mutation must go through the command/transaction system once that system exists.
12. Successful authored mutations must integrate dirty-state signaling so autosave/checkpoint behavior remains correct.
13. Persistent references use stable IDs, not scene-tree paths or transient network IDs.
14. External asset source folders are read-only.
15. UI work must compare against `assets/reference/CANONICAL_UI_REFERENCE.png`.
16. Core flows require keyboard/mouse and gamepad verification.
17. Update architecture/schema/system docs when those contracts change. Update `TASK_BACKLOG.md` as internal tasks become complete, but do not create a new PR solely for task-status bookkeeping.
18. At milestone completion, update `CURRENT_HANDOFF.md` with the milestone result, changed files, verification evidence, unresolved risks, and exactly one next authorized milestone/gate.
19. If a defect is discovered inside the authorized milestone, fix and verify it in the same milestone branch when the fix is required for milestone acceptance. Do not defer a necessary defect merely to preserve artificial task boundaries.
20. Distinguish infrastructure failures that prevent tests from executing from failures in executed product tests. Never call an unexecuted test a pass, and never patch product code solely to mask a runner/download outage.
21. User instructions override the default milestone size. If the user asks for larger or smaller review gates, update the handoff/execution rules accordingly.

## Required milestone completion report
- Milestone / task range
- Summary
- Internal tasks completed
- Files changed
- Tests/commands run
- Runtime/manual verification
- Screenshots/evidence where relevant
- Known limitations
- Current PR/branch/head state
- Next authorized milestone or merge gate
