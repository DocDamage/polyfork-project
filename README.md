# PlayWorld Studio

PlayWorld Studio is a Godot 4.7.x runtime game-creation platform for building open worlds, placing and converting assets into gameplay-ready prefabs, sculpting terrain, visually scripting interactions, testing instantly, exporting standalone Godot games, and running bounded direct-connect multiplayer Play sessions.

The user-facing experience is intentionally simple: **smart defaults first, advanced controls on demand**. The canonical UI reference is `assets/reference/CANONICAL_UI_REFERENCE.png`. Visual deviation from that reference is treated as a defect unless a documented functional requirement forces a change.

## Repository authority

The repository default branch and authoritative integrated line is `master`.

Current authoritative `master`:

`37d311b90f0684668a49e7f3b8ab197e6abcbe3a`

That commit is the verified signed merge of **PR #21 — Phase 16 — Inherited Product Completeness and Integration Closure**.

The historical `main` branch contains obsolete starter code and must not be used for development.

Phases **0 through 16 are complete and merged**. Phase 17 — Release Candidate and Distribution is complete and release-verified on `dev/phase17-milestone`, pending its single completion PR to `master`. Do not merge that PR without explicit authorization.

## Phase 17 release candidate

Product version: `PlayWorld Studio 0.1.0-rc.1`

Windows package: `PlayWorld-Studio-0.1.0-rc.1-Windows-x64.zip`

Verified implementation/evidence head:

`8f46b4cddd62efc5502033b3a9c0259bb740ec26`

Full release workflow: **31668662576 — PASS**

- `source-regressions` — PASS
- `windows-release` — PASS
- deterministic independent ZIP rebuild — PASS
- packaged creator clean first run — PASS
- create/edit/save/reopen/upgrade/read-only-style install — PASS
- packaged creator → standalone Windows game export → launch — PASS
- packaged UI/controller/accessibility acceptance — PASS
- package integrity and credential-like material scan — PASS

Release evidence artifact: **9169011730 — `phase17-release-candidate`**

RC ZIP SHA-256:

`0911cc136b3deaf689b7959359ec9c45bee2f10255c7af573c9855ea0bbcdfa3`

The final evidence artifact's eight packaged acceptance screenshots were visually reviewed: Home at 1600×900 and 1280×720, compact Home, Asset Library, New World, Build workspace, Instant Play, and Export. The expected hosted-runner ANGLE fallback to Microsoft's Basic Render Driver is a CI-environment limitation, not a PlayWorld Studio product failure. The repaired GLTF fixture warning is absent from the final release logs.

## Core promise

1. Choose a world size before creation: Small, Medium, or Large/streamed.
2. Spawn directly into a runtime editor.
3. Browse a universal asset library with large cards and search.
4. Place assets with move/rotate/scale and snapping/scatter/painting tools.
5. Convert plain assets into reusable gameplay prefabs through components, archetypes, sockets, and node-based logic.
6. Toggle **Build | Play** instantly without changing scenes or losing edits.
7. Save worlds, reusable chunks, prefabs, visual graphs, terrain, lighting, weather, and gameplay state.
8. Export prototypes as normal standalone Godot projects/games.
9. Opt supported templates into Offline, Host, or Client Play while keeping offline single-player first-class.
10. Extend toward durable collaborative authoring through a separate command/history-aware protocol rather than treating transient gameplay replication as editor collaboration.

## Start here

- `docs/PROJECT_CHARTER.md`
- `docs/PRODUCT_REQUIREMENTS.md`
- `docs/DECISIONS.md`
- `docs/design/UI_UX_CANONICAL_SPEC.md`
- `docs/architecture/SYSTEM_ARCHITECTURE.md`
- `docs/implementation/MASTER_IMPLEMENTATION_PLAN.md`
- `docs/implementation/PHASE17_RELEASE_CANDIDATE_DISTRIBUTION_PLAN.md`
- `docs/qa/PHASE17_QA.md`
- `docs/implementation/CODEX_EXECUTION_RULES.md`
- `docs/handoffs/CURRENT_HANDOFF.md`

## Non-negotiables

- Godot 4.7.x.
- Desktop first; architecture must not block later Linux/macOS/controller/touch support.
- RTX 3060 12 GB class GPU is the Balanced quality baseline.
- Universal external Asset Library; original asset folders remain untouched.
- Runtime-first world creation.
- Full undo/redo for authored operations.
- Components + archetypes + prefabs + visual scripting.
- Large worlds use streaming and instancing.
- AI operates against the actual indexed asset catalog and its changes are transactional/undoable.
- Licensing/source metadata is first-class.
- Offline projects and exports must not be forced to carry multiplayer runtime dependencies.
- Gameplay networking is transient Play state; authored project identity remains stable and separate.
- Production collaborative editing is not claimed by the gameplay network layer.
- UI must match the canonical reference image closely.

Historical `.polyforkAPI` credential material in Git history must be treated as exposed. Never print, restore, test, copy, or reuse it. External revocation/rotation remains required unless independently confirmed outside the repository.
