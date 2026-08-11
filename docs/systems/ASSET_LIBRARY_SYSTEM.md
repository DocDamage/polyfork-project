# Asset Library System

## Goal
Treat the user's large local asset collection as one searchable, non-destructive catalog.

## Source handling
- User registers one or more root folders.
- Source files remain untouched.
- Registry stores normalized paths and content hashes.
- Generated thumbnails/cache live under project/user cache directories.
- Re-scan is incremental.

## Initial priority
1. GLB/GLTF
2. Godot `.tscn` / `.scn`
3. Images/material textures
4. Audio
5. Animation resources
6. Adapter pipeline for FBX/OBJ and other formats supported by Godot/import tooling.

## Asset analysis
Collect dimensions, mesh count, vertex/triangle estimate, materials, texture dimensions, skeleton presence, animation names/durations, collision status, LOD presence, and rough memory footprint.

## Catalog UX
Large cards default, density toggle, categories, filters, favorites, collections, search, natural-language semantic search, recently used, and source-pack filters.

## Licensing
License/source metadata is never optional in the schema even if values are unknown. Unknown license status must be visible, not silently treated as unrestricted.

## Placement
Selecting an asset creates a ghost placement object. Placement confirmation creates a command/transaction. Users can choose single-place or paint/repeat mode.
