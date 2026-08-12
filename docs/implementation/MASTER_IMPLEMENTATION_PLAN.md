# Master Implementation Plan

## Phase 0 — Repository and contracts — COMPLETE
- Project skeleton, coding rules, docs, CI, task IDs, test harness, canonical UI reference.
- Stable IDs, command interface, persistence versioning, and module boundaries.

## Phase 1 — App shell and canonical UI foundation — COMPLETE
- Home screen, New World flow, workspace shell, Build|Play switch, inspector, bottom tool dock, asset drawer shell, and gamepad navigation.
- Theme tokens and rendered screenshot-comparison workflow.

## Phase 2 — World project + save foundation — COMPLETE
- Create/open/save projects and Small/Medium/Large profiles.
- Stable entity IDs and command/undo/redo framework.
- Crash-safe autosave/checkpoints and recovery.

## Phase 3 — Runtime placement editor — COMPLETE
- Selection, transforms, duplicate/delete, multi-select, grouping.
- Grid/angle/surface/object/socket snapping and drop-to-ground.
- Ghost placement, contextual toolbar, controller tool wheel, rendered verification.

## Phase 4 — Universal asset library — COMPLETE
- Read-only external source registry, deterministic cataloging/import analysis, thumbnails/search/favorites/collections, and Phase 3 placement handoff.
- Merged by PR #9.

## Phase 5 — Terrain + streaming — COMPLETE
- Terrain sculpting, partition cells, dirty-cell persistence, deterministic streaming, biome hooks, and rendered verification.
- Merged by PR #10.

## Phase 6 — Components, archetypes, prefabs — COMPLETE
- Versioned gameplay composition, archetypes, prefab inheritance/overrides, sockets/attachments, gameplay workspace, and persistence/scale verification.
- Merged by PR #11.

## Phase 7 — Instant Play and templates — COMPLETE
- Disposable Build → Play → Build lifecycle, semantic gameplay input, third-person/FPS foundations, deterministic template system, seven starter templates, module editability, persistence/performance/visual verification.
- Merged by PR #12.

## Phase 8 — Visual scripting — COMPLETE
- Stable schema-v1 graph/node/connection/variable contracts and project-managed crash-safe graph persistence under `visual_scripting/graphs.json`.
- Command-backed graph authoring through the existing universal Undo/Redo history and project dirty-state path.
- Deterministic compiler, bounded interpreter, reusable macros/functions, native GraphEdit Logic workspace, debugger/breakpoints/trace, and Phase 7 PlaySession execution against disposable runtime state.
- Merged by PR #13 at authoritative `master` commit `6ea437f3d5ea1077773ef797e8f5895e84b5a7f1`.

## Phase 9 — Foliage / Procedural / Splines — COMPLETE
- Schema-v1 project-managed procedural registry persisted crash-safely under `procedural/procedural.json`, with stable foliage-set, scatter-layer, stroke, spline, and spline-point identities mirrored into project registries.
- Nondestructive procedural authoring: saved source records, settings, paint strokes, and erase masks are authoritative; generated foliage and spline runtime geometry is disposable derived state.
- Real `MultiMeshInstance3D` foliage batches with deterministic density/spacing/biome/height/slope/scale/yaw/normal rules, Phase 4 Asset Library and Phase 6 inherited-prefab source resolution, terrain coupling, streaming, and automatic regeneration after terrain edits.
- Stable-ID road/path/fence splines with command-backed point authoring, generated `ArrayMesh` road/path ribbons, MultiMesh fence segments, streamed geometry, keyboard/mouse and gamepad authoring, strict regression gates, and rendered evidence.
- Merged by PR #14 at authoritative `master` commit `953d8b500beb1b65485104c85ab9bd5c4ff8224b`.

## Phase 10 — Gameplay Framework Breadth — COMPLETE
Phase 10 was developed as one continuous milestone on `dev/phase10-gameplay-framework-milestone`, created from exactly authoritative `master` commit `953d8b500beb1b65485104c85ab9bd5c4ff8224b`.

The milestone extends the existing Phase 6 gameplay-component contracts and Phase 7 disposable Play runtime rather than creating parallel gameplay systems. Authored Build data remains authoritative; mutable gameplay state is session/runtime state unless explicitly saved through the Phase 10 save-state layer.

Completed milestone breadth:
- stable-ID runtime gameplay-state service initialized from the existing Phase 6 gameplay registry, with validation, disposable Play lifecycle, runtime events, and safe missing-reference handling;
- reusable inventory/item/container operations with capacity, quantity, transfer, pickup, and interaction routing;
- reusable doors plus health/damage/healing/death state and event surfaces without genre-specific combat assumptions;
- basic NPC navigation/AI goals, destinations, waits/idle behavior, target interactions, and deterministic fallback behavior;
- dialogue scaffolding with stable dialogue/conversation/line/participant references, conditions, choices, and runtime progression;
- quest scaffolding with stable quest/objective IDs, progress, completion/failure state, and event-driven updates;
- reusable vehicle runtime state with stable vehicle/seat references, occupancy, enter/exit, throttle/steer/brake semantics, and semantic keyboard/gamepad input;
- explicit save-state components and project-managed runtime snapshots that restore opted-in Play fields without silently mutating authored Build data;
- Visual Scripting-facing gameplay actions/events integrated with the existing Phase 7 semantic input/runtime lifecycle;
- native Gameplay workspace integration with keyboard/mouse and gamepad authoring paths;
- strict Phase 10 contract gates, representative 256-entity/768-component scale regression coverage, Godot smoke coverage, and rendered Phase 10 visual evidence exercising real Gameplay authoring and disposable Play transitions.

Phase 10 was merged by PR #15 at authoritative `master` commit `ac2753f81c9c6be53abe89b102e1f9911a595944`.

