# System Architecture

## Architectural rule
The editor core operates on generic entities, assets, terrain cells, components, archetypes, prefabs, sockets, attachments, properties, graphs, transactions, resources, runtime modules, and stable IDs. It does not hard-code broad gameplay behavior into the scene editor.

Persistent relationships use stable UUIDs. Scene-tree paths, node names, runtime pointers, transport peer IDs, and array positions are never persistent authored identity.

## Authoritative module map
1. App Shell / Workspace Layers — `src/app`
2. Project/World Manager — `src/world`
3. Runtime Placement Editor — `src/editor`
4. Command + Transaction/Undo System — `src/commands`
5. Asset Registry / Import / Thumbnail Pipeline — `src/assets`
6. Terrain + World Partition / Streaming — `src/terrain`
7. Entity/Component/Archetype/Prefab/Socket Authoring — `src/gameplay`
8. Instant Play / Runtime Controllers — `src/runtime`
9. Template System / Runtime Module Registry — `src/templates`, `templates/manifests`
10. Visual Script Runtime + Editor — `src/visual_script`
11. Foliage/Procedural/Spline Systems — `src/foliage`, `src/procedural`, `src/splines`
12. Environment/Weather/Water Integration — `src/environment`
13. AI Creation Orchestrator — `src/ai`
14. Export Pipeline / Standalone Runtime — `src/export`
15. Scale / Performance Profiles — `src/scale`
16. Input Abstraction — `src/input` plus semantic runtime input services
17. Diagnostics / Verification Harnesses — `src/diagnostics`, `tests`
18. Multiplayer Runtime Foundations — `src/network`
19. Future Collaborative Authoring — architecture roadmap only; no persistent collaboration runtime is claimed.

## Authored mutation boundary
All authored mutations flow through reversible commands or transactions. Failed execution/undo/redo does not advance history. Preview-only or disposable Play state does not dirty authored data.

Networking does not create a second authored mutation channel. Phase 15 session/peer lifecycle, remote player state, replicated gameplay state, and match state are transient Play concerns. Future collaborative authoring must integrate with the command/operation model rather than bypass it.

## Build / Play boundary
Phase 7 established `PlaySession` as the disposable runtime boundary. Later phases extend that same lifecycle rather than replace it:
- Visual Scripting compiles/executes against the disposable Play copy.
- Gameplay framework services own runtime interactions/state.
- Environment runtime applies Play-only simulation.
- AI authoring remains Build/transaction oriented.
- Phase 15 `NetworkRuntime` scans/binds the active Play session only when multiplayer capability is enabled.
- Stopping/replacing Play tears down network services and runtime peers without rewriting authored Build data.

## Stable identity and runtime identity
Authored stable IDs remain authoritative across world entities, components, prefabs, sockets, graphs, procedural sources, environment records, assets, templates, and project registries.

Phase 15 adds separate runtime identity:
- transport peer ID;
- session/network player ID;
- locally meaningful runtime ownership bindings.

These identities are disposable and may never replace authored stable IDs. `network_identity_registry.gd` maps runtime ownership to authored references only for the lifetime of a Play session.

## Multiplayer transport and authority
`network_session_contract.gd` owns protocol/version/message envelopes and role/config validation.

`enet_session_adapter.gd` owns Godot `ENetMultiplayerPeer` Offline/Host/Client lifecycle, compatibility handshake, reliable/unreliable packet boundaries, peer join/leave, disconnect/reconnect cleanup, and clean shutdown.

`network_runtime_service.gd` is the Phase 15 autoload coordinator. It binds networking to the existing active Play session and does not replace `PlaySession` architecture.

Host authority is the default Phase 15 gameplay boundary:
- player movement/presence is replicated through existing controller foundations;
- generic gameplay actions are validated before host-side application;
- health/damage/heal and interaction/door outcomes converge from host-authoritative results;
- match membership/team/score/objective state is host-authoritative;
- clients do not hold runtime persistence authority.

## Match/template integration
`multiplayer_template_contract.gd` normalizes the opt-in multiplayer capability with bounded player counts, mode, spawn strategy/spacing, teams, score mode, and rejoin policy.

The existing Template System remains the project-start contract. Multiplayer-enabled templates add `phase15.multiplayer` runtime capability without becoming editor forks. Offline templates normalize to disabled multiplayer and retain ordinary single-player behavior.

## Visual Scripting integration
Phase 15 does not create a second graph engine. Multiplayer uses the existing gameplay event/action boundary:
- namespaced actions such as `multiplayer.score.add` and `multiplayer.objective.set` flow through existing gameplay-event routing;
- session/peer lifecycle is surfaced as gameplay events;
- host-only mutation is enforced by the match/network services.

New graph event types should only be introduced when the graph runtime actually supports them; documentation must not claim fake join/leave graph entry nodes.

## Export architecture
Phase 13 owns deterministic runtime dependency closure and standalone packaging. Phase 14 adds performance-profile packaging. Phase 15 extends that closure conditionally:
- offline projects use the normal standalone runtime root and omit Phase 15 network runtime;
- multiplayer-enabled projects add the required network runtime root/dependencies;
- generated `runtime_data/multiplayer_profile.json` carries normalized capability metadata;
- standalone bootstrap dynamically loads networking only when capability and requested role require it.

This keeps multiplayer optional and prevents networking from contaminating ordinary offline exports.

## Multiplayer workspace UX
`multiplayer_workspace_layer.gd` provides the contextual Offline / Host & Play / Join & Play surface. It owns player name, address, port, capability summary, peer/session status, and keyboard/gamepad focus/hints. Full/compact layout must stay within the viewport and preserve the canonical dark playful visual language.

## Collaboration boundary
`docs/architecture/PHASE15_COLLABORATIVE_AUTHORING_ROADMAP.md` defines the future durable collaboration protocol. It requires durable author/session/operation identity, permissions, operation ordering, command-log compatibility, conflicts, asset revisions, presence, reconnect/rebase, audit/history, and service security.

Gameplay packet replication must never become the persistent document protocol by accident.

## Crash safety and persistence
`PlayWorldSafeJsonWriter` and phase-specific repositories remain the common fail-closed persistence pattern for authored JSON. Runtime networking state is not persisted as authored identity. Generated export metadata is packaging output and is recreated from normalized project capability.

## Performance / verification boundary
Phase 14 Low/Balanced/High profiles provide deterministic performance policy. Phase 15 adds bounded Small/Medium/Large network-state regression coverage and real two-process Windows export verification.

CI scale tests are regression proxies, not hardware FPS benchmarks. Setup/download failures that prevent a test from running must be reported as infrastructure failures rather than product passes or product failures.

## Current phase boundary
Phases 0–14 are merged on authoritative `master`. Phase 15 implementation is complete on its milestone branch and PR #20 remains the merge gate. Production matchmaking, relay/NAT traversal, account/auth infrastructure, voice chat, anti-cheat platform integration, rollback netcode, dedicated-server fleet orchestration, and real-time collaborative editor mutation remain outside Phase 15's implemented scope.
