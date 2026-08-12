# Task Backlog

Task IDs use `P##-T##` as internal implementation checkpoints. Pull requests are milestone gates, not task gates, unless a handoff explicitly says otherwise.

## Completed phases 0–13
All Phase 0 through Phase 13 checkpoints are complete and merged on authoritative `master`.

- [x] Phase 0 — Repository and contracts
- [x] Phase 1 — App shell and canonical UI foundation
- [x] Phase 2 — World project + save foundation
- [x] Phase 3 — Runtime Placement Editor
- [x] Phase 4 — Universal Asset Library — PR #9
- [x] Phase 5 — Terrain + Streaming — PR #10
- [x] Phase 6 — Components, Archetypes, Prefabs — PR #11
- [x] Phase 7 — Instant Play + Templates — PR #12
- [x] Phase 8 — Visual Scripting — PR #13
- [x] Phase 9 — Foliage / Procedural / Splines — PR #14
- [x] Phase 10 — Gameplay Framework Breadth — PR #15
- [x] Phase 11 — Environment — PR #16
- [x] Phase 12 — AI Creation — PR #17
- [x] Phase 13 — Export Pipeline — PR #18 at `cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`

## Phase 14 — Scale and Polish — COMPLETE / PR #19 OPEN
Milestone branch:

`dev/phase14-scale-polish-milestone`

Base:

`cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`

Verified implementation head before documentation-only closeout:

`b15439461cfae5d41d5951b5af808d20f2bb5f1b`

- [x] P14-T01 Establish performance telemetry, reproducible benchmark fixtures, explicit budgets, and Low/Balanced/High quality-performance preset contracts
- [x] P14-T02 Harden terrain/streaming and procedural/foliage runtime hot paths while preserving authored semantics; integrate policy-aware Play/Environment cadence
- [x] P14-T03 Harden large-project responsiveness with no-op/incremental runtime work, timed operation status, performance-aware workspace refresh, and scale/save/Build↔Play/export regression coverage
- [x] P14-T04 Implement shared accessibility foundations for UI scaling/readability, visible focus, reduced-motion preference, minimum interaction targets, keyboard reachability, and persistent user-only settings
- [x] P14-T05 Complete controller/input-context polish with deterministic focus navigation, consistent keyboard/gamepad hints/glyph language, and inherited gamepad authoring/runtime verification
- [x] P14-T06 Add touch-ready/adaptive Home, Settings, and workspace behavior while preserving keyboard/mouse and gamepad parity and avoiding a separate mobile architecture
- [x] P14-T07 Complete canonical visual-parity sweep for new/changed surfaces, retain the dark playful Nintendo/Apple-inspired design language, and capture/inspect full and compact rendered evidence
- [x] P14-T08 Integrate performance preset controls into Settings, editor Play/procedural behavior, Export, packaged runtime policy, and standalone PlaySession with deterministic legacy fallback
- [x] P14-T09 Add Phase 14 contracts, Small/Medium/Large/Stress scale gate, inherited Phase 6–13 gate, Godot Smoke, rendered evidence, and profiled Windows clean-package export/launch gate
- [x] P14-T10 Open the single Phase 14 completion PR targeting authoritative `master` — PR #19 OPEN; do not merge without explicit user authorization

Verification on `b15439461cfae5d41d5951b5af808d20f2bb5f1b`:
- Phase 14 Contracts — run `31626516078` — PASS
- Phase 14 Scale Stress — run `31626516104` — PASS
- Phase 14 Inherited Regressions — run `31626516105` — PASS
- Godot Smoke — run `31626516120` — PASS
- Phase 14 Visual Evidence — run `31626516053` — PASS
- Phase 14 Windows Export — run `31626516187` — PASS

Windows profile matrix:
- Small → Low — clean-package launch PASS
- Medium → Balanced — clean-package launch PASS
- Large → High — clean-package launch PASS

No accepted Phase 14 performance exceptions remain open.

Detailed checkpoint closeout is in `docs/implementation/PHASE14_SCALE_POLISH_PLAN.md`.

## Later phases
Phase 15 is blocked. Do not begin it until PR #19 is explicitly merged into authoritative `master` with user authorization and the resulting `master` SHA is verified.
