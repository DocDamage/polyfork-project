# Core Data Model

All persisted records follow the stable-ID/schema conventions in `PERSISTENT_ID_SCHEMA_CONVENTIONS.md`. Filesystem paths, scene-tree paths, runtime node names, and array positions are never persistent identity.

## AssetSource / AssetCatalog
Ownership: `src/assets`.

Phase 4 source registrations use stable `source_id`, external `root_path` metadata, and mandatory `read_only: true`. Catalog records use stable `asset_id` plus source-relative metadata, SHA-256 content hash, type, licensing, favorites, collections, analysis, derived import, thumbnail, and missing-state fields.

Asset source folders remain external read-only inputs.

## WorldEntity
Ownership: `src/world`.

Key fields:
- `entity_id` — stable UUID
- `display_name`
- `cell_id` — stable owning world/terrain cell UUID
- optional `asset_id`, `prefab_id`, `parent_entity_id`
- component instance IDs
- transform

Phase 5 makes `cell_id` spatially meaningful for partitioned worlds. Placement/movement across a terrain boundary updates transform and owning cell atomically through command history. Streaming never rewrites `entity_id`, `parent_entity_id`, or `cell_id` merely because a referenced entity is unloaded.

## TerrainManifest
Ownership: `src/terrain/terrain_schema.gd` + `terrain_repository.gd`.

Schema-v1 fields:
- `document_type: "terrain_manifest"`
- `schema_version`
- `project_id`
- `profile_id`
- `streaming`
- `cell_size_m`
- `resolution`
- `load_radius`
- `cells[]` with stable `cell_id` and integer `[x,z]` coordinate

Cell IDs and coordinates are unique. Unsupported future schema versions fail safely.

## TerrainCell
Ownership: `src/terrain`.

Schema-v1 fields:
- `document_type: "terrain_cell"`
- `schema_version`
- `project_id`
- `cell_id`
- integer `[x,z]` coordinate
- `cell_size_m`
- odd grid `resolution` (Phase 5 default 17)
- flat `heights[]` array of `resolution²` float samples
- non-negative `revision`
- stable `biome_id`
- positive `saved_at_msec`

The terrain cell record is authored state. Runtime mesh/collision is rebuildable from it and is not persistent identity.

## BiomeRegistry / Biome
Ownership: `src/terrain`.

Biome registry schema-v1 fields:
- `document_type: "biome_registry"`
- `schema_version`
- `project_id`
- `biomes[]`

Biome fields:
- `biome_id` — stable UUID
- `display_name`
- RGBA `color`
- `terrain_material_slots[]`
- `future_defaults` dictionary

The initial Phase 5 presets are Meadow, Desert, and Alpine. Their fields are data hooks, not hard-coded foliage/weather implementations. Future foliage/environment IDs remain null until their owning phases.

## WorldProject
Ownership: `src/world`.

The project retains stable project/profile/template metadata, `cell_ids`, world entity records, environment/settings/registry data, and timestamps. Terrain height grids are intentionally not embedded in the project manifest; they are project-managed sibling files under `<project>/terrain`.

When a Phase 5 topology introduces additional stable cells, those IDs are added to `WorldProject.cell_ids` so existing entity validation can require owning cell references to resolve.

## WorldCheckpoint
Ownership: `src/world`.

World checkpoints still protect `WorldProject` state. Terrain cells have their own prior-known-good recovery copies because terrain is persisted incrementally per cell rather than by rewriting the complete project checkpoint for every sculpt stroke.

## Later models
ComponentDefinition, ComponentInstance, Archetype, Prefab, VisualGraph, and ProceduralSet remain owned by later phases. Phase 5 does not fabricate these models to implement terrain.

## Reference rule
No persisted relationship may use scene-tree path, node name, runtime array index, source filesystem path, or streaming load order as identity. Asset, entity, biome, project, parent, component, prefab, and cell relationships use stable IDs.
