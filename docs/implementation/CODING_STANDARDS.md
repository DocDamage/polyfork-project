# Coding Standards

## Scope
These standards apply to all production and test code in PlayWorld Studio.

## Godot and GDScript
- Target Godot 4.7.x APIs only unless a compatibility note is documented.
- Prefer typed GDScript for public methods, state, signals, and return values.
- One primary responsibility per script. Prefer <=300 LOC where practical.
- Prefer composition and narrow services over giant manager singletons.
- Autoloads are reserved for truly application-wide infrastructure and must expose narrow interfaces.
- Persistent identity must never depend on scene-tree paths.
- Do not hard-code gameplay semantics into generic editor infrastructure.

## Architecture boundaries
- `src/app`: application shell and navigation only.
- `src/editor`: generic runtime authoring UI and tools.
- `src/commands`: authoring commands, transactions, undo/redo.
- `src/world`: project, entity identity, persistence, and streaming coordination.
- `src/assets`: external asset catalog, adapters, analysis, thumbnails.
- `src/gameplay`: components, archetypes, prefabs, runtime gameplay primitives.
- `src/visual_script`: graph authoring/runtime.
- `src/terrain`, `src/foliage`, `src/splines`, `src/environment`: dedicated world systems.
- `src/ai`: provider adapters and transactional AI orchestration.
- `src/export`: standalone-project/build generation.
- `src/input`: keyboard, mouse, gamepad, and future touch abstraction.
- `src/diagnostics`: logging, profiling, validation, and performance diagnostics.

Cross-module calls should depend on stable public interfaces, data contracts, signals, or injected collaborators rather than reaching through another module's internals.

## Mutation and state
- Once the command framework exists, every user-visible authoring mutation must execute through it.
- Commands must be deterministic enough to support undo/redo and future collaboration.
- Persisted mutable objects use stable IDs and explicit schema versions.
- External asset source folders are read-only. Derived/imported data belongs in project-managed storage.

## UI
- The canonical reference image and UI specification are acceptance inputs, not loose inspiration.
- Smart defaults first; Advanced controls are progressively disclosed.
- Core authoring flows must remain keyboard/mouse and gamepad reachable.
- Do not introduce enterprise-dashboard density or permanent editor chrome without a documented requirement.

## Errors and validation
- Fail loudly for invalid persistent data, unsupported schema versions, missing required IDs, or unsafe write targets.
- User-facing recoverable failures should return actionable messages.
- Avoid silent fallback that can corrupt authored state.

## Tests
- Test behavior, not implementation trivia.
- Never weaken a test to match broken behavior.
- Unit tests cover deterministic logic and contracts.
- Integration tests cover module boundaries and persistence flows.
- Runtime tests launch real Godot scenes and exercise user-visible behavior.
- A test that only verifies a symbol exists is not sufficient acceptance evidence.

## Completion standard
A task is not complete merely because code compiles or a test passes. Completion requires the task's acceptance criteria, relevant automated tests, runtime/manual evidence where possible, and an updated handoff with known limitations.
