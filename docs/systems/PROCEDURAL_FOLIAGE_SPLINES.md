# Procedural Foliage and Splines

## Scope

Phase 9 adds project-managed nondestructive procedural authoring for:

- foliage sets;
- deterministic scatter layers;
- paint and erase strokes;
- road splines;
- path splines;
- fence splines;
- streamed derived runtime geometry.

The authored procedural registry is the source of truth. Generated foliage instances, road/path meshes, and fence segment batches are derived runtime state and are never serialized as thousands of authored world entities.

## Persistence contract

Project-local storage:

`procedural/procedural.json`

Current document contract:

- `document_type`: `procedural_registry`
- `schema_version`: `1`
- `project_id`
- `foliage_sets`
- `scatter_layers`
- `splines`

Stable UUID identity is required for:

- foliage sets;
- scatter layers;
- paint/erase strokes;
- splines;
- spline control points.

The active `WorldProject.registries` mirrors:

- `procedural_foliage_set_ids`
- `procedural_scatter_layer_ids`
- `procedural_spline_ids`

Duplicate IDs, malformed records, future schema versions, cross-project registries, and invalid references fail closed.

Persistence uses the existing crash-safe JSON writer. Command execution rolls authored state back if persistence or derived-runtime refresh fails.

## Foliage source model

A foliage set references one source descriptor.

Supported source kinds:

### Built-in primitive

`{"kind":"primitive","primitive":"grass|shrub|tree|post"}`

Built-ins exist so a new project can use procedural tools without importing assets first. They use lightweight native meshes and readable default materials.

### Asset Library asset

`{"kind":"asset","source_id":"<stable asset UUID>"}`

Resolution uses the existing Phase 4 Asset Library. The external source folder remains read-only. A managed scene is instantiated through the Asset Library and the first usable `MeshInstance3D` mesh becomes the procedural batch source.

The file-system path is not identity.

### Phase 6 prefab

`{"kind":"prefab","source_id":"<stable prefab UUID>"}`

The existing Phase 6 prefab resolver computes the effective inherited prefab. The first asset-backed visual node supplies the mesh through the Asset Library.

Missing assets, missing prefabs, prefabs without an asset-backed visual node, or assets without a usable mesh fail closed.

## Foliage-set settings

Phase 9 foliage sets support:

- display name;
- source descriptor;
- scale range;
- random Y rotation;
- optional surface-normal alignment;
- shadow toggle;
- maximum instances per terrain cell.

Built-in primitives use a known ground offset so their center-origin meshes sit on the sampled terrain instead of half below it.

## Scatter layers

Each scatter layer references one stable foliage-set ID and stores:

- enabled state;
- deterministic integer seed;
- density per 100 m²;
- minimum spacing;
- slope range;
- height range;
- optional stable biome-ID filter;
- ordered paint/erase strokes.

A stroke stores:

- stable stroke ID;
- `paint` or `erase` operation;
- stable owning terrain-cell ID;
- brush center;
- radius;
- strength.

Paint/erase is nondestructive. Erase strokes mask generated results; they do not delete the authored paint source data.

## Deterministic scatter generation

Runtime scatter generation operates per scatter layer × active terrain cell.

For each applicable paint stroke the generator:

1. derives a stable random sequence from the layer seed, stable stroke ID, and stable cell ID;
2. computes the requested sample count from brush area, layer density, and stroke strength;
3. generates deterministic radial candidates;
4. rejects candidates outside the owning terrain cell;
5. samples current Phase 5 terrain height;
6. applies configured height limits;
7. applies erase masks;
8. enforces minimum spacing;
9. samples an approximate terrain normal and slope;
10. applies configured slope limits;
11. applies deterministic scale/yaw variation;
12. optionally aligns the instance basis to the terrain normal;
13. stops at the foliage-set per-cell instance cap.

Same authored data + same terrain state + same seed produces the same transform list.

## MultiMesh runtime representation

Generated foliage uses real Godot `MultiMeshInstance3D` nodes.

Default batching granularity:

**one MultiMesh batch per scatter layer × active terrain cell**

This avoids creating one authored/runtime node per foliage blade/tree and makes Phase 5 terrain-cell streaming the natural ownership boundary.

When terrain cells unload, their procedural foliage batches unload. When terrain cells load, matching batches regenerate from saved source data.

## Terrain and biome coupling

Procedural scatter uses the existing Phase 5 terrain system for:

- stable cell lookup;
- current height sampling;
- approximate surface normal/slope;
- biome assignment;
- loaded-cell streaming state.

`PlayWorldTerrainRuntime.refresh_cell()` emits `cell_refreshed(cell_id)` after a successful terrain refresh. Phase 9 listens for that signal and regenerates derived foliage and spline geometry for affected active terrain.

A terrain edit therefore changes generated content without rewriting procedural source records.

