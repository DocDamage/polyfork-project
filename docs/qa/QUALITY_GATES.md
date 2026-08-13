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
11. For creator distribution, execute the **packaged creator**, not merely the source project/editor, through first-run authoring, restart/reopen, upgrade/replacement-package, read-only-style installation, visual, controller/accessibility, and creator→game export/launch gates.
12. For a reproducible release claim, independently rebuild from identical inputs and compare the distributed archive byte-for-byte.
13. For release security, validate manifest hashes/sizes, SHA-256 sums, required bundled tooling/runtime files, forbidden development material, and credential-like material.
14. For release visual acceptance, download and visually inspect the final green run's screenshots rather than relying only on file-existence assertions.

## Phase 17 release-candidate gate

Phase 17 completion requires the dedicated `.github/workflows/phase17-release.yml` workflow to pass both `source-regressions` and `windows-release` on the claimed implementation/evidence head.

Final verified baseline:

- implementation/evidence head: `8f46b4cddd62efc5502033b3a9c0259bb740ec26`;
- workflow: `31668662576` — PASS;
- artifact: `9169011730` / `phase17-release-candidate`;
- RC ZIP SHA-256: `0911cc136b3deaf689b7959359ec9c45bee2f10255c7af573c9855ea0bbcdfa3`;
- packaged acceptance marker: `PASS: Phase 17 packaged creator UI, controller, accessibility, and major-screen acceptance completed.`;
- package integrity/credential scan: PASS;
- creator→standalone Windows game export and launch: PASS;
- restart/reopen/upgrade/read-only user-data separation: PASS;
- independent deterministic ZIP rebuild: PASS;
- final packaged acceptance screenshots: visually inspected and accepted.

The synthetic GLTF fixture must define a valid default scene; the final baseline no longer emits the prior fixture warning.

The GitHub-hosted Windows runner's OpenGL 3.3 → ANGLE fallback to Microsoft Basic Render Driver is a runner-specific warning and is not, by itself, a PlayWorld Studio product defect. Do not suppress unrelated product/runtime errors under that exception.

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
- Weakening or removing semantic input/controller assertions to make a release gate pass.
- Calling a skipped/unexecuted test a pass.
- Pushing dummy product changes solely to manipulate third-party check state.
- Declaring a release from source/editor tests when the distributed packaged executable has not passed.

## Definition of done

A feature is done only when implementation, tests, runtime evidence, documentation, and handoff status agree. A milestone merge additionally requires a fresh verification of the live PR head and required checks immediately before merge.

Phase 17 is implementation/release-evidence complete on its milestone branch, but its milestone boundary is not complete until the single completion PR is opened and its PR-triggered checks are reviewed. The PR must remain unmerged until explicit authorization.
