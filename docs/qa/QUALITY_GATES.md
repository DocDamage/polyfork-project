# Quality Gates

A task is not complete because code compiles or a unit test passes.

## Required evidence classes
1. Static correctness: parse/type/lint where available.
2. Automated behavior: focused unit/integration tests.
3. Scene/runtime verification: run the actual affected workflow.
4. Persistence verification when authored state changes are involved.
5. Undo/redo verification for authored mutations.
6. Controller verification for core user-facing workflows.
7. Performance sanity for systems touching rendering/streaming/instancing/network scale.
8. Visual comparison for canonical UI work.
9. Export/package verification when dependency closure or standalone behavior changes.
10. For multiplayer, real host/client lifecycle evidence in addition to isolated contract tests when the milestone claims packaged runtime interoperability.

## CI interpretation rule
- A setup/download failure that prevents the test step from executing is an **infrastructure failure**, not a product pass and not evidence that the product test itself failed.
- Retry infrastructure-only failed jobs without weakening product tests.
- Once the real test executes, its result is authoritative for that attempt.
- Third-party GitHub App check suites must be distinguished from repository-owned GitHub Actions workflows.
- Never claim a PR is fully green solely because one API surface shows no failed check-runs; inspect aggregate PR/check-suite state when it matters to merge readiness.

## Prohibited shortcuts
- Fake tests that assert constants.
- Replacing real behavior with stubs while marking feature complete.
- Passing only because an exception is swallowed.
- Snapshotting broken UI as the new baseline.
- Claiming controller support without navigating the actual workflow.
- Calling a skipped/unexecuted test a pass.
- Pushing dummy product changes solely to manipulate third-party check state.

## Definition of done
A feature is done only when implementation, tests, runtime evidence, documentation, and handoff status agree. A milestone merge additionally requires a fresh verification of the live PR head and required checks immediately before merge.
