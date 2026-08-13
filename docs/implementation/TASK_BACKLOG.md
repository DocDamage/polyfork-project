# Task Backlog

Task IDs use `P##-T##` as internal implementation checkpoints. Pull requests are milestone gates, not task gates, unless a handoff explicitly says otherwise.

## Integrated milestones

- [x] Phase 0 — Repository and Contracts
- [x] Phase 1 — Application Shell and Canonical UI
- [x] Phase 2 — World Project + Save Foundation
- [x] Phase 3 — Runtime Placement Editor
- [x] Phase 4 — Universal Asset Library — PR #9
- [x] Phase 5 — Terrain + Streaming — PR #10
- [x] Phase 6 — Components, Archetypes, Prefabs — PR #11
- [x] Phase 7 — Instant Play + Templates — PR #12
- [x] Phase 8 — Visual Scripting — PR #13
- [x] Phase 9 — Foliage / Procedural / Splines — PR #14
- [x] Phase 10 — Gameplay Framework Breadth — PR #15
- [x] Phase 11 — Environment — PR #16
- [x] Phase 12 — AI Creation — PR #17
- [x] Phase 13 — Export Pipeline — PR #18
- [x] Phase 14 — Scale and Polish — PR #19
- [x] Phase 15 — Multiplayer Foundations and Collaboration Roadmap — PR #20
- [x] Phase 16 — Inherited Product Completeness and Integration Closure — PR #21
- [x] Phase 17 — Release Candidate and Distribution — PR #22
- [x] Phase 18 — Stable Release and Windows Productization — PR #23 plus corrective closeout PR #24

Repository default and authoritative branch: `master`.

Authoritative `master`: `49a5b55748244097d952ab9c095dd00ed0ec9f06`.

Historical `main` is obsolete starter code. `archive/obsolete-main-phase14` is historical only and is not a development base.

`master` is protected by active repository rules. Normal development must use a branch and pull request.

## Phase 18 — STABLE RELEASE AND WINDOWS PRODUCTIZATION — COMPLETE

Original milestone branch: `dev/phase18-stable-release`.

Corrective branch: `fix/phase18-post-merge-closeout`.

Final signed merge: PR #24 at `master@49a5b55748244097d952ab9c095dd00ed0ec9f06`.

- [x] P18-T01 Reconcile merged Phase 17/master authority and create stable milestone branch
- [x] P18-T02 Promote all authoritative product/version/package surfaces to `0.1.0`
- [x] P18-T03 Add Windows installer, Start Menu integration, uninstall path, and install/user-data separation
- [x] P18-T04 Implement explicit non-destructive/idempotent RC→stable migration and exact RC artifact upgrade fixture
- [x] P18-T05 Add damaged-project checkpoint recovery and malformed-preference backup/recovery
- [x] P18-T06 Add bounded diagnostics/support bundle and release-material validation
- [x] P18-T07 Add first-class Support & Recovery UI and explicit recovery/failure reporting
- [x] P18-T08 Add portable + clean installed + repair/reinstall + uninstall-preservation + alternate/read-only install QA
- [x] P18-T09 Retain packaged controller/accessibility acceptance and gamepad A → `ui_accept`
- [x] P18-T10 Generate and manually inspect the eleven-image stable visual evidence set
- [x] P18-T11 Validate portable package, independent rebuild, installer, support bundle, and release material
- [x] P18-T12 Add dedicated Phase 18 stable-release automation and deterministic portable rebuild proof
- [x] P18-T13 Wire full inherited creator/export/scale/multiplayer regression into the final stable workflow
- [x] P18-T14 Reconcile canonical planning/QA/handoff/release documentation
- [x] P18-T15 Correct the About overlay typing/stacking and require exact runtime/renderability assertions before screenshot capture
- [x] P18-GATE Exact corrective source passed source + Windows stable-release jobs; artifacts/checksums verified; all screenshots manually inspected; PR #24 evidence completed and merged

## Phase 18 release identities

- Stable product: `PlayWorld Studio 0.1.0`
- Portable: `PlayWorld-Studio-0.1.0-Windows-x64.zip`
- Installer: `PlayWorld-Studio-0.1.0-Windows-x64-Setup.exe`
- Supported upgrade fixture: `0.1.0-rc.1`
- Exact Phase 17 artifact: `9169222546`

## Next work

No Phase 19 tasks are defined or authorized. A new milestone may begin only after an explicit user-approved handoff is created from current authoritative `master`.
