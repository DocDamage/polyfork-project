# POLYFORK PROJECT — PHASE 15 HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## AUTHORITATIVE BRANCH
The real project lives on:

`master`

Current authoritative `master`:

`14085eb703b72d930f39121d3da18362d43cc77d`

This is the verified signed merge commit for **PR #19 — Phase 14 — Scale and Polish**. PR #19 is confirmed merged.

The repository default branch `main` remains obsolete starter code. **Never develop from `main`.**

## MERGED PROJECT STATE
Phases **0 through 14 are complete and merged** into authoritative `master`.

Phase 14 delivered deterministic performance presets/budgets, Small/Medium/Large/Stress verification, streaming/procedural hardening, accessibility completion, keyboard/gamepad polish, adaptive layouts, canonical visual parity, performance-aware Play/export behavior, strict regressions, Godot Smoke, rendered evidence, and Windows clean-package verification.

Verified Phase 14 implementation head before documentation-only closeout:

`b15439461cfae5d41d5951b5af808d20f2bb5f1b`

## ACTIVE PHASE 15 BRANCH
Phase 15 — Multiplayer Foundations and Collaboration Roadmap is authorized and active.

Milestone branch:

`dev/phase15-multiplayer-collaboration-milestone`

It was created from exactly authoritative Phase 14 `master`:

`14085eb703b72d930f39121d3da18362d43cc77d`

No Phase 15 implementation code has been written yet at handoff establishment.

## PHASE 15 PLAN
Detailed plan:

`docs/implementation/PHASE15_MULTIPLAYER_COLLABORATION_PLAN.md`

Internal checkpoints:

**P15-T01 through P15-T10**

Use them as continuous implementation checkpoints. Do not stop for task-by-task PRs.

## NEXT AUTHORIZED MILESTONE
**Phase 15 — Multiplayer Foundations and Collaboration Roadmap**

The milestone must cover at minimum:
- runtime-only network/session identity compatible with authored persistent stable IDs;
- Offline / Host / Client session roles and explicit connection lifecycle;
- project-owned Godot 4.7.1 networking adapter using ENet for the bounded local/LAN/loopback prototype path;
- host-authoritative gameplay state and validated client action requests;
- two-peer co-op player spawning, ownership, presence, movement, join/leave, and clean teardown through the existing Phase 7 PlaySession/template/controller paths;
- bounded generic Phase 10 gameplay replication, prioritizing reusable systems rather than one-off mechanics;
- multiplayer capability declarations, player-count limits, spawn/team/session metadata, and simple score/objective hooks;
- bounded Visual Scripting multiplayer events/actions where they fit the existing graph architecture cleanly;
- accessible Offline/Host/Join Play UX with keyboard-only and gamepad navigation, compact/adaptive behavior, and Phase 14 focus/glyph consistency;
- host-only runtime save authority, disconnect/rejoin hardening, duplicate/incompatible identity rejection, and complete Play → Build cleanup;
- Phase 13/14 export integration for multiplayer-capable packages;
- deterministic two-process exported Windows host/client verification;
- inherited Phase 6–14 regression coverage;
- Godot Smoke;
- rendered multiplayer UI/runtime evidence;
- a concrete collaborative-authoring roadmap covering identity/permissions, command/conflict model, asset sync, presence, history, security/privacy, offline/reconnect, hosted service requirements, and reuse boundaries with runtime networking;
- documentation closeout and one Phase 15 completion PR.

## ARCHITECTURE RULES
- Do not replace the existing editor/runtime architecture.
- Do not rewrite authored stable IDs into network IDs. Session/network identity must be layered on top and disposable.
- Offline single-player must remain first-class and unchanged when multiplayer is disabled.
- Existing Phase 10 gameplay state remains the gameplay source of truth; networking adapts/replicates it rather than creating parallel gameplay systems.
- Existing Phase 7 semantic gameplay input remains the player-input abstraction.
- The host is authoritative for replicated gameplay state and runtime save authority in this milestone.
- Multiplayer lifecycle alone must never mutate authored project data.
- Real-time collaborative editor mutation is not implemented in Phase 15; only its future architecture/roadmap is required.

## OUT OF SCOPE FOR PHASE 15
Do not expand this milestone into:
- production matchmaking;
- cloud relay/account infrastructure;
- NAT traversal service;
- voice chat;
- anti-cheat platform integration;
- rollback netcode;
- dedicated-server fleet orchestration;
- full real-time collaborative editor implementation.

## DEVELOPMENT RULE
Work continuously on:

`dev/phase15-multiplayer-collaboration-milestone`

Intermediate commits and CI runs are expected.

Do **not** stop for task-by-task pull requests.

At Phase 15 completion:
1. finish P15-T01 through P15-T10;
2. run the full Phase 15 verification matrix;
3. run inherited Phase 6–14 regression gates;
4. run Godot Smoke;
5. capture rendered UI/runtime evidence;
6. verify exported Windows two-process host/client behavior;
7. close the implementation plan, backlog, master plan, and current handoff;
8. open **one** Phase 15 completion PR targeting authoritative `master`;
9. **do not merge it without explicit user authorization**.

Do not begin Phase 16 until the Phase 15 completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.

## SECURITY REMINDER
The historical `.polyforkAPI` credential material remains present in Git history and must still be treated as exposed. Rotate/revoke it separately.
