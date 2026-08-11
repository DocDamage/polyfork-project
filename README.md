# PlayWorld Studio

PlayWorld Studio is a Godot 4.7.x runtime game-creation platform for building open worlds, placing and converting assets into gameplay-ready prefabs, sculpting terrain, visually scripting interactions, testing instantly, and exporting standalone Godot games.

The user-facing experience is intentionally simple: **smart defaults first, advanced controls on demand**. The canonical UI reference is `assets/reference/CANONICAL_UI_REFERENCE.png`. Visual deviation from that reference is treated as a defect unless a documented functional requirement forces a change.

## Core promise

1. Choose a world size before creation: Small, Medium, or Large/streamed.
2. Spawn directly into a runtime editor.
3. Browse a universal asset library with large cards and search.
4. Place assets with move/rotate/scale, grid, angle, surface, object, vertex/socket snapping, scatter, and painting tools.
5. Convert plain assets into reusable gameplay prefabs through components, archetypes, sockets, and node-based logic.
6. Toggle **Build | Play** instantly without changing scenes or losing edits.
7. Save worlds, reusable chunks, prefabs, visual graphs, terrain, lighting, weather, and gameplay state.
8. Export prototypes as normal standalone Godot projects/games.
9. Scale toward AI-assisted building, procedural world tools, controller/touch authoring, and future multiplayer collaboration.

## Start here

Read in this order:

- `docs/PROJECT_CHARTER.md`
- `docs/PRODUCT_REQUIREMENTS.md`
- `docs/design/UI_UX_CANONICAL_SPEC.md`
- `docs/architecture/SYSTEM_ARCHITECTURE.md`
- `docs/implementation/MASTER_IMPLEMENTATION_PLAN.md`
- `docs/implementation/CODEX_EXECUTION_RULES.md`
- `docs/handoffs/CURRENT_HANDOFF.md`

## Non-negotiables

- Godot 4.7.x.
- Desktop first; architecture must not block later Linux/macOS/controller/touch support.
- RTX 3060 12 GB class GPU is the baseline target for the primary quality preset.
- Universal external asset library; original asset folders remain untouched.
- Runtime-first world creation.
- Full undo/redo for all authoring operations.
- Components + archetypes + prefabs + visual scripting.
- Large worlds use streaming and instancing; no monolithic-world assumptions.
- AI operates against the actual indexed asset catalog and its changes are transactional/undoable.
- Licensing/source metadata is first-class.
- UI must match the canonical reference image closely.
