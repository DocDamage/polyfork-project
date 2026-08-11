# File Formats and Versioning

## General rules
- Every custom persistent document has a positive integer `schema_version`.
- `document_type` identifies custom records where file context alone is insufficient.
- Unsupported future versions fail safely.
- Stable UUIDs are never derived from paths or array positions.
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

Terrain runtime meshes/collision are generated from these cell records and are not canonical files.

## Incremental terrain write rule
A sculpt/biome edit dirties only its affected cell. Terrain autosave writes dirty cell files independently. An unchanged neighboring cell is not rewritten solely because another cell changed.

Before promoting a replacement cell, the repository writes the prior validated canonical record to `terrain/recovery/<cell-id>.json`. The new canonical candidate uses the existing safe JSON sequence: temporary write, flush/close, parse, semantic validation, promotion.

If promotion fails, the previous canonical remains untouched and the terrain cell remains dirty for retry.

If canonical terrain data is corrupt but a validated recovery copy exists, the recovery record may be loaded into memory and flagged as recovered; the corrupt canonical is not silently overwritten. If neither canonical nor recovery is valid/present, open fails closed instead of silently regenerating authored terrain.

## Streaming and persistence
Streaming load/unload state is runtime state and is never serialized as identity. Stable `cell_id` relationships survive unload/reload. A dirty cell may not be discarded by streaming before incremental persistence succeeds.

## Migration rule
Schema migrations belong in persistence/migration code, not UI scripts. Any future terrain schema change requiring transformation must increment its schema version and provide deterministic migration/recovery behavior.
