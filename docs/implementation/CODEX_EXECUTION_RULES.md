# Codex Execution Rules

## Purpose
Keep implementation grounded, verifiable, and resumable across threads.

## Rules
1. Read `README.md`, `docs/PRODUCT_REQUIREMENTS.md`, `docs/implementation/MASTER_IMPLEMENTATION_PLAN.md`, and `docs/handoffs/CURRENT_HANDOFF.md` before modifying code.
2. Only implement tasks explicitly authorized by CURRENT_HANDOFF.
3. Prefer code files <=300 LOC where practical. Split by responsibility, not arbitrary line count.
4. No stubs presented as finished work.
5. Never weaken tests to make broken behavior pass.
6. Every authoring mutation must go through the command/transaction system once that system exists.
7. Persistent references use stable IDs, not scene-tree paths.
8. External asset source folders are read-only.
9. UI work must compare against `assets/reference/CANONICAL_UI_REFERENCE.png`.
10. Core flows require keyboard/mouse and gamepad verification.
11. Update docs when architecture or persistent schemas change.
12. At task completion, create/update a handoff documenting: changed files, tests run, runtime evidence, unresolved risks, exact next authorized task.

## Required completion report
- Task ID
- Summary
- Files changed
- Tests/commands run
- Runtime/manual verification
- Screenshots/evidence where relevant
- Known limitations
- Next authorized task
