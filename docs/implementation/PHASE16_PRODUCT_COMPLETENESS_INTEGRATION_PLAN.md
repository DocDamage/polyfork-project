# Phase 16 — Inherited Product Completeness and Integration Closure

## Status
Defined from a source-level audit of authoritative `master` `b4b5e88ef11ba514b1c8755e45e1a9de5cf04613` and authorized for continuous implementation on `dev/phase16-milestone`.

See `docs/qa/PHASE16_INHERITED_COMPLETENESS_AUDIT.md` for the evidence that invalidated the earlier release-candidate assumption.

## Milestone goal
Close the verified creator-facing and cross-phase implementation gaps inherited from Phases 1–11, strengthen the tests that previously allowed those gaps to pass, and restore agreement between actual product behavior and the authoritative product requirements before release packaging begins.

## P16-T01 — Complete application-shell creator routes
Deliver real in-app surfaces and navigation for:
- My Worlds: list persisted projects, open a selected project, deterministic empty state;
- Templates: browse built-in template manifests and start New World with a selected template;
- Asset Library: open a library-management surface even when no world is active, including registered source roots and scan status.

All routes must preserve canonical styling, keyboard/gamepad focus, and back navigation.

## P16-T02 — Complete New World biome selection
Deliver creation-time biome selection with a safe default and persist the selected biome into project/runtime configuration. The selected biome must be applied through the existing terrain/environment contracts when a project is activated; no parallel biome system.

## P16-T03 — Replace fake thumbnails and deepen Asset Library inspection
Replace hash-art placeholders with real asset depiction:
- supported 3D assets/scenes render in an offscreen thumbnail studio;
- image/texture assets use decoded image previews;
- unsupported/unrenderable sources use an explicit fallback state rather than pretending to depict the asset.

Expand analyzer metadata where deterministically available:
- bounds/dimensions;
- material/texture counts/details;
- animation/skeleton counts;
- collision/LOD indicators;
- source/file/runtime memory estimates.

Preserve source folders as read-only.

## P16-T04 — Add deterministic semantic-style catalog search
Add a local, offline semantic search layer that ranks records using normalized token/tag/metadata concepts and synonyms without requiring cloud embeddings. Exact/lexical matches remain strongly weighted. The API must be extensible to future embedding providers but the shipped path remains local-first and deterministic.

## P16-T05 — Finish viewport authoring interaction
Using the existing editor session/command boundaries, deliver:
- free-fly authoring camera;
- switchable third-person orbit authoring camera;
- visible move/rotate/scale gizmo handles;
- viewport marquee/box selection;
- keyboard/mouse and controller-compatible camera/tool switching;
- no mutation outside command/Undo/Redo ownership.

## P16-T06 — Complete snapping and grounding integration
Deliver:
- vertex snapping from real runtime mesh geometry where available;
- surface-normal orientation alignment;
- Phase 6 authored-socket snapping using actual socket local transforms resolved onto placed entity transforms;
- terrain/geometry-aware Drop-to-Ground using collision/terrain resolution rather than a fixed Y value.

Add cross-phase tests proving Phase 3 placement consumes Phase 6 sockets and Phase 5 terrain.

## P16-T07 — Promote later gameplay systems into built-in templates
Update runtime-module contracts and built-in templates so existing Phase 10 capabilities are actually represented in starter experiences:
- RPG: inventory + dialogue + quests;
- Survival: inventory/health-oriented starter capability;
- Driving: vehicle runtime capability;
- FPS/Third-Person keep their existing controller and multiplayer behavior.

Use existing gameplay services; do not fork template-specific engines.

## P16-T08 — Complete water provider integration
Add a provider registry/adapter boundary that consumes existing Environment water-hook records. Provide at least one project-owned basic water provider and an imported-scene provider path so owned/imported water assets can be instantiated and configured at runtime. Provider failure must be explicit and non-destructive.

## P16-T09 — Close test gaps and inherited regressions
Add focused contracts/runtime evidence for:
- all primary Home routes;
- biome creation/persistence/application;
- real thumbnail depiction/fallback semantics;
- analyzer metadata and semantic ranking;
- camera/gizmo/box-selection behavior;
- vertex/normal/socket/drop-to-ground integration;
- template promotion;
- water provider consumption.

Then run inherited Phase 6–15 regressions, Godot Smoke, scale stress, and relevant export/multiplayer gates.

## P16-T10 — Visual evidence and closeout
Capture and inspect running-app evidence at 1600×900 and 1024×640 for:
- Home/My Worlds/Templates/Asset Library route surfaces;
- New World biome selection;
- editor viewport camera/gizmo/selection state;
- real Asset Library thumbnails;
- water/template integration where visually meaningful.

Update canonical docs to reflect actual verified behavior and open one Phase 16 completion PR to `master`.

## Explicit non-goals
- release-candidate packaging of PlayWorld Studio itself; deferred until after this milestone;
- production collaborative editing;
- cloud matchmaking/relay/auth/voice/anti-cheat/rollback/dedicated-server infrastructure;
- arbitrary FBX repair;
- cloud semantic-search requirement;
- replacement of `PlaySession`, command history, stable IDs, Asset Library contracts, or save/export architecture.

## Required completion evidence
- Phase 16 Contracts — PASS;
- Phase 16 Inherited Regressions — PASS;
- Godot Smoke — PASS;
- Phase 16 Visual Evidence — PASS and inspected;
- relevant Windows game-export and multiplayer-export inherited gates — PASS where affected;
- no known inherited gap listed in the Phase 16 audit remains open;
- one Phase 16 completion PR targets authoritative `master`.
