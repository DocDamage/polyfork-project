# Repository Structure

```text
assets/
  reference/          canonical design references only
config/               project-level defaults/schema versions
schemas/              JSON schemas and examples
src/
  app/                application shell/navigation
  editor/             runtime editor UI/tools
  commands/           transactions + undo/redo
  world/              project/entity/streaming
  assets/             registry/import/thumbnail services
  gameplay/           components/archetypes/prefabs
  visual_script/      graph editor/runtime
  terrain/
  foliage/
  splines/
  environment/
  ai/
  export/
  input/
  diagnostics/
  main/
tests/
  unit/
  integration/
  runtime/
docs/
```

Avoid giant manager scripts. Services should expose narrow interfaces and be replaceable in tests.
