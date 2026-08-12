# Phase 15 — Collaborative Authoring Roadmap

## Status
DESIGN COMPLETE / IMPLEMENTATION DEFERRED

This document defines the future collaborative-authoring architecture requested by Phase 15. It does **not** claim that real-time collaborative editing is implemented.

## Core boundary
Gameplay networking and collaborative authoring solve different problems.

Phase 15 gameplay networking is:
- disposable Play-session state;
- host-authoritative;
- optimized for runtime player/gameplay replication;
- allowed to discard transient state when Play ends;
- deliberately separated from authored project persistence.

Future collaborative authoring must instead be:
- durable across sessions;
- operation/history aware;
- compatible with the universal command + Undo/Redo model;
- safe for concurrent edits to persistent authored documents and assets;
- capable of conflict reporting and recovery after disconnects.

The collaboration protocol may reuse transport/session primitives from Phase 15, but it must not reuse gameplay replication messages as its document protocol.

## Identity model
Every collaborative session needs three distinct identities:

1. **Account/author identity** — durable person or service identity used for permissions, attribution, audit, and ownership.
2. **Device/session identity** — reconnectable collaboration endpoint identity for a specific editor session.
3. **Operation identity** — globally unique immutable ID for every authored command submitted to the collaboration log.

None of these replace authored entity, prefab, graph, terrain-source, spline, asset, or project stable IDs.

Recommended operation envelope:

```text
operation_id
project_id
base_revision
actor_id
session_id
client_sequence
command_type
command_payload
referenced_stable_ids[]
asset_revisions{}
timestamp_hint
```

The authoritative service assigns the accepted revision/order. Client clock time must never determine authoritative ordering.

## Permissions
Future collaboration should support at minimum:
- owner;
- editor;
- commenter/reviewer;
- viewer;
- automation/service principal.

Permissions should be capability-based rather than only UI-based. Server-side validation must gate persistent operations such as project settings, authored entity mutation, asset replacement, AI Execute, export/release configuration, destructive operations, and permission changes.

A viewer receiving an editor UI by mistake must still be unable to commit editor operations.

## Command-log integration
The existing universal command/Undo/Redo model should become the collaboration operation source, not be bypassed.

Recommended flow:
1. local author creates a normal project command;
2. client assigns operation ID and base revision;
3. optimistic local preview may apply when the command is declared safely reversible;
4. authoritative collaboration service validates permissions, schema, references, and revision/conflict policy;
5. accepted operation receives an authoritative revision and is broadcast;
6. rejected operation is rolled back locally through its inverse/Undo contract;
7. all clients converge by replaying the same accepted operation stream.

Collaborative Undo should create a new inverse operation against a previously accepted operation. It must not erase shared history.

## Conflict model
Do not use one universal last-writer-wins rule.

Classify commands by conflict behavior:

### Naturally commutative
Examples:
- adding independent entities with distinct stable IDs;
- adding independent graph nodes;
- adding non-overlapping collection membership.

These may merge automatically when references remain valid.

### Field-level replace
Examples:
- entity display name;
- transform component;
- scalar environment setting.

Use base revision plus per-field revision stamps. Non-overlapping fields can merge. Same-field concurrent edits require deterministic policy and visible conflict history.

### Structural/exclusive
Examples:
- delete vs edit of the same entity;
- prefab inheritance changes;
- graph edge rewires touching the same port;
- terrain topology/partition changes;
- asset replacement/version changes;
- destructive bulk AI Execute.

These require explicit validation and may reject/rebase rather than silently overwrite.

### Large spatial operations
Terrain, foliage paint/erase, and procedural authoring should record bounded regions/source IDs so overlap can be detected without locking the whole world.

## Conflict resolution policy
Preferred order:
1. merge automatically when operations are independent;
2. rebase deterministic commands when their referenced state still exists;
3. reject when semantic preconditions changed;
4. surface a human conflict when two valid intents cannot be safely combined.

Never silently invent a merged authored result when intent is ambiguous.

Conflict records should include both operations, affected stable IDs/fields/regions, accepted revision, and available resolution actions.

## Asset synchronization
The Asset Library needs revision-aware collaboration rather than raw path sharing.

Future shared asset references should identify:
- asset ID;
- content hash;
- importer/version metadata;
- license/attribution metadata;
- availability state;
- optional source repository/provider revision.

Before accepting an authored operation that references an asset, the service must validate that all required collaborators can resolve the declared asset revision or clearly mark the operation/project as having unavailable dependencies.

Asset replacement should create a new revision. It must not mutate historical operations to pretend they referenced the new bytes.

