# Phase 15 — Multiplayer Foundations and Collaboration Roadmap

## Status
IMPLEMENTATION COMPLETE / PR #20 OPEN / PRE-MERGE DOCUMENTATION REFRESH COMPLETE

Authoritative base: `14085eb703b72d930f39121d3da18362d43cc77d`

Milestone branch: `dev/phase15-multiplayer-collaboration-milestone`

Verified implementation head before documentation closeout: `93b67eb5e50ffe5b2b686027d6a400ee9ccff1f0`

Pre-merge documentation refresh began from PR head: `72ab4d275fc5dbfeb69b35ab1679fee8588616b6`

Completion PR: `#20 — Phase 15 — Multiplayer Foundations and Collaboration Roadmap`

## Milestone result
Phase 15 added bounded host-authoritative multiplayer foundations to the existing Polyfork runtime and export architecture without replacing the Phase 7 `PlaySession`, Phase 10 gameplay state, Phase 13 export pipeline, or Phase 14 scale/polish architecture.

Offline single-player remains first-class. Session/network IDs remain runtime-only and layered over authored stable IDs. Real-time collaborative editor mutation remains explicitly deferred to a future durable collaboration protocol.

## Completed checkpoints
- [x] P15-T01 — Network identity and session contracts
- [x] P15-T02 — Host/client ENet transport adapter and lifecycle
- [x] P15-T03 — Multiplayer player spawning and movement/presence replication
- [x] P15-T04 — Host-authoritative generic gameplay replication
- [x] P15-T05 — Multiplayer template, match, competitive, and bounded Visual Scripting hooks
- [x] P15-T06 — Accessible adaptive Offline/Host/Join Play UX
- [x] P15-T07 — Runtime save authority, reconnect, host termination, and failure hardening
- [x] P15-T08 — Optional export/package integration and real two-process Windows verification
- [x] P15-T09 — Collaborative-authoring architecture roadmap
- [x] P15-T10 — Full verification, inherited regressions, rendered evidence, documentation closeout, and one completion PR
- [x] P15-T11 — Pre-merge canonical documentation audit and refresh

## Delivered architecture
Authored stable IDs remain authoritative. Runtime multiplayer uses versioned peer/session/network identity, a project-owned ENet adapter, host authority for gameplay mutations/save authority, existing Phase 7 controller/input paths, existing Phase 10 gameplay services, deterministic match/team/spawn/score state, bounded multiplayer events through the existing Visual Scripting gameplay-event route, and complete disposable Play teardown.

The canonical Multiplayer workspace integrates Offline / Host & Play / Join & Play with address/port/player identity, peer/session status, keyboard/gamepad focus/hints, and corrected adaptive full/compact layout.

Standalone packaging extends Phase 13/14 closure only when a project declares multiplayer capability. Offline exports omit Phase 15 networking. Multiplayer exports package required network dependencies and generated capability metadata, then dynamically load the network runtime through Godot's export-aware resource system.

## Collaboration roadmap
`docs/architecture/PHASE15_COLLABORATIVE_AUTHORING_ROADMAP.md`

The roadmap covers durable author/session/operation identities, permissions, universal command-log compatibility, conflict policy, asset revisions, presence, offline/reconnect/rebase, audit/history, security/privacy, and hosted-service boundaries. It does **not** claim collaborative editing is implemented.

## Verification
Implementation evidence:
- Phase 15 Contracts — `31635239746` — PASS — all eight suites
- Phase 15 Inherited Regressions — `31634218734` — PASS
- Godot Smoke — `31635582701` — PASS
- Phase 15 Visual Evidence — `31634842058` — PASS; corrected full/compact evidence inspected
- Phase 15 Windows Multiplayer Export — `31635582699` — PASS; offline package plus real concurrent exported host/client

At PR head `72ab4d...`, a later pull-request-triggered sweep initially showed multiple red workflows because individual runners failed while downloading Godot 4.7.1 before their test steps. Targeted reruns allowed the actual tests to execute and the GitHub Actions workflow runs recovered without any product-code patch.

The aggregate PR still reported `unstable` because external GitHub App suites from Cursor, Graphite App, and Netlify were queued with zero check runs. This is documented separately from product verification in `docs/qa/PHASE15_QA.md`.

## Scope guard retained
No production matchmaking, cloud relay/account infrastructure, NAT traversal service, voice chat, anti-cheat platform integration, rollback netcode, dedicated-server fleet orchestration, or real-time collaborative editor mutation is claimed.

## Completion / merge rule
PR #20 is **OPEN / NOT MERGED**.

This documentation commit changes the PR head, so the new head and current checks must be fetched again before merge.

Do **not** merge PR #20 without explicit user authorization. Do not begin Phase 16 until PR #20 is explicitly merged and the resulting authoritative `master` SHA is verified.

## Security reminder
Historical `.polyforkAPI` credential material remains in Git history and must still be treated as exposed and rotated/revoked separately.
