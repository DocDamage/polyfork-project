# Master Implementation Plan

## Authoritative state

- Repository default branch and authoritative integrated line: `master`.
- Current authoritative `master`: `37d311b90f0684668a49e7f3b8ab197e6abcbe3a`, verified signed merge commit for PR #21 / Phase 16.
- Historical `main` contains obsolete starter code and is not a development base.
- Phases 0 through 16 are complete and merged.
- Phase 17 is implementation-complete and release-verified on `dev/phase17-milestone`, pending its single completion PR to `master`.
- Verified Phase 17 implementation/evidence head: `8f46b4cddd62efc5502033b3a9c0259bb740ec26`.
- Full Phase 17 release workflow `31668662576`: source and Windows jobs PASS.
- Final evidence artifact: `9169011730` / `phase17-release-candidate`.
- RC ZIP SHA-256: `0911cc136b3deaf689b7959359ec9c45bee2f10255c7af573c9855ea0bbcdfa3`.

Historical `.polyforkAPI` credential material remains exposed in Git history and must be rotated/revoked separately unless that external action has already been independently completed. Never print, restore, test, copy, or reuse it.

## Completed phases

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

## Phase 17 — Release Candidate and Distribution — VERIFIED

Target release: `PlayWorld Studio 0.1.0-rc.1`

Target package: `PlayWorld-Studio-0.1.0-rc.1-Windows-x64.zip`

### P17-T01 — Product/version identity — COMPLETE
Formal creator product identity, release channel/version, icon, branded Windows metadata, and About/version UI are implemented and contract-tested.

### P17-T02 — Windows creator export preset — COMPLETE
A dedicated Windows x64 creator preset builds the PlayWorld Studio application itself.

### P17-T03 — Deterministic release package — COMPLETE
Release construction produces the portable creator ZIP deterministically. Run `31668662576` independently rebuilt the package and proved byte-for-byte identical ZIP output.

### P17-T04 — Release manifest/checksums/notices — COMPLETE
The package contains schema-v1 release identity, included-file hashes/sizes, `SHA256SUMS.txt`, ZIP SHA-256 sidecar, third-party notices, and release/user documentation.

### P17-T05 — Clean Windows installation verification — COMPLETE
The packaged executable launches against a clean user-data root and successfully creates/edits/saves a real project.

### P17-T06 — Core creator workflow smoke — COMPLETE
Packaged Home/New World/workspace, real placement/editing, Asset Library indexing, Instant Play, Build return, save/reopen, and major creator surfaces are runtime-verified.

### P17-T07 — Standalone export from packaged creator — COMPLETE
The distributed creator carries its required Godot exporter, Windows templates, and raw runtime source closure. The packaged creator exports a standalone Windows game and the exported game launches to the Phase 13 runtime marker. Missing exporter/template conditions fail explicitly.

### P17-T08 — Upgrade and data safety — COMPLETE
Per-user project/library/preferences paths remain outside the installation directory. Malformed preferences fall back safely. Restart/reopen, independent replacement-package upgrade, and read-only-style install verification pass.

### P17-T09 — Release UX and visual acceptance — COMPLETE
Packaged Home 1600×900/1280×720/compact, Asset Library, New World, Build workspace, Instant Play, and Export screenshots were captured and visually inspected. Controller/focus/accessibility acceptance passes, including physical gamepad A → semantic `ui_accept`.

### P17-T10 — Supply-chain and secret validation — COMPLETE
Package validation checks required tooling/runtime files, manifest hashes/sizes, SHA-256 sums, forbidden development paths/files, legacy `.polyforkAPI` marker material, and OpenAI-style credential patterns. The final package validation passes.

### P17-T11 — Regression and release automation — COMPLETE
Dedicated `.github/workflows/phase17-release.yml` runs source contracts, inherited Phase 4–16 regressions, Phase 14 Windows profiles, Phase 15 exported multiplayer, deterministic packaging, packaged creator runtime verification, visual capture, acceptance, and bounded evidence upload.

### P17-T12 — Release documentation and handoff — COMPLETE
Release guides/notices and canonical README/plan/backlog/QA/handoff state are reconciled to the final verified release evidence.

## Final Phase 17 evidence

Workflow `31668662576` passed both `source-regressions` and `windows-release`. The required packaged acceptance log contains:

`PASS: Phase 17 packaged creator UI, controller, accessibility, and major-screen acceptance completed.`

Artifact `9169011730` contains the RC ZIP/checksum/manifest, release logs, and packaged visual evidence. The repaired GLTF fixture no longer emits the previous default-scene warning. The only visual-run warning observed is the GitHub-hosted Windows ANGLE fallback to Microsoft Basic Render Driver.

## Completion boundary

The next milestone action is exactly one Phase 17 completion PR from `dev/phase17-milestone` to `master`. Do not merge it without explicit user authorization.

Phase 18 is undefined and unauthorized until Phase 17 is merged and a new handoff explicitly defines the next milestone.

## Architectural invariants retained

- existing `PlaySession` remains the disposable Build/Play boundary;
- authored mutation remains command/transaction owned with Undo/Redo;
- stable authored IDs remain authoritative;
- external Asset Library sources remain read-only;
- gameplay event/Visual Scripting boundaries are reused;
- project export architecture is reused;
- multiplayer remains opt-in and transient;
- gameplay replication remains separate from collaborative authoring;
- no fake parallel editor/runtime was introduced.
