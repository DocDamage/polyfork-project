# Codex Execution Rules

## Purpose
Keep implementation grounded, verifiable, resumable across threads, and efficient enough to make meaningful progress before review gates.

## Milestone workflow
A **task** is an implementation checkpoint such as `P03-T04`. A **milestone** is the larger authorized delivery range that may contain several consecutive tasks, usually a complete implementation phase or an explicitly grouped subset of one.

Pull requests are milestone gates, not task gates. Internal task boundaries remain useful for scope, commits, tests, and debugging, but they do not require stopping development or opening a PR unless the current handoff explicitly says otherwise.

## Rules
1. Read `README.md`, `docs/PRODUCT_REQUIREMENTS.md`, `docs/implementation/MASTER_IMPLEMENTATION_PLAN.md`, and `docs/handoffs/CURRENT_HANDOFF.md` before modifying code.
2. Implement only the milestone or task range explicitly authorized by `CURRENT_HANDOFF.md`. The handoff may authorize multiple consecutive task IDs when they belong to one milestone.
3. Work continuously through the authorized milestone on one focused branch. Do not stop merely because an internal task ID is complete.
4. Commit at sensible internal checkpoints and run real verification throughout the milestone. Intermediate CI failures are evidence to fix, not a reason to weaken tests or prematurely open a PR.
5. Open a PR only when the authorized milestone is complete and verified, or when a genuine external blocker requires review/decision before safe progress can continue.
6. Do not merge PRs unless the user explicitly authorizes the merge.
7. Prefer code files <=300 LOC where practical. Split by responsibility, not arbitrary line count.
8. No stubs presented as finished work.
9. Never weaken tests to make broken behavior pass.
10. Every authoring mutation must go through the command/transaction system once that system exists.
11. Successful authoring mutations must integrate dirty-state signaling so autosave/checkpoint behavior remains correct.
12. Persistent references use stable IDs, not scene-tree paths.
13. External asset source folders are read-only.
14. UI work must compare against `assets/reference/CANONICAL_UI_REFERENCE.png`.
15. Core flows require keyboard/mouse and gamepad verification.
16. Update architecture/schema docs when those contracts change. Update `TASK_BACKLOG.md` as internal tasks become complete, but do not create a new PR solely for task-status bookkeeping.
17. At milestone completion, update `CURRENT_HANDOFF.md` with the milestone result, changed files, verification evidence, unresolved risks, and the next authorized milestone.
18. If a defect is discovered inside the authorized milestone, fix and verify it in the same milestone branch when the fix is required for milestone acceptance. Do not defer a necessary defect merely to preserve artificial task boundaries.
19. User instructions override the default milestone size. If the user asks for larger or smaller review gates, update the handoff/execution rules accordingly.

## Required milestone completion report
- Milestone / task range
- Summary
- Internal tasks completed
- Files changed
- Tests/commands run
- Runtime/manual verification
- Screenshots/evidence where relevant
- Known limitations
- Next authorized milestone
