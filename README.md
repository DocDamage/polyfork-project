# PlayWorld Studio

PlayWorld Studio is a Godot 4.7.x runtime game-creation platform for building open worlds, placing and converting assets into gameplay-ready prefabs, sculpting terrain, visually scripting interactions, testing instantly, exporting standalone Godot games, and running bounded direct-connect multiplayer Play sessions.

The user-facing experience is intentionally simple: **smart defaults first, advanced controls on demand**. The canonical UI reference is `assets/reference/CANONICAL_UI_REFERENCE.png`. Visual deviation from that reference is treated as a defect unless a documented functional requirement forces a change.

## Repository authority

The real project lives on `master`. The repository default branch `main` is obsolete starter code and must not be used for development.

Current authoritative `master` before Phase 15 merge is `14085eb703b72d930f39121d3da18362d43cc77d`, the verified signed merge commit for PR #19 — Phase 14 — Scale and Polish.

Phases 0 through 14 are merged. Phase 15 — Multiplayer Foundations and Collaboration Roadmap is complete on `dev/phase15-multiplayer-collaboration-milestone` and is represented by PR #20, which remains open until explicitly authorized for merge.

## Core promise

1. Choose a world size before creation: Small, Medium, or Large/streamed.
2. Spawn directly into a runtime editor.
3. Browse a universal asset library with large cards and search.
4. Place assets with move/rotate/scale, grid, angle, surface, object, vertex/socket snapping, scatter, and painting tools.
5. Convert plain assets into reusable gameplay prefabs through components, archetypes, sockets, and node-based logic.
6. Toggle **Build | Play** instantly without changing scenes or losing edits.
7. Save worlds, reusable chunks, prefabs, visual graphs, terrain, lighting, weather, and gameplay state.
8. Export prototypes as normal standalone Godot projects/games.
9. Opt supported templates into Offline, Host, or Client Play using bounded host-authoritative ENet multiplayer foundations while keeping offline single-player first-class.
10. Extend toward durable collaborative authoring through a separate command/history-aware protocol rather than treating transient gameplay replication as editor collaboration.

## Start here

Read in this order:

- `docs/PROJECT_CHARTER.md`
- `docs/PRODUCT_REQUIREMENTS.md`
- `docs/DECISIONS.md`
- `docs/design/UI_UX_CANONICAL_SPEC.md`
- `docs/architecture/SYSTEM_ARCHITECTURE.md`
- `docs/implementation/MASTER_IMPLEMENTATION_PLAN.md`
- `docs/implementation/CODEX_EXECUTION_RULES.md`
- `docs/handoffs/CURRENT_HANDOFF.md`

Phase 15-specific references:

- `docs/implementation/PHASE15_MULTIPLAYER_COLLABORATION_PLAN.md`
- `docs/architecture/PHASE15_COLLABORATIVE_AUTHORING_ROADMAP.md`
- `docs/qa/PHASE15_QA.md`
- `docs/systems/MULTIPLAYER_COLLABORATION_ROADMAP.md`

## Non-negotiables

- Godot 4.7.x.
- Desktop first; architecture must not block later Linux/macOS/controller/touch support.
- RTX 3060 12 GB class GPU is the baseline target for the Balanced quality preset.
- Universal external asset library; original asset folders remain untouched.
- Runtime-first world creation.
- Full undo/redo for authored authoring operations.
- Components + archetypes + prefabs + visual scripting.
- Large worlds use streaming and instancing; no monolithic-world assumptions.
- AI operates against the actual indexed asset catalog and its changes are transactional/undoable.
- Licensing/source metadata is first-class.
- Offline projects and exports must not be forced to carry multiplayer runtime dependencies.
- Gameplay networking is transient Play state; authored project identity remains stable and separate.
- Production collaborative editing is not claimed by the Phase 15 gameplay network layer.
- UI must match the canonical reference image closely.
