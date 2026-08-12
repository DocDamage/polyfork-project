# Task Backlog

Task IDs use `P##-T##` as internal implementation checkpoints. Pull requests are milestone gates, not task gates, unless a handoff explicitly says otherwise.

## Completed phases 0–15
Phases 0 through 14 are complete and merged on authoritative `master`. Phase 15 implementation is complete and its completion PR is open; it is **not merged yet**.

- [x] Phase 0 — Repository and contracts
- [x] Phase 1 — App shell and canonical UI foundation
- [x] Phase 2 — World project + save foundation
- [x] Phase 3 — Runtime Placement Editor
- [x] Phase 4 — Universal Asset Library — PR #9
- [x] Phase 5 — Terrain + Streaming — PR #10
- [x] Phase 6 — Components, Archetypes, Prefabs — PR #11
- [x] Phase 7 — Instant Play + Templates — PR #12
- [x] Phase 8 — Visual Scripting — PR #13
- [x] Phase 9 — Foliage / Procedural / Splines — PR #14
- [x] Phase 10 — Gameplay Framework Breadth — PR #15
- [x] Phase 11 — Environment — PR #16
- [x] Phase 12 — AI Creation — PR #17
- [x] Phase 13 — Export Pipeline — PR #18
- [x] Phase 14 — Scale and Polish — PR #19 at `14085eb703b72d930f39121d3da18362d43cc77d`
- [x] Phase 15 — Multiplayer Foundations and Collaboration Roadmap — PR #20 OPEN

## Phase 15 — COMPLETE / PR #20 OPEN
Milestone branch:

`dev/phase15-multiplayer-collaboration-milestone`

Authoritative base:

`14085eb703b72d930f39121d3da18362d43cc77d`

Verified implementation head before documentation-only closeout:

`93b67eb5e50ffe5b2b686027d6a400ee9ccff1f0`

Completion PR:

`#20 — Phase 15 — Multiplayer Foundations and Collaboration Roadmap`

- [x] P15-T01 Network identity/session contracts
- [x] P15-T02 ENet host/client transport and lifecycle
- [x] P15-T03 Multiplayer spawn/ownership/movement replication
- [x] P15-T04 Host-authoritative gameplay replication
- [x] P15-T05 Template/match/Visual Scripting multiplayer hooks
- [x] P15-T06 Accessible adaptive Offline/Host/Join UX
- [x] P15-T07 Save authority/reconnect/failure hardening
- [x] P15-T08 Optional export closure and exported two-process Windows verification
- [x] P15-T09 Collaborative-authoring architecture roadmap
- [x] P15-T10 Full verification/evidence/docs/completion PR

## Completion verification
- Phase 15 Contracts — `31635239746` — PASS — all 8 suites
- Phase 15 Inherited Regressions — `31634218734` — PASS
- Godot Smoke — `31635582701` — PASS
- Phase 15 Visual Evidence — `31634842058` — PASS; corrected full/compact evidence inspected
- Phase 15 Windows Multiplayer Export — `31635582699` — PASS; offline package and concurrent exported host/client

A later matrix run had one infrastructure-only Godot download failure before its identity shard began; its other seven shards passed. The full eight-suite run above is green.

## Release rule
PR #20 must **not** be merged without explicit user authorization. Phase 16 is blocked until PR #20 is explicitly merged and the resulting authoritative `master` SHA is verified.
