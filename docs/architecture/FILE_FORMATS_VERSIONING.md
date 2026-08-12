# File Formats and Versioning

## General rules
- Every custom persistent document has a positive integer `schema_version`.
- `document_type` identifies custom records where file context alone is insufficient.
- Unsupported future versions fail safely.
- Stable UUIDs are never derived from paths, array positions, runtime node names, or scene-tree paths.
- Canonical authoring metadata is human-reviewable JSON where practical.
- Rebuildable caches must be deletable without changing authored identity.

## Phase 4 Asset Library
Each project owns managed `asset_library/` storage:
- `sources.json` — source-folder registry
- `catalog.json` — stable asset catalog and metadata
- `imports/` — rebuildable managed runtime copies
- `thumbnails/` — rebuildable generated cache

Registered external source roots are strictly read-only and never contain generated project files.

Supported source analysis/import formats remain `.gltf`, `.glb`, `.tscn`, and `.scn`.

## Phase 5 Terrain layout
Each project owns:

```text
<project>/terrain/
  manifest.json
  biomes.json
  cells/
    <stable-cell-id>.json
  recovery/
    <stable-cell-id>.json
```

### `terrain/manifest.json`
- `document_type: "terrain_manifest"`
- schema version 1
- stable project/profile topology
- cell size/resolution/streaming radius
- stable cell ID + coordinate map

### `terrain/biomes.json`
- `document_type: "biome_registry"`
- schema version 1
- stable data-driven biome records and terrain material hooks

### `terrain/cells/<cell-id>.json`
- `document_type: "terrain_cell"`
- schema version 1
- stable project/cell/biome IDs
- height samples
- revision and save timestamp

Terrain runtime meshes/collision are generated from these records and are not canonical files.

## Phase 6 Gameplay composition layout
Each project owns:

```text
<project>/gameplay/
  definitions.json
  instances.json
  archetypes.json
  prefabs.json
  sockets.json
  attachments.json
  prefab_instances.json
```

All Phase 6 documents use schema version 1 and are independently validated before promotion.

### `gameplay/definitions.json`
- `document_type: "component_registry"`
- contains `definitions[]`
- each record is a `component_definition`
- stable definition UUIDs, unique keys, typed property schemas/defaults, dependency/conflict UUIDs, editor category, runtime-hook metadata

### `gameplay/instances.json`
- `document_type: "component_instance_registry"`
- contains `instances[]`
- each record is a `component_instance`
- stable instance UUID, stable definition UUID, stable owner entity UUID, typed values

### `gameplay/archetypes.json`
- `document_type: "archetype_registry"`
- contains `archetypes[]`
- each record is an `archetype_definition`
- stable archetype UUID, required component-definition UUIDs, component default patches, tags

### `gameplay/prefabs.json`
- `document_type: "prefab_registry"`
- contains `prefabs[]`
- each record is a `prefab_definition`
- stable prefab UUID, optional base-prefab UUID, stable node UUIDs, component snapshots, authored node/socket overrides and removals

### `gameplay/sockets.json`
- `document_type: "socket_registry"`
- contains `sockets[]`
- each record is a `socket_definition`
- stable socket UUID, entity/prefab-node owner identity, owner-unique name, typed category, local transform

### `gameplay/attachments.json`
- `document_type: "attachment_registry"`
- contains `attachments[]`
- each record is an `attachment_record`
- parent entity/socket UUIDs, child entity UUID, optional child socket UUID, offset transform

### `gameplay/prefab_instances.json`
- `document_type: "prefab_instance_registry"`
- contains `prefab_instances[]`
- each record is a `prefab_instance_record`
- stable instance/prefab/root-entity UUIDs, stable prefab-node to world-entity mapping, explicit instance overrides

## Gameplay persistence rule
Gameplay authored data is project-managed content. It is never written into registered Phase 4 external source folders.

`PlayWorldSafeJsonWriter` is used for gameplay registry writes:
1. write a temporary candidate;
2. flush and close;
3. parse the candidate as JSON;
4. run semantic schema validation;
5. promote only after validation succeeds.

If promotion fails, the previous canonical document remains untouched. Corrupt JSON and unsupported future schema versions fail closed rather than silently replacing authored gameplay state.

JSON-parsed arrays are explicitly reconstructed into typed `Array[Dictionary]` gameplay state on reopen.

## Prefab and runtime identity rule
Prefab definitions, prefab nodes, prefab instances, world entities, component instances, sockets, and attachments use separate stable IDs.

Instantiating a prefab allocates fresh world entity UUIDs, component-instance UUIDs, and entity-owned socket UUIDs while retaining the prefab UUID. Runtime attachment anchors and runtime scene nodes are disposable and are not serialized.

## Incremental terrain write rule
A sculpt/biome edit dirties only its affected cell. Terrain autosave writes dirty cell files independently. An unchanged neighboring cell is not rewritten solely because another cell changed.

Before promoting a replacement terrain cell, the repository writes the prior validated canonical record to `terrain/recovery/<cell-id>.json`. If promotion fails, the previous canonical remains untouched and the cell remains dirty for retry.

If canonical terrain data is corrupt but a validated recovery copy exists, the recovery record may be loaded into memory and flagged as recovered; the corrupt canonical is not silently overwritten.

## Streaming and persistence
Streaming load/unload state is runtime state and is never serialized as identity. Stable `cell_id`, entity, component, prefab, socket, and attachment relationships survive unload/reload.

A dirty terrain cell may not be discarded before incremental terrain persistence succeeds. Gameplay references whose world participants are temporarily unavailable remain stable authored records and may resolve again when the runtime participant becomes available.

## Migration rule
Schema migrations belong in persistence/migration code, not UI scripts. Any future terrain or gameplay schema transformation must increment the relevant schema version and provide deterministic migration or explicit safe rejection behavior.
