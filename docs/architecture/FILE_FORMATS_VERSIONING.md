# File Formats and Versioning

## General rules
- Every custom persistent authoring document has a positive integer `schema_version` where its owning contract defines one.
- `document_type` identifies custom records where file context alone is insufficient.
- Unsupported future versions fail safely.
- Stable authored UUIDs are never derived from paths, array positions, runtime node names, scene-tree paths, or transport peer IDs.
- Canonical authoring metadata is human-reviewable JSON where practical.
- Rebuildable caches and generated export metadata must be deletable/regenerable without changing authored identity.

## Project-managed authoring layout
Phase-owned project storage includes, as applicable:
- `asset_library/` — registered source metadata, catalog, imports, thumbnails; external roots remain read-only.
- `terrain/` — manifest, biomes, per-cell data, recovery.
- `gameplay/` — component/archetype/prefab/socket/attachment registries.
- `visual_scripting/` — graph registry/content.
- procedural/spline/environment/AI/runtime configuration owned by their phase-specific repositories.

The owning system documents define the exact schema contracts. Authored registries use stable IDs and fail closed on corruption/future unsupported versions.

## Phase 15 multiplayer capability
Phase 15 does **not** add a persisted peer/session identity database.

The authored/runtime configuration may contain a normalized multiplayer capability with these fields:

```json
{
  "enabled": true,
  "mode": "coop",
  "min_players": 1,
  "max_players": 4,
  "spawn_strategy": "offset",
  "spawn_spacing": 2.5,
  "teams": [],
  "score_mode": "objective",
  "rejoin_allowed": true
}
```

Contract rules are owned by `src/network/multiplayer_template_contract.gd`:
- mode is `coop` or `competitive`;
- implementation max players is 16;
- enabled multiplayer must support at least two players;
- disabled capability normalizes to one player;
- spawn strategy is `offset` or `spawn_points`;
- spawn spacing is bounded from 0.5 to 50.0;
- score mode is `none`, `player`, `team`, or `objective`;
- competitive enabled configurations require at least two team IDs;
- `rejoin_allowed` is explicit.

## Runtime network protocol
`src/network/network_session_contract.gd` owns the Phase 15 runtime protocol/version/message envelope. Protocol compatibility is a runtime handshake concern and is not the same as authored file schema migration.

Session/peer/network-player IDs and live match snapshots are transient Play state and are not serialized as authored identity.

## Phase 13–15 export-generated files
Export staging may generate runtime-only package metadata in addition to authored runtime data:

```text
runtime_data/
  performance_profile.json     # when a performance profile is packaged
  multiplayer_profile.json     # only when multiplayer capability is enabled
export_report.json
export_manifest.json
ATTRIBUTIONS.txt
```

`runtime_data/multiplayer_profile.json` is the normalized multiplayer capability used by standalone runtime startup. It is generated from project data during export, not edited as a second source of truth.

`export_report.json` includes `multiplayer_enabled` and, when enabled, a `multiplayer_capability` snapshot. Repeat export staging resets the destination so stale multiplayer metadata cannot survive an offline replacement export.

Offline export dependency closure excludes `src/network/network_runtime_service.gd`. Multiplayer-enabled closure adds the required network runtime root and its resolved source dependencies.

## Persistence / promotion rule
Authoring repositories that use `PlayWorldSafeJsonWriter` or equivalent phase-owned safe writers follow the fail-closed pattern: write candidate -> flush/close -> parse -> validate -> promote. Failed promotion preserves the prior canonical content.

## Streaming and identity
Streaming load/unload state is runtime state and is never serialized as identity. Stable authored relationships survive unload/reload. Runtime network ownership may disappear/rebind as sessions change without rewriting those stable authored relationships.

## Migration rule
Schema migrations belong in persistence/migration code, not UI scripts. Any future authored schema transformation must increment the owning schema version and provide deterministic migration or explicit safe rejection behavior. A runtime network protocol change must update its protocol compatibility contract independently from authored data migrations.
