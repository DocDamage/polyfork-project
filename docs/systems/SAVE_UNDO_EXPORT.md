# Save, Undo/Redo, and Export

## Save model
- World project metadata is versioned.
- Autosave uses atomic/replace-safe writes.
- User saves/checkpoints are recoverable according to the owning world persistence contracts.
- Large worlds save dirty cells independently.
- Phase-owned authored registries use their validated fail-closed persistence paths.

## Undo/redo
All authored user-visible mutations use the command/transaction system. Transform drags/brush strokes coalesce appropriately. Procedural and AI operations are top-level transactions where designed.

Disposable Play state is not authored Undo history. Phase 15 network packets, peer mappings, remote transforms, and runtime match snapshots do not become Build undo entries.

## Multiplayer runtime save authority
During a Phase 15 network Play session, the host is the only runtime role allowed to persist authoritative runtime gameplay state. Clients must reject runtime persistence authority.

This rule does not make network session state authored project data. Leaving Play still discards transient network identity/session state.

## Export
Export produces a normal runnable Godot project/build containing authored runtime systems but excluding authoring-only UI, indexing services, thumbnail caches, and private editor metadata not required by gameplay.

Phase 15 extends dependency closure conditionally:
- offline project: omit Phase 15 networking runtime and multiplayer profile;
- multiplayer-capable project: include required network runtime closure and generated `runtime_data/multiplayer_profile.json`.

Standalone bootstrap dynamically loads `NetworkRuntime` only when the package declares multiplayer capability and the requested launch role requires it. Normal offline launch behavior remains first-class.

## Validation before export
Check missing source dependencies, broken prefab inheritance, unresolved graph errors, unavailable components, license warnings, invalid spawn/template configuration, world-cell errors, required runtime modules, performance profile validity, and multiplayer capability validity when enabled.

Repeat export staging must clear stale files so a prior multiplayer export cannot leave networking metadata in a later offline package.