## Spline authoring model

Supported spline kinds:

- `road`
- `path`
- `fence`

Each spline stores:

- stable spline ID;
- display name;
- kind;
- open/closed state;
- width;
- sample spacing;
- terrain-conformance toggle;
- ordered stable control points.

Fence splines also store a segment source descriptor using the same primitive/asset/prefab source model as foliage.

Command-backed operations include:

- create spline;
- delete spline;
- add point;
- move point;
- delete point;
- configure supported spline properties.

A spline may never be reduced below two control points.

## Road and path runtime geometry

Phase 9 samples the authored control-point polyline at the configured spacing and optionally conforms each sample to current terrain height.

Roads and paths derive a real `ArrayMesh` ribbon:

- segment direction is flattened to X/Z;
- ribbon width is derived from spline width;
- two triangles form each active segment quad;
- a small vertical lift reduces terrain z-fighting;
- only segments whose midpoint belongs to an active terrain cell are emitted.

Road and path runtime meshes are disposable and regenerated from source spline data.

## Fence runtime geometry

Fence splines:

- sample the same terrain-conforming path;
- resolve the configured segment mesh through the procedural source resolver;
- orient repeated segments along the sampled tangent;
- generate the repeated segments in a real `MultiMeshInstance3D`;
- include only samples belonging to active terrain cells.

## Streaming behavior

Procedural runtime follows the exact loaded terrain-cell set from Phase 5.

On a terrain streaming update:

- stale foliage batches are removed;
- newly active cell foliage regenerates;
- road/path/fence derived geometry regenerates against the active-cell set;
- spline geometry disappears when no active terrain cell intersects it and reappears when relevant cells stream back in.

The persisted spline/scatter data never changes because of streaming.

## Universal Undo / Redo

Phase 9 procedural edits use snapshot commands on the existing universal command history.

Execution and Undo/Redo all use the same sequence:

1. validate the staged procedural document;
2. replace authored procedural state;
3. persist crash-safely;
4. synchronize project registries;
5. regenerate derived runtime state;
6. report failure and restore the previous snapshot if persistence/runtime refresh fails;
7. signal project dirty state through the existing autosave path.

This keeps procedural authoring compatible with world placement, gameplay composition, and visual scripting history semantics.

## Procedural workspace

Phase 9 uses the existing bottom dock rather than adding a parallel editor shell.

Existing entries:

- `Foliage`
- `Roads`

Both open the same contextual Procedural workspace in different sections.

### Foliage section

Controls include:

- foliage-set selection;
- create built-in grass set;
- scatter-layer selection;
- create scatter layer;
- Paint / Erase;
- brush radius;
- density.

### Roads & Splines section

Controls include:

- spline selection;
- New Road;
- New Path;
- New Fence;
- Add Point.

### World interaction

The Procedural workspace owns a terrain-conforming translucent world cursor.

Keyboard/gamepad paths:

- arrows / D-pad: move cursor;
- Enter / gamepad A: apply current action;
- gamepad X: toggle Paint/Erase in foliage mode;
- `[` / `]`: brush radius adjustment;
- terrain viewport click: move cursor to hit and apply.

Two-point spline creation is armed by New Road/New Path/New Fence, then two A/Enter/click placements create the initial spline.

Back/Cancel first cancels pending spline creation, then closes the Procedural tool. Switching to another contextual tool closes Procedural.

## Build / Play authority

Procedural source data is authored in Build mode and remains authoritative.

The Phase 9 editor runtime can display derived foliage/splines in Build. Streaming or terrain regeneration may rebuild derived nodes, but these nodes are not authored world records.

Phase 9 does not introduce a Play-time authoring path and does not permit Play to mutate saved procedural state.

## Failure semantics

Phase 9 fails closed for:

- unsupported/future procedural schema;
- malformed or duplicate stable IDs;
- missing foliage-set references;
- invalid biome IDs in configured filters;
- missing Asset Library asset IDs;
- missing prefab IDs;
- prefabs without usable visual assets;
- source scenes without a usable mesh;
- invalid spline kinds/data;
- invalid fence segment sources;
- persistence failure;
- derived-runtime regeneration failure.

## Deliberate Phase 9 limits

Phase 9 establishes the production foundation; it does **not** claim the following are complete:

- Bezier/handle-based curve editing;
- lane graphs or traffic simulation from roads;
- road intersections/junction generation;
- navmesh baking from procedural roads/paths;
- spline mesh profiles, banking, curbs, shoulders, or bridges;
- GPU compute scatter or hierarchical foliage LOD;
- procedural collision generation for every foliage instance;
- wind animation or environment simulation;
- arbitrary material/mesh authoring UI for imported sources.

Those features can build on the stable source/runtime contracts introduced here without changing identity or persistence fundamentals.
