# Multiplayer and Collaboration System

## Current implementation status
Phase 15 implements bounded **gameplay networking foundations**. Production collaborative authoring remains a roadmap item and is intentionally separate.

Implementation owner: `src/network` plus existing Play/template/gameplay/export/input integration points.

Detailed future collaboration design: `docs/architecture/PHASE15_COLLABORATIVE_AUTHORING_ROADMAP.md`.

## Gameplay networking implemented in Phase 15
### Roles / transport
- Offline, Host, Client/Join roles.
- Project-owned Godot 4.7.1 `ENetMultiplayerPeer` adapter.
- Versioned compatibility handshake.
- Reliable/unreliable packet boundary owned by the network session adapter.
- Join/leave/disconnect/reconnect/host-termination cleanup.

### Identity
Authored stable IDs remain canonical. Runtime peer/session/network-player identity is separate, transient, and may not rewrite authored entity/component/prefab/project identity.

### Player replication
Existing first-person and third-person controller foundations are reused. Remote controllers have local input disabled and accept network-applied state; local controller ownership remains local.

### Gameplay authority
Host validates/applies replicated generic gameplay requests. Phase 15 covers bounded health/damage/heal and interaction/door state convergence, including client spoof/direct-authority rejection.

Clients do not have authoritative runtime save permission.

### Match state
Normalized template capability defines co-op/competitive mode, player limits, spawn strategy/spacing, teams, score mode, and rejoin policy. Host owns authoritative player/team/score/objective snapshots.

### Visual Scripting
Multiplayer extends the existing gameplay event/action route rather than creating a second graph runtime. Namespaced score/objective actions and session/peer events are serviced by network/match systems.

### UX
The Multiplayer workspace exposes Offline / Host & Play / Join & Play, player identity, endpoint configuration, capability summary, peer/session status, keyboard/gamepad focus/hints, and adaptive full/compact layout.

### Export
Offline exports omit Phase 15 network runtime. Multiplayer-enabled exports include required network closure and generated `runtime_data/multiplayer_profile.json`; standalone runtime loads networking only when capability and requested role require it.

## Explicit Phase 15 boundaries
Not implemented/claimed:
- production matchmaking;
- hosted relay or NAT traversal service;
- account/auth service;
- voice chat;
- anti-cheat platform integration;
- rollback netcode;
- dedicated-server fleet orchestration;
- production hostile-internet security guarantees;
- real-time collaborative editor mutation.

## Collaborative editing roadmap
Future collaboration replicates durable commands/operations, not raw gameplay packets or scene-tree diffs.

It requires:
- durable account/author identity;
- reconnectable editor-session identity;
- globally unique operation identity;
- project revision/order assigned by an authoritative service;
- permission/capability enforcement;
- universal command/Undo integration;
- conflict classification/resolution;
- asset revisions/sync;
- transient presence separate from durable operations;
- optimistic reversible edits;
- offline/reconnect/rebase policy;
- append-only audit/history;
- security/privacy/hosted-service architecture.

Collaborative Undo should create an inverse operation; it should not erase shared history.

## Reuse rule
Future collaboration may reuse selected transport/session concepts from Phase 15, but **must not** reuse gameplay replication messages as its persistent document protocol.
