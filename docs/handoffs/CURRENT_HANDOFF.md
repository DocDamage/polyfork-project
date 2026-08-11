# Current Handoff

## Status
OPEN — Phase 3 Runtime Placement Editor milestone is complete and verified on its milestone branch; merge is required before `master` reflects Phase 3 completion.

## Project state
Phase 0, Phase 1, and Phase 2 are complete on authoritative `master`.

PR #7 merged `P03-T01 — Implement runtime entity scene bridge and single-selection foundation` into `master` at merge commit `95ec15bdc4d6a2b293511f724cfc4204e9ae485d`.

P03-T02 through P03-T09 were completed continuously from that baseline on:
`dev/phase3-runtime-placement-milestone`

The repository default branch remains obsolete `main`; do not develop from it. The authoritative project branch remains `master`.

## Milestone workflow policy
The project uses milestone-based review gates rather than one PR per internal task.

- Task IDs are implementation checkpoints.
- Commit and run CI throughout a milestone.
- Do not stop at individual task boundaries.
- Open one PR when the authorized milestone is complete and verified, unless a genuine blocker requires an earlier review decision.
- Never merge without explicit user authorization.

This policy is recorded in `docs/implementation/CODEX_EXECUTION_RULES.md`.

## Completed milestone
**Phase 3 — Runtime Placement Editor**

Completed internal tasks:
- P03-T02 command-backed object placement and ghost preview
- P03-T03 command-backed move/rotate/scale editing and transform-tool state
- P03-T04 command-backed duplicate and delete operations
- P03-T05 multi-select and grouping foundations
- P03-T06 grid and angle snapping
- P03-T07 surface/object/socket snapping and drop-to-ground
- P03-T08 contextual placement toolbar and controller tool wheel
- P03-T09 Phase 3 integration, gamepad, failure-path, and visual verification

## Runtime editor architecture delivered
- `src/editor/editor_session.gd` coordinates the bound project, command history, runtime bridge, multi-selection, ghost placement, snapping, transform state, and dirty-state callback.
- `src/editor/runtime_entity_node.gd` now provides generic visible/collidable proxy geometry until Phase 4 supplies actual asset content.
- `src/editor/editor_viewport_3d.gd` / `EditorViewport3D.tscn` provide the live 3D editor viewport, camera/lighting, ground, and physics picking.
- `src/editor/multi_selection.gd` provides stable-ID multi-selection with one primary entity.
- `src/editor/snapping_service.gd` provides deterministic grid, angle, surface, object, socket, and ground snapping.
- `src/editor/placement_ghost.gd` keeps preview placement transient until commit.
- `src/editor/transform_gizmo_state.gd` owns transform tool/axis state.

## Command-backed authoring delivered
New reversible authoring commands:
- `src/commands/place_entity_command.gd`
- `src/commands/set_entity_transforms_command.gd`
- `src/commands/duplicate_entities_command.gd`
- `src/commands/delete_entities_command.gd`
- `src/commands/group_entities_command.gd`

Successful authoring operations refresh the runtime bridge and invoke the active project's dirty-state callback. Preview-only selection/ghost operations do not dirty persisted state. Failed operations do not advance command history or intentionally persist partial edits.

Delete captures descendant closure so removing a group/parent cannot leave invalid persisted child references. Grouping creates a generic stable-ID `WorldEntity` group and uses stable `parent_entity_id` relationships.

## Snapping behavior
- Grid and angle snapping are deterministic numeric editor policies.
- Surface snapping uses hit position/normal.
- Object and socket placement automatically discover bridged runtime entities using project-local positions.
- Until later prefab/socket metadata exists, each bridged entity origin is exposed as a temporary generic socket candidate identified as `<entity_id>:origin`.
- Drop-to-ground is command-backed and undoable.

## Workspace and input
The existing workspace now includes:
- a live 3D editor viewport;
- compact contextual placement/snapping controls;
- existing transform toolbar wired to command-backed move/rotate/scale/duplicate/delete;
- multi-select/grouping;
- undo/redo controls;
- an opt-in controller-first quick tool wheel.

Keyboard/mouse and gamepad route into the same editor-session mutation path. The gamepad smoke verifies D-pad transform movement and left-shoulder tool-wheel access.

## Behavioral verification
New/expanded tests include:
- `tests/unit/snapping_contracts.gd`
- `tests/integration/phase3_editor_session_contracts.gd`
- `tests/integration/phase3_placement_snapping_contracts.gd`
- `tests/runtime/phase3_editor_smoke.gd`
- existing P03-T01 bridge/selection tests remain active
- all Phase 0–2 persistence/recovery tests remain active

