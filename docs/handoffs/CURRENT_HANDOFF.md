# POLYFORK PROJECT — PHASE 5 HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authoritative branch

The real project lives on:

`master`

Current authoritative `master`:

`a7788d6806375bea415cc835be71754e951229c0`

PR #9 — **Phase 4 — Universal Asset Library** — is merged into that commit.

The repository default branch `main` remains obsolete starter code.

**Never develop from `main`.**

## Current project state

Phases 0 through 4 are complete and merged.

Phase 4 delivered:

- strictly read-only external asset source folders
- deterministic incremental scanning and SHA-256 indexing
- stable asset-ID reconciliation across ordinary rescans and provable moves
- GLTF, GLB, Godot `.tscn`, and Godot `.scn` analysis/import support
- project-managed derived imports, thumbnails, and caches
- source/license metadata persistence
- favorites, collections, duplicate detection, search, and filters
- large-card default browser plus compact density
- keyboard/mouse and gamepad Asset Library workflows
- real Asset Library → Phase 3 ghost → `PlaceEntityCommand` placement handoff
- asset-backed runtime visuals with safe missing-source proxy fallback
- 131-asset scale/incremental verification
- rendered Phase 4 visual evidence

## Development workflow

The project uses **milestone-based development**, not one PR per small task.

For an authorized milestone:

1. Start from current authoritative `master`.
2. Create one focused milestone branch.
3. Work continuously through the entire authorized task range.
4. Make internal commits and run CI whenever useful.
5. Do **not** stop at individual task boundaries.
6. Do **not** open per-task PRs.
7. Fix failures without weakening tests.
8. Update architecture, backlog, and handoff documentation during milestone closeout.
9. Open **one PR only when the entire milestone is complete and verified**.
10. Never merge the milestone PR without explicit user authorization.

A genuine external blocker may justify an earlier review point, but ordinary implementation failures do not.

# NEXT AUTHORIZED MILESTONE

## Phase 5 — Terrain + Streaming

Milestone branch already created from authoritative `master`:

`dev/phase5-terrain-streaming-milestone`

Complete the entire Phase 5 range continuously:

- **P05-T01** — Versioned terrain/biome/cell persistence contracts and stable cell identity
- **P05-T02** — Deterministic runtime terrain chunk mesh generation and editor viewport integration
- **P05-T03** — Command-backed runtime terrain sculpt brushes with undo/redo and dirty-state integration
- **P05-T04** — World partition topology derived from Small/Medium/Large world profiles
- **P05-T05** — Crash-safe dirty-cell persistence, reload, checkpoint, and corruption recovery behavior
- **P05-T06** — Deterministic streaming manager load/unload policy with stable cross-cell references
- **P05-T07** — Biome rule-set data, terrain material hooks, and biome assignment/editing foundations
- **P05-T08** — Phase 5 integration, scale/performance, gamepad, failure-path, persistence, streaming, and rendered visual verification

Use **one Phase 5 milestone branch** and **one Phase 5 completion PR**.

Do not stop for PR review between P05-T01 and P05-T08.

## Phase 5 product requirements

Phase 5 must satisfy the existing product requirements:

- Small worlds represent the existing 1–2 km² profile.
- Medium worlds represent the existing 4–16 km² profile.
- Large worlds start at 16+ km² and are streamed.
- World size remains chosen before terrain creation.
- Terrain must be sculptable at runtime.
- Large worlds must be partitioned into streamable cells/chunks.
- Biomes are rule sets, not baked art dependencies.
- Biome presets may configure terrain material hooks and future foliage/environment defaults without prematurely implementing later foliage/environment phases.
- Representative medium-world work must preserve the 60 FPS target on an RTX 3060-class desktop at 1080p using the standard preset.

## Phase 5 architecture constraints

- Terrain persistence must use stable IDs and versioned schemas; never use scene-tree paths, node names, or array positions as persistent identity.
- Terrain/chunk/cell identity must remain deterministic across save/reopen and streaming unload/reload.
- Do not represent terrain chunks as ordinary placed asset entities merely to reuse Phase 3 systems.
- Existing world entities must keep their stable entity IDs and owning cell references while cells stream in and out.
- Streaming must not assume a referenced parent/entity is currently loaded.
- Large-world streaming must be bounded and deterministic; tests must prove which cells load/unload around a focus position.
- Small and Medium profiles must remain usable without forcing Large-world streaming behavior.
- Terrain sculpting is authored state and must run through reversible commands/transactions; preview-only brush state must not dirty persistence.
- Undo/redo must restore terrain data and runtime mesh state together.
- Dirty terrain/cell persistence must be incremental; unchanged cells must not be rewritten merely because another cell changed.
- Terrain/cell writes must use the existing crash-safe persistence principles: write/flush/validate/promote, preserving previous known-good canonical data on failure.
- Corrupt, missing, unsupported-version, or incomplete terrain/cell data must fail safely and must not silently replace known-good authored terrain.
- Streaming unload must never discard unsaved dirty authored terrain.
- Cross-cell references remain stable-ID references and may resolve lazily when the target cell is not loaded.
- Biome records must be data-driven and versioned. Do not bake specific art packs, foliage systems, weather systems, or gameplay semantics into the terrain core.
- Phase 5 may expose terrain material slots/hooks, but full foliage/procedural scatter belongs to Phase 9 and full environment/weather belongs to Phase 11.
- Preserve Phase 4 external asset source-folder read-only guarantees.
- Preserve Phase 4 Asset Library placement behavior and Phase 3 command-backed entity editing.
- Core terrain workflows must support keyboard/mouse and gamepad.
- Preserve the canonical dark, playful, Nintendo-forward / Apple-clean UI direction.
- Keep production files around 300 LOC where practical and split by responsibility.
- Never weaken tests to make broken behavior pass.
- CI must continue rejecting `SCRIPT ERROR:` and engine `ERROR:` output even when Godot exits successfully.
- Continue using Godot **4.7.1**.

## Phase 5 verification expectations

The Phase 5 completion gate must include real behavioral verification for at least:

- terrain schema validation and stable IDs
- deterministic height/mesh generation
- runtime sculpt add/subtract/smooth/flatten behavior
- brush preview versus committed authored state
- command-backed sculpt undo/redo
- project dirty/autosave integration
- Small/Medium/Large partition topology
- stable owning-cell relationships for existing world entities
- dirty-cell incremental save behavior
- save/reopen terrain persistence
- checkpoint/recovery interaction where applicable
- corrupt/missing/future-version terrain/cell failure paths
- deterministic streaming load/unload sets
- dirty-cell protection during unload
- cross-cell stable-reference behavior when targets are unloaded
- biome schema/preset/assignment persistence
- representative scale/performance tests
- keyboard/mouse terrain authoring
- gamepad terrain authoring
- rendered terrain/streaming UI evidence against the canonical visual direction
- strict inspection of raw Godot CI logs

## Completion gate

Phase 5 is complete only when P05-T01 through P05-T08 are implemented together and verified through:

- behavioral unit tests
- integration tests
- real Godot runtime tests
- persistence/restart tests
- dirty-cell incremental persistence tests
- corruption/recovery failure paths
- deterministic streaming tests
- stable identity/reference verification
- keyboard/mouse verification
- gamepad verification
- representative performance/scale verification
- rendered visual evidence
- strict raw Godot log inspection

Then update the backlog, architecture docs, and `CURRENT_HANDOFF.md`, and open **one Phase 5 completion PR targeting `master`**.

Do not begin Phase 6 until that Phase 5 milestone PR is merged.
