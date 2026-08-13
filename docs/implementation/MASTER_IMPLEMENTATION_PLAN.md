# Master Implementation Plan

## Authoritative state

- Repository default and authoritative integrated line: `master`.
- Current `master`: `9ed7abd28144f9757244f33aa33176e7074aca86`, verified signed merge commit for PR #23 / Phase 18.
- PR #23 was merged prematurely before the required manual visual gate was valid. Preserve the merge and repair forward; do not reset or rewrite `master`.
- Historical `main` is obsolete starter code and is not a development base.
- Phases 0 through 17 are complete and accepted.
- Phase 18 implementation is integrated but final acceptance remains open.
- Active corrective branch: `fix/phase18-post-merge-closeout`.
- The corrective PR targets `master` and remains unmerged until explicit user authorization.
- Phase 19 is not authorized.

## Accepted phases

- Phase 0 — Repository and Contracts
- Phase 1 — Application Shell and Canonical UI
- Phase 2 — World Project / Save Foundation
- Phase 3 — Runtime Placement Editor
- Phase 4 — Universal Asset Library
- Phase 5 — Terrain + Streaming
- Phase 6 — Components, Archetypes, Prefabs, Sockets
- Phase 7 — Instant Play + Templates
- Phase 8 — Visual Scripting
- Phase 9 — Foliage / Procedural / Splines
- Phase 10 — Gameplay Framework Breadth
- Phase 11 — Environment
- Phase 12 — AI Creation
- Phase 13 — Export Pipeline
- Phase 14 — Scale and Polish
- Phase 15 — Multiplayer Foundations and Collaboration Roadmap
- Phase 16 — Inherited Product Completeness and Integration Closure
- Phase 17 — Release Candidate and Distribution

## Phase 18 — Stable Release and Windows Productization

Target product: **PlayWorld Studio 0.1.0**.

Target portable package: `PlayWorld-Studio-0.1.0-Windows-x64.zip`.

Target installer: `PlayWorld-Studio-0.1.0-Windows-x64-Setup.exe`.

### P18-T01 — Reconcile merged Phase 17 state — COMPLETE
Phase 18 was branched from exact authoritative `master@91b8b9c39fddda4b80ad5c6101d563245ef3e2d0`; PR #22 and `master` default-branch authority were verified.

### P18-T02 — Stable 0.1.0 identity — COMPLETE
Application/project/export/manifest/package/About identity is stable `0.1.0`, Windows x64, with RC wording retained only where historical or explicitly describing the supported upgrade source.

### P18-T03 — Windows installer/uninstall — COMPLETE
Inno Setup packaging installs the complete creator payload, creates normal Windows integration, marks installed mode, supports alternate installation directories, and uninstalls application files without deleting per-user authored data.

### P18-T04 — Upgrade/migration hardening — COMPLETE
The exact Phase 17 artifact `9169222546` and RC ZIP hash `8db8162872077d00582ab20de5361a59cae19a45a9bacb2a3a7f199d18b4d9b9` are the upgrade fixture. Stable migration is explicit, idempotent, non-destructive, records source/target versions, and preserves RC user data.

### P18-T05 — Backup and recovery — COMPLETE
Existing atomic saves/checkpoints are reused. Corrupt canonical project metadata is backed up before checkpoint promotion; malformed preferences are backed up before safe defaults; unavailable sources and missing release/export components remain explicit failures.

### P18-T06 — Diagnostics/support bundle — COMPLETE
The Support & Recovery surface emits bounded diagnostics covering stable identity, source/build identity, runtime/OS/rendering/GPU, install mode, user-data directories, exporter/template availability, schema, and Asset Library health. Automated scans reject private release material.

### P18-T07 — Production failure/recovery UX — COMPLETE
Support/recovery is a first-class Home action. Existing project, Asset Library, and export surfaces retain explicit error reporting; damaged projects are surfaced with recoverability status and a user-triggered checkpoint recovery path.

### P18-T08 — Installer/package QA — COMPLETE IN AUTOMATION
The stable workflow exercises portable first run/reopen/read-only layout, clean installed first run, repair/reinstall, uninstall with user-data preservation, reinstall, alternate install location, exact RC-profile upgrade, creator export, and exported-game launch.

### P18-T09 — Controller/accessibility regression — RETAINED
The Phase 17 packaged acceptance marker remains mandatory, including gamepad A → `ui_accept`, D-pad focus navigation, compact layouts, keyboard/mouse parity, and major creator screens.

### P18-T10 — Stable visual acceptance — CORRECTION REQUIRED
The original workflow captured eleven files, but downloaded evidence showed that `09-about-version-1280x720.png` was Home rather than About/version. Therefore the original green workflow did not satisfy the manual visual gate.

### P18-T11 — Release security hardening — COMPLETE
Portable payload, installer, release manifests/checksums, and support bundle remain subject to the existing private-material and credential-pattern scans. The corrective work does not weaken those scanners.

### P18-T12 — Stable release automation — COMPLETE, WITH VISUAL ASSERTION HARDENED
`.github/workflows/phase18-stable-release.yml` runs source regressions and Windows productization, builds deterministic portable packages, builds the installer, verifies real RC→stable migration, executes packaged app workflows, captures visuals, scans artifacts, and uploads bounded release evidence.

The corrective implementation activates the real About action and requires exact overlay identity, stacking, coverage, and label-renderability assertions before the About screenshot is accepted.

### P18-T13 — Full inherited regression — REQUIRED AT CORRECTIVE HEAD
The corrective Phase 18 workflow must rerun the core harness, Phase 4–15 suites, Phase 16 product/integration/shared-asset closure, Phase 14 scale/export, Phase 15 multiplayer export/host/client, and Phase 17 packaged controller/accessibility assertions.

### P18-T14 — Documentation/closeout — CORRECTED
Canonical planning, QA, backlog, and handoff documentation must reflect the premature PR #23 merge and the forward-fix branch. Exact run/artifact/checksum/manual-review evidence belongs in the corrective PR rather than the historical merged PR.

### P18-T15 — About/version evidence hardening — IMPLEMENTED, AWAITING CI
The Home overlay is promoted to the topmost Home child, exposes bounded presentation state, receives a correctly typed About item collection, displays a visible stable identity card, and is verified before packaged capture.

## Phase 18 corrective completion gate

Phase 18 is finally accepted only when the exact corrective head has green source and Windows stable-release jobs, newly generated package/installer artifacts and checksums are verified, all eleven screenshots are manually inspected, the About image visibly proves stable `0.1.0` identity, and the corrective PR contains exact evidence while remaining unmerged until explicit authorization.

## Architectural invariants retained

- existing `PlaySession` remains the Build/Play boundary;
- authored mutation remains command/transaction owned with Undo/Redo;
- stable authored IDs remain authoritative;
- external Asset Library sources remain read-only;
- terrain/streaming, components/prefabs/sockets, Visual Scripting, gameplay, Environment, AI privacy/consent, authored-game export, and multiplayer boundaries are reused;
- user data remains separate from application installation;
- offline behavior remains first-class;
- no parallel editor/runtime/exporter architecture was introduced.
