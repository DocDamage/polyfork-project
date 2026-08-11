# File Formats and Versioning

## Canonical contract
Persistent identity and schema rules are defined in `docs/architecture/PERSISTENT_ID_SCHEMA_CONVENTIONS.md`. This file defines format-level policy and must remain consistent with that contract.

## Rules
- Every custom persistent document contains a positive integer `schema_version`.
- Use `document_type` when file context alone is not sufficient to identify the record type safely.
- Changes requiring loader transformation increment the schema version.
- Loaders migrate forward sequentially and preserve a recoverable backup/checkpoint before destructive migration.
- Unsupported future versions fail safely rather than being interpreted as the current version.
- Stable IDs are lowercase canonical UUID strings and are never path-derived identities.
- Persistent references use stable IDs, not scene-tree paths, node names, array positions, or filesystem locations.
- Human-reviewable formats are preferred for canonical authoring metadata.

## Suggested custom files
Use JSON or Godot Resources initially for asset registry metadata, project manifests, archetypes, component schemas, procedural definitions, and visual graphs. Binary caches may be generated but must be rebuildable.

## Ownership
Each persistent type must define its owning module, ID field, schema-version owner, reference fields, migration responsibility, and whether each field is editor-only or runtime-required.

## Cache rule
If deleting the cache breaks the user's authored project, the data was not a cache and belongs in persistent project storage.

## Migration rule
Migration implementation belongs in dedicated persistence/migration code rather than feature scripts. Migration functions should be deterministic and testable independently once the persistence and test foundations exist.
