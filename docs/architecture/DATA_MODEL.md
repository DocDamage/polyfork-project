# Core Data Model

All persisted records follow the stable-ID/schema conventions in `PERSISTENT_ID_SCHEMA_CONVENTIONS.md`. Filesystem paths, scene-tree paths, runtime node names/pointers, and array positions are never persistent identity.

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
- `component_instance_ids[]`
- transform

Placement/movement across a terrain boundary updates transform and owning cell atomically. Streaming never rewrites stable entity/parent/cell identity merely because a referenced runtime node is unloaded.

Generic duplication clears copied component-instance IDs so a new world entity never aliases another entity's gameplay-owned component records.

## TerrainManifest / TerrainCell / BiomeRegistry
Ownership: `src/terrain`.

Phase 5 remains unchanged:
- `terrain_manifest` stores stable profile topology, cell IDs/coordinates, cell size/resolution, and streaming policy.
- `terrain_cell` stores stable project/cell/biome IDs, height samples, revision, and save timestamp.
- `biome_registry` stores stable data-driven biome records and terrain material hooks.

Runtime terrain mesh/collision is rebuildable presentation, not persistent identity.

## ComponentDefinition
Ownership: `src/gameplay/gameplay_contracts.gd` + `builtin_component_library.gd`.

Schema-v1 fields include:
- `document_type: "component_definition"`
- `schema_version`
- `definition_id` — stable UUID
- unique `key`
- `display_name`
- editor `category`
- `properties` dictionary
- stable `dependencies[]`
- stable `conflicts[]`
- `runtime_hook` metadata string

Each property spec declares a supported type (`bool`, `int`, `float`, `string`, `enum`, or `vector3`), default, and optional constraints such as min/max or enum options.

The initial Phase 6 library contains the required 21 definitions:
TransformMetadata, Collision, Interactable, Health, Damageable, PhysicsProp, InventoryContainer, Pickup, AudioEmitter, LightSource, Door, Seat, VehicleBody, CharacterController, NPCBrain, SpawnPoint, DialogueParticipant, QuestParticipant, TriggerVolume, SaveState, NetworkIdentityStub.

## ComponentInstance
Ownership: `src/gameplay`.

Schema-v1 fields:
- `document_type: "component_instance"`
- `schema_version`
- `instance_id` — stable UUID
- `definition_id` — stable ComponentDefinition UUID
- `owner_entity_id` — stable WorldEntity UUID
- typed `values` dictionary

`WorldEntity.component_instance_ids` mirrors the instances currently authored onto that entity. Configuration preserves the instance UUID. Undo/Redo restores the same instance IDs rather than allocating replacements.

Gameplay registries may retain a dormant component instance while its world owner is temporarily absent due to delete/undo/streaming. New authoring operations still require a live valid entity target.

## ArchetypeDefinition
Ownership: `src/gameplay/builtin_archetype_library.gd`.

Schema-v1 fields:
- `document_type: "archetype_definition"`
- `schema_version`
- `archetype_id` — stable UUID
- unique `key`
- `display_name`
- `required_definition_ids[]`
- `component_defaults` keyed by component-definition UUID
- `tags[]`

Archetype application adds/configures required components through deterministic dependency resolution while retaining the existing WorldEntity UUID and unrelated authored components.

## PrefabDefinition
Ownership: `src/gameplay/prefab_authoring_service.gd` + `prefab_resolver.gd`.

Schema-v1 fields:
- `document_type: "prefab_definition"`
- `schema_version`
- `prefab_id` — stable UUID
- `display_name`
- optional stable `base_prefab_id`
- `nodes[]`
- `node_overrides` keyed by stable node UUID
- `removed_node_ids[]`
- `socket_ids[]`
- `socket_overrides`
- `removed_socket_ids[]`

Each prefab node has a stable `node_id`, optional stable `parent_node_id`, display name, optional asset ID, transform, and a component-values dictionary keyed by component-definition UUID.

A base prefab has one effective root. Derived prefabs retain their own prefab ID and authored differences. Inheritance cycles and missing bases fail safely.

## PrefabInstanceRecord
Ownership: `src/gameplay`.

Schema-v1 fields:
- `document_type: "prefab_instance_record"`
- `schema_version`
- `instance_id` — stable prefab-instance UUID
- `prefab_id`
- `root_entity_id`
- `node_entity_ids` mapping stable prefab-node IDs to fresh stable WorldEntity IDs
- explicit `overrides`

Instantiating the same prefab multiple times allocates new entity/component/socket IDs for every instance while preserving the common prefab reference.

## SocketDefinition
Ownership: `src/gameplay/socket_attachment_service.gd`.

Schema-v1 fields:
- `document_type: "socket_definition"`
- `schema_version`
- `socket_id` — stable UUID
- `owner_kind` — `entity` or `prefab_node`
- stable `owner_id`
- owner-unique `name`
- typed `category`
- optional `custom_category`
- `local_transform`

Built-in categories: Grip, Seat, Mount, DoorHandle, Light, LootSpawn, Wheel, Muzzle, Camera, InteractionPoint, plus Custom.

Prefab-node sockets are canonical prefab data. Instantiation materializes fresh entity-owned socket records so separate prefab instances never share socket identity.

## AttachmentRecord
Ownership: `src/gameplay/socket_attachment_service.gd`.

Schema-v1 fields:
- `document_type: "attachment_record"`
- `schema_version`
- `attachment_id` — stable UUID
- `parent_entity_id`
- `parent_socket_id`
- `child_entity_id`
- optional `child_socket_id`
- `offset_transform`

An entity may have only one active attachment parent. Runtime anchor nodes are derived presentation and are never persisted.

## WorldProject
Ownership: `src/world`.

The project retains stable project/profile/template metadata, world `cell_ids`, WorldEntity records, environment/settings/registry data, and timestamps.

`registries.prefab_ids` tracks project-owned prefab identity. Terrain height grids and Phase 6 gameplay registries remain project-managed sibling documents rather than inflating `project.json`.

## WorldCheckpoint
Ownership: `src/world`.

World checkpoints protect `WorldProject` state. Terrain cells keep their Phase 5 recovery records. Gameplay registries use crash-safe atomic promotion and fail closed on corrupt/future data rather than silently regenerating authored content.

## Reference rule
No persisted relationship may use scene-tree path, node name, runtime array index, source filesystem path, or streaming load order as identity. Asset, entity, component, archetype, prefab, prefab-node, prefab-instance, socket, attachment, biome, project, parent, and cell relationships use stable IDs.
