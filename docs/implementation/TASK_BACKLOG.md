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
Milestone review gate: **complete P03-T02 through P03-T09 continuously on one milestone branch, then open one Phase 3 completion PR.** P03-T01 is already merged and is the baseline for this milestone.

- [x] P03-T01 Implement runtime entity scene bridge and single-selection foundation
- [ ] P03-T02 Implement command-backed object placement and ghost preview
- [ ] P03-T03 Implement command-backed move/rotate/scale editing and gizmo state
- [ ] P03-T04 Implement command-backed duplicate and delete operations
- [ ] P03-T05 Implement multi-select and grouping foundations
- [ ] P03-T06 Implement grid and angle snapping
- [ ] P03-T07 Implement surface/object/socket snapping and drop-to-ground
- [ ] P03-T08 Implement contextual placement toolbar and controller tool wheel
- [ ] P03-T09 Complete Phase 3 integration, gamepad, failure-path, and visual verification

## Later phases
Before beginning a later phase, decompose it into implementation-sized internal tasks. The handoff should authorize a meaningful milestone range—normally a full phase when dependencies permit—rather than forcing one PR per task. Use intermediate commits and CI runs inside the milestone, then open one PR at the milestone boundary.
