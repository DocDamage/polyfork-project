# File Formats and Versioning

## Rules
- Every custom persistent document contains `schema_version`.
- Changes requiring migration increment the version.
- Loaders migrate forward and preserve backups before destructive migration.
- Stable IDs are UUIDs, never path-derived identities.
- Human-reviewable formats are preferred for authoring metadata.

## Suggested custom files
Use JSON or Godot Resources initially for asset registry metadata, project manifests, archetypes, component schemas, procedural definitions, and visual graphs. Binary caches may be generated but must be rebuildable.

## Cache rule
If deleting the cache breaks the user's authored project, the data was not a cache and belongs in persistent project storage.
