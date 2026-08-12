# Phase 15 — Multiplayer Foundations and Collaboration Roadmap

## Status
AUTHORIZED / ACTIVE

Authoritative base:

`14085eb703b72d930f39121d3da18362d43cc77d`

Milestone branch:

`dev/phase15-multiplayer-collaboration-milestone`

Phase 15 begins only after the verified signed merge of PR #19 — Phase 14 — Scale and Polish.

## Milestone intent
Phase 15 adds bounded multiplayer foundations to the existing Polyfork runtime and export architecture without replacing the Phase 7 `PlaySession`, Phase 10 gameplay state, Phase 13 export pipeline, or Phase 14 scale/polish work.

The milestone must deliver a usable host/join co-op prototype, deterministic network identity and replication contracts, multiplayer-aware template/runtime hooks, export verification, and a concrete future collaboration roadmap.

This is not a production online-services milestone.

## Architecture invariants
- Authored persistent stable IDs remain the source of truth for project content. Network/session identity must be layered on top and must not rewrite authored IDs.
- Offline single-player remains first-class and must keep existing behavior when multiplayer is disabled.
- Multiplayer session state is runtime/disposable state and must not leak into authored project serialization unless a future schema explicitly requires it.
- The initial runtime model is host-authoritative. Clients may request actions; the host validates and commits authoritative gameplay state.
- Existing Phase 10 gameplay systems remain the gameplay source of truth. Networking adapts/replicates them rather than creating parallel gameplay implementations.
- Existing Phase 7 semantic gameplay input remains the local input abstraction for each local player endpoint.
- Existing Phase 13 export dependency closure must determine whether multiplayer runtime files are included. Editor-only networking diagnostics must not leak into standalone packages.
- Phase 14 performance presets may alter network/render/update cadence only where semantics remain unchanged.
- Real-time collaborative editor mutation is out of implementation scope for Phase 15. Phase 15 must produce a future collaboration design/roadmap instead.
- No production matchmaking, account system, cloud relay, NAT traversal service, voice chat, anti-cheat platform, rollback netcode, or dedicated-server fleet is required in Phase 15.

## Networking baseline
Use Godot 4.7.1 multiplayer primitives through a project-owned adapter/service boundary. The default prototype transport should be ENet for local/LAN/loopback validation while keeping transport selection isolated from gameplay code.

Required concepts:
- session role: offline / host / client;
- session ID;
- peer ID;
- player/network identity mapped to persistent authored/runtime entities without replacing their stable IDs;
- connection state and explicit join/leave lifecycle;
- authoritative ownership metadata;
- bounded replicated state snapshots/deltas;
- RPC/action-request validation boundary;
- host-only runtime save authority;
- deterministic disconnect cleanup.

## Co-op prototype scope
The prototype must prove two-peer gameplay through the existing Play runtime:
- host creates a multiplayer Play session;
- client joins by explicit address/port in development/test flows;
- both peers spawn controllable player avatars through existing template/runtime paths;
- local input controls only the local player;
- player movement/presence replicates;
- at least a bounded subset of Phase 10 gameplay interaction state replicates through host authority;
- join, leave, disconnect, and reconnect/rejoin behavior is defined and tested;
- host termination cleanly ends the session;
- no client may directly write authoritative project/save data.

The initial interaction replication set should favor high-value generic systems rather than one-off gameplay: health/damage, door/open state, simple inventory/container transfer, and one quest/objective or score-like state where practical.

## Competitive/template hooks
Phase 15 must add reusable hooks, not a full competitive game framework:
- session/match metadata;
- team or side assignment contract;
- multiplayer spawn-point selection hooks;
- simple score/objective state contract;
- template/runtime capability declaration for multiplayer support;
- deterministic player-count limits and validation;
- Visual Scripting-facing multiplayer events/actions where the existing graph model can support them cleanly.

Starter templates that do not declare multiplayer support must continue to run unchanged.

## Editor/runtime UX
Add a compact multiplayer surface integrated with the existing Build → Play flow rather than a new application shell.

Required UX:
- Offline / Host / Join mode selection;
- host port and join address/port fields for development/LAN use;
- explicit session status and peer count;
- clear errors for bind failure, connection failure, incompatible session/runtime contract, and host disconnect;
- keyboard-only and gamepad-accessible navigation consistent with Phase 14 focus/input standards;
- compact/adaptive behavior consistent with the canonical dark playful Nintendo/Apple-inspired UI.

Do not expose raw low-level networking controls by default when a simple host/join path is sufficient.

## Persistence and authority
- Authored project save remains editor-owned.
- Runtime multiplayer save/state snapshots are host-authoritative.
- Client requests that would mutate gameplay state must be validated by the host before commit.
- Disconnecting a client must not corrupt runtime state or authored data.
- Network identity/state must be reset between disposable Play sessions.
- Re-entering Build mode must leave no active multiplayer peer or leaked network callback behind.

## Export integration
Phase 15 multiplayer-capable exports must reuse Phase 13 packaging and Phase 14 preset policy.

Verification must cover:
- multiplayer runtime dependency closure;
- multiplayer-disabled exports do not unnecessarily include editor-only/network-debug material;
- multiplayer-enabled Windows packages launch cleanly;
- two exported processes can establish a loopback/LAN-style host/client session in CI or an equivalent deterministic harness;
- keyboard/mouse and gamepad semantic input remain valid in exported multiplayer runtime;
- repeat export retains deterministic stale-file replacement.

