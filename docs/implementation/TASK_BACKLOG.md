# Task Backlog

Task IDs use `P##-T##` as internal implementation checkpoints. Pull requests are milestone gates, not task gates, unless a handoff explicitly says otherwise.

## Completed phases 0–14
All Phase 0 through Phase 14 milestones are complete and merged on authoritative `master`.

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

Phase 14 verified implementation head before documentation-only closeout:

`b15439461cfae5d41d5951b5af808d20f2bb5f1b`

Phase 14 completion verification:
- Phase 14 Contracts — run `31626516078` — PASS
- Phase 14 Scale Stress — run `31626516104` — PASS
- Phase 14 Inherited Regressions — run `31626516105` — PASS
- Godot Smoke — run `31626516120` — PASS
- Phase 14 Visual Evidence — run `31626516053` — PASS
- Phase 14 Windows Export — run `31626516187` — PASS

## Phase 15 — Multiplayer Foundations and Collaboration Roadmap — ACTIVE
Milestone branch:

`dev/phase15-multiplayer-collaboration-milestone`

Base:

`14085eb703b72d930f39121d3da18362d43cc77d`

Detailed plan:

`docs/implementation/PHASE15_MULTIPLAYER_COLLABORATION_PLAN.md`

- [ ] P15-T01 Define runtime-only network identity/session/ownership/capability handshake contracts with offline fallback and authored stable-ID preservation
- [ ] P15-T02 Implement project-owned ENet host/join transport adapter, clean PlaySession lifecycle, explicit failure handling, and complete teardown
- [ ] P15-T03 Add multiplayer-aware player spawn/ownership and remote movement/presence replication through existing template/controller paths
- [ ] P15-T04 Add bounded host-authoritative Phase 10 gameplay replication with validated client requests and convergent state
- [ ] P15-T05 Add multiplayer template capability, team/spawn/session/score-objective hooks, plus bounded Visual Scripting multiplayer events/actions
- [ ] P15-T06 Integrate Offline/Host/Join Play UX with session status, keyboard-only/gamepad coverage, compact layout, and Phase 14 focus/glyph conventions
- [ ] P15-T07 Harden host-only runtime save authority, join/leave/rejoin, host termination, duplicate identity rejection, and repeated-session cleanup
- [ ] P15-T08 Integrate multiplayer into Phase 13/14 export closure and verify two exported Windows processes can host/join with keyboard/mouse and gamepad semantics intact
- [ ] P15-T09 Deliver the collaborative-authoring roadmap covering identity/permissions, command/conflict model, asset sync, presence, history, security, reconnect, and service boundaries
- [ ] P15-T10 Run full Phase 15 verification, inherited Phase 6–14 regressions, Godot Smoke, rendered evidence, Windows multiplayer export verification, close docs, and open one completion PR

## Phase 15 scope guard
Phase 15 implements bounded host-authoritative multiplayer foundations and a real co-op prototype. It does not require production matchmaking, cloud relay/account infrastructure, NAT traversal service, voice chat, anti-cheat platform integration, rollback netcode, dedicated-server fleet orchestration, or real-time collaborative editor mutation.

## Release rule
Work Phase 15 continuously on its milestone branch. Intermediate commits and CI runs are expected. Do not stop for task-by-task PRs. Open one completion PR only after P15-T01 through P15-T10 and the full verification matrix are complete. Do not merge that PR without explicit user authorization.
