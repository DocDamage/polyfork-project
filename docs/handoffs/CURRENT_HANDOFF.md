# POLYFORK PROJECT — PHASE 8 ACTIVE HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authoritative branch
The real project lives on `master`.

Authoritative `master` after the Phase 7 merge:

`06df50b6ffb752731d21f1ced88eb2cf1191f542`

This is the verified GitHub merge commit for PR #12 — Phase 7 — Instant Play + Templates.

The repository default branch `main` remains obsolete starter code. **Never develop from `main`.**

## Active milestone
Phase 8 — Visual Scripting — is active on:

`dev/phase8-visual-scripting-milestone`

The branch was created from the exact authoritative Phase 7 merge commit above.

Work continuously through P08-T01–P08-T08. Intermediate commits and CI runs are expected. Do not stop for per-task PRs. Open exactly one Phase 8 completion PR to `master` after the milestone is fully implemented and verified. Do not merge that PR without explicit user authorization.

## Phase 8 required outcomes
- schema-v1 graph persistence with stable graph, node, connection, variable, and macro identity
- project-managed graph storage using crash-safe JSON promotion and fail-closed corrupt/future-schema handling
- command-backed graph authoring integrated with existing Undo/Redo and dirty-state behavior
- deterministic compiler with typed port validation, endpoint validation, macro dependency validation, and executable plans
- bounded runtime interpreter usable during real Phase 7 Play sessions
- reusable macro/function graphs with parameters and recursion/cycle guards
- initial useful event/flow/value/math/logic/variable/entity/debug node library
- compact GraphEdit-based authoring UI that preserves the canonical dark playful Nintendo-forward / Apple-clean workspace
- keyboard/mouse and gamepad graph authoring paths with reliable Back/Cancel behavior
- validation/debugger surface with trace, breakpoints, paused/error state, and actionable diagnostics
- template `example_graph_references` integration without inventing unsupported later-phase systems
- save/reopen, Undo/Redo, missing/corrupt/future data, runtime failure rollback, repeated execution, scale/performance, strict-log, inherited regression, and rendered visual evidence

## Internal checkpoints
- P08-T01 contracts, node catalog, state, repository
- P08-T02 command-backed authoring service
- P08-T03 compiler and validation
- P08-T04 runtime interpreter and Play integration
- P08-T05 macros/functions
- P08-T06 graph editor workspace and input
- P08-T07 debugger/diagnostics/template references
- P08-T08 integration/scale/failure/gamepad/visual closeout

## Merge rule
Phase 9 is not authorized until the single Phase 8 completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.
