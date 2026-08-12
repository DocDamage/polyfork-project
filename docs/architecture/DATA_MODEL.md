# Core Data Model

All persisted records follow the stable-ID/schema conventions in `PERSISTENT_ID_SCHEMA_CONVENTIONS.md`. Filesystem paths, scene-tree paths, runtime node names/pointers, transport peer IDs, and array positions are never persistent authored identity.

## AssetSource / AssetCatalog
Ownership: `src/assets`.

Source registrations use stable `source_id`, external `root_path` metadata, and mandatory read-only behavior. Catalog records use stable `asset_id` plus source-relative metadata, SHA-256 content hash, type, licensing, favorites, collections, analysis, derived import, thumbnail, and missing-state fields. Asset source folders remain external read-only inputs.

## WorldEntity
Ownership: `src/world`.

Key fields include stable `entity_id`, display name, stable owning `cell_id`, optional `asset_id`/`prefab_id`/`parent_entity_id`, component-instance references, and transform. Placement/movement across a terrain boundary updates transform and owning cell atomically. Streaming never rewrites authored identity.

## Terrain / gameplay / prefab / graph data
Terrain manifests/cells/biomes, component definitions/instances, archetypes, prefab definitions/instances, sockets/attachments, Visual Scripting graphs, procedural sources, environment state, AI history, and export configuration remain phase-owned project data using their documented stable IDs and schema contracts.

For detailed Phase 4–14 persisted layouts, see the owning system documents and `FILE_FORMATS_VERSIONING.md`.

## WorldProject
Ownership: `src/world`.

The project retains stable project/profile/template metadata, world cell/entity state, settings/registries, runtime module configuration, environment configuration, export configuration, and timestamps.

Phase 15 may store normalized multiplayer capability under the project's runtime/template-derived configuration. This capability is authored configuration; live session/peer/player transport identity is not.

## MultiplayerCapability
Ownership: `src/network/multiplayer_template_contract.gd` plus template/project runtime configuration.

Normalized fields:
- `enabled` — bool
- `mode` — `coop` or `competitive`
- `min_players` / `max_players` — bounded positive integers; implementation maximum is 16
- `spawn_strategy` — `offset` or `spawn_points`
- `spawn_spacing` — bounded float
- `teams[]` — normalized team IDs
- `score_mode` — `none`, `player`, `team`, or `objective`
- `rejoin_allowed` — bool

When multiplayer is disabled, the normalized capability is single-player (`min_players = 1`, `max_players = 1`). Competitive enabled configurations require at least two teams.

## RuntimeNetworkIdentity — explicitly non-persistent
Ownership: `src/network/network_identity_registry.gd` and network runtime services.

Runtime-only bindings include transport peer identity, session/network player identity, authored entity association when applicable, and local/remote ownership. They exist only for the active Play session.

Rules:
- network/session IDs never replace authored entity/component/prefab/graph/project IDs;
- runtime peer identity is not user/account authentication;
- disconnect/reconnect and Play teardown may allocate/remove runtime mappings without modifying authored stable IDs;
- no network identity registry is promoted into authored project persistence by Phase 15.

## NetworkMatchState — runtime-only
Ownership: `src/network/network_match_state.gd`.

Runtime match state contains normalized multiplayer capability, active players, team assignment, scores/objectives, and deterministic spawn offsets. Host snapshots are authoritative for clients. Match state is disposable Play state unless a future explicitly designed persisted gameplay system records a derived result.

## Exported multiplayer profile — generated, not canonical authored identity
When multiplayer is enabled, Phase 13/15 export staging writes `runtime_data/multiplayer_profile.json` from the normalized project capability. The file is regenerated during export and does not become a separate canonical authoring database.

Offline exports do not write that profile and do not include the Phase 15 network runtime root.

## WorldCheckpoint / crash safety
World checkpoints protect authored `WorldProject` state. Terrain/gameplay/graph/environment/AI repositories retain their phase-specific atomic/fail-closed contracts. Runtime networking state is not recovered as authored project state.

## Reference rule
No persisted relationship may use scene-tree path, node name, runtime array index, transient peer ID, source filesystem path, or streaming load order as identity. Authored relationships use their stable IDs; runtime network identity is explicitly separate and disposable.
