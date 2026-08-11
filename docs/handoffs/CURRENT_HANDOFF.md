# Current Handoff

## Status
OPEN — Phase 4 Universal Asset Library implementation is complete and verified on its milestone branch. The single Phase 4 completion PR must be reviewed and merged before Phase 5 begins.

## Authoritative branch state
Repository: `DocDamage/polyfork-project`

Authoritative project branch: `master`

Phase 4 started from authoritative `master` commit:
`e5c80c82a4a18ad0225111d15720347c5614612a`

The repository default branch `main` remains obsolete starter code. Never develop from `main`.

Phase 4 milestone branch:
`dev/phase4-universal-asset-library-milestone`

## Milestone workflow policy
The project uses milestone-based review gates rather than one PR per internal task.

- Task IDs are implementation checkpoints.
- Commit and run CI throughout a milestone.
- Do not stop at individual task boundaries.
- Open one PR only when the whole authorized milestone is complete and verified.
- Never merge without explicit user authorization.

## Completed milestone
**Phase 4 — Universal Asset Library**

Completed internal tasks:
- P04-T01 read-only source-folder registry and source contracts
- P04-T02 incremental scanner, hashing, and stable asset-ID reconciliation
- P04-T03 GLB/GLTF and Godot scene analysis/import support
- P04-T04 asset metadata, licensing, and catalog persistence contracts
- P04-T05 thumbnail generation, cache invalidation, and failure handling
- P04-T06 large-card asset browser, search, filters, and favorites
- P04-T07 collections, duplicate detection, source/license details, and placement handoff
- P04-T08 integration, scale, gamepad, failure-path, raw-log, and rendered visual verification

## Asset Library architecture delivered
Per-project managed storage lives under:
`<project-directory>/asset_library`

Canonical managed files:
- `sources.json` — versioned read-only source-folder registry
- `catalog.json` — versioned stable asset catalog/metadata

Rebuildable managed data:
- `imports/` — derived copies used for runtime loading
- `thumbnails/` — content-addressed thumbnail cache

External registered source folders are input-only. Scanner, metadata, imports, thumbnails, caches, reconciliation, duplicate detection, and placement never intentionally write into them.

## Stable identity and incremental scanning
Supported discovery types are GLTF, GLB, Godot `.tscn`, and Godot `.scn`.

Scanning is deterministic and sorted. Unchanged same-path files reuse prior SHA-256 results when size and modification metadata also match. Same-path assets keep their `asset_id`. A move inside the same source retains its prior ID only when exactly one unmatched content-signature candidate proves the relationship. Duplicate source files remain separate catalog records and are never silently merged or deleted.

Missing source records remain in the catalog with `missing: true`, preserving stable world references without retargeting another asset.

## Analysis/import and failure behavior
- GLTF 2.x JSON receives structural preflight.
- GLB receives binary header/version/length preflight.
- Godot text scenes receive scene/node structural preflight.
- Godot binary scenes receive resource-header preflight.
- Corrupt supported inputs remain failed-analysis catalog records and are blocked before placement.
- Unsupported extensions are ignored rather than fabricated into supported assets.
- GLTF local dependencies are copied to managed imports; remote dependencies and source-root escapes fail safely.

## Catalog/browser delivered
Catalog persistence includes favorites, collections, licensing/source fields, user metadata, analysis state, derived-import metadata, and thumbnail metadata.

The existing Asset drawer now provides:
- large cards by default;
- compact density option;
- search;
- source/type/collection filters;
- favorites and duplicate filters;
- read-only source and license details;
- collection assignment;
- rescan and source-folder registration;
- native keyboard/mouse/gamepad card activation;
- keyboard `F` / gamepad `Y` favorite shortcut.

The UI remains inside the existing dark, playful Nintendo-forward / Apple-clean workspace rather than becoming an enterprise dashboard.

## Phase 3 placement integration
Catalog selection enters `asset_placement_handoff.gd`, which validates the stable asset ID and managed scene import before starting the existing Phase 3 ghost.

Preview carries `WorldEntity.asset_id` but does not create an entity or mark project state dirty. Commit remains the existing `PlaceEntityCommand` path. Runtime bridge rebuild resolves asset-backed entities to real managed scene visuals. Duplicate preserves `asset_id` with a new entity UUID. Save/reopen retains the reference. Missing source content falls back to a safe generic proxy instead of invalidating authored entities.

No prefab/component system was fabricated for Phase 4.

## Verification evidence
Behavioral coverage includes:
- 131 supported source fixtures in the scale/incremental scan test;
- first scan hashes all supported fixtures;
- unchanged rescan reuses all 131 hashes and hashes zero unchanged files;
- source-folder before/after SHA snapshots proving scanner/catalog/import/thumbnail workflows leave source files unchanged;
- stable ID across a uniquely proven in-source move;
- independent IDs plus reporting for duplicate content;
- catalog/license/favorite/collection persistence across restart;
- thumbnail generation and content-change invalidation;
- managed imports only under project storage;
- valid GLTF, GLB, Godot text scene, and Godot binary scene coverage;
- corrupt GLTF/Godot scene rejection and unsupported-extension ignore behavior;
- real asset ghost → command-backed placement → runtime visual → duplicate → save/reopen;
- missing-source proxy fallback;
- search/filter/favorites/collections/duplicates/density browser behavior;
- keyboard and gamepad browser controls;
- existing Phase 0–3 tests retained.

Godot Actions run `31537427941` used `4.7.1.stable.official.a13da4feb` and passed:
- `runtime-smoke` — SUCCESS
- `phase1-visual-capture` — SUCCESS
- `phase4-visual-capture` — SUCCESS

The raw runtime log contains `PASS: PlayWorld Studio test harness completed.` and passed the workflow's strict rejection of `SCRIPT ERROR:` and engine `ERROR:` output.

The raw Phase 4 visual log contains `PASS: Phase 4 rendered screenshots captured.` and passed the same strict script/engine error gate. Rendered evidence artifact `phase4-visual-evidence` contains:
- `00-canonical-reference.png`
- `01-asset-library-large.png`
- `02-asset-library-compact.png`

Visual inspection confirmed the Asset Library remains integrated into the canonical dark/playful workspace. A compact-density horizontal overflow exposed by that inspection was corrected before milestone closeout.

## Scope boundary
Phase 5 has not started. Terrain/streaming work is not authorized until the Phase 4 completion PR is merged into authoritative `master`.

## Next action
Open one Phase 4 completion PR targeting `master`. Do not merge it without explicit user authorization. After it is merged, verify the new authoritative `master` commit and create the next handoff before beginning Phase 5.
