# Asset Library Behavior

The release creator uses the universal user-scoped Asset Library introduced and completed before Phase 17.

- Registered source folders remain external and read-only from the library's perspective.
- Source registration and catalog metadata persist outside the application install directory.
- The same shared catalog can be used by multiple projects.
- Supported scanning includes GLTF, GLB, and Godot scene formats.
- GLTF/GLB records use real document inspection rather than filename-only metadata.
- Missing or unreadable sources surface as failures/warnings instead of fake successful scans.
- Game export resolves referenced Asset Library records into deterministic staged dependencies and fails if required source material is unavailable.

Relocating or reinstalling PlayWorld Studio must not relocate or delete the user's external source folders.
