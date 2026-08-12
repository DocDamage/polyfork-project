# Phase 13 — Export Pipeline Implementation Plan

## Completion state
**COMPLETE — MERGED BY PR #18**

- Authoritative Phase 12 base: `master` at `b2a97a6cea52c6620f2b826a390a1d2d531ad81e`.
- Milestone branch: `dev/phase13-export-pipeline-milestone`.
- Pre-write compare gate: exact merge base, 0 ahead, 0 behind.
- `main` is obsolete and prohibited as a development base.
- Verified code-complete head before documentation closeout: `e8c939a4bc86ef011fcb42c0e8f4b197b470b4e2`.
- Final Phase 13 branch head: `2fd3c5e9516e6cd135d4b899ab8a2a3fb8ad3eac`.
- PR #18 merged on August 12, 2026.
- Verified signed Phase 13 merge commit / resulting authoritative `master`: `cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`.
- Phase 14 is unblocked.

## Architectural invariant — SATISFIED
Export is packaging and runtime bootstrapping, not a second engine. Exported games reuse the Phase 7 `PlaySession` and existing world, terrain/streaming, gameplay, templates/modules, Visual Scripting, procedural, Environment, and semantic-input implementations.

The standalone path uses thin read-only staging/load adapters around those systems. No parallel runtime architecture was introduced.

## P13-T01 — Contracts and package model — COMPLETE
Delivered schema-v1 contracts for build/export manifests, target/platform settings, deterministic package paths, runtime/editor classification, dependencies/source lineage, license/attribution entries, validation findings, and export results/reports.

Verified behavior:
- strict schema/version validation;
- deterministic ordering;
- unsafe traversal/absolute package paths rejected;
- unknown target/runtime classification rejected;
- prohibited credential material rejected from manifests.

## P13-T02 — Dependency discovery — COMPLETE
Delivered deterministic authored dependency discovery with separate validation for Phase 7 runtime module IDs and Asset Library UUID dependencies.

Verified behavior:
- world and authored subsystem references are scanned deterministically;
- procedural asset sources participate in discovery;
- runtime module IDs such as `core.world` are not misinterpreted as Asset Library UUIDs;
- editor selection/history/UI state is not treated as runtime dependency input;
- dependencies are de-duplicated and ordered.

## P13-T03 — Asset Library resolution — COMPLETE
Delivered resolution through the existing Phase 4 Asset Library metadata and source registry.

Verified behavior:
- external source folders remain read-only;
- only required assets are copied into deterministic project-managed staging paths;
- source asset/path lineage is preserved;
- missing or unavailable required assets block export;
- arbitrary source-folder bulk copy is not used.

## P13-T04 — Licensing and attribution — COMPLETE
Delivered deterministic machine-readable and human-readable attribution output.

Verified behavior:
- known Asset Library author/source/license metadata is preserved;
- unknown/missing license information is reported explicitly;
- no license grant or compatibility claim is invented;
- output ordering is deterministic.

## P13-T05 — Deterministic staging and stripping — COMPLETE
Delivered staging from exact runtime source dependency closure plus an explicit authored-data plan.

Verified behavior:
- required runtime source/data is copied deterministically;
- editor shell/workspaces, authoring-only AI/config/history data, checkpoints, recovery copies, and other non-runtime data are excluded;
- authored world, terrain, gameplay, Visual Scripting, procedural, Environment, template/runtime, and resolved asset data required by the standalone build is preserved;
- source project is not mutated;
- repeated staging replaces stale output.

## P13-T06 — Standalone runtime bootstrap — COMPLETE
Delivered a standalone entry scene/bootstrap with thin runtime adapters feeding the existing Phase 7 `PlaySession`.

Verified behavior:
- editor shell is not instantiated;
- Phase 7 template/runtime modules resolve through the existing registry;
- semantic input is installed through the existing gameplay input map;
- terrain/streaming, gameplay, Visual Scripting, procedural, and Environment paths use existing implementations;
- standalone runtime saves use the existing runtime save-state boundary rather than editor project mutation.

## P13-T07 — Windows export orchestration — COMPLETE
Delivered Windows-first standalone export orchestration including managed preset generation, safe output validation, deterministic staging/output paths, Godot invocation, package promotion, reports, and repeat-export replacement.

Verified behavior:
- Small/Medium/Large Windows projects export successfully;
- a second export replaces stale package files rather than accumulating them;
- failed dependencies/export conditions return explicit failures;
- package includes executable/runtime payload plus manifest/report/attribution outputs.

## P13-T08 — Build → Export UX — COMPLETE
Delivered a compact Build-mode Export control integrated into the canonical workspace rather than a separate export application or permanent enterprise-style toolbar.

Verified behavior:
- Windows target/output/status are visible in the Export panel;
- keyboard/mouse and gamepad focus paths are supported;
- Export is unavailable with no project and blocked during Play/transient placement/invalid states;
- successful export reports the deterministic output location.

## P13-T09 — Automated verification — COMPLETE
Dedicated Phase 13 suites verify behavior rather than symbol presence, including:
- manifest/schema/path/classification contracts;
- source dependency closure;
- Asset Library resolution and missing dependencies;
- license/attribution behavior;
- editor stripping/runtime preservation;
- deterministic/idempotent staging;
- standalone bootstrap reuse of Phase 7 runtime;
- semantic keyboard/gamepad input contracts;
- canonical Export workspace behavior and transient-state blocking;
- inherited Phase 6–12 regressions.

## P13-T10 — Real export evidence and closeout — COMPLETE
The milestone gate completed:
1. representative Small/Medium/Large projects were created/staged/exported;
2. Windows standalone packages were produced;
3. package/report/attribution layout was verified;
4. exports were repeated and stale-file replacement verified;
5. packages were copied to a separate clean-package location;
6. copied executables launched through the existing Phase 7 third-person runtime;
7. keyboard/mouse and gamepad semantic bindings were verified;
8. strict Godot log gates passed;
9. inherited Phase 6–12 regression gates passed;
10. Godot Smoke passed;
11. rendered canonical Build → Export evidence was captured;
12. documentation closeout was completed.

### Verified branch workflow evidence
All five required Phase 13 workflows passed on the completed branch, including the final documentation head:
- Godot Smoke;
- Phase 13 Windows Export;
- Phase 13 Visual Evidence;
- Phase 13 Inherited Regressions;
- Phase 13 Contracts.

### PR-triggered verification
PR #18 also finished with all triggered legacy and current checks green. Several isolated matrix jobs initially failed before tests ran because GitHub-hosted runners could not complete Godot 4.7.1 downloads. The failed jobs were rerun, their downloads succeeded, and their actual contract suites passed with no repository code changes.

## Final gate — SATISFIED
PR #18 was explicitly merged. The resulting signed authoritative `master` was verified as:

`cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`

Phase 13 is closed. Phase 14 may proceed from that exact authoritative commit.