## Collaboration roadmap deliverable
Create a concrete design document for future collaborative authoring that covers:
- author identity and permissions;
- document/project operation IDs;
- command-log compatibility with the existing universal command/Undo/Redo model;
- conflict model and resolution policy;
- asset availability/version synchronization;
- presence/cursor/selection concepts;
- optimistic vs authoritative authoring operations;
- offline/reconnect behavior;
- audit/history implications;
- security/privacy boundaries;
- hosted relay/service requirements;
- what can reuse Phase 15 runtime networking and what must remain a separate collaboration protocol.

This roadmap must explicitly avoid pretending that gameplay replication alone solves collaborative editing.

## Internal checkpoints

### P15-T01 — Network identity and session contracts
Define runtime-only network/session identity, peer roles, ownership, capability/version handshake, connection lifecycle, and offline fallback.

Acceptance:
- authored stable IDs are unchanged;
- network identity is disposable/session-scoped;
- invalid/incompatible joins fail deterministically;
- offline behavior remains unchanged.

### P15-T02 — Host/client transport adapter and lifecycle
Implement the project-owned Godot multiplayer adapter with ENet host/join, clean shutdown, disconnect cleanup, and PlaySession integration.

Acceptance:
- loopback host/client connects;
- Play → Build tears networking down completely;
- host failure/bind/join errors are explicit;
- no gameplay system reaches directly into transport implementation details.

### P15-T03 — Multiplayer player spawning and movement replication
Add multiplayer-aware spawn/ownership plumbing through existing playable template/controller paths.

Acceptance:
- host and client each control only their local avatar;
- remote presence/movement replicates;
- stable authored/runtime identity remains intact;
- join/leave removes or restores peer-owned runtime entities cleanly.

### P15-T04 — Host-authoritative gameplay replication
Replicate a bounded generic Phase 10 interaction set through validated client requests and host commits.

Acceptance:
- at minimum health/damage and one interaction-state system are host-authoritative;
- client-side direct authoritative mutation is rejected;
- state converges after normal replicated actions;
- disconnects do not corrupt runtime state.

### P15-T05 — Multiplayer template and competitive hooks
Add capability declarations, spawn/team/session metadata, simple score/objective hooks, and clean Visual Scripting exposure where appropriate.

Acceptance:
- multiplayer-capable templates can opt in;
- legacy templates behave unchanged;
- player-count/team/spawn validation is deterministic;
- graph nodes/events remain bounded and testable.

### P15-T06 — Multiplayer Play UX and accessibility
Integrate Offline/Host/Join controls and session status into the existing Build → Play experience.

Acceptance:
- keyboard-only and gamepad flows work;
- Phase 14 focus/target/glyph conventions are preserved;
- compact layout remains usable;
- connection errors are actionable and non-destructive.

### P15-T07 — Runtime authority, save, reconnect, and failure hardening
Harden host-only runtime save authority, join/leave/rejoin state, host termination, duplicate identity rejection, and Play-session cleanup.

Acceptance:
- clients cannot authoritatively save project/runtime state;
- repeated start/stop sessions do not leak peers;
- failure/reconnect cases are deterministic;
- no authored project mutation occurs from networking lifecycle alone.

### P15-T08 — Export/package integration and two-process verification
Extend Phase 13/14 export verification for multiplayer-capable packages.

Acceptance:
- exact runtime dependency closure includes required multiplayer files;
- multiplayer-enabled exported host/client processes connect and exercise the prototype;
- keyboard/mouse and gamepad exported runtime checks remain green;
- repeat-export stale-file replacement remains green.

### P15-T09 — Collaboration roadmap and boundary documentation
Produce the future collaborative-authoring architecture roadmap and explicitly separate it from gameplay networking.

Acceptance:
- identity, permissions, command/conflict model, asset sync, presence, history, security, offline/reconnect, and service requirements are specified;
- reuse boundaries with Phase 15 runtime networking are explicit;
- no fake collaborative-editing implementation is claimed.

### P15-T10 — Full Phase 15 verification and one completion PR
Run Phase 15 contracts, two-peer runtime tests, inherited Phase 6–14 regressions, Godot Smoke, rendered multiplayer UI/runtime evidence, Windows multiplayer export verification, documentation closeout, and open one completion PR to authoritative `master`.

Acceptance:
- all Phase 15 gates are green or any accepted exception is explicitly documented;
- backlog/master plan/current handoff are closed accurately;
- one completion PR is opened;
- the PR is not merged without explicit user authorization;
- Phase 16 does not begin before that merge is verified.

## Verification matrix
Required at milestone completion:
- Phase 15 contract suites: identity/session, transport/lifecycle, replication/authority, templates/visual scripting, UX/accessibility/export;
- deterministic two-peer headless/loopback runtime verification;
- join/leave/rejoin and host-termination failure-path verification;
- Small/Medium/Large multiplayer-capable fixture coverage where scale-sensitive;
- inherited Phase 6–14 regression gate;
- Godot Smoke;
- rendered Host/Join/session-status evidence in full and compact layouts;
- Windows exported two-process host/client verification;
- keyboard/mouse and gamepad exported input verification;
- documentation and collaboration-roadmap review.

## Development rule
Work continuously on `dev/phase15-multiplayer-collaboration-milestone`.

Intermediate commits and CI runs are expected. Do not stop for task-by-task PRs.

At Phase 15 completion:
1. finish P15-T01 through P15-T10;
2. run the full Phase 15 verification matrix and inherited gates;
3. capture required evidence;
4. close implementation/backlog/handoff documentation;
5. open one Phase 15 completion PR targeting authoritative `master`;
6. do not merge it without explicit user authorization.

## Security reminder
Historical `.polyforkAPI` credential material remains in Git history and must still be treated as exposed and rotated/revoked separately.
