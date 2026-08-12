# Phase 14 — Scale and Polish Implementation Plan

## Base and branch contract
- Authoritative base: `master` at `cbf5afa2427b3dc3aa9ebb9f27597045b8a148f0`.
- This is the verified signed merge commit for PR #18 — Phase 13 — Export Pipeline.
- Milestone branch: `dev/phase14-scale-polish-milestone`.
- Pre-write compare gate: exact merge base, 0 ahead, 0 behind.
- `main` is obsolete and prohibited as a development base.
- Work continuously on one milestone branch; no task-by-task PRs.
- At completion, open one Phase 14 completion PR to authoritative `master` and do not merge without explicit user authorization.

## Milestone invariant
Phase 14 hardens and polishes the existing product. It must not replace working systems with parallel architectures or expand into unrelated feature breadth.

Optimization must preserve:
- stable IDs and project/save contracts;
- command/Undo/Redo behavior;
- terrain/streaming semantics;
- Asset Library source safety and licensing metadata;
- gameplay/prefab/template/runtime contracts;
- Visual Scripting semantics;
- procedural and Environment behavior;
- AI privacy/transaction guarantees;
- Phase 13 export/runtime reuse guarantees.

Performance wins that weaken correctness, persistence, rollback, export determinism, or authored-data integrity are not acceptable.

## P14-T01 — Performance telemetry, budgets, and presets
Establish reproducible measurement before optimization.

Implement/define:
- deterministic benchmark fixtures for Small/Medium/Large and stress-scale projects;
- frame-time, memory, project-open, save/reopen, Build↔Play, streaming, and export timing instrumentation;
- Low/Balanced/High quality-performance preset contracts;
- explicit per-system budget reporting rather than a single aggregate FPS number;
- stable benchmark output suitable for CI comparisons.

Acceptance:
- benchmarks can be repeated with comparable results;
- preset changes are deterministic and persist as user/project settings only where intended;
- telemetry does not mutate authored content;
- failure thresholds are explicit and documented.

## P14-T02 — World/runtime scale hardening
Profile and optimize existing runtime-heavy systems.

Cover:
- terrain chunk/partition streaming;
- runtime entities and visibility/culling;
- foliage/MultiMesh and procedural scatter;
- splines and generated runtime geometry;
- Environment evaluation/rendering;
- Phase 7 runtime modules and controller path;
- Visual Scripting runtime execution where scale-sensitive.

Acceptance:
- no duplicate runtime architecture;
- deterministic authored output is preserved;
- stress fixtures meet defined memory/frame-time budgets or produce explicit documented exceptions;
- strict Godot logs remain clean.

## P14-T03 — Editor and project-scale responsiveness
Harden large-project authoring workflows.

Cover:
- project startup/open;
- save/reopen/autosave/checkpoint flows;
- Asset Library query/dependency operations;
- large selection/inspector/workspace changes;
- Build↔Play transitions;
- AI bounded project-query surfaces;
- Phase 13 staging/export preparation.

Acceptance:
- long-running work exposes clear status instead of appearing frozen;
- no crash-safety or atomic-save guarantees are removed for speed;
- no authored data is silently skipped to meet timing targets;
- representative Large/stress projects remain interactive under defined budgets.

## P14-T04 — Accessibility foundations
Implement product-wide accessibility behavior using shared contracts rather than one-off workspace fixes.

Cover:
- UI/text scaling and readable minimum sizes;
- focus visibility and contrast;
- reduced-motion behavior;
- non-color-only state/error/status communication;
- keyboard reachability for existing controls;
- persistent accessibility preferences;
- accessible error/validation/status messaging.

Acceptance:
- settings persist without contaminating project-authored data where user-scoped behavior is appropriate;
- core workflows remain usable at supported scaling levels;
- focus indicators remain visible across tool-context colors;
- reduced-motion mode removes or minimizes nonessential motion without breaking feedback.

## P14-T05 — Controller completeness
Close remaining gamepad gaps across the existing application.

