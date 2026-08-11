# File Formats and Versioning

## Canonical contract
Persistent identity and schema rules are defined in `docs/architecture/PERSISTENT_ID_SCHEMA_CONVENTIONS.md`. This file defines format-level policy and must remain consistent with that contract.

## General rules
- Every custom persistent document contains a positive integer `schema_version`.
- Use `document_type` when file context alone is not sufficient to identify the record type safely.
- Changes requiring loader transformation increment the schema version.
- Loaders migrate forward sequentially and preserve a recoverable backup/checkpoint before destructive migration.
- Unsupported future versions fail safely rather than being interpreted as current data.
- Stable IDs are lowercase canonical UUID strings and are never path-derived identities.
- Persistent references use stable IDs, not scene-tree paths, node names, array positions, or filesystem locations.
- Human-reviewable formats are preferred for canonical authoring metadata.

## Phase 4 Asset Library layout
Each world project's stable project directory owns a managed `asset_library/` directory.

Canonical editor metadata:
- `asset_library/sources.json`
  - `document_type: "asset_source_registry"`
  - schema version 1
  - registered external source folders and stable `source_id` values
- `asset_library/catalog.json`
  - `document_type: "asset_catalog"`
  - schema version 1
  - stable asset records, licensing metadata, favorites, collections, analysis/derived/thumbnail metadata

Rebuildable managed data:
- `asset_library/imports/<asset-id>/<hash-prefix>/...`
  - project-managed copies used for runtime import/instantiation
  - GLTF local dependencies are copied here when valid
- `asset_library/thumbnails/<asset-id>-<hash-prefix>.png`
  - generated thumbnail cache
  - stale same-asset entries are invalidated when source content changes

## External source-folder rule
Registered source roots are strictly read-only inputs. No registry, catalog, imported copy, generated thumbnail, cache, metadata file, rename, deletion, or reorganization may be written into a source root.

A source filesystem path is location metadata only. `source_id` identifies a registration and `asset_id` identifies a catalog asset. Reconciliation may retain an asset ID across a move only when identity can be proven deterministically. Duplicate content never authorizes source-file deletion or destructive merging.

## Supported Phase 4 source formats
- `.gltf` — JSON GLTF 2.x structural preflight; local dependencies copied to managed import storage; remote dependency URIs and source-root escapes fail safely.
- `.glb` — binary GLB 2 structural preflight before Godot runtime import.
- `.tscn` — Godot text scene structural preflight before managed copy/load.
- `.scn` — Godot binary scene header preflight before managed copy/load.

Corrupt supported files remain representable as catalog records with failed analysis state. They cannot proceed into runtime placement. Unsupported file extensions are ignored rather than fabricated into an asset type.

## Cache rule
If deleting a cache breaks the user's authored project, the data was not a cache and belongs in persistent storage. Deleting Phase 4 thumbnail/import caches may require regeneration but must not change stable catalog identity or authored world entity references.

## Migration rule
Migration implementation belongs in dedicated persistence/migration code rather than feature UI scripts. Migration functions should be deterministic and independently testable.
