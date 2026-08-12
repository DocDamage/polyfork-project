# Task Backlog

Task IDs use `P##-T##` as internal implementation checkpoints. Pull requests are milestone gates, not task gates, unless a handoff explicitly says otherwise.

## Phase 0
- [x] P00-T01 Create Godot 4.7.x project and repository structure
- [x] P00-T02 Add coding/documentation rules
- [x] P00-T03 Define persistent ID and schema-version conventions
- [x] P00-T04 Implement test harness and runtime smoke-test scene
- [x] P00-T05 Add canonical UI visual reference and comparison checklist

## Phase 1
- [x] P01-T01 Implement theme/tokens
- [x] P01-T02 Implement Home screen
- [x] P01-T03 Implement Create New World flow
- [x] P01-T04 Implement main workspace shell
- [x] P01-T05 Implement Build|Play switch UI
- [x] P01-T06 Implement right inspector shell
- [x] P01-T07 Implement bottom category dock and asset drawer shell
- [x] P01-T08 Implement keyboard/mouse + gamepad navigation
- [x] P01-T09 Screenshot parity review against canonical reference

## Phase 2 — World project + save foundation
- [x] P02-T01 Implement stable ID utility and Small/Medium/Large world-profile contracts
- [x] P02-T02 Implement world-project model and atomic create/open/save repository
- [x] P02-T03 Integrate New World creation with persistent projects and project reopening
- [x] P02-T04 Implement stable world-entity record and registry foundation
- [x] P02-T05 Implement command, transaction, undo, and redo framework
- [x] P02-T06 Implement crash-safe autosave and checkpoint recovery
- [x] P02-T07 Complete Phase 2 integration tests and persistence hardening

## Phase 3 — Runtime Placement Editor
Phase 3 is complete and merged on authoritative `master`.

- [x] P03-T01 Implement runtime entity scene bridge and single-selection foundation
- [x] P03-T02 Implement command-backed object placement and ghost preview
- [x] P03-T03 Implement command-backed move/rotate/scale editing and gizmo state
- [x] P03-T04 Implement command-backed duplicate and delete operations
- [x] P03-T05 Implement multi-select and grouping foundations
- [x] P03-T06 Implement grid and angle snapping
- [x] P03-T07 Implement surface/object/socket snapping and drop-to-ground
- [x] P03-T08 Implement contextual placement toolbar and controller tool wheel
- [x] P03-T09 Complete Phase 3 integration, gamepad, failure-path, and visual verification

## Phase 4 — Universal Asset Library
Phase 4 is complete and merged on authoritative `master` by PR #9.

- [x] P04-T01 Implement read-only source-folder registry and source contracts
- [x] P04-T02 Implement incremental scanner, hashing, and stable asset-ID reconciliation
- [x] P04-T03 Implement GLB/GLTF and Godot scene analysis/import support
- [x] P04-T04 Implement asset metadata, licensing, and catalog persistence contracts
- [x] P04-T05 Implement thumbnail generation, cache invalidation, and failure handling
- [x] P04-T06 Implement large-card asset browser, search, filters, and favorites
- [x] P04-T07 Implement collections, duplicate detection, source/license details, and placement handoff
- [x] P04-T08 Complete Phase 4 integration, scale, gamepad, failure-path, and visual verification

## Phase 5 — Terrain + Streaming
Phase 5 is complete and merged on authoritative `master` by PR #10.

- [x] P05-T01 Implement versioned terrain/biome/cell persistence contracts and stable cell identity
- [x] P05-T02 Implement deterministic runtime terrain chunk mesh generation and editor viewport integration
- [x] P05-T03 Implement command-backed runtime terrain sculpt brushes with undo/redo and dirty-state integration
- [x] P05-T04 Implement world partition topology derived from Small/Medium/Large world profiles
- [x] P05-T05 Implement crash-safe dirty-cell persistence, reload, checkpoint/recovery behavior, and corruption failure paths
- [x] P05-T06 Implement deterministic streaming manager load/unload policy with stable cross-cell references
- [x] P05-T07 Implement biome rule-set data, terrain material hooks, and biome assignment/editing foundations
- [x] P05-T08 Complete Phase 5 integration, scale/performance, gamepad, failure-path, persistence, streaming, and rendered visual verification

