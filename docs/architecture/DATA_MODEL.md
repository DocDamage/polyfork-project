# Core Data Model

All persisted records follow `docs/architecture/PERSISTENT_ID_SCHEMA_CONVENTIONS.md`: stable lowercase UUID identities, positive integer `schema_version`, stable-ID references, and explicit editor/runtime ownership.

## AssetRecord
Fields include: schema_version, id, source_path, canonical_path, hash, type, display_name, source_pack, author, license, source_url, commercial_use, attribution_required, tags, categories, dimensions, thumbnail, material_summary, texture_summary, animation_summary, skeleton_summary, collision_summary, lod_summary, estimated_memory, import_status, warnings.

Ownership: `src/assets`. `id` remains stable across ordinary rescans when the catalog entry is reconciled. Source paths and hashes are metadata, not identity.

## WorldEntity
Fields include: schema_version, document_type, entity_id, display_name, transform, asset/prefab reference IDs, component instance IDs, owning world-cell ID, and parent entity ID.

Ownership: `src/world`. `entity_id` is stable across ordinary edits and persistence cycles. Parent, prefab, component, and cell relationships are stable-ID references. Optional UUID fields serialize as JSON `null` and load back to an empty runtime reference rather than a stringified null value.

## ComponentDefinition
Fields include: schema_version, id, display name, category, properties schema, runtime script/class, dependencies, incompatible component IDs, exposed events/actions, serialization version.

Ownership: `src/gameplay`.

## ComponentInstance
Fields include: schema_version, id, definition_id, owner_entity_id, property values, runtime-required state, editor metadata where applicable.

Ownership: `src/gameplay`. Each independently persisted component instance has its own stable ID.

## Archetype
Fields include: schema_version, id, base_archetype_id, required/default component definition IDs, property defaults, tags, icon, validation rules.

Ownership: `src/gameplay`.

## Prefab
Fields include: schema_version, id, base_prefab_id optional, root entity snapshot, child entities, component overrides, socket definitions, exposed parameters, inheritance overrides, thumbnail metadata.

Ownership: `src/gameplay`.

## VisualGraph
Fields include: schema_version, id, owner scope/reference ID, variables, nodes, edges, entry events, macros/functions, validation state, runtime compile/cache metadata.

Ownership: `src/visual_script`. Canonical graph data is persistent; compiled/cache data must be rebuildable.

## ProceduralSet
Fields include: schema_version, id, generator type, seed, bounds, rule set, source asset queries, generated entity ownership IDs, regeneration policy.

Ownership: the system that owns the generator type (`src/foliage`, `src/splines`, terrain/procedural systems, etc.).

## WorldCell
Fields include: schema_version, id, project_id, coordinates/bounds, owned entity IDs, terrain resource IDs, dirty/revision metadata, streaming metadata.

Ownership: `src/world`.

## WorldProject
Fields include: schema_version, document_type, project_id, title, template ID, world profile, cell IDs, persisted entity records, environment references/state, registries, editor settings, export settings, dependency list, created/updated Unix timestamps, and optional millisecond-resolution created/updated timestamps.

Ownership: `src/world`. `project_id` is the root stable UUID for the authored project. `entities` is an additive optional schema-v1 field containing validated `WorldEntity` records. Older schema-v1 manifests without `entities` load with an empty entity-record collection. Persisted entity IDs must be unique, owning `cell_id` values must resolve within the project, and `parent_entity_id` values must resolve to another persisted project entity and may not self-reference.

Millisecond timestamps are backward-compatible optional schema-v1 metadata for deterministic save/checkpoint ordering; older schema-v1 manifests without those fields derive them from the existing Unix-second timestamps when loaded.

## WorldCheckpoint
Fields: schema_version, document_type, id, project_id, created_at_msec, project_state.

Ownership: `src/world`, with `checkpoint_store.gd` as write/retention authority and `checkpoint_record.gd` as schema/validation authority. `id` is the checkpoint's stable UUID. `project_id` is the stable owning project reference. `project_state` is a complete validated `WorldProject` snapshot and must carry the same `project_id`. Checkpoint documents are editor persistence/recovery data rather than exported runtime gameplay state. Checkpoint schema migration responsibility remains in world persistence code.

## Reference rule
No persisted relationship in these models may use a scene-tree path, node name, array index, or filesystem path as identity. Those values may exist as metadata only where explicitly documented.
