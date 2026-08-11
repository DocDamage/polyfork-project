# Save, Undo/Redo, and Export

## Save model
- World project metadata is versioned.
- Autosave uses atomic/replace-safe writes.
- User saves create recoverable checkpoints.
- Large worlds save dirty cells independently.

## Undo/redo
All user-visible mutations use the command system. Transform drags coalesce into one logical operation. Brush strokes coalesce appropriately. Procedural and AI operations are top-level transactions.

## Export
Export produces a normal runnable Godot project/build containing authored runtime systems but excluding authoring-only UI, indexing services, thumbnail caches, and private editor metadata not required by gameplay.

## Validation before export
Check missing source dependencies, broken prefab inheritance, unresolved graph errors, unavailable components, license warnings, invalid spawn configuration, world-cell errors, and template-required systems.
