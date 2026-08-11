# Current Handoff

## Status
OPEN — P03-T01 implementation is complete and verified on its task branch; merge is required before `master` advances beyond completed Phase 2.

## Project state
Phase 0, Phase 1, and Phase 2 are complete on authoritative `master`.

PR #6 merged P02-T07 into `master` at merge commit `20ee082ee242a06e80364df57fda0e2f8aebe678`. P03-T01 was implemented from that exact merged baseline on `dev/p03-t01-runtime-selection`.

The repository default branch remains the obsolete starter branch `main`; do not develop from it. The authoritative project branch remains `master`.

## Completed task on the implementation branch
`P03-T01 — Implement runtime entity scene bridge and single-selection foundation`

## Runtime editor architecture added
- `src/editor/runtime_entity_node.gd` defines the generic `Node3D` wrapper for one persisted `WorldEntity`. The wrapper copies the stable entity UUID into runtime metadata and applies persisted position, rotation, and scale.
- `src/editor/runtime_entity_bridge.gd` builds the runtime node hierarchy from validated entity dictionaries and resolves runtime nodes back to stable entity IDs.
- Runtime parent relationships are reconstructed from `parent_entity_id`; no persistent relationship depends on node names or scene-tree paths.
- Bridge rebuild rejects invalid records, duplicate stable IDs, unresolved parents, self-parenting, and parent cycles.
- Bridge rebuild is failure-safe: invalid replacement data is staged and rejected before the prior known-good runtime mapping is destroyed.
- `src/editor/single_selection.gd` owns exactly one selected entity at a time and accepts either a stable entity ID or a descendant runtime node resolved through the bridge.
- Invalid selection attempts preserve the previous selection; selecting a new entity clears the prior wrapper's selected state.
- Selection is editor-only state. It does not change project persistence, enter command history, or mark the project dirty.

## Workspace integration
`src/app/workspace/workspace_screen.gd` now:
- creates and owns the runtime entity bridge when the workspace initializes;
- rebuilds bridged entities from the persisted `entities` collection supplied by the active project configuration;
- exposes stable-ID and runtime-node selection entry points for later picking/placement systems;
- drives the existing right inspector from selected entity records;
- displays persisted position, rotation, scale, stable entity ID, owning cell ID, and parent ID;
- clears entity selection when the inspector is closed;
- preserves existing generic inspector behavior, mode controls, bottom dock, and canonical UI shell.

No new permanent UI chrome or visual redesign was introduced.

## P03-T01 scope boundaries
Not implemented in this task:
- object placement;
- ghost preview;
- viewport raycast/picking geometry;
- move/rotate/scale authoring;
- transform commands or gizmo state;
- duplicate/delete;
- multi-select/grouping;
- snapping;
- controller tool wheel;
- asset loading or asset-registry behavior.

The bridge intentionally provides generic `Node3D` anchors rather than inventing asset loading before the asset-library phase exists. Later selectable geometry can resolve to the owning entity through bridge metadata.

## Automated tests added
`tests/unit/runtime_entity_bridge_contracts.gd` verifies:
- one runtime node per persisted entity;
- stable-ID lookup;
- persisted position/rotation/scale application;
- stable-ID parent hierarchy reconstruction;
- descendant runtime-node resolution back to owning entity ID;
- selecting by stable ID;
- replacing a previous single selection;
- selecting through a descendant runtime node;
- rejected unknown-ID selection preserving prior state;
- selection clearing runtime selected state;
- parent-cycle rejection;
- failed bridge rebuild preserving the previous known-good mapping.

`tests/runtime/entity_selection_smoke.gd` verifies the actual workspace integration:
- valid project entity records rebuild into runtime wrappers;
- entity selection opens the existing inspector;
- inspector content comes from the persisted entity record;
- selecting a second entity leaves exactly one runtime wrapper selected;
- descendant runtime-node selection resolves through stable identity;
- selection does not mutate workspace project configuration;
- closing the inspector clears the selection and runtime selected state.

`tests/test_runner.gd` runs the new bridge contracts together with all existing Phase 0–2 contracts.

`tests/runtime/runtime_smoke.gd` now exercises the entity-selection smoke inside the real application workspace while retaining all existing shell, mode, inspector, dock, cancel, persistence, and Continue-path verification.

## Verification evidence
Implementation commit:
`16a581704fc0f1b85f1c31504a0f88254aa070a8`

GitHub Actions run `31515688225` used Godot `4.7.1.stable.official.a13da4feb` and passed:
- `runtime-smoke` — SUCCESS
- `phase1-visual-capture` — SUCCESS

The runtime raw log contains `PASS: PlayWorld Studio test harness completed.` and contains no `SCRIPT ERROR:` or engine `ERROR:` output.

The visual-capture raw log retains `--audio-driver Dummy` and `--disable-vsync`, contains `PASS: Phase 1 rendered screenshots captured.`, and contains no `SCRIPT ERROR:` or engine `ERROR:` output. The existing five canonical Phase 1 evidence images remain generated.

After this documentation closeout commit, require one final Godot 4.7.1 branch workflow run and record that final run in the PR/completion report before treating P03-T01 as ready to merge.

## Changed files
- `src/editor/runtime_entity_node.gd`
- `src/editor/runtime_entity_bridge.gd`
- `src/editor/single_selection.gd`
- `src/app/workspace/workspace_screen.gd`
- `tests/unit/runtime_entity_bridge_contracts.gd`
- `tests/runtime/entity_selection_smoke.gd`
- `tests/runtime/runtime_smoke.gd`
- `tests/test_runner.gd`
- `docs/architecture/SYSTEM_ARCHITECTURE.md`
- `docs/implementation/TASK_BACKLOG.md`
- `docs/handoffs/CURRENT_HANDOFF.md`

## Known limitations and residual risks
- P03-T01 selection is programmatic/editor-model selection. Real viewport picking requires selectable geometry and belongs to later placement/editor work rather than being fabricated against the current placeholder viewport.
- Runtime wrappers currently contain no asset scene content because the universal asset registry/import pipeline has not been implemented yet.
- Wrapper selected state is a generic selection flag; a rendered bright outline requires actual rendered selectable content and remains a later visual/editor integration responsibility.
- Selection is intentionally not persisted across sessions.
- The obsolete `main` versus authoritative `master` branch mismatch remains intentionally unresolved.

## Next authorized task
Only after the P03-T01 PR is reviewed and merged into authoritative `master`, authorize only:

`P03-T02 — Implement command-backed object placement and ghost preview`

Do not begin P03-T03 or broader Phase 3 work in the same authorization step.

## New-thread start prompt
Verify the P03-T01 PR has been merged into authoritative `master`; never develop from stale default `main`. Read the standard project/architecture/implementation documents and this handoff. If P03-T01 is present on `master`, implement only `P03-T02 — Implement command-backed object placement and ghost preview`. All authoring mutations must go through the command/transaction framework, successful mutations must mark the active project dirty, persistent identity remains stable-ID based, and UI/visual work must preserve the canonical dark/playful Nintendo-forward direction. Do not begin P03-T03 until P03-T02 is verified, documented, and merged.
