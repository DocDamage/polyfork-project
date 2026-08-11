# Core Data Model

## AssetRecord
Fields include: id, source_path, canonical_path, hash, type, display_name, source_pack, author, license, source_url, commercial_use, attribution_required, tags, categories, dimensions, thumbnail, material_summary, texture_summary, animation_summary, skeleton_summary, collision_summary, lod_summary, estimated_memory, import_status, warnings.

## WorldEntity
Stable ID, transform, asset/prefab reference, component list, archetype reference, owning world cell, visibility flags, editor flags, tags, parent entity ID, socket attachment data.

## ComponentDefinition
ID, display name, category, properties schema, runtime script/class, dependencies, incompatible components, exposed events/actions, serialization version.

## Archetype
ID, base archetype, required/default components, property defaults, tags, icon, validation rules.

## Prefab
ID, base prefab optional, root entity snapshot, child entities, component overrides, socket definitions, exposed parameters, inheritance overrides, thumbnail.

## VisualGraph
ID, owner scope, variables, nodes, edges, entry events, macros/functions, validation state, runtime compile/cache metadata.

## ProceduralSet
ID, generator type, seed, bounds, rule set, source asset queries, generated entity ownership, regeneration policy.

## WorldProject
Project ID, title, template, world profile, cell layout, environment, registries, save version, editor settings, export settings, dependency list.
