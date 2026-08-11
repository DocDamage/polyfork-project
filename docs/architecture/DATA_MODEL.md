# Core Data Model

All persisted records follow `docs/architecture/PERSISTENT_ID_SCHEMA_CONVENTIONS.md`: stable lowercase UUID identities, positive integer `schema_version`, stable-ID references, and explicit ownership. Filesystem paths are metadata, never persistent object identity.

## AssetSource
Ownership: `src/assets`.

Schema-v1 fields:
- `document_type: "asset_source"`
- `schema_version`
- `source_id` — stable UUID
- `display_name`
- `root_path` — normalized external folder path used only to locate source content
- `enabled`
- `read_only` — must always be `true`

External source folders are never project-managed storage. Registration, scanning, analysis, imports, metadata, thumbnail generation, and duplicate detection must not write into them.

## AssetSourceRegistry
Ownership: `src/assets/source_folder_registry.gd`.

Schema-v1 document fields:
- `document_type: "asset_source_registry"`
- `schema_version`
- `sources[]` — validated `AssetSource` records with unique source IDs and root paths

The registry itself is stored under the owning project's managed `asset_library` directory, not in any source folder.

## AssetRecord
Ownership: `src/assets`.

Schema-v1 fields implemented in Phase 4:
- `document_type: "asset_record"`
- `schema_version`
- `asset_id` — stable UUID and the only persistent asset identity
- `source_id` — stable reference to the registered source
- `relative_path` — source-relative location metadata
- `display_name`
- `asset_type` — `gltf`, `glb`, `godot_text_scene`, or `godot_binary_scene`
- `content_hash` — SHA-256 content hash
- `size_bytes`
- `modified_time`
- `missing`
- `favorite`
- `collections[]`
- `license` — `spdx`, `author`, `source_url`, `notes`
- `user_metadata`
- `analysis`
- `derived`
- `thumbnail`

`asset_id` survives ordinary rescans. Same-path records retain identity. A move inside the same registered source retains identity only when the reconciliation pass can prove a unique content-signature match. Ambiguous duplicate content is not silently merged; each source file remains an independent catalog record.

`relative_path`, modification time, file size, and content hash support discovery/reconciliation but are not identity. Missing records are retained so existing world references do not silently retarget another source file.

## AssetCatalog
Ownership: `src/assets/asset_catalog.gd`.

Schema-v1 document fields:
- `document_type: "asset_catalog"`
- `schema_version`
- `records[]` — validated `AssetRecord` values with unique `asset_id`

Favorites, collections, licensing/source metadata, analysis state, derived-import metadata, and thumbnail metadata are canonical editor catalog state. Exact-content duplicate groups are a computed view and never authorize source deletion or merging.

## WorldEntity
Fields include: schema_version, document_type, entity_id, display_name, transform, optional asset/prefab reference IDs, component instance IDs, owning world-cell ID, and parent entity ID.

Ownership: `src/world`. `entity_id` is stable across ordinary edits and persistence cycles. `asset_id` is a stable reference into the project Asset Library catalog. Phase 4 uses that existing field directly and does not create a prefab record simply to place a catalog asset.

Parent, prefab, component, asset, and cell relationships use stable IDs. Optional UUID fields serialize as JSON `null` and load back to an empty runtime reference rather than a stringified null value.

## ComponentDefinition
Fields include: schema_version, id, display name, category, properties schema, runtime script/class, dependencies, incompatible component IDs, exposed events/actions, serialization version.

Ownership: `src/gameplay`. This is a later-phase model and was not fabricated by Phase 4.

## ComponentInstance
Fields include: schema_version, id, definition_id, owner_entity_id, property values, runtime-required state, editor metadata where applicable.

Ownership: `src/gameplay`. This is a later-phase model.

## Archetype
Fields include: schema_version, id, base_archetype_id, required/default component definition IDs, property defaults, tags, icon, validation rules.

Ownership: `src/gameplay`. This is a later-phase model.

## Prefab
Fields include: schema_version, id, base_prefab_id optional, root entity snapshot, child entities, component overrides, socket definitions, exposed parameters, inheritance overrides, thumbnail metadata.

Ownership: `src/gameplay`. Prefabs remain a later phase. Phase 4 asset placement does not manufacture prefab records.

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
Fields include: schema_version, document_type, project_id, title, template ID, world profile, cell IDs, persisted entity records, environment references/state, registries, editor settings, export settings, dependency list, created/updated timestamps.

Ownership: `src/world`. `project_id` is the root stable UUID for authored project state. Asset Library catalog/source documents are project-managed sibling persistence under the stable project directory rather than embedded into `WorldProject` JSON.

## WorldCheckpoint
Fields: schema_version, document_type, id, project_id, created_at_msec, project_state.

Ownership: `src/world`. Checkpoint documents contain validated `WorldProject` state. Asset Library catalog state has its own crash-safe managed files and can be reopened independently while world entities retain stable `asset_id` references.

## Reference rule
No persisted relationship in these models may use a scene-tree path, node name, array index, source filesystem path, or catalog array position as identity. Those values may exist only as explicitly documented metadata.
