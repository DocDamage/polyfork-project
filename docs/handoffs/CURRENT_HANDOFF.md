# POLYFORK PROJECT — PHASE 10 ACTIVE HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authoritative branch

The real project lives on:

`master`

Current authoritative `master`:

`953d8b500beb1b65485104c85ab9bd5c4ff8224b`

This is the verified signed merge commit for PR #14 — Phase 9 — Foliage / Procedural / Splines.

The repository default branch `main` remains obsolete starter code.

**Never develop from `main`.**

## Phase 9 status

PR #14 is merged.

Phases 0 through 9 are complete on authoritative `master`.

Phase 9 delivered project-managed nondestructive foliage/scatter, terrain-coupled deterministic regeneration, real MultiMesh foliage, paint/erase strokes, roads/paths/fences, generated spline geometry, streaming, Asset Library/prefab source resolution, keyboard/mouse + gamepad authoring, persistence/failure testing, and rendered verification.

## Phase 10 milestone branch

Phase 10 — Gameplay Framework Breadth — is active on:

`dev/phase10-gameplay-framework-milestone`

The branch was created from exactly:

`953d8b500beb1b65485104c85ab9bd5c4ff8224b`

No obsolete `main` ancestry was used.

## Phase 10 development rule

Work Phase 10 as one continuous milestone.

Use internal commits and CI freely, but do not stop after each P10 task for a pull request.

At milestone completion:

1. run full Phase 10 and inherited verification;
2. update implementation/QA/handoff documentation;
3. open one Phase 10 completion PR targeting authoritative `master`;
4. do not merge it without explicit user authorization.

## Architecture rules

Phase 10 must extend, not replace:

- Phase 2 stable project/entity identity and crash-safe persistence;
- universal command history and Undo/Redo;
- Phase 3 runtime entity/editor bridge;
- Phase 4 Asset Library;
- Phase 5 terrain and streaming;
- Phase 6 component/archetype/prefab/socket systems;
- Phase 7 disposable PlaySession and semantic gameplay input;
- Phase 8 Visual Scripting;
- Phase 9 procedural/foliage/spline runtime.

Build remains authoritative. Mutable Play state is disposable unless explicitly captured by the Phase 10 save-state system. Play/runtime state must never silently write back into authored Build data.

Persisted references must use stable IDs. Missing/corrupt references fail safely. Keyboard/mouse and gamepad remain first-class. Preserve the existing dark playful Nintendo-forward / Apple-clean UI direction.

## Phase 10 checkpoints

- P10-T01 — runtime gameplay-state contracts/service, stable IDs, Play lifecycle, event bus, validation
- P10-T02 — inventory/item/container state, transfers, pickups, interaction routing
- P10-T03 — doors plus health/damage/healing/death runtime systems
- P10-T04 — basic NPC navigation/AI goals, destinations, waits, target interaction
- P10-T05 — dialogue scaffolding with stable conversations/lines/participants/choices
- P10-T06 — quest scaffolding with stable quests/objectives and event-driven progress
- P10-T07 — vehicles, seats, occupancy, enter/exit, throttle/steer/brake semantics
- P10-T08 — explicit save-state snapshots and crash-safe restore without Build mutation
- P10-T09 — Visual Scripting and semantic input integration plus repeated Play/rollback coverage
- P10-T10 — Gameplay workspace UX, gamepad/keyboard coverage, scale/performance/failure QA, rendered evidence, docs closeout, single completion PR

## Immediate execution state

The Phase 9 stale merge-state documentation has been corrected and the Phase 10 milestone has been decomposed. Implementation is authorized to continue immediately on the Phase 10 branch without task-by-task PR interruptions.

Do not begin Phase 11 until the Phase 10 completion PR is explicitly merged into authoritative `master` and the resulting `master` SHA is verified.
