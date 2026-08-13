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

Repository default/authoritative branch: `master`

Authoritative `master`: `37d311b90f0684668a49e7f3b8ab197e6abcbe3a`

Historical `main` is obsolete starter code and is not a development base.

## Phase 17 — RELEASE CANDIDATE AND DISTRIBUTION — VERIFIED

Milestone branch: `dev/phase17-milestone`

Authoritative base: `37d311b90f0684668a49e7f3b8ab197e6abcbe3a`

Verified implementation/evidence head: `8f46b4cddd62efc5502033b3a9c0259bb740ec26`

Final release workflow: `31668662576` — **PASS**

Final evidence artifact: `9169011730` — `phase17-release-candidate`

RC ZIP SHA-256: `0911cc136b3deaf689b7959359ec9c45bee2f10255c7af573c9855ea0bbcdfa3`

- [x] P17-T01 Product identity/version/icon/About surface
- [x] P17-T02 Windows x64 creator export preset and branded metadata
- [x] P17-T03 Deterministic release ZIP packaging and independent rebuild proof
- [x] P17-T04 Release manifest, SHA-256 checksums, third-party notices, and release docs
- [x] P17-T05 Clean packaged Windows first-run verification
- [x] P17-T06 Core creator create/open/edit/save/Asset Library/Instant Play runtime smoke
- [x] P17-T07 Packaged creator → standalone Windows game export → launch, with bundled exporter/templates/runtime closure and explicit failure handling
- [x] P17-T08 Restart/reopen, malformed preferences, upgrade/replacement-package persistence, and read-only-style user-data separation
- [x] P17-T09 Packaged UI visual review plus controller/focus/accessibility acceptance, including gamepad A → `ui_accept`
- [x] P17-T10 Package integrity, supply-chain, forbidden-material, and credential-like-material scanning
- [x] P17-T11 Dedicated release CI plus inherited Phase 4–16/scale/export/multiplayer regressions
- [x] P17-T12 Canonical release documentation and completion handoff reconciliation
- [ ] P17-GATE Open exactly one completion PR `Phase 17 — Release Candidate and Distribution` from `dev/phase17-milestone` to `master`; verify PR-triggered checks; merge only with explicit user authorization

### Phase 17 verification details

Both source and Windows release jobs passed in workflow `31668662576`. The Windows job includes byte-identical deterministic rebuild, package integrity/credential scan, clean first run, creator-to-game export and launch, reopen/upgrade/read-only persistence, packaged visual capture, and packaged UI/controller/accessibility acceptance.

The final artifact's eight acceptance screenshots were downloaded and visually inspected. The prior GLTF default-scene warning is absent. The hosted runner's ANGLE/Microsoft Basic Render Driver warning is an infrastructure limitation, not a product gate failure.

## Next milestone boundary

Complete the single Phase 17 PR boundary and leave the PR unmerged until explicit user authorization. No Phase 18 implementation is authorized.

Historical `.polyforkAPI` credential material remains exposed in Git history and requires separate external rotation/revocation unless independently completed. Do not print, recover, test, copy, restore, or reuse it.
