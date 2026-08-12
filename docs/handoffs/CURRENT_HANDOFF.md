# POLYFORK PROJECT — PHASE 9 COMPLETION HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authoritative branch

The real project lives on:

`master`

Authoritative `master` before the Phase 9 merge:

`6ea437f3d5ea1077773ef797e8f5895e84b5a7f1`

This is the verified signed merge commit for PR #13 — Phase 8 — Visual Scripting.

The repository default branch `main` remains obsolete starter code.

**Never develop from `main`.**

## Current milestone status

Phases 0 through 8 are merged on authoritative `master`.

Phase 9 — Foliage / Procedural / Splines — is implementation-complete and verified on:

`dev/phase9-foliage-procedural-splines-milestone`

All internal checkpoints P09-T01 through P09-T08 are complete.

Verified implementation/rendered candidate before documentation-only closeout:

`f3113343ba6c2677639044285f050dd7bab56587`

The remaining Phase 9 milestone action is to verify this documentation closeout and open one completion PR targeting authoritative `master`. Do not merge that PR without explicit user authorization.

## Branch integrity before documentation closeout

- authoritative `master`: `6ea437f3d5ea1077773ef797e8f5895e84b5a7f1`
- merge base: `6ea437f3d5ea1077773ef797e8f5895e84b5a7f1`
- Phase 9 branch: ahead only
- behind `master`: 0 commits
- obsolete `main`: not used

## Verified implementation candidate

### Phase 9 Contracts

Run `31575327522` — **SUCCESS**

Passing suites:

- foundation
- foliage
- splines
- sources
- scale
- workspace

All dedicated Phase 9 suites use Godot `4.7.1.stable.official.a13da4feb` and reject raw `SCRIPT ERROR:` / engine `ERROR:` output.

### Godot Smoke

Run `31575327471` — **SUCCESS**

Head:

`f3113343ba6c2677639044285f050dd7bab56587`

### Phase 9 Visual Evidence

Run `31575327501` — **SUCCESS**

Artifact:

- ID `9132929723`
- digest `sha256:3a0a68ac693f8b3fdf38b5d05233f7e92e9cc082bf2156566b999f63f9b00fcb`
- `01-foliage-scatter.png`
- `02-road-fence.png`

Both final captures were manually inspected in addition to the automated rendered PASS gate.

### Representative scale result

Run `31575327522`, job `94046036272`:

`25 terrain focus transitions, peak 2142 foliage instances, streamed road/fence regeneration in 2792 ms`

CI regression budget:

`12000 ms`

This is a regression proxy, not an FPS claim.

## Phase 9 delivered

### Project-managed procedural persistence

- schema-v1 `procedural_registry`
- crash-safe `procedural/procedural.json`
- stable foliage-set IDs
- stable scatter-layer IDs
- stable paint/erase stroke IDs
- stable spline IDs
- stable spline-point IDs
- mirrored WorldProject procedural registries
- corrupt, future-schema, duplicate, cross-project, and invalid-reference failure paths

### Foliage source resolution

- built-in zero-asset grass/shrub/tree/post sources
- readable built-in materials and ground offsets
- real Phase 4 Asset Library scene mesh resolution through stable asset IDs
- real Phase 6 inherited-prefab resolution through stable prefab IDs
- external source folders remain read-only
- missing/invalid asset and prefab sources fail closed

### Nondestructive scatter

- command-backed foliage-set creation
- command-backed scatter-layer creation/configuration
- stable terrain-cell-owned paint and erase strokes
- deterministic seed/density/spacing generation
- biome filtering
- height filtering
- slope filtering
- scale/yaw variation
- terrain-normal alignment
- nondestructive erase masks
- per-cell instance caps
- exact deterministic regeneration
- universal Undo/Redo and project dirty/autosave integration

### Real MultiMesh runtime

- real `MultiMeshInstance3D` foliage batches
- default batch granularity: scatter layer × active terrain cell
- loaded-cell generation
- unloaded-cell cleanup
- disposable derived runtime state rather than authored entity spam

### Terrain/streaming coupling

- stable Phase 5 terrain cells own procedural scatter work
- live terrain height/normal sampling
- Phase 5 streaming drives procedural active cells
- terrain runtime emits `cell_refreshed`
- procedural foliage/splines regenerate automatically after terrain refresh

### Spline authoring

- road/path/fence source records
- stable control points
- command-backed create/delete/add/move/delete-point/configure
- open/closed path data
- width
- sample spacing
- terrain-conformance toggle
- minimum two-point invariant

### Road/path/fence runtime

- road/path real `ArrayMesh` ribbon triangles
- terrain conformance
- active-cell filtering
- fence repeated segment source resolution
- fence real `MultiMeshInstance3D`
- streamed appearance/unloading based on active terrain cells

### Procedural workspace

- existing Foliage dock entry opens foliage mode
- existing Roads dock entry opens Roads & Splines mode
- shared contextual bottom-wide Procedural panel
- terrain-conforming world cursor
- foliage/scatter selectors
- New Grass / New Scatter
- Paint / Erase
- radius / density controls
- New Road / New Path / New Fence / Add Point
- viewport-click authoring
- arrows / D-pad cursor movement
- Enter / gamepad A apply
- gamepad X Paint/Erase toggle
- Back/Cancel behavior
- contextual-tool exclusivity with Terrain/Gameplay/Logic

### QA / scale / visuals

- save/reopen
- Undo/Redo
- corruption/future-schema
- missing stable references
- real external Asset Library source
- inherited prefab source
- terrain-refresh regeneration
- large-world streaming
- representative procedural scale workload
- real Main-scene gamepad workspace paths
- strict raw-log rejection
- inherited Godot smoke
- rendered foliage/road/fence evidence with manual inspection

## Documentation closeout

Updated/added for actual Phase 9 implementation:

- `docs/implementation/TASK_BACKLOG.md`
- `docs/implementation/MASTER_IMPLEMENTATION_PLAN.md`
- `docs/systems/PROCEDURAL_FOLIAGE_SPLINES.md`
- `docs/qa/PHASE9_QA.md`
- this handoff

## Next action

1. verify the documentation-only closeout head remains green on Phase 9 Contracts, Godot Smoke, and Phase 9 Visual Evidence;
2. confirm the branch remains 0 behind authoritative `master` with merge base `6ea437f3d5ea1077773ef797e8f5895e84b5a7f1`;
3. open exactly one draft Phase 9 completion PR from `dev/phase9-foliage-procedural-splines-milestone` to authoritative `master`;
4. record the actual PR number in this handoff;
5. require all PR-triggered/inherited checks to pass on the final PR head;
6. merge only after explicit user authorization.

After the Phase 9 completion PR is explicitly merged, verify the resulting authoritative `master` SHA before creating a Phase 10 milestone branch.

**Do not begin Phase 10 before the Phase 9 completion PR is explicitly merged.**
