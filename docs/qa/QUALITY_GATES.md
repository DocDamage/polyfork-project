# Quality Gates

A task is not complete because code compiles or a unit test passes.

## Required evidence classes
1. Static correctness: parse/type/lint where available.
2. Automated behavior: focused unit/integration tests.
3. Scene/runtime verification: run the actual affected workflow.
4. Persistence verification when state changes are involved.
5. Undo/redo verification for authoring mutations.
6. Controller verification for core user-facing workflows.
7. Performance sanity for systems touching rendering/streaming/instancing.
8. Visual comparison for canonical UI work.

## Prohibited shortcuts
- Fake tests that assert constants.
- Replacing real behavior with stubs while marking feature complete.
- Passing only because an exception is swallowed.
- Snapshotting broken UI as the new baseline.
- Claiming controller support without navigating the actual workflow.

## Definition of done
A feature is done only when implementation, tests, runtime evidence, documentation, and handoff status agree.
