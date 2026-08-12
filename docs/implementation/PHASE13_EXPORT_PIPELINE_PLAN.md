# Phase 13 — Export Pipeline Implementation Plan

## Base and branch contract
- Authoritative base: `master` at `b2a97a6cea52c6620f2b826a390a1d2d531ad81e`.
- Milestone branch: `dev/phase13-export-pipeline-milestone`.
- Pre-write compare gate: exact merge base, 0 ahead, 0 behind.
- `main` is obsolete and prohibited as a development base.
- One milestone PR only; do not merge without explicit authorization.

## Architectural invariant
Export is packaging and runtime bootstrapping, not a second engine. Exported games must reuse the Phase 7 Play/runtime foundation and existing systems for world data, terrain/streaming, gameplay, templates/modules, Visual Scripting, procedural content, Environment, and semantic input.

Editor-only systems may be omitted from the staged/exported project, but runtime-required code cannot be duplicated or reimplemented merely for export.

## P13-T01 — Contracts and package model
Implement schema-v1 contracts for:
- export manifest and build identity;
- target/platform settings (Windows first);
- deterministic package paths;
- runtime/editor classification;
- dependency entries and source lineage;
- license/attribution entries;
- validation findings;
- export result/report metadata.

Acceptance:
- strict schema/version validation;
- deterministic serialization/order;
- unsafe/absolute traversal-style package paths rejected;
- unknown target/runtime class rejected;
- manifest contains no local secret/provider credential values.

## P13-T02 — Dependency discovery
Discover runtime dependencies from the real authored project rather than scanning arbitrary editor state.

Include references from:
- world entities and placed asset IDs;
- Phase 6 gameplay/prefab definitions and attachments;
- Phase 7 selected template and runtime modules;
- Phase 8 Visual Scripting graphs/macros and runtime references;
- Phase 9 foliage/scatter/spline source references;
- Phase 11 Environment/water integration descriptors where they identify shipped resources;
- terrain/project-managed runtime data required for standalone boot.

Acceptance:
- stable-ID based, deterministic, de-duplicated results;
- no dependency inferred from editor selection/history/UI state;
- missing references return explicit findings rather than silent omission.

## P13-T03 — Asset Library resolution
Resolve external dependencies through the existing Phase 4 catalog/import metadata.

Acceptance:
- external source folders stay read-only;
- shipped copies are staged into project-managed export space;
- source asset ID and source path lineage retained in the report;
- unavailable/missing required asset blocks export;
- no arbitrary source-folder bulk copy.

## P13-T04 — Licensing and attribution
Aggregate license/attribution data for shipped dependencies.

Acceptance:
- deterministic deduplication/order;
- preserve author/source/license fields already known to the Asset Library;
- unknown or missing license data is reported explicitly;
- never invent a license grant or compatibility claim;
- generate human-readable attribution plus machine-readable report data.

## P13-T05 — Deterministic staging and stripping
Build a staging tree from an allowlisted runtime model.

Runtime-required examples:
- Phase 7 runtime/session/controller and semantic input code;
- world/project records needed to load the authored game;
- terrain/streaming runtime;
- gameplay runtime primitives and opted-in save-state behavior;
- Visual Scripting compiler/interpreter/runtime session as required;
- procedural runtime generation/source data;
- Environment evaluator/render/runtime;
- resolved templates/runtime modules;
- resolved shipped assets.

Editor-only examples:
- Home/New World/editor workspace scenes;
- inspector/tool panels/gizmos/selection/placement ghost;
- authoring commands and Undo/Redo history where not required at runtime;
- AI provider/workspace/configuration/orchestration;
- thumbnail/browser/source-scanning UI and authoring caches;
- editor evidence/test data.

Acceptance:
- classification is explicit and testable, not filename-guessing at export time;
- staging is deterministic for the same project/config;
- authoring-only files are absent;
- all required runtime files/data are present;
- source project is never mutated.

## P13-T06 — Standalone runtime bootstrap
Add an exported entry scene/bootstrap that loads the staged authored project and enters the existing Phase 7 runtime path directly.

Acceptance:
- no editor shell is instantiated;
- selected Phase 7 template/runtime modules resolve normally;
- semantic input is installed for keyboard/mouse and gamepad;
- terrain/streaming, gameplay, Visual Scripting, procedural, and Environment runtime integrations use their existing implementations;
- runtime mutable state remains disposable or save-state managed according to existing contracts.

## P13-T07 — Windows export orchestration
Windows is the first supported standalone target.

Implement:
- generated/managed Godot export preset contract;
- deterministic staging/output directories;
- safe output-path validation;
- Godot command/export invocation boundary with actionable exit/error reporting;
- repeat-export replacement/idempotency semantics;
- deterministic report/artifact naming.

Acceptance:
- second identical export does not accumulate stale files;
- failed export leaves an explicit failure report and does not masquerade as success;
- editor project remains intact;
- package contains standalone executable/PCK or equivalent Godot Windows artifacts plus attribution/report files.

## P13-T08 — Build → Export UX
Expose export from the existing canonical application shell without adding permanent enterprise-style chrome.

Acceptance:
- clear Windows target/output/status controls;
- keyboard/mouse path;
- gamepad reachable path;
- export disabled/blocked for no project, Play-active/transient states, validation failure, or unresolved dependencies;
- success reveals the deterministic output location/report.

## P13-T09 — Automated verification
Add dedicated Phase 13 suites for:
- manifest/schema/path/classification contracts;
- dependency discovery and de-duplication;
- Phase 4 asset resolution and missing dependency failures;
- licensing/attribution aggregation;
- editor stripping/runtime preservation;
- deterministic/idempotent staging;
- standalone bootstrap reusing Phase 7 runtime;
- Small/Medium/Large representative project manifests/staging;
- keyboard/gamepad input contract preservation;
- inherited Phase 6–12 regressions and strict Godot log gates.

Tests must verify behavior, not merely symbol existence.

## P13-T10 — Real export evidence and closeout
Run the real Windows milestone gate:
1. create/open representative project;
2. Build/save;
3. export;
4. inspect package structure/report/attributions;
5. launch standalone build without the editor shell;
6. verify runtime world/template path, keyboard/mouse and gamepad semantics;
7. verify strict logs;
8. repeat export and verify deterministic replacement/idempotency;
9. run representative Small/Medium/Large coverage;
10. retain rendered/exported runtime evidence;
11. run inherited Phase 6–12 regression gates and Godot Smoke;
12. close documentation and open one Phase 13 completion PR.

Do not merge that PR without explicit user authorization. Do not begin Phase 14 before merge verification.