Verified behavior includes:
- ghost preview does not mutate/dirty project state;
- placement commit and first-cell ownership;
- placement undo/redo;
- stable IDs across runtime bridge and save/reopen;
- move/rotate/scale command history;
- duplicate with new stable UUIDs;
- additive multi-selection;
- grouping and group undo;
- descendant-closure delete and restore;
- deterministic snapping modes;
- automatic runtime object/socket placement candidates;
- invalid action/failure atomicity;
- crash-safe Phase 2 repository save/reopen after Phase 3 edits;
- real workspace/gamepad editor flow.

## Defect evidence retained during milestone
Intermediate CI runs intentionally exposed and helped repair real defects rather than weakening tests, including:
- workspace GDScript typing and signal-wiring errors;
- redundant SubViewport sizing while stretch was enabled;
- strict Variant inference in command scripts;
- P03-T01 preview/selection regression while a real project was bound;
- typed selection-array runtime failure during placement commit;
- invalid off-tree `global_position` use in automatic snapping.

The final snapping fix changed automatic candidate coordinates to project-local `Node3D.position`, matching persisted editor transform space and eliminating off-tree engine errors.

## Verified implementation evidence
Milestone implementation/fix checkpoints include:
- `2b3be0559042ab29cc7bf9edfff47922edefddcd` — placement editor core architecture
- `cbc02e053184b1026779174f947cad32a9fd28cd` — parser/viewport wiring repair
- `4c83ea779bbb7380156d240a254912c57fdee192` — strict command typing
- `607211c0a1fe9833e9167320e41b150b10841a4c` — preview bridge regression repair
- `6045eb10dfb09c23963b08703840aa4fb0e954b6` — full behavioral acceptance coverage
- `34fd1d7593634f2e9f327d38f8878d1317dfc563` — typed selection-state repair
- `3d82b423a784a554718ac1447bd07fadfb9b3b1f` — rendered Phase 3 evidence
- `6628f70e475e3c28794f38d40566035ce7aeda7a` — project-local automatic snap candidates

Godot Actions run `31521956419` used `4.7.1.stable.official.a13da4feb` and passed:
- `runtime-smoke` — SUCCESS
- `phase1-visual-capture` — SUCCESS

Raw runtime log contains `PASS: PlayWorld Studio test harness completed.` with no `SCRIPT ERROR:` or engine `ERROR:` output.

Raw visual log retains `--audio-driver Dummy` and `--disable-vsync`, contains both:
- `PASS: Phase 1 rendered screenshots captured.`
- `PASS: Phase 3 editor screenshots captured.`

Visual evidence contains seven files:
- `00-canonical-reference.png`
- `01-home.png`
- `02-new-world.png`
- `03-workspace-clean.png`
- `04-workspace-tools.png`
- `05-phase3-editor.png`
- `06-phase3-tool-wheel.png`

## Scope boundaries / known limitations
- The universal asset registry/import/browser is not fabricated in Phase 3. Runtime entities use generic proxy geometry until Phase 4 attaches real assets.
- Generic origin sockets are temporary compatibility anchors; richer named sockets belong to later prefab/socket work.
- Selection/tool/ghost state is editor-only and not persisted.
- Phase 4 has not started.

## Next milestone
Only after the Phase 3 completion PR is reviewed and merged into authoritative `master`, authorize the full:

**Phase 4 — Universal Asset Library milestone**

Internal task range:
- P04-T01 read-only source-folder registry and source contracts
- P04-T02 incremental scanner, hashing, and stable asset-ID reconciliation
- P04-T03 GLB/GLTF and Godot scene analysis/import support
- P04-T04 asset metadata, licensing, and catalog persistence contracts
- P04-T05 thumbnail generation, cache invalidation, and failure handling
- P04-T06 large-card asset browser, search, filters, and favorites
- P04-T07 collections, duplicate detection, source/license details, and placement handoff
- P04-T08 Phase 4 integration, scale, gamepad, failure-path, and visual verification

Use one Phase 4 milestone branch and one Phase 4 completion PR. Do not stop for per-task PRs unless a genuine external blocker requires a review decision.

## New-thread start prompt
Verify the Phase 3 completion PR has merged into authoritative `master`; never use stale default `main`. If merged, begin the complete Phase 4 Universal Asset Library milestone (P04-T01 through P04-T08) on one focused milestone branch. Commit and verify internally as needed, but do not stop or open PRs at individual task boundaries. Open one PR only after the full Phase 4 milestone is complete and verified. Preserve stable IDs, read-only source folders, command-backed placement handoff, gamepad accessibility, and the canonical dark/playful Nintendo-forward UI direction.
