# Phase 18 — Stable Release and Windows Productization Plan and Completion Record

## Status

**COMPLETE AND ACCEPTED**

Final authoritative integration:

- PR #24 — Phase 18 — Post-merge closeout correction
- Signed `master` merge: `49a5b55748244097d952ab9c095dd00ed0ec9f06`
- Final workflow: `31699466148` — SUCCESS

## Objective

Convert the verified Phase 17 `0.1.0-rc.1` creator into **PlayWorld Studio 0.1.0** without replacing working editor/runtime/export architecture, then close the stable Windows release with valid package, installer, lifecycle, recovery, controller, and visual evidence.

## Authority history

- Original Phase 18 base: `master@91b8b9c39fddda4b80ad5c6101d563245ef3e2d0`.
- Original implementation branch: `dev/phase18-stable-release`.
- PR #23 integrated the implementation before the required manual visual closeout was valid.
- Corrective branch: `fix/phase18-post-merge-closeout`.
- PR #24 repaired the issue forward from the integrated history and completed final acceptance.
- Current authoritative `master`: `49a5b55748244097d952ab9c095dd00ed0ec9f06`.

## Delivered scope

1. Stable `0.1.0` identity across application, About UI, Windows metadata, package, installer, and release manifest.
2. Deterministic portable ZIP with independent byte-for-byte rebuild proof.
3. Windows installer, repair/reinstall, alternate-location support, and uninstall path.
4. Strict user-data/install separation.
5. Exact RC→stable migration validation using the final Phase 17 artifact.
6. Checkpoint-based damaged-project recovery and malformed-preference recovery backups.
7. Support & Recovery UI plus bounded diagnostics.
8. Portable and installed lifecycle QA, including clean first run, restart/reopen, repair, uninstall preservation, reinstall, read-only-style application location, export, and exported-game launch.
9. Inherited controller, accessibility, scale, export, and multiplayer regressions.
10. Stable visual evidence with automated surface assertions and manual inspection.
11. Portable, installer, generated support material, and release evidence validation.
12. Stable release documentation and exact completion evidence.

## About/version corrective closeout

The original Phase 18 artifact contained an invalid `09-about-version-1280x720.png`: Home was captured instead of the About/version surface.

PR #24 corrected the actual runtime path rather than substituting an image. The final implementation:

1. activates the real Home About button;
2. uses a correctly typed overlay item collection;
3. renders a visible PlayWorld Studio `0.1.0` identity card;
4. requires the exact `About PlayWorld Studio` title;
5. requires `0.1.0`, stable channel, and Windows x64 identity;
6. requires Godot and source identity text;
7. requires title, subtitle, and status labels to be renderable;
8. requires the overlay to cover Home and remain the topmost Home surface;
9. captures the image only after those assertions pass.

The corrected screenshot was downloaded and visually inspected successfully.

## Final verification

Workflow `31699466148` passed both required jobs:

- `source-regressions`
- `windows-stable-release`

The final run also retained inherited contract, runtime, scale, Windows export, multiplayer host/client, controller, accessibility, lifecycle, migration, and release-validation gates.

Final stable artifact:

- ID: `9180943528`
- Digest: `sha256:fc5dc19a7ba37a8a02c7fdce579a3a2bb6cb0e70fb5e90661cf28d4ec76f480a`

Final distributed files:

- `PlayWorld-Studio-0.1.0-Windows-x64.zip`
- `PlayWorld-Studio-0.1.0-Windows-x64-Setup.exe`

Exact file checksums and the eleven-image review record are maintained in `docs/qa/PHASE18_QA.md` and merged PR #24.

## Architecture rule retained

Phase 18 reused Phase 17 packaging/export, Phase 2 atomic-save/checkpoint infrastructure, the universal Asset Library, the existing `PlaySession`, the authored-game export pipeline, and the existing UI shell. No parallel editor, runtime, or exporter architecture was created.

## Completion boundary

All Phase 18 completion gates are satisfied. Phases 0 through 18 are complete and accepted on authoritative `master`.

No Phase 19 work is authorized until a new user-approved handoff defines the next milestone.
