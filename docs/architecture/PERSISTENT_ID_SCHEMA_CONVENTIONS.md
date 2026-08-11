# Persistent ID and Schema-Version Conventions

## Purpose
Define the identity and version contracts used by every persisted PlayWorld Studio structure before runtime persistence code is implemented.

## Stable IDs

### Format
- Persistent IDs are RFC 4122/9562-compatible UUID strings in lowercase canonical text form: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`.
- New authored records use UUID v4 initially. A later deterministic-ID strategy may be added only where a documented use case requires it.
- IDs are opaque. Code must not derive type, hierarchy, source path, or ownership from an ID's text.
- Nil/zero UUIDs are invalid for persisted authored objects.

### Identity scope
The following receive stable IDs when persisted:
- projects;
- world entities;
- world cells;
- asset registry records;
- component definitions and component instances;
- archetypes;
- prefabs and prefab instances where independently addressable;
- visual graphs and reusable graph functions/macros;
- procedural sets/generators;
- terrain cells/resources where independently persisted;
- transactions/checkpoints when retained in history;
- future network/collaboration identities that reference authored records.

### Reference rules
- Persistent references store another record's stable ID, never a scene-tree path, node name, array index, or absolute filesystem path.
- Filesystem paths may be persisted as source metadata, but never serve as record identity.
- A missing referenced ID is an explicit validation error or unresolved-reference state; loaders must not silently bind to a similarly named object.
- Parent/child and cross-cell relationships use stable IDs.
- Runtime scene nodes may cache resolved object references, but the persisted representation remains ID-based.

### ID lifecycle
- An object's ID is created once and remains stable across save/load, rename, reparent, transform, file relocation, and ordinary edits.
- Duplicating an authored object creates new IDs for every newly independent persisted record unless the operation intentionally creates a reference/instance to the same underlying definition.
- Import rescans preserve an asset record ID when the same catalog entry can be confidently reconciled; source hash/path changes are metadata changes, not automatic identity changes.
- Deleted IDs are not immediately recycled.

## Schema versions

### Field
Every custom persistent document or independently versioned persisted record contains:

```json
"schema_version": 1
```

Use a positive integer. Version `0`, missing versions, strings, and floating-point versions are invalid unless a legacy migration explicitly handles them.

### Increment rules
Increment `schema_version` when a stored representation changes in a way that requires loader logic or migration, including:
- renamed/removed required fields;
- changed field meaning or units;
- changed reference representation;
- incompatible structural changes;
- changed defaults that must be materialized for old documents.

Do not increment for purely additive optional metadata when old readers/loaders remain valid and no migration is required.

### Migration policy
- Loaders identify the document/record type and schema version before interpreting version-specific fields.
- Migrations are forward-only and applied sequentially (`1 -> 2 -> 3`), not by a collection of ad-hoc conditionals spread through feature code.
- Unsupported future schema versions fail safely with an actionable message.
- Destructive migrations create or preserve a recoverable backup/checkpoint before replacing authored data.
- Migration code must be deterministic and covered by tests once the persistence/test harness exists.
- Caches do not require migration if they can be safely deleted and rebuilt from canonical data.

## Document type and ownership
Custom persisted JSON documents should include a stable type discriminator where the file context alone is insufficient:

```json
"document_type": "world_project"
```

Each persisted type must document:
- ID field name and owner;
- `schema_version` owner;
- write authority/module;
- references to other records;
- editor-only vs runtime-required data;
- migration responsibility.

## Editor/runtime boundaries
- Editor-only metadata should be separable from data required by exported games.
- Runtime-required IDs remain available in exported content when gameplay or save-state references need them.
- Editor conveniences such as selection state, panel layout, thumbnail cache keys, and diagnostics must not become gameplay dependencies.

## Initial field naming
Use these names unless a specific schema documents a reason to differ:
- `schema_version` — positive integer schema version.
- `document_type` — lowercase snake_case type discriminator.
- `project_id` — root world/project UUID.
- `id` — stable UUID for an independently stored record.
- `<type>_id` — foreign/reference UUID, such as `parent_entity_id`, `prefab_id`, or `cell_id`.

Optional references use JSON `null` rather than empty strings.

## Validation expectations
Before persistence code accepts authored data, it must eventually validate:
- recognized document type;
- supported positive schema version;
- syntactically valid non-nil UUIDs;
- required IDs unique within their owning registry/scope;
- foreign IDs either resolve or are represented as an intentional unresolved reference;
- no persistent relationship depends on a scene-tree path.
