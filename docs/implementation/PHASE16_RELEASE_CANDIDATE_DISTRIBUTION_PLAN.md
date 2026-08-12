# Phase 16 — Release Candidate and Distribution

## Status
Phase 16 is defined and authorized for implementation on `dev/phase16-milestone`.

Authoritative base: `master` at `b4b5e88ef11ba514b1c8755e45e1a9de5cf04613`, the verified signed merge commit for PR #20 — Phase 15 — Multiplayer Foundations and Collaboration Roadmap.

The repository default branch `main` remains obsolete starter code and is not a development base.

## Why this is the next milestone
The authoritative Product Requirements, Decisions, Charter, Risk Register, Security document, System Architecture, QA matrix, acceptance scenarios, and completed Phase 10–15 plans show that the major creative/runtime subsystems are already implemented and verified: world/save, placement, Asset Library, terrain/streaming, components/prefabs, Instant Play/templates, Visual Scripting, procedural/foliage/splines, gameplay breadth, Environment, AI Creation, project export, scale/polish, and bounded multiplayer Play.

The remaining explicit Phase 15 deferrals—production matchmaking/relay/auth/voice/anti-cheat/rollback/dedicated-server infrastructure and production collaborative editing—are outside the current major-release scope and therefore are not promoted into Phase 16 by default.

The concrete major-release gap is distribution of **PlayWorld Studio itself**. The repository has project-export verification, but no versioned product release contract, no PlayWorld Studio Windows export preset/release package, and no clean-package launch/first-run gate for the creation application. The Project Charter defines a successful major release as a usable game-creation platform, so release/distribution readiness is the highest-value coherent next milestone.

## Milestone goal
Produce a versioned Windows release-candidate package of PlayWorld Studio that launches outside the source checkout, uses safe user-scoped writable storage, preserves the canonical UI and existing architecture, and passes a cross-phase release acceptance gate plus inherited regressions.

## P16-T01 — Release identity and compatibility contract
Deliver:
- schema-versioned `config/release_manifest.json`;
- product ID/name/version/channel;
- required Godot baseline;
- supported initial release platform declaration;
- runtime validation through a small release-contract module;
- `project.godot` product version aligned with the manifest;
- fail-closed behavior for malformed or incompatible packaged release metadata.

The manifest contains no credentials, user-specific data, project content, or network identity.

## P16-T02 — Windows creation-app distribution
Deliver a project-owned Windows Desktop export preset for **PlayWorld Studio itself**, distinct from Phase 13 user-project export.

Requirements:
- release executable and PCK are produced from the existing `Main.tscn` application;
- tests, CI artifacts, documentation, and other development-only material are not intentionally included as runtime product dependencies;
- authored projects continue to use `user://projects` by default;
- external Asset Library source folders remain read-only;
- no editor/gameplay architecture is forked for the release build;
- package identity/version metadata comes from the Phase 16 release contract.

## P16-T03 — Clean-package first-run and reopen gate
Add a release-smoke path that is activated only by an explicit test environment flag and exercises the real packaged application bootstrap.

The gate must prove, from a copied clean package:
1. release metadata loads and validates;
2. the real application shell reaches Home;
3. writable project storage resolves under `user://` rather than the source checkout;
4. a Medium `third_person_adventure` project can be created through the same project/application services;
5. the project can be activated in the canonical workspace;
6. saved/recent-project state can be reopened;
7. Build-mode authored state remains valid after the round trip;
8. the packaged process exits cleanly with a deterministic PASS marker and no strict Godot errors.

The smoke mode must not run during ordinary user launches.

## P16-T04 — Release acceptance contracts
Add Phase 16 focused contracts for:
- manifest schema and project-version consistency;
- required release resources and export-preset safety;
- user-scoped storage policy;
- creation/reopen persistence using real repositories;
- release package exclusion/identity expectations;
- canonical application bootstrap assumptions.

No constant-only or existence-only fake tests qualify as completion evidence.

## P16-T05 — Inherited regression gate
Run the established Phase 6–15 contract/runtime gates that cover the current reusable platform surface, including Phase 14 scale/polish and Phase 15 multiplayer contracts.

A release milestone may not weaken earlier architecture or tests to make packaging pass.

## P16-T06 — Canonical release visual evidence
Capture actual running-app evidence at 1600×900 and 1024×640 for release-relevant surfaces:
- Home / first-run surface;
- Settings / product-ready configuration surface;
- canonical workspace after creating the release-smoke Medium project.

Evidence must preserve the dark playful Nintendo/Apple visual language, adaptive layout, controller focus rules, and viewport-first composition. Generic dark-slate styling is a defect.

## P16-T07 — Windows release-package CI
Add a repository-owned Windows workflow that:
- installs Godot 4.7.1 and export templates;
- validates the Phase 16 contract suites;
- exports PlayWorld Studio with the release preset;
- copies the produced package to a separate clean-package directory;
- launches the copied executable with the explicit release-smoke flag;
- requires the deterministic release PASS marker;
- treats setup/download failures as infrastructure failures, not product results;
- uploads package/log evidence as a bounded-retention workflow artifact.

This workflow proves PlayWorld Studio distribution. It does not replace Phase 13/14/15 verification of user-created game exports.

## P16-T08 — Documentation and release closeout
Update:
- README and repository orientation;
- Product/Architecture documentation where release distribution changes the current boundary;
- Quality Gates and Test Matrix with creation-app release evidence;
- Master Implementation Plan and Task Backlog;
- Current Handoff;
- repository/file index if required.

Open one Phase 16 completion PR targeting authoritative `master` after implementation and verification are complete.

## Architectural invariants
- `PlaySession` remains the disposable Build/Play runtime boundary.
- Persistent authored mutation remains command/transaction owned.
- Stable authored IDs remain authoritative.
- Asset Library source folders remain untouched.
- Visual Scripting continues to use existing gameplay/service boundaries.
- Phase 13 user-project export remains separate from Phase 16 PlayWorld Studio distribution.
- Multiplayer remains opt-in and transient Play state.
- No collaborative-authoring runtime is introduced.
- No cloud service, updater service, account system, marketplace, or telemetry backend is introduced.

## Explicit non-goals
Phase 16 does **not** implement:
- production collaborative editing;
- matchmaking, relay/NAT traversal, account/auth, voice, anti-cheat, rollback netcode, or dedicated-server fleets;
- automatic updater/cloud distribution infrastructure;
- code signing/notarization credentials or paid certificate integration;
- macOS/Linux release packages;
- marketplace/asset hosting;
- arbitrary FBX repair;
- a replacement launcher/editor architecture.

## Required completion evidence
Phase 16 is complete only when all are true:
- Phase 16 Contracts — PASS;
- Phase 16 Inherited Regressions — PASS;
- Godot Smoke — PASS;
- Phase 16 Visual Evidence — PASS and captures inspected;
- Phase 16 Windows Studio Release — PASS with real clean-package launch/create/reopen smoke;
- canonical documentation agrees on Phase 16 completion state;
- one Phase 16 completion PR targets `master`.