## Phase 6 — Components, Archetypes, Prefabs
Phase 6 is complete and merged on authoritative `master` by PR #11.

- [x] P06-T01 Implement versioned component-definition, component-instance, archetype, prefab, socket, and attachment persistence contracts
- [x] P06-T02 Implement the initial reusable component registry with defaults, dependencies, conflicts, and validation
- [x] P06-T03 Implement command-backed add/remove/configure component workflows for existing world entities
- [x] P06-T04 Implement data-driven archetype registry and reversible archetype conversion/application flow
- [x] P06-T05 Implement prefab save/snapshot, managed prefab repository, and stable-ID prefab instantiation through the existing placement/runtime systems
- [x] P06-T06 Implement prefab inheritance, derived prefabs, meaningful per-instance overrides, and deterministic effective-value resolution
- [x] P06-T07 Implement named typed sockets, socket editing, command-backed attachments, and runtime attachment resolution without path-based identity
- [x] P06-T08 Complete Phase 6 workspace, persistence/restart, scale, keyboard/mouse, gamepad, failure-path, inheritance, attachment, and rendered visual verification

## Phase 7 — Instant Play + Templates
Phase 7 is complete and merged on authoritative `master` by PR #12.

- [x] P07-T01 Implement versioned template manifests, registry, runtime-module resolution, validation, and failure-safe application
- [x] P07-T02 Implement deterministic starter materialization, stable starter identity, reusable Player archetype, and project-managed template configuration
- [x] P07-T03 Implement isolated Build → Play → Build lifecycle, authored-state protection, selection restoration, autosave suspension, and semantic gameplay-input ownership
- [x] P07-T04 Implement reusable third-person movement/camera/controller foundation on real Phase 5 terrain collision
- [x] P07-T05 Implement reusable first-person movement/camera/controller foundation on the same runtime and semantic input layer
- [x] P07-T06 Deliver Blank Sandbox, Third-Person Adventure, FPS, Survival, RPG, Driving, and Walking Simulator manifests without genre-locking projects
- [x] P07-T07 Verify save/reopen identity, module editability, failure rollback, repeated Play transitions, streaming compatibility, and representative performance
- [x] P07-T08 Complete keyboard/mouse, gamepad, strict-log, inherited regression, and rendered visual verification for Build/Play and both playable controller foundations

## Phase 8 — Visual Scripting
Phase 8 implementation and verification are complete on `dev/phase8-visual-scripting-milestone`. The single completion PR targeting authoritative `master` is the remaining milestone gate.

- [x] P08-T01 Implement schema-v1 graph contracts, stable graph/node/connection identity, built-in node definitions, and crash-safe project graph repository
- [x] P08-T02 Implement command-backed graph/node/connection/variable authoring integrated with the existing universal Undo/Redo history
- [x] P08-T03 Implement deterministic graph compiler, port/type validation, dependency validation, and executable-plan generation
- [x] P08-T04 Implement runtime interpreter and initial executable event/flow/value/math/logic/entity/debug node set with bounded execution
- [x] P08-T05 Implement reusable macro/function graphs, parameter mapping, nested execution, missing-reference handling, and recursion/cycle guards
- [x] P08-T06 Implement compact GraphEdit-based visual scripting workspace with search/add/connect/delete/configure, keyboard/mouse, and gamepad authoring paths
- [x] P08-T07 Implement debugger/validation UX with trace, breakpoints, paused/error state, runtime diagnostics, and template graph-reference validation
- [x] P08-T08 Complete save/reopen, undo/redo, failure/corruption, live Play integration, scale/performance, strict-log, gamepad, inherited regression, and rendered visual verification

## Later phases
Before beginning a later phase, decompose it into implementation-sized internal tasks. Use intermediate commits and CI runs inside the milestone, then open one PR at the milestone boundary.

Do not begin Phase 9 until the Phase 8 completion PR is explicitly merged into authoritative `master`.
