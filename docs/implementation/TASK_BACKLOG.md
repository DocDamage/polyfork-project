# Task Backlog

Task IDs use `P##-T##` as internal implementation checkpoints. Pull requests are milestone gates, not task gates, unless a handoff explicitly says otherwise.

## Completed phases 0–15
Phases 0 through 14 are complete and merged on authoritative `master`. Phase 15 implementation is complete on its milestone branch and is ready for its single completion PR; it is **not merged yet**.

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
- [x] Phase 15 — Multiplayer Foundations and Collaboration Roadmap — completion PR pending

## Phase 15 — COMPLETE / PR READY
Milestone branch:

`dev/phase15-multiplayer-collaboration-milestone`

Authoritative base:

`14085eb703b72d930f39121d3da18362d43cc77d`

Verified implementation head before documentation-only closeout:

`93b67eb5e50ffe5b2b686027d6a400ee9ccff1f0`

Detailed plan:

`docs/implementation/PHASE15_MULTIPLAYER_COLLABORATION_PLAN.md`

- [x] P15-T01 Runtime-only network identity/session/ownership/capability handshake contracts with offline fallback and authored stable-ID preservation
- [x] P15-T02 Project-owned ENet host/join transport adapter, clean Play lifecycle, explicit failure handling, and teardown
- [x] P15-T03 Multiplayer player spawning/ownership and remote movement/presence replication through existing controllers
- [x] P15-T04 Bounded host-authoritative Phase 10 gameplay replication with validated client requests and convergent state
- [x] P15-T05 Multiplayer template capability, team/spawn/session/score-objective hooks, and bounded Visual Scripting multiplayer events/actions
- [x] P15-T06 Accessible Offline/Host/Join Play UX with keyboard/gamepad focus and compact-layout behavior
- [x] P15-T07 Host-only runtime save authority, join/leave/rejoin, host termination, duplicate/incompatible identity rejection, and repeated-session cleanup
- [x] P15-T08 Multiplayer-aware Phase 13/14 export closure plus real two-process Windows host/client verification
- [x] P15-T09 Collaborative-authoring architecture roadmap with explicit separation from gameplay replication
- [x] P15-T10 Full Phase 15 verification, inherited Phase 6–14 regressions, Godot Smoke, rendered evidence, Windows multiplayer export verification, and documentation closeout

## Phase 15 completion verification
- Phase 15 Contracts — run `31635239746` — PASS — all eight suites
- Phase 15 Inherited Regressions — run `31634218734` — PASS
- Godot Smoke — run `31635582701` — PASS on final implementation head
- Phase 15 Visual Evidence — run `31634842058` — PASS; corrected full/compact Host/Join UI inspected
- Phase 15 Windows Multiplayer Export — run `31635582699` — PASS; offline package plus concurrent exported host/client verified

A later contract matrix run `31635582748` had one runner fail while downloading Godot before tests; the other seven shards passed. The complete eight-suite contract run above is green, and final-head Godot Smoke and Windows two-process export are green.

## Phase 15 scope guard
Phase 15 implements bounded host-authoritative multiplayer foundations and a real co-op prototype. It does not claim production matchmaking, cloud relay/account infrastructure, NAT traversal service, voice chat, anti-cheat platform integration, rollback netcode, dedicated-server fleet orchestration, or real-time collaborative editor mutation.

## Release rule
Open one Phase 15 completion PR targeting authoritative `master`. Do **not** merge it without explicit user authorization. Do not begin Phase 16 until that PR is explicitly merged and the resulting authoritative `master` SHA is verified.