Large binary transfer should use an object/blob service, not the collaboration operation stream itself.

## Presence
Presence is transient and must remain separate from the durable authoring log.

Useful presence data:
- online/offline author status;
- current workspace;
- selected stable IDs;
- viewport/camera location when explicitly shared;
- graph cursor/selection;
- optional text-field editing presence;
- temporary soft-lock/intention hints.

Presence may expire by lease/heartbeat. Losing presence must never delete authored data.

## Optimistic authoring
Safe optimistic operations may render locally before server acknowledgement when:
- the command has a deterministic inverse;
- referenced IDs are known;
- no privileged permission boundary is crossed;
- rollback does not destroy uncommitted dependent work.

High-risk structural or destructive operations should wait for authoritative acceptance or use a staged preview/commit model.

AI Execute should remain Preview-before-Execute and become one atomic collaboration operation/batch with explicit provenance, rather than broadcasting individual generated mutations ad hoc.

## Offline and reconnect
Offline collaborative work should maintain a local branch of operations with:
- last acknowledged authoritative revision;
- ordered local operation IDs;
- referenced asset revisions;
- command inverses where required.

On reconnect:
1. fetch authoritative operations after the last acknowledged revision;
2. replay them locally;
3. rebase queued local operations in original client order;
4. submit each or an atomic declared batch;
5. surface conflicts/rejections explicitly;
6. never reuse operation IDs for changed payloads.

A device/session identity may reconnect, but author identity and operation IDs remain durable.

## History and audit
Shared history should be append-only at the logical operation layer.

Record:
- actor identity;
- authoritative revision;
- operation type;
- affected stable IDs/regions;
- result status;
- inverse/revert relationships;
- AI provenance when applicable;
- asset revisions;
- permission-sensitive administrative actions.

Project checkpoints can compact replay cost while preserving the operation/audit lineage needed to explain later state.

## Security and privacy
Required boundaries:
- TLS or equivalent authenticated encryption for hosted collaboration transport;
- authenticated author/session credentials, never project-stored API secrets;
- server-side authorization for every persistent mutation;
- bounded payload/schema validation before command execution;
- rate/size limits for operations and presence;
- asset/object authorization independent of guessed URLs;
- explicit cloud consent for AI requests consistent with Phase 12;
- no transmission of local Asset Library contents merely because a collaboration session exists;
- log redaction policy for credentials/private paths;
- revocable sessions and permission changes;
- auditability of destructive/admin operations.

The historical `.polyforkAPI` material already present in Git history remains unrelated exposed credential material and still requires separate rotation/revocation.

## Hosted-service requirements
A production collaboration service will likely need separate components for:
- authentication/account identity;
- project membership and permissions;
- authoritative operation sequencing/log;
- project checkpoints/snapshots;
- transient presence fan-out;
- binary asset/blob storage and revision metadata;
- reconnect cursors/acknowledgements;
- conflict records;
- audit retention;
- optional relay/WebSocket/WebRTC transport depending deployment constraints.

This is substantially more than an ENet gameplay host.

## Reuse from Phase 15 runtime networking
Reasonable reuse:
- session-role vocabulary;
- peer/session lifecycle concepts;
- bounded message-envelope/versioning discipline;
- capability/version handshake ideas;
- deterministic disconnect cleanup patterns;
- common status/error UI conventions;
- test strategies using multiple endpoints.

Do **not** reuse as the collaboration protocol:
- gameplay player IDs as durable author identities;
- transient player-state snapshots;
- gameplay action RPCs;
- host runtime save authority;
- ENet host ownership as project ownership;
- disposable PlaySession lifetime.

## Recommended future milestones
### Collaboration Phase A — Durable operation protocol
Author/session/operation identities, command serialization, authoritative revision log, permissions, two-editor headless convergence tests.

### Collaboration Phase B — Presence and conflict UX
Selections/cursors/presence, field and structural conflict surfaces, reconnect/rebase tooling, shared history UI.

### Collaboration Phase C — Asset synchronization
Revisioned binary/object service, availability/version checks, import metadata synchronization, license/attribution preservation.

### Collaboration Phase D — Hosted production hardening
Authentication providers, encrypted hosted transport, scale/relay deployment, audit retention, abuse/rate controls, disaster recovery, service observability.

## Phase 15 completion criterion
Phase 15 satisfies its collaboration requirement by delivering this explicit architecture boundary and roadmap while implementing only gameplay multiplayer foundations. No document should describe real-time collaborative editing as a completed Phase 15 feature.
