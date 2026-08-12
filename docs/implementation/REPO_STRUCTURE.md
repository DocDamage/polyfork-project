# Repository Structure

```text
.github/workflows/       milestone and regression CI
assets/
  reference/             canonical design references only
config/                  project-level defaults/schema versions
schemas/                 JSON schemas and examples
templates/
  manifests/             data-driven project/template capability manifests
src/
  app/                   application shell and contextual workspace layers
  editor/                runtime editor UI/tools
  commands/              transactions + undo/redo
  world/                 project/entity persistence
  assets/                registry/import/thumbnail services
  terrain/               terrain, partition, streaming integration
  gameplay/              components/archetypes/prefabs/runtime gameplay services
  runtime/               disposable Play controllers/session helpers
  templates/             template contracts/application/runtime-module registry
  visual_script/         graph editor/compiler/interpreter
  foliage/               foliage runtime/authoring
  procedural/            nondestructive procedural source runtime
  splines/               roads/splines
  environment/           environment/weather/water integration
  ai/                    AI creation/providers/query/history
  export/                staging/closure/build/standalone runtime
  scale/                 Low/Balanced/High performance policy and scale helpers
  input/                 input abstraction/support services
  network/               Phase 15 runtime multiplayer contracts/transport/replication/match state
  diagnostics/           diagnostics/performance support
  main/                  application entry scene/code
tests/
  unit/
  integration/
  runtime/
  phase*_suite_runner.gd
docs/
  architecture/
  design/
  handoffs/
  implementation/
  qa/
  systems/
```

Avoid giant manager scripts. Services should expose narrow interfaces and be replaceable in tests.

`src/network` owns transient gameplay networking only. Future persistent collaborative authoring is documented in `docs/architecture/PHASE15_COLLABORATIVE_AUTHORING_ROADMAP.md` and must not be silently implemented as packet replication inside the editor.
