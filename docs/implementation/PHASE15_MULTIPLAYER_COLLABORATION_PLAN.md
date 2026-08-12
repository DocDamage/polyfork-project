# Phase 15 — Multiplayer Foundations and Collaboration Roadmap

## Status
COMPLETE / PR READY

Authoritative base:

`14085eb703b72d930f39121d3da18362d43cc77d`

Milestone branch:

`dev/phase15-multiplayer-collaboration-milestone`

Verified implementation head before documentation-only closeout:

`93b67eb5e50ffe5b2b686027d6a400ee9ccff1f0`

## Milestone result
Phase 15 added bounded host-authoritative multiplayer foundations to the existing Polyfork runtime and export architecture without replacing the Phase 7 `PlaySession`, Phase 10 gameplay state, Phase 13 export pipeline, or Phase 14 scale/polish architecture.

Offline single-player remains first-class. Multiplayer session/network IDs remain runtime-only and layered over authored stable IDs. Real-time collaborative editor mutation remains explicitly deferred to a future collaboration protocol.

## Architecture invariants retained
- Authored persistent stable IDs remain the source of truth; network/session identity does not rewrite them.
- Offline Play remains unchanged when multiplayer is disabled.
- Multiplayer state is disposable Play-session state.
- Host authority validates and commits replicated gameplay state.
- Phase 10 runtime gameplay services remain the gameplay source of truth.
- Phase 7 semantic gameplay input remains the local-player input abstraction.
- Multiplayer export dependencies are optional and derived from declared project capability.
- Editor-only networking UI/diagnostics are excluded from standalone dependency closure.
- Collaborative authoring is a separate durable operation/history problem, not gameplay replication.

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
- [x] P15-T10 — Full verification, inherited regressions, rendered evidence, documentation closeout, and completion-PR readiness

## Delivered networking baseline
- roles: offline / host / client;
- versioned protocol/runtime-contract handshake;
- session and peer IDs;
- runtime peer↔authored-entity ownership mapping without stable-ID mutation;
- ENet LAN/loopback host/client transport behind project-owned adapter;
- reliable/unreliable packet boundary;
- explicit peer join/leave/disconnect cleanup;
- host termination/reconnect/repeated-session hardening;
- host-only runtime save authority.

## Delivered co-op/runtime prototype
- existing first/third-person controllers can represent local and remote multiplayer players;
- local player consumes semantic input; remote players do not;
- player transform/presence state replicates;
- health/damage/heal and door/interaction state use host-authoritative requests/results;
- spoofed client ownership/action claims fail closed;
- runtime match membership converges;
- Play teardown leaves no authored networking mutation.

## Delivered template/match/Visual Scripting hooks
- opt-in multiplayer capability declarations;
- bounded min/max player validation;
- deterministic team assignment and spawn offsets;
- score/objective match state;
- `multiplayer.score.add` and `multiplayer.objective.set` host-authoritative actions through the existing `gameplay.emit_event` graph path;
- `multiplayer.session.ready`, `multiplayer.peer.joined`, and `multiplayer.peer.left` runtime events on the existing gameplay event bus;
- legacy/offline templates remain valid.

## Delivered UX
- canonical top-bar Multiplayer surface;
- Offline / Host & Play / Join & Play;
- host address/port/player fields;
- session status and peer count;
- explicit error status;
- keyboard-only and gamepad-aware focus/input hints;
- Phase 14 minimum-target/focus policy reuse;
- corrected full/compact right-anchored panel behavior.

## Delivered export integration
- offline export source closure excludes Phase 15 network runtime;
- multiplayer-capable export closure adds only required network runtime roots/dependencies;
- multiplayer capability metadata is packaged for enabled builds;
- standalone bootstrap dynamically loads networking through Godot's export-aware resource loader;
- environment-driven Host/Client launch is available for standalone validation without changing default offline behavior;
- Windows verification creates multiplayer and offline packages, verifies repeat-export stale-file removal, launches offline standalone, then launches exported host/client concurrently;
- exported host/client verifies peer convergence, local input enabled, remote input disabled, keyboard/mouse and gamepad semantic bindings, and match membership.

## Collaboration roadmap
`docs/architecture/PHASE15_COLLABORATIVE_AUTHORING_ROADMAP.md`

The roadmap covers durable author/session/operation identity, permissions, universal command-log compatibility, conflict classes and resolution, asset revisions, presence, optimistic operations, offline/reconnect/rebase, append-only history/audit, security/privacy, hosted-service requirements, and clear reuse/non-reuse boundaries with Phase 15 gameplay networking.

It does **not** claim collaborative editing is implemented.

## Verification
- Phase 15 Contracts — run `31635239746` — PASS — identity, loopback, replication, templates, lifecycle, match, export, scale
- Phase 15 Inherited Regressions — run `31634218734` — PASS — Phase 6 through Phase 14 plus Phase 14 scale stress
- Godot Smoke — run `31635582701` — PASS on final implementation head
- Phase 15 Visual Evidence — run `31634842058` — PASS; corrected compact panel visually inspected
- Phase 15 Windows Multiplayer Export — run `31635582699` — PASS; offline package plus real exported concurrent host/client

A later contract matrix run had one infrastructure-only Godot download failure before its test shard began; the complete eight-suite contract run above is green.

## Scope guard retained
Phase 15 does not claim production matchmaking, cloud relay/account infrastructure, NAT traversal service, voice chat, anti-cheat platform integration, rollback netcode, dedicated-server fleet orchestration, or real-time collaborative editor mutation.

## Completion rule
Open one completion PR targeting authoritative `master`.

Do **not** merge it without explicit user authorization.

Do not begin Phase 16 until the Phase 15 PR is explicitly merged and the resulting authoritative `master` SHA is verified.

## Security reminder
Historical `.polyforkAPI` credential material remains in Git history and must still be treated as exposed and rotated/revoked separately.
