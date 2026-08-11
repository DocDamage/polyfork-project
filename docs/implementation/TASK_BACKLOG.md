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
Phase 4 implementation is complete and verified on `dev/phase4-universal-asset-library-milestone`. The milestone remains merge-gated: one Phase 4 completion PR must target authoritative `master`, and Phase 5 may not begin until that PR is explicitly merged.

- [x] P04-T01 Implement read-only source-folder registry and source contracts
- [x] P04-T02 Implement incremental scanner, hashing, and stable asset-ID reconciliation
- [x] P04-T03 Implement GLB/GLTF and Godot scene analysis/import support
- [x] P04-T04 Implement asset metadata, licensing, and catalog persistence contracts
- [x] P04-T05 Implement thumbnail generation, cache invalidation, and failure handling
- [x] P04-T06 Implement large-card asset browser, search, filters, and favorites
- [x] P04-T07 Implement collections, duplicate detection, source/license details, and placement handoff
- [x] P04-T08 Complete Phase 4 integration, scale, gamepad, failure-path, and visual verification

## Later phases
Before beginning a later phase, decompose it into implementation-sized internal tasks. The handoff should authorize a meaningful milestone range—normally a full phase when dependencies permit—rather than forcing one PR per task. Use intermediate commits and CI runs inside the milestone, then open one PR at the milestone boundary.

Phase 5 is not authorized while the Phase 4 completion PR remains unmerged.
