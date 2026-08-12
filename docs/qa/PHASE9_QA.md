# Phase 9 QA — Foliage / Procedural / Splines

## Verification candidate

Verified implementation/rendered candidate before documentation-only closeout:

`f3113343ba6c2677639044285f050dd7bab56587`

Authoritative base / merge base:

`6ea437f3d5ea1077773ef797e8f5895e84b5a7f1`

This is the merged Phase 8 `master` commit from PR #13.

## Dedicated Phase 9 contracts

Workflow: `Phase 9 Contracts`

Run: `31575327522`

Result: **SUCCESS**

Godot: `4.7.1.stable.official.a13da4feb`

Passing suites:

- `foundation`
- `foliage`
- `splines`
- `sources`
- `scale`
- `workspace`

The workflow rejects raw `SCRIPT ERROR:` and engine `ERROR:` output before accepting the PASS marker.

### Foundation suite

Verifies:

- schema-v1 procedural document creation;
- stable foliage/scatter/spline identities;
- crash-safe save/reopen;
- `WorldProject.registries` synchronization;
- future schema rejection;
- duplicate identity rejection;
- missing foliage-set reference rejection.

### Foliage suite

Uses real Phase 5 terrain runtime and verifies:

- command-backed built-in foliage-set creation;
- command-backed scatter-layer creation;
- stable terrain-owned paint strokes;
- real `MultiMeshInstance3D` runtime batches;
- nonzero generated instance population;
- deterministic regeneration produces exactly the same transform list;
- full-strength erase masks generated foliage without deleting the authored paint source;
- universal Undo restores the deterministic pre-erase population;
- universal Redo restores the erased result;
- project dirty-state signaling;
- all built-in primitive sources resolve;
- asset-backed source resolution without a bound Asset Library fails closed.

### Spline suite

Uses real Phase 5 terrain runtime and verifies:

- command-backed stable road spline creation;
- stable point IDs;
- road runtime is a real generated `MeshInstance3D` / `ArrayMesh` ribbon;
- command-backed point movement;
- universal Undo/Redo restores/reapplies spline point state exactly;
- path ribbon generation;
- real fence `MultiMeshInstance3D` segment generation;
- terrain height mutation + `TerrainRuntime.refresh_cell()` automatically regenerates a terrain-conforming road at the new height;
- spline point deletion cannot reduce a path below two control points.

### Sources suite

Uses an actual temporary external Godot `.tscn` source file and the real Phase 4 Asset Library:

- registers/scans the external source;
- produces a stable managed asset ID;
- resolves its real `MeshInstance3D` mesh as a procedural source;
- leaves the external source file in place;
- verifies an inherited Phase 6 prefab resolves its base prefab's asset-backed visual mesh through the real prefab resolver;
- preserves `prefab` source provenance;
- missing asset and missing prefab references fail closed.

### Scale suite

Uses the Phase 5 `large` world profile and exercises:

- authored paint data across the large partition;
- terrain focus / streaming transitions;
- MultiMesh foliage regeneration;
- streamed road and fence generation;
- exact procedural active-cell parity with terrain loaded-cell IDs;
- removal of foliage batches for unloaded cells;
- spline appearance when relevant cells are active;
- spline unloading when active cells no longer intersect derived geometry.

Final measurement on run `31575327522`, job `94046036272`:

`25 terrain focus transitions, peak 2142 foliage instances, streamed road/fence regeneration in 2792 ms`

CI regression budget:

`12000 ms`

This is a broad CI regression proxy, **not** a frame-rate or shipping-device performance claim.

### Workspace suite

Instantiates the real `Main.tscn` application shell and verifies:

- existing Foliage and Roads dock entries resolve the Phase 9 Procedural workspace;
- project service/runtime/panel binding;
- Foliage panel foliage-set/scatter creation;
- gamepad A applies scatter paint at the procedural cursor;
- generated MultiMesh population appears;
- gamepad X toggles Paint/Erase;
- gamepad A applies erase;
- real workspace universal Undo restores erased foliage;
- Roads switches the shared panel to spline mode;
- gamepad two-point road creation with D-pad + A;
- road creation generates derived spline geometry;
- switching to Terrain closes Procedural and preserves contextual-tool exclusivity;
- Back/Cancel closes Procedural before leaving the workspace.

## Baseline / inherited smoke

Workflow: `Godot Smoke`

Run: `31575327471`

Result: **SUCCESS**

Head: `f3113343ba6c2677639044285f050dd7bab56587`

This confirms the Phase 9 Main-scene/workspace integration did not break the baseline runtime smoke or inherited visual capture jobs executed by that workflow.

## Rendered visual evidence

Workflow: `Phase 9 Visual Evidence`

Run: `31575327501`

Result: **SUCCESS**

Job: `94046036099`

Artifact:

- name: `phase9-visual-evidence`
- ID: `9132929723`
- digest: `sha256:3a0a68ac693f8b3fdf38b5d05233f7e92e9cc082bf2156566b999f63f9b00fcb`

Files:

- `01-foliage-scatter.png`
- `02-road-fence.png`

The capture runs the real application under xvfb / `gl_compatibility`, creates a persisted small world, authors real foliage/scatter/road/fence source data through the Phase 9 service, verifies a representative foliage population and derived spline runtime, opens the real contextual workspace, and captures rendered frames.

### Manual visual inspection

`01-foliage-scatter.png` passes because it visibly shows:

- the real application workspace;
- the Procedural panel in Foliage mode;
- selected `Meadow Grass` and `Meadow` scatter;
- New Grass / New Scatter / Paint / Erase / Radius / Density controls;
- a visible terrain-conforming translucent brush cursor;
- bright-green painted grass MultiMesh population;
- distinct green tree clusters;
- the road in the authored scene;
- brown fence posts;
- meaningful status text describing the foliage state.

`02-road-fence.png` passes because it visibly shows:

- the same authored world with a closer spline-focused camera;
- a clearly distinguishable gray road ribbon;
- a denser, visible brown fence-post line;
- remaining foliage context;
- the active Roads & Splines panel;
- selected road entry;
- New Road / New Path / New Fence / Add Point controls;
- meaningful status text describing streamed road/fence geometry.

## Failure / regression findings fixed during Phase 9

The Phase 9 QA loop caught and corrected:

- JSON numeric normalization differences after persistence reopen;
- an initially incorrect scale assertion that required both long splines to remain visible in the final streamed cell set rather than verifying appearance/unloading over the transition sequence;
- built-in primitive center-origin placement that left foliage partly below terrain;
- weak default primitive materials that made procedural evidence visually ambiguous;
- an evidence-fixture typed-array mismatch where `create_spline(Array[Vector3])` was called with an untyped array literal;
- initial spline evidence framing where fence posts existed but were not visually strong enough.

These were fixed without weakening the functional contracts.

## Merge gate

Phase 9 is implementation-complete only after the documentation-only closeout head reruns:

- Phase 9 Contracts;
- Godot Smoke;
- Phase 9 Visual Evidence.

After those remain green, open exactly one Phase 9 completion PR to authoritative `master`.

Do not merge that PR without explicit user authorization.