## Phase 11 — Environment — COMPLETE
Phase 11 was developed as one continuous milestone on `dev/phase11-environment-milestone`, created from exactly authoritative `master` commit `ac2753f81c9c6be53abe89b102e1f9911a595944`.

Completed milestone breadth:
- schema-v1 authored environment registry persisted crash-safely under `environment/environment.json`, including stable weather-profile, biome-override, and water-hook identities mirrored into project registries;
- command-backed Environment authoring through the existing universal Undo/Redo and project dirty-state path;
- deterministic time-of-day evaluation layered over authored defaults, with configurable Play progression and weather transitions;
- real Godot `WorldEnvironment`/`Environment`, `Sky`/`ProceduralSkyMaterial`, directional-sun, ambient-light, and fog rendering integrated into the existing editor/play viewport;
- reusable weather profiles for sky, light, fog, precipitation/cloud metadata, wind, and water modifiers rather than hardcoded weather modes;
- Phase 5 biome/environment coupling with deterministic precedence, position/cell awareness, streamed-world focus changes, and safe fallback for missing references;
- reusable wind state consumed by the existing Phase 9 procedural runtime without mutating authored foliage/spline data;
- stable water integration descriptors/hooks for future providers rather than a hardcoded water implementation;
- fully disposable Phase 7 Play environment runtimes with authored Build restoration, no leaked Play nodes, and existing gameplay-event routing;
- Phase 8 Visual Scripting Environment nodes for reading state, setting time/weather, and clearing runtime weather overrides;
- native Environment authoring behind the canonical Water dock entry, preserving the existing shell while providing time/weather/fog/wind/biome/water controls with keyboard/mouse and gamepad paths;
- six dedicated Phase 11 contract suites, inherited Phase 6–10 regression coverage, Godot Smoke, strict logs, and rendered evidence.

Phase 11 was merged by PR #16 at authoritative `master` commit `d7245cad68b512fc5cbf9b897bce506ecbb9837d`.

## Phase 12 — AI Creation — IMPLEMENTATION COMPLETE / COMPLETION PR PENDING
Phase 12 was developed as one continuous milestone on `dev/phase12-ai-creation-milestone`, created from exactly authoritative `master` commit `d7245cad68b512fc5cbf9b897bce506ecbb9837d`.

Completed milestone breadth:
- schema-v1 AI request, proposal, action, provider-settings, and execution-history contracts with stable local identities, bounded prompts/context/action counts, and strict untrusted-output validation;
- user-scoped provider settings under `user://polyfork/ai/providers.json`, with local-only/cloud-consent privacy policy and no credential values persisted into projects or AI history;
- real OpenAI-compatible HTTP provider support for loopback/local or HTTPS cloud endpoints, environment-variable credential lookup, cancellation/timeouts, structured content/tool-call parsing, malformed/remote-error handling, and explicit local/cloud disclosure;
- bounded read-only project tools over the real Phase 4 Asset Library and authored project state, including entities, gameplay, terrain/biomes, Visual Scripting, procedural data, Environment state, stable IDs, and sanitized license metadata;
- provider proposals normalized locally so providers cannot select persisted IDs, with sequential proposal-local aliases for newly placed entities and strict live reference/missing-asset checks;
- Suggest mode with bounded read-only provider/tool rounds and zero authored mutation;
- Preview mode with deterministic impact summaries/source-asset lineage and zero authored mutation;
- Execute mode compiled through existing world/gameplay/Visual Scripting/procedural/Environment snapshot commands inside one outer universal transaction, providing all-or-nothing rollback and exactly one Undo/Redo step;
- crash-safe project-managed `ai/history.json` execution history with applied/undone status, exact source Asset Library IDs, save/reopen/corruption checks, and no credentials;
- representative cross-system AI actions for existing-asset/proxy placement and transforms, dependency-aware gameplay composition, validated Visual Scripting graph creation, procedural foliage authoring, and Environment authoring without duplicate subsystem state;
- native AI workspace behind the existing AI dock entry with provider configuration, local/cloud disclosure, Suggest/Preview/Execute, Preview-before-Execute, cancellation/status, keyboard/mouse, and Y/X/A gamepad paths;
- Build-only provider authoring enforcement so AI requests/Execute cannot mutate authored state during Play;
- removal of the unused tracked `.polyforkAPI` token file from the active branch and explicit `.gitignore` protection for local Polyfork token files; historical credential material must still be rotated/revoked separately;
- seven dedicated Phase 12 contract suites covering foundation/privacy/provider parsing, atomic rollback, crash-safe history, cross-system Execute/Undo/Redo, real workspace/gamepad, bounded provider orchestration, and a 256-entity/64-action scale boundary;
- inherited Phase 6–11 regression coverage, Godot Smoke, strict-log gates, and rendered Phase 12 visual evidence for validated Preview, atomic Execute, and complete Undo restoration.

Phase 12 is completion-PR gated. Open one completion PR targeting authoritative `master`; do not merge it without explicit user authorization. Phase 13 remains blocked until the Phase 12 completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.

## Phase 13 — Export pipeline
- Strip editor-only systems.
- Standalone project/build export.
- Dependency/license checks.
- Smoke tests.

## Phase 14 — Scale and polish
- Performance presets.
- Large-world stress passes.
- Accessibility, touch-ready layouts, controller completeness.
- UI visual parity sweep.

## Phase 15 — Multiplayer foundations and collaboration roadmap
- Network identity compatibility.
- Co-op prototype support.
- Competitive template hooks.
- Collaboration design; implementation may be deferred.

## Release rule
Do not start a new phase while critical acceptance criteria from the current phase are unresolved or its required milestone PR is unmerged unless an explicit handoff authorizes parallel work.
