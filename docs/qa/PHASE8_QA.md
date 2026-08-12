# Phase 8 QA — Visual Scripting

## Candidate verified

Implementation/visual candidate:

`9136c572a8526409e6f6550d79b4afb73adeae30`

Base / merge base:

`06df50b6ffb752731d21f1ced88eb2cf1191f542`

At candidate verification the Phase 8 branch was 15 commits ahead of authoritative `master` and 0 behind.

## Engine

All dedicated Phase 8 contract jobs use:

`Godot 4.7.1.stable.official.a13da4feb`

Dedicated Phase 8 workflows reject `SCRIPT ERROR:` and engine `ERROR:` output.

## Phase 8 contract matrix

Workflow run:

`31568775999` — SUCCESS

All nine suites passed:
- `phase8-foundation`
- `phase8-authoring`
- `phase8-compiler`
- `phase8-runtime`
- `phase8-macros`
- `phase8-workspace`
- `phase8-debugger`
- `phase8-play`
- `phase8-scale`

Coverage includes schema/persistence/corruption, stable identity, universal history and Undo/Redo, compiler type/port/cardinality checks, bounded execution, macro interfaces and recursion guards, real Main-scene GraphEdit authoring, gamepad shortcuts, breakpoint/resume/trace, live Phase 7 PlaySession graph execution, Build-state isolation, and representative scale.

## Representative performance

The exact candidate's scale job reported:

`Phase 8 representative workload: 120 graphs compiled + executed in 17 ms (CI budget 12000 ms).`

The 12,000 ms value is a broad CI regression budget, not an FPS or end-user hardware claim.

Scale log artifact:
- artifact ID `9130473152`
- digest `sha256:c24a7df3d75c60d31771d5756c165b891ad42952b4e6c011036b5e5036a77e83`

## Baseline and inherited smoke

Godot Smoke run:

`31568775977` — SUCCESS

Passed jobs:
- runtime smoke
- Phase 1 visual capture
- Phase 4 Asset Library visual capture
- Phase 5 Terrain visual capture

This verifies that the Phase 8 candidate did not regress the inherited application shell, Asset Library, or Terrain evidence gates covered by the baseline workflow.

## Phase 8 rendered evidence

Workflow run:

`31568776022` — SUCCESS

Visual artifact:
- artifact ID `9130478900`
- digest `sha256:038fec8b994001aab9c09093c2424ff46b91100e7d9077d850280e4487f5e075`

Captured files:
- `01-visual-scripting-graph.png`
- `02-debugger-paused.png`

The capture uses the real Main scene and creates a real project-owned `Door Interaction` event graph. The graph contains Start, two Literal nodes, Add, and Print with real exec/data connections.

Manual inspection confirms:
- Visual Scripting is presented as a compact contextual workspace rather than a dashboard replacement.
- The graph canvas remains legible at 1600×900.
- Exec and data connections are visually distinct.
- Node palette, graph selector, New Event/New Macro, property editor, and debugger remain visible without covering the graph's primary content.
- Paused evidence clearly shows selected `debug.print`, active breakpoint indicator, Resume enabled, and paused stable-node status.
- Existing Build/Play controls and application identity remain visible around the contextual Logic workspace.

## Acceptance result

Phase 8 implementation is verified ready for its single completion PR to authoritative `master`.

Do not merge the Phase 8 completion PR without explicit user authorization. Do not begin Phase 9 until that merge is explicit and the resulting authoritative `master` SHA is verified.
