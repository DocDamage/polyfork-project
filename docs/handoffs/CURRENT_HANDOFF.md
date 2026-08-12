# POLYFORK PROJECT — PHASE 16 TRANSITION HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## AUTHORITATIVE BRANCH
The real project lives on `master`.

Current authoritative `master`:

`b4b5e88ef11ba514b1c8755e45e1a9de5cf04613`

This is the verified signed GitHub merge commit for:

**PR #20 — Phase 15 — Multiplayer Foundations and Collaboration Roadmap**

PR #20 is **MERGED**.

Merged at:

`2026-08-12T21:16:19Z`

Phase 15 branch head included in the merge:

`5f981a75f7c77ae1d144d1abb30831c57f7abfba`

The repository default branch `main` remains obsolete starter code. **Never develop from `main`.**

## MERGED PROJECT STATE
Phases **0 through 15 are complete and merged** into authoritative `master`.

## PHASE 15 — COMPLETE / MERGED
Phase 15 delivered the multiplayer foundation while preserving the existing `PlaySession` and gameplay architecture, plus a durable collaborative-authoring roadmap that explicitly keeps gameplay replication separate from collaborative project editing.

### Delivered
- runtime-only stable network/session identity and versioned compatibility handshake;
- Godot 4.7.1 ENet Offline/Host/Client lifecycle;
- local/remote player ownership and movement/presence replication through existing controllers;
- host-authoritative generic gameplay replication and client-authority rejection;
- multiplayer template capability, bounded player limits, teams, spawn offsets/strategies, score/objective state;
- bounded Visual Scripting multiplayer actions/events through the existing gameplay event bus;
- adaptive accessible Offline / Host & Play / Join & Play workspace UX;
- host-only runtime save authority and reconnect/host-disconnect cleanup;
- optional multiplayer standalone dependency closure while offline exports remain free of network runtime;
- real concurrent exported Windows host/client verification;
- Small/Medium/Large network-state coverage and inherited Phase 6–14 regressions;
- corrected full/compact rendered evidence;
- collaborative-authoring architecture roadmap.

### Verified implementation gates
- Phase 15 Contracts — `31635239746` — PASS — all eight suites
- Phase 15 Inherited Regressions — `31634218734` — PASS
- Godot Smoke — `31635582701` — PASS
- Phase 15 Visual Evidence — `31634842058` — PASS
- Phase 15 Windows Multiplayer Export — `31635582699` — PASS

The final documentation-refresh head also passed repository-owned GitHub Actions after transient Godot-download setup failures were retried. Those failures happened before tests executed and are infrastructure/setup failures, not product failures. Cursor, Graphite, and Netlify remain third-party integration checks and must be interpreted separately.

## PHASE 16 — UNBLOCKED / DISCOVERY AUTHORIZED
Milestone branch:

`dev/phase16-milestone`

Base:

`b4b5e88ef11ba514b1c8755e45e1a9de5cf04613`

The Phase 16 implementation scope is **not yet defined**. Do not infer it from the Phase 15 collaboration roadmap or any single deferred limitation.

### Required discovery before implementation
Inspect the current:
- Product Requirements;
- Product Decisions;
- Product Charter;
- Risk Register;
- Security / Privacy / Licensing;
- System Architecture and related architecture documents;
- Master Implementation Plan and task backlog;
- QA quality gates, test matrix, performance/visual acceptance documents;
- system documentation;
- known deferred limitations and historical phase closeouts.

Then select the highest-value remaining coherent milestone and explicitly document Phase 16 scope, non-goals, architecture reuse, task checkpoints, acceptance criteria, and verification evidence before implementing it.

## DEVELOPMENT STYLE
Use one long Phase 16 milestone. Internal `P16-T##` checkpoints are not PR boundaries.

Workflow:

`verified master → dev/phase16-milestone → define Phase 16 from authoritative evidence → implement complete milestone → tests/regressions/visual/Windows-export evidence where applicable → documentation closeout → one completion PR`

## ARCHITECTURAL GUARDS
- reuse existing `PlaySession`;
- reuse command / Undo / Redo mutation boundaries;
- reuse stable authored IDs;
- reuse the gameplay event bus and existing Visual Scripting architecture;
- reuse Asset Library and save/export contracts;
- preserve offline-first behavior;
- keep multiplayer opt-in;
- do not turn runtime replication into collaborative authoring;
- do not introduce duplicate/fake placeholder systems.

All new persistent mutation must respect existing project/save and command ownership boundaries.

## UI / UX GUARD
Preserve the canonical Polyfork visual language: dark, playful but professional, approximately 70/30 Nintendo/Apple influence, large cards by default with denser alternatives where appropriate, minimal hidden menus, context-sensitive tool colors, controller-first usability with keyboard/mouse parity, strong focus states, and adaptive layouts.

Do not regress to a generic dark-slate developer-tool interface.

## SECURITY NOTE
Historical `.polyforkAPI` credential material remains present in Git history and must be treated as exposed. Do not print, copy, restore, or reuse it. Rotation/revocation is a separate external action.

## COMPLETED TRANSITION TASK
**P16-T00 — Verify Phase 15 merge and reconcile stale post-merge canonical status — COMPLETE.**

## NEXT AUTHORIZED WORK
**P16-T01/P16-T02 — Audit remaining authoritative requirements and deferred limitations, then define the complete Phase 16 milestone before implementation.**

After Phase 16 is defined, execute the entire milestone continuously and open one completion PR at the milestone boundary.
