# Quality Gates

A task is not complete because code compiles or one test passes.

## Required evidence classes

1. Static correctness and parse/type checks where available.
2. Automated unit/contract behavior.
3. Actual scene/runtime verification.
4. Persistence/recovery verification for authored state.
5. Undo/Redo verification for authored mutations.
6. Controller verification for core user-facing workflows.
7. Performance/scale sanity for rendering/streaming/network scale.
8. Visual comparison against the canonical UI direction.
9. Export/package verification for standalone behavior.
10. Real exported host/client lifecycle evidence for multiplayer interoperability claims.
11. Packaged creator execution—not source-only tests—for release claims.
12. Independent deterministic rebuild of the distributed portable archive.
13. Release integrity/security validation: manifests, SHA-256, required bundled tooling, forbidden development files, credential-like material.
14. Manual review of final green packaged screenshots.
15. For stable Windows productization: clean portable and installed first run, exact RC→stable upgrade, repair/reinstall, uninstall user-data preservation, alternate/read-only application location, diagnostics/support scan, and creator→game export/launch.

## Phase 18 stable-release gate — SATISFIED

Phase 18 completion required `.github/workflows/phase18-stable-release.yml` on the exact corrective source to pass:

- `source-regressions`;
- `windows-stable-release`.

Workflow `31699466148` passed both jobs, and PR #24 integrated the verified corrective source as signed `master@49a5b55748244097d952ab9c095dd00ed0ec9f06`.

The Windows job proved:

- stable `0.1.0` package identity;
- deterministic portable ZIP rebuild;
- portable clean first run/restart/reopen/read-only location;
- clean installed first run;
- installer repair/reinstall;
- uninstall removes application payload but preserves authored per-user state;
- exact Phase 17 RC artifact/hash verification and RC→stable preservation in portable and installed modes;
- packaged creator→standalone Windows game export and launch;
- inherited Phase 14 Windows size profiles;
- exported Phase 15 multiplayer host/client;
- Phase 17 packaged controller/accessibility assertions;
- stable About/Settings/Support visual capture;
- portable/installer/support-bundle credential/private-material scans.

The final stable screenshots were downloaded and inspected for clipping, overlap, unreadable text, broken focus, spacing drift, generic dark-slate regression, incorrect version text, missing assets/icons, compact-layout failure, and screenshot substitution. The corrected About/version screenshot visibly proves PlayWorld Studio `0.1.0`, stable, Windows x64, Godot 4.7.1, and source identity.

Exact evidence is recorded in `docs/qa/PHASE18_QA.md` and merged PR #24.

## CI interpretation

- Setup/download failure before a product test executes is infrastructure failure, not product pass/fail evidence.
- Retry infrastructure-only failures without weakening product assertions.
- Once the real test executes, its result is authoritative for that attempt.
- Historical milestone workflows must not test later stable identities against obsolete hard-coded release-candidate constants; their actual behavioral coverage must remain inherited in the active milestone workflow.
- Never claim full green status from a single API surface; inspect the relevant workflow/jobs and completion PR state.

## Prohibited shortcuts

- Fake constant-only tests.
- Stubs replacing real behavior while marking a feature complete.
- Swallowing exceptions to force pass.
- Snapshotting broken UI as a new baseline.
- Claiming controller support without navigating the real workflow.
- Weakening semantic gamepad/focus assertions.
- Calling skipped tests passes.
- Declaring a stable release from source-only checks.
- Treating screenshot existence as visual approval.
- Deleting authored user data during application uninstall unless the user explicitly requests it.

## Repository integration gate

`master` is protected by active repository rules. Normal changes must be developed on a branch and integrated through a pull request.

## Definition of done

Implementation, tests, runtime evidence, release artifacts, documentation, and handoff status must agree. Phase 18 satisfies this definition through PR #24, workflow `31699466148`, final artifacts and checksums, lifecycle evidence, and manual review recorded in `docs/qa/PHASE18_QA.md`.

No Phase 19 work is authorized until a new user-approved handoff defines the next milestone.

<!-- PHASE19_CORRECTION_STATUS_START -->
## Phase 19 release-maintenance gates

Phase 19 adds strict signed-manifest, channel, staging, migration, session-recovery, updater-helper, deterministic package, installer, real portable/installed `0.1.0 → 0.2.0`, interruption, repair, rollback, offline/export, controller/accessibility, visual, privacy, security, and publication-dry-run gates. Inherited checks do not replace these focused gates. Screenshot existence alone is not visual acceptance.
<!-- PHASE19_CORRECTION_STATUS_END -->
