# Current Handoff

## Status
OPEN — Phase 3 runtime-placement milestone in progress.

## Project state
Phase 0, Phase 1, and Phase 2 are complete on authoritative `master`.

PR #7 merged `P03-T01 — Implement runtime entity scene bridge and single-selection foundation` into `master` at merge commit `95ec15bdc4d6a2b293511f724cfc4204e9ae485d`.

The repository default branch remains the obsolete starter branch `main`; do not develop from it. The authoritative project branch remains `master`.

## Workflow policy change
The project now uses milestone-based review gates rather than one PR per internal task.

- Task IDs remain internal implementation checkpoints.
- Work continuously through the authorized milestone on one branch.
- Commit and run CI at useful checkpoints.
- Do not stop merely because one task ID is complete.
- Open a PR only when the full authorized milestone is complete and verified, unless a genuine external blocker requires review.
- Do not merge a PR without explicit user authorization.

This policy is recorded in `docs/implementation/CODEX_EXECUTION_RULES.md` and applies to future threads unless the user explicitly changes milestone size.

## Current milestone
**Phase 3 Runtime Placement Editor completion**

Authorized task range:
- `P03-T02 — Implement command-backed object placement and ghost preview`
- `P03-T03 — Implement command-backed move/rotate/scale editing and gizmo state`
- `P03-T04 — Implement command-backed duplicate and delete operations`
- `P03-T05 — Implement multi-select and grouping foundations`
- `P03-T06 — Implement grid and angle snapping`
- `P03-T07 — Implement surface/object/socket snapping and drop-to-ground`
- `P03-T08 — Implement contextual placement toolbar and controller tool wheel`
- `P03-T09 — Complete Phase 3 integration, gamepad, failure-path, and visual verification`

Milestone branch:
`dev/phase3-runtime-placement-milestone`

Milestone baseline:
`master` at `95ec15bdc4d6a2b293511f724cfc4204e9ae485d`.

Do not open the Phase 3 completion PR until P03-T02 through P03-T09 are complete and the milestone passes strict Godot 4.7.1 verification.

## Merged P03-T01 foundation
The milestone begins with these already-merged contracts:
- generic `Node3D` runtime wrapper for persisted `WorldEntity` records;
- stable-ID runtime entity bridge and hierarchy reconstruction;
- failure-safe bridge rebuilds;
- descendant runtime-node -> stable entity resolution;
- single-selection model;
- workspace/right-inspector selection integration;
- no persistent scene-tree-path identity.

## Milestone-wide constraints
- Every user-visible authoring mutation must execute through the command/transaction framework.
- Successful mutations must mark the active project dirty so autosave/checkpoint behavior remains correct.
- Undo/redo must restore authored project state and the runtime bridge consistently.
- Persistent identity remains stable-ID based.
- Invalid commands/transactions must not leave partial project or runtime state.
- Placement/transform/delete/duplicate/group operations must be behaviorally tested, including failure paths.
- Snapping must be deterministic and separable from persistence identity.
- Keyboard/mouse and gamepad authoring flows must be tested by P03-T09.
- UI additions must preserve the canonical dark/playful Nintendo-forward visual direction and avoid permanent enterprise-style density.
- Do not fabricate the universal asset-library/import pipeline. Until Phase 4 exists, placement may use generic editor preview/runtime proxy geometry while preserving `asset_id`/`prefab_id` contracts for later integration.
- Do not begin Phase 4 during this milestone.

## PR/review boundary
The next planned PR is the **Phase 3 completion PR** containing the completed P03-T02 through P03-T09 milestone. Internal commits and CI runs should occur throughout the milestone, but no intermediate task PR is required.

## Next milestone after Phase 3
Only after the Phase 3 milestone is complete, verified, reviewed, and merged should the next handoff authorize a meaningful Phase 4 milestone for the Universal Asset Library.

## New-thread start prompt
Use authoritative `master`, never stale default `main`. If the Phase 3 milestone branch already exists, continue `dev/phase3-runtime-placement-milestone` rather than creating per-task PR branches. Read the standard architecture/implementation documents and this handoff. Continue through the full authorized P03-T02 through P03-T09 milestone, committing and verifying internally as needed. Do not stop at individual task boundaries and do not open a PR until the Phase 3 milestone is complete unless a genuine external blocker requires review.
