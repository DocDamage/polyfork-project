# POLYFORK PROJECT — PHASE 11 ACTIVE HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authoritative branch

The real project lives on:

`master`

Current authoritative `master`:

`ac2753f81c9c6be53abe89b102e1f9911a595944`

This is the verified signed merge commit for PR #15 — Phase 10 — Gameplay Framework Breadth.

The repository default branch `main` remains obsolete starter code.

**Never develop from `main`.**

## Completed state

PR #15 is merged.

Phases 0 through 10 are complete on authoritative `master`.

## Phase 11 milestone branch

Phase 11 — Environment — is active on:

`dev/phase11-environment-milestone`

The branch was created from exactly:

`ac2753f81c9c6be53abe89b102e1f9911a595944`

The branch/base comparison was verified identical before Phase 11 writes: zero commits ahead and zero commits behind.

No obsolete `main` ancestry is being used.

Phase 11 must be developed as one continuous milestone without task-by-task pull requests.

## Phase 11 objective

Deliver a coherent, reusable, data-driven environment system that integrates day/night, weather, fog, wind, water hooks, and biome/environment coupling through the existing Polyfork architecture.

Authored Build data remains authoritative. Runtime evaluation during Play is disposable and must not silently mutate Build state. Persisted identities use stable IDs where identity is required, and missing/corrupt references fail safely.

## Phase 11 checkpoints

- [ ] P11-T01 — schema-v1 environment state, stable weather-profile IDs, validation, registry synchronization, crash-safe persistence
- [ ] P11-T02 — command-backed environment/profile authoring through universal Undo/Redo and project dirty-state semantics
- [ ] P11-T03 — deterministic time-of-day evaluation and Godot rendering bridge for sun, ambient/sky, and fog-capable Environment resources
- [ ] P11-T04 — weather profile selection/transitions, runtime events, deterministic evaluation, safe missing-profile fallback
- [ ] P11-T05 — reusable wind state/hooks for foliage, particles, water, gameplay, and future consumers
- [ ] P11-T06 — Phase 5 biome/environment overrides with deterministic precedence and streaming-aware active-cell behavior
- [ ] P11-T07 — stable water integration descriptors/hooks for future providers without hardcoded water implementation
- [ ] P11-T08 — Phase 7 disposable Play integration plus Phase 8 Visual Scripting environment actions/events
- [ ] P11-T09 — native Environment workspace UX with keyboard/mouse and gamepad authoring paths
- [ ] P11-T10 — persistence/Undo/day-night/weather/biome/foliage/wind/streaming/Build-Play isolation/failure/scale/gamepad/visual/strict-log/inherited regression/Godot Smoke closeout and one completion PR

## Architecture inspection findings before implementation

- Phase 5 already owns terrain cells, biome assignment, dirty-cell persistence, deterministic streaming, and terrain refresh behavior; Phase 11 must consume those systems instead of recreating terrain or biome state.
- Phase 7 already owns the isolated Build → Play → Build lifecycle; Play environment progression belongs in disposable session/runtime state.
- Phase 9 already owns derived foliage/procedural runtime and streaming; wind/environment coupling must feed that runtime through reusable hooks without making generated foliage authoritative.
- Phase 10 already owns reusable gameplay runtime events/state; environment signals may be consumed there but should not duplicate gameplay state.
- `src/environment` is reserved and currently empty, making it the correct module boundary for the Phase 11 contracts/repository/service/runtime/render bridge.
- Existing Phase-specific suite runners and integration-contract tests should be extended with a Phase 11 runner and environment contract suites rather than replaced.

## Verification required before completion PR

- persistence/save/reopen and corruption/future-schema handling;
- universal Undo/Redo for authored environment editing;
- deterministic day/night behavior;
- weather profile switching and transitions;
- biome/environment coupling and streamed-world behavior;
- terrain/foliage/wind integration regression coverage;
- stable water-hook behavior and missing-provider safety;
- Build → Play → Build isolation;
- Visual Scripting environment actions/events;
- keyboard/mouse and gamepad authoring;
- representative scale/performance checks;
- strict Godot log gates;
- inherited Phase 6–10 regression gates;
- rendered Phase 11 visual evidence;
- Godot Smoke.

## Completion gate

After all P11 checkpoints and verification are complete, open exactly one Phase 11 completion PR from `dev/phase11-environment-milestone` to authoritative `master`.

Do not merge that PR without explicit user authorization.

Do not begin Phase 12 until the Phase 11 completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.
