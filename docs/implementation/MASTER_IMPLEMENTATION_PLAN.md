# Master Implementation Plan

## Authoritative state
- The real project lives on `master`; repository default branch `main` is obsolete starter code and must not be used for development.
- Authoritative `master`: `14085eb703b72d930f39121d3da18362d43cc77d`, the verified signed merge commit for PR #19.
- Phases 0 through 14 are complete and merged.
- Phase 15 — Multiplayer Foundations and Collaboration Roadmap is **COMPLETE** on `dev/phase15-multiplayer-collaboration-milestone`.
- Phase 15 completion PR **#20 is OPEN and NOT MERGED**.
- Phase 16 remains blocked until PR #20 is explicitly merged and the resulting authoritative `master` SHA is verified.

## Phases 0–14 — COMPLETE / MERGED
The repository contains the completed application shell, world/save foundation, runtime placement editor, Asset Library, terrain/streaming, components/archetypes/prefabs/sockets, Instant Play/templates, Visual Scripting, foliage/procedural/splines, gameplay framework breadth, Environment, AI Creation, Export Pipeline, and Scale/Polish milestones. See the phase-specific implementation documents and merged PR history for detailed evidence.

Historical `.polyforkAPI` credential material remains exposed in Git history and must be rotated/revoked separately.

## Phase 15 — Multiplayer Foundations and Collaboration Roadmap — COMPLETE / PR #20 OPEN
Branch:

`dev/phase15-multiplayer-collaboration-milestone`

Base:

`14085eb703b72d930f39121d3da18362d43cc77d`

Verified implementation head before documentation-only closeout:

`93b67eb5e50ffe5b2b686027d6a400ee9ccff1f0`

Completion PR:

`#20 — Phase 15 — Multiplayer Foundations and Collaboration Roadmap`

### Delivered
- versioned runtime-only session/peer/network identity layered over authored stable IDs;
- Offline/Host/Client roles and project-owned Godot 4.7.1 ENet transport;
- compatibility handshake, join/leave/disconnect/reconnect cleanup, host termination hardening, and no authored mutation from network lifecycle;
- existing first/third-person controllers extended for local-input ownership and remote player replication;
- host-authoritative health/damage/heal and door/interaction replication with client spoof/direct-authority rejection;
- opt-in multiplayer template capability, deterministic player limits, teams, spawn offsets, score/objective match state;
- bounded Visual Scripting integration through existing `gameplay.emit_event` and namespaced multiplayer events;
- accessible adaptive canonical Multiplayer panel with Offline / Host & Play / Join & Play;
- host-only runtime save authority;
- optional export dependency closure so offline builds omit networking and multiplayer builds package only required networking dependencies/capability metadata;
- export-aware standalone Host/Client startup and real concurrent Windows two-process verification;
- Small/Medium/Large bounded multiplayer state coverage;
- inherited Phase 6–14 regressions and corrected rendered full/compact evidence;
- `docs/architecture/PHASE15_COLLABORATIVE_AUTHORING_ROADMAP.md`, explicitly separating durable collaborative authoring from transient gameplay replication.

### Verified gates
- Phase 15 Contracts — `31635239746` — PASS — all 8 suites
- Phase 15 Inherited Regressions — `31634218734` — PASS
- Godot Smoke — `31635582701` — PASS
- Phase 15 Visual Evidence — `31634842058` — PASS
- Phase 15 Windows Multiplayer Export — `31635582699` — PASS

### Scope guard retained
Phase 15 does not claim production matchmaking, cloud relay/account infrastructure, NAT traversal service, voice chat, anti-cheat platform integration, rollback netcode, dedicated-server fleet orchestration, or real-time collaborative editor mutation.

## Phase 16 — BLOCKED
Do not begin Phase 16 until PR #20 is explicitly merged and the resulting authoritative `master` SHA is verified.
