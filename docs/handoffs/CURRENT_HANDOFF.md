# POLYFORK PROJECT — PHASE 8 COMPLETION HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authoritative branch

The real project lives on:

`master`

Authoritative `master` before the Phase 8 merge:

`06df50b6ffb752731d21f1ced88eb2cf1191f542`

This is the verified merge commit for PR #12 — Phase 7 — Instant Play + Templates.

The repository default branch `main` remains obsolete starter code.

**Never develop from `main`.**

## Current milestone status

Phases 0 through 7 are merged on authoritative `master`.

Phase 8 — Visual Scripting — is implementation-complete and verified on:

`dev/phase8-visual-scripting-milestone`

All internal checkpoints P08-T01 through P08-T08 are complete.

Phase 8 completion PR:

- PR #13 — `https://github.com/DocDamage/polyfork-project/pull/13`
- Title: `Phase 8 — Visual Scripting`
- Base: `master`
- Head: `dev/phase8-visual-scripting-milestone`
- Status: **DRAFT / OPEN — DO NOT MERGE WITHOUT EXPLICIT USER AUTHORIZATION**

Verified implementation/visual candidate before documentation closeout:

`9136c572a8526409e6f6550d79b4afb73adeae30`

Verified documentation-only pre-PR head:

`5f6ab9c41fd07b8d1c9e12ca2c3e94ff8dabb0e5`

This handoff-only PR-number commit is the final pre-merge branch mutation. All workflows on its resulting SHA must be green before PR #13 is considered merge-ready.

## Branch integrity before this handoff-only commit

- authoritative `master`: `06df50b6ffb752731d21f1ced88eb2cf1191f542`
- merge base: `06df50b6ffb752731d21f1ced88eb2cf1191f542`
- Phase 8 branch: ahead only
- ahead of `master`: 16 commits
- behind `master`: 0 commits

No obsolete `main` ancestry was used.

## Verified pre-PR runs

### Phase 8 Contracts
Run `31569145553` — SUCCESS

Passing suites:
- foundation
- authoring
- compiler
- runtime
- macros
- workspace
- debugger
- play
- scale

### Godot Smoke
Run `31569145551` — SUCCESS

Passing inherited jobs:
- runtime smoke
- Phase 1 visual capture
- Phase 4 Asset Library visual capture
- Phase 5 Terrain visual capture

### Phase 8 Visual Evidence
Run `31569145576` — SUCCESS

Artifact:
- ID `9130618921`
- digest `sha256:7d80d1d41f61ce543c47c2eb40b80d452f80468fecf41dd274cfaeb8426fe0c0`

All dedicated Phase 8 verification runs use Godot `4.7.1.stable.official.a13da4feb` and reject `SCRIPT ERROR:` / engine `ERROR:` output.

Representative scale result: 120 graphs compiled and executed in 17 ms against a broad 12,000 ms CI regression budget. This is a regression proxy, not an FPS claim.

## Phase 8 delivered

### Graph contracts and persistence
- schema-v1 project graph registry
- crash-safe `visual_scripting/graphs.json`
- stable graph/node/connection/variable identity
- mirrored `WorldProject.registries.visual_graph_ids`
- corrupt/future-schema/duplicate/invalid references fail closed

### Command-backed graph authoring
- graph create/delete/configure
- node create/delete/move/configure
- connection/disconnection
- graph variables
- persistence rollback on failed writes
- shared universal Undo/Redo and project dirty-state path

### Compiler and bounded runtime
- deterministic executable plans
- exec/data port validation
- data type compatibility
- input cardinality validation
- event entry validation
- data dependency-cycle rejection
- hard runtime step budget
- variables, flow, math, logic, entity position, and debug trace

### Macros/functions
- Macro Entry / Macro Return
- typed macro interfaces
- dynamic Call Macro ports
- nested execution and output propagation
- missing-target rejection
- compile-time dependency-cycle rejection
- independent runtime recursion guard

### Logic workspace
- bottom dock exposes `Logic`
- native Godot `GraphEdit` / `GraphNode`
- searchable node palette
- event/macro creation
- native connect/disconnect/delete/move
- JSON property editing
- gamepad X/Y authoring shortcuts
- reliable Back/Cancel and contextual-tool switching
- shared existing app theme and workspace rather than a parallel editor fork

### Debugger
- Validate
- Run
- Breakpoint
- Resume
- stable node selection
- paused/completed/error state
- live debug trace/status
- resume continues existing interpreter state rather than restarting

### Real Play integration
- active project's graph service is the Phase 7 PlaySession graph provider
- project registry compiles at Play entry
- enabled event graphs execute in deterministic graph-ID order
- stable entity operations target only disposable Play runtime state
- graph failure rejects Play startup and follows the existing rollback path
- authored Build project data remains unchanged
- real Main-scene integration test verifies graph execution count and clean return to Build

### Template graph references
- template graph references must be stable project graph UUIDs
- missing and malformed references fail closed
- no scene paths or hidden template-specific editor forks

## Rendered evidence inspected

`01-visual-scripting-graph.png` shows a real connected Start/Literal/Add/Print event graph in the native Logic workspace.

`02-debugger-paused.png` shows the same graph paused at a real `debug.print` breakpoint with Breakpoint active, Resume enabled, stable-node status, and the debugger toolbar visible.

The captures were manually inspected in addition to the automated rendered PASS gate.

## Documentation closeout

Updated for actual Phase 8 implementation:
- `docs/implementation/TASK_BACKLOG.md`
- `docs/implementation/MASTER_IMPLEMENTATION_PLAN.md`
- `docs/systems/VISUAL_SCRIPTING.md`
- `docs/qa/PHASE8_QA.md`
- this handoff

## Next action

1. verify the final handoff-only PR head remains green across Phase 8, baseline, and all PR-triggered inherited gates;
2. review PR #13 and its checks;
3. merge only after explicit user authorization.

After PR #13 is explicitly merged, verify the resulting authoritative `master` SHA before creating a Phase 9 milestone branch.

**Do not begin Phase 9 before PR #13 is explicitly merged.**
