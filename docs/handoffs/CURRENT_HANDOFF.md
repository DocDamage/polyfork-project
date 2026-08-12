# POLYFORK PROJECT — PHASE 15 PRE-MERGE HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## AUTHORITATIVE BRANCH
The real project lives on `master`.

Authoritative `master` before Phase 15 merge:

`14085eb703b72d930f39121d3da18362d43cc77d`

This is the verified signed merge commit for **PR #19 — Phase 14 — Scale and Polish**.

The repository default branch `main` remains obsolete starter code. **Never develop from `main`.**

## MERGED PROJECT STATE
Phases **0 through 14 are complete and merged** into authoritative `master`.

## PHASE 15 — IMPLEMENTATION COMPLETE / PR #20 OPEN
Milestone branch:

`dev/phase15-multiplayer-collaboration-milestone`

Base:

`14085eb703b72d930f39121d3da18362d43cc77d`

Verified implementation head before documentation closeout:

`93b67eb5e50ffe5b2b686027d6a400ee9ccff1f0`

PR head immediately before this pre-merge documentation refresh:

`72ab4d275fc5dbfeb69b35ab1679fee8588616b6`

At that point the branch comparison was:
- ahead: 60
- behind: 0
- merge base: `14085eb703b72d930f39121d3da18362d43cc77d`

This documentation refresh intentionally creates a newer PR head. **Do not use `72ab4d...` as the merge SHA. Fetch the live PR head again before any merge.**

Completion PR:

**PR #20 — Phase 15 — Multiplayer Foundations and Collaboration Roadmap**

PR #20 targets authoritative `master` and remains **OPEN / NOT MERGED**.

## PHASE 15 DELIVERED
- runtime-only stable network/session identity and versioned compatibility handshake;
- ENet Offline/Host/Client lifecycle;
- local/remote player ownership and movement/presence replication through existing controllers;
- host-authoritative generic gameplay replication and client-authority rejection;
- multiplayer template capability, player limits, teams, spawn offsets/strategies, score/objective state;
- bounded Visual Scripting multiplayer actions/events through the existing gameplay event bus;
- adaptive accessible Offline / Host & Play / Join & Play workspace UX;
- host-only runtime save authority and reconnect/host-disconnect cleanup;
- optional multiplayer standalone dependency closure while offline exports remain free of network runtime;
- real concurrent exported Windows host/client verification;
- Small/Medium/Large network-state coverage and inherited Phase 6–14 regressions;
- corrected full/compact rendered evidence;
- collaborative-authoring roadmap explicitly separated from gameplay networking.

## VERIFIED IMPLEMENTATION GATES
- Phase 15 Contracts — `31635239746` — PASS — all eight suites
- Phase 15 Inherited Regressions — `31634218734` — PASS
- Godot Smoke — `31635582701` — PASS
- Phase 15 Visual Evidence — `31634842058` — PASS; corrected compact panel inspected
- Phase 15 Windows Multiplayer Export — `31635582699` — PASS; package build and exported concurrent host/client

## PR CI INCIDENT / CURRENT INTERPRETATION
At pre-refresh head `72ab4d...`, multiple pull-request workflows initially failed during the **Download Godot 4.7.1** setup step before their tests ran. Failed jobs were retried; the actual GitHub Actions test/runtime jobs that reached execution completed successfully without product-code changes.

The PR aggregate still reported `mergeable_state: unstable` because external Cursor, Graphite App, and Netlify check suites were stuck queued with zero check runs. They must be evaluated as third-party integration state, not described as Phase 15 product-test failures. See `docs/qa/PHASE15_QA.md`.

Because this documentation refresh creates a new head, its newly triggered checks must be reviewed from scratch before merge.

## DOCUMENTATION REFRESH
Completed pre-merge audit/refresh covers:
- repository orientation/branch authority;
- Product Requirements / Decisions / Charter / Acceptance / Risks / Security;
- System Architecture / Data Model / File Formats;
- UI screen inventory and canonical multiplayer UX behavior;
- repository structure/execution rules;
- Phase 15 master plan/backlog/phase plan;
- QA quality gates/test matrix/Phase 15 QA evidence;
- Multiplayer, template, input, Visual Scripting, save/export system docs.

Historical phase-specific documents that remain accurate were intentionally left as historical evidence rather than rewritten.

## COLLABORATION ROADMAP
`docs/architecture/PHASE15_COLLABORATIVE_AUTHORING_ROADMAP.md`

Design is complete; implementation is deferred. Gameplay replication is explicitly not treated as collaborative editing.

## UNRESOLVED LIMITATIONS
- no production matchmaking/relay/NAT traversal/account/auth/voice/anti-cheat/rollback/dedicated-server fleet;
- no real-time collaborative editor mutation;
- third-party GitHub App suites may remain queued even when Polyfork Actions tests pass;
- historical `.polyforkAPI` credential material remains exposed in Git history and must be rotated/revoked separately.

## COMPLETED TASK
**P15-T11 — Pre-merge canonical documentation audit/refresh — COMPLETE.**

## NEXT AUTHORIZED TASK
**P15-GATE — Verify PR #20's new live head, branch integrity, and newly triggered checks; then await explicit user authorization before merging.**

Do not begin Phase 16 before PR #20 is explicitly merged and the resulting authoritative `master` SHA is verified.
