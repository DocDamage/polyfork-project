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
- [x] Phase 18 implementation integrated prematurely — PR #23

Repository default/authoritative branch: `master`.

Current `master`: `9ed7abd28144f9757244f33aa33176e7074aca86`.

PR #23 was merged before the required manual visual gate was valid. Preserve history and repair forward.

Historical `main` is obsolete starter code and is not a development base.

## Phase 18 — STABLE RELEASE AND WINDOWS PRODUCTIZATION

Original milestone branch: `dev/phase18-stable-release`.

Original base: `91b8b9c39fddda4b80ad5c6101d563245ef3e2d0`.

Premature merge: PR #23 into `master@9ed7abd28144f9757244f33aa33176e7074aca86`.

Corrective branch: `fix/phase18-post-merge-closeout`.

- [x] P18-T01 Reconcile merged Phase 17/master authority and create stable milestone branch
- [x] P18-T02 Promote all authoritative product/version/package surfaces to `0.1.0`
- [x] P18-T03 Add Windows installer, Start Menu integration, uninstall path, and install/user-data separation
- [x] P18-T04 Implement explicit non-destructive/idempotent RC→stable migration and exact RC artifact upgrade fixture
- [x] P18-T05 Add damaged-project checkpoint recovery and malformed-preference backup/recovery
- [x] P18-T06 Add bounded diagnostics/support bundle and private-material rejection
- [x] P18-T07 Add first-class Support & Recovery UI and explicit recovery/failure reporting
- [x] P18-T08 Add portable + clean installed + repair/reinstall + uninstall-preservation + alternate/read-only install QA
- [x] P18-T09 Retain packaged controller/accessibility acceptance and gamepad A → `ui_accept`
- [x] P18-T10 Generate the eleven-image stable visual evidence set
- [x] P18-T11 Scan portable package, installer, support bundle, and release material for private development files
- [x] P18-T12 Add dedicated Phase 18 stable-release automation and deterministic portable rebuild proof
- [x] P18-T13 Wire full inherited creator/export/scale/multiplayer regression into the final stable workflow
- [x] P18-T14 Reconcile canonical planning/QA/handoff/release documentation for the original milestone
- [x] P18-T15 Correct the About overlay typing/stacking and require exact runtime/renderability assertions before screenshot capture
- [ ] P18-GATE Exact corrective head: source + Windows stable-release jobs pass; new artifacts/checksums verified; all screenshots manually inspected; corrective PR evidence completed; leave unmerged until explicit authorization

## Phase 18 release identities

- Stable product: `PlayWorld Studio 0.1.0`
- Portable: `PlayWorld-Studio-0.1.0-Windows-x64.zip`
- Installer: `PlayWorld-Studio-0.1.0-Windows-x64-Setup.exe`
- Supported upgrade fixture: `0.1.0-rc.1`
- Exact Phase 17 artifact: `9169222546`
- Exact Phase 17 RC ZIP SHA-256: `8db8162872077d00582ab20de5361a59cae19a45a9bacb2a3a7f199d18b4d9b9`

No Phase 19 work is authorized. The corrective Phase 18 PR must not be merged without explicit user authorization.