Verify and fix:
- Home/New World/project opening;
- Build workspace and placement/editor tools;
- Asset Library;
- Gameplay workspace;
- Visual Scripting;
- procedural/foliage/spline authoring;
- Environment;
- AI workspace;
- Play mode;
- Export;
- dialogs, errors, confirmations, and recovery flows.

Acceptance:
- deterministic focus recovery after modal/transient states;
- no focus traps;
- consistent glyph language;
- remapping behavior remains correct;
- representative authoring and runtime flows can be completed gamepad-only.

## P14-T06 — Touch-ready and adaptive layouts
Add adaptive layout behavior without creating a separate mobile application architecture.

Cover:
- major workspace panels/cards;
- inspector/tool controls;
- Asset drawer/library surfaces;
- modal/dialog layouts;
- Build/Play/AI/Export primary controls;
- minimum hit-target sizing and scroll behavior.

Acceptance:
- keyboard/mouse and gamepad layouts remain first-class;
- adaptive behavior is driven by available space/input context rather than device-specific duplicated screens;
- critical controls never become inaccessible at supported compact sizes;
- density controls continue to work predictably.

## P14-T07 — Canonical visual-parity sweep
Bring the implemented application back into strict alignment with the approved canonical visual direction.

Visual target:
- dark but playful;
- Nintendo-forward interaction character with Apple-like restraint/polish;
- large-card default density with optional denser presentation;
- context-sensitive tool color;
- minimal hidden navigation rather than permanent enterprise chrome;
- consistent rounded geometry, spacing, typography hierarchy, motion, and feedback.

Audit/fix:
- Home/New World;
- core workspace shell;
- Build/Play controls;
- inspector/tool dock;
- Asset Library/drawer;
- Gameplay;
- Visual Scripting;
- procedural/Environment/AI/Export surfaces;
- empty/loading/error/disabled states;
- keyboard, gamepad, accessibility, and adaptive-layout states.

Acceptance:
- remove generic slate/enterprise visual drift;
- no workspace looks like a separately designed product;
- tool-context colors remain coherent and accessible;
- rendered evidence is captured for representative major surfaces.

## P14-T08 — User-facing performance preset integration
Expose performance/quality controls through the existing settings/workspace model.

Acceptance:
- Low/Balanced/High presets map to explicit system settings;
- advanced overrides remain possible where appropriate;
- switching presets does not mutate authored world content;
- project/runtime/export behavior remains deterministic;
- current effective settings are inspectable and testable.

## P14-T09 — Automated verification and evidence
Create dedicated Phase 14 verification for:
- benchmark contract stability;
- performance budget enforcement;
- Small/Medium/Large/stress fixtures;
- save/open/Build↔Play/export responsiveness;
- accessibility preference persistence and behavior;
- keyboard focus and controller navigation/focus recovery;
- adaptive layout behavior;
- visual token/parity regressions;
- quality preset application;
- inherited Phase 6–13 contract/regression gates;
- strict Godot log gates;
- rendered canonical visual evidence.

Tests must verify behavior, not merely symbol existence.

## P14-T10 — Milestone closeout
Before opening the Phase 14 completion PR:
1. run all Phase 14 benchmark/performance gates;
2. run accessibility/controller/adaptive-layout suites;
3. run Small/Medium/Large plus stress-scale verification;
4. run inherited Phase 6–13 regressions;
5. run Godot Smoke and strict log gates;
6. capture rendered UI evidence for representative major workspaces;
7. verify Phase 13 Windows export remains functional after performance/polish changes;
8. document any intentionally accepted performance exceptions with evidence;
9. close `MASTER_IMPLEMENTATION_PLAN.md`, `TASK_BACKLOG.md`, and `CURRENT_HANDOFF.md` to Phase 14 completion state;
10. open one Phase 14 completion PR targeting authoritative `master`.

Do not merge that PR without explicit user authorization. Do not begin Phase 15 until the PR is explicitly merged and the resulting authoritative `master` SHA is verified.
