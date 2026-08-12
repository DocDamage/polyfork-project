# POLYFORK PROJECT — PHASE 9 ACTIVE HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authoritative branch

The real project lives on:

`master`

Authoritative `master` after the Phase 8 merge:

`6ea437f3d5ea1077773ef797e8f5895e84b5a7f1`

This is the verified signed merge commit for PR #13 — Phase 8 — Visual Scripting.

The repository default branch `main` remains obsolete starter code.

**Never develop from `main`.**

## Active milestone

Phase 9 — Foliage / Procedural / Splines

Branch:

`dev/phase9-foliage-procedural-splines-milestone`

The branch was created from exactly:

`6ea437f3d5ea1077773ef797e8f5895e84b5a7f1`

Work P09-T01 through P09-T08 continuously. Intermediate commits and CI runs are allowed. Do not open task-by-task pull requests. Open exactly one Phase 9 completion PR targeting authoritative `master` when the milestone is complete and verified.

Do not merge that completion PR without explicit user authorization.

## Phase 9 implementation checkpoints

- P09-T01 — schema-v1 procedural registry, stable foliage/scatter/stroke/spline identities, crash-safe project persistence, project registry synchronization, corruption/future-schema failure paths.
- P09-T02 — reusable foliage-set source resolution for built-in primitives, Asset Library assets, and Phase 6 prefabs; real Godot `MultiMeshInstance3D` runtime batches.
- P09-T03 — command-backed scatter layers with deterministic paint/erase strokes, universal Undo/Redo, stable terrain-cell ownership, seed/density/spacing configuration.
- P09-T04 — nondestructive deterministic regeneration with terrain height, biome, slope, height, density, erase-mask, streaming, and terrain-refresh coupling.
- P09-T05 — command-backed stable-ID spline authoring for road/path/fence paths, point editing, closed/open paths, width and sampling configuration.
- P09-T06 — deterministic road/path ribbon geometry and fence segment generation, terrain conformance, stable cell-aware runtime loading/unloading.
- P09-T07 — compact native Procedural workspace integrated into the existing app shell with foliage/scatter/spline controls, keyboard/mouse, gamepad, status, and Back/Cancel behavior.
- P09-T08 — persistence/reopen, Undo/Redo, corruption/failure, asset/prefab missing-reference, streaming, terrain interaction, representative scale/performance, strict raw-log, inherited regression, gamepad, and rendered visual verification.

## Architecture rules

- Authored procedural data is the source of truth; generated foliage/spline runtime objects are disposable derived state.
- Paint/erase is nondestructive: persist strokes/masks and regenerate deterministically rather than serializing thousands of generated world entities.
- Stable terrain cell IDs own generated scatter work and streaming boundaries.
- External Phase 4 asset source folders remain read-only.
- Asset Library and prefab references use stable IDs, never file-system path identity.
- Procedural authoring uses the existing universal command history and project dirty/autosave path.
- MultiMesh batches are the default foliage runtime representation.
- Splines are project-managed data, not hidden scene-node-only state.
- Build remains authoritative. Play may consume procedural runtime data but must not mutate authored procedural state.
- Preserve the existing dark playful Nintendo-forward / Apple-clean workspace and gamepad-first usability.

## Merge rule

Do not begin Phase 10 until the single Phase 9 completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.
