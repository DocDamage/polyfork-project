# POLYFORK PROJECT — PHASE 7 ACTIVE MILESTONE HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authoritative source
The real project lives on `master`.

Phase 7 started from exact authoritative `master` commit:

`14d87bb12a3423dc54fc186f47f491a393537420`

That commit is the merge commit for PR #11 — Phase 6: Components, Archetypes, Prefabs.

The repository default branch `main` remains obsolete starter code. **Never develop from `main`.**

## Active milestone
Phase 7 — Instant Play and Templates is authorized on:

`dev/phase7-instant-play-templates-milestone`

Phases 0 through 6 are complete and merged.

Work continuously through P07-T01 through P07-T08. Use intermediate commits and CI runs as needed, but do not open internal-task PRs.

The next user-facing merge/review stop is exactly one Phase 7 completion PR targeting `master`. Do not merge it without explicit user authorization.

## Phase 7 scope
- versioned validated data-driven template manifests and registry
- same-loaded-world Build ↔ Play transition with isolated disposable runtime state
- semantic gameplay input separate from editor navigation/input
- reusable third-person instant-play controller/camera
- reusable FPS instant-play controller/camera
- deterministic template application and runtime-module resolution
- seven initial prototype templates: Blank Sandbox, Third-Person Adventure, FPS, Survival, RPG, Driving, Walking Simulator
- full integration, persistence, failure-path, input, regression, performance-proxy, raw-log, and rendered visual verification

## Core rules
- Build-authored state is authoritative; Play-only state must never silently persist or enter Undo history.
- Build and Play operate in the same loaded world.
- Repeated Play entry/exit must not accumulate runtime nodes.
- Failed Play startup must return safely to Build.
- Editor and gameplay input must be logically separated by mode.
- Templates are project starters, never editor forks and never permanent genre locks.
- Missing required runtime modules fail clearly; do not fabricate unavailable systems or assets.
- Preserve Phase 3 placement/transform/Undo/Redo, Phase 4 Asset Library read-only source guarantees, Phase 5 terrain/streaming, and Phase 6 components/archetypes/prefabs/sockets/attachments.
- Do not begin Phase 8 Visual Scripting or broad Phase 10 gameplay systems.
- Godot 4.7.1 remains authoritative.
- Keep production files around 300 LOC where practical and split by responsibility.
- Strict final logs reject `SCRIPT ERROR:` and engine `ERROR:` output.

## Current checkpoint
PR #11 merge and exact Phase 7 base were verified before branch creation. The Phase 7 milestone branch was created directly from `14d87bb12a3423dc54fc186f47f491a393537420`.

Implementation is now authorized across P07-T01 through P07-T08 without additional task-level approval stops.
