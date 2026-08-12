# Project Charter

## Working title
PlayWorld Studio.

## Vision
Create a reusable Godot-based game-creation platform that feels approachable enough to use like a game while retaining the depth needed to build complete prototypes and eventually complete games.

## Product identity
The product is not a conventional editor clone. It is a **runtime creative sandbox** with a Nintendo-forward visual personality and Apple-like restraint. Complexity exists behind progressive disclosure rather than permanently occupying the screen.

## Target user
A creator who owns a large and varied 3D asset library and wants to rapidly assemble playable worlds without repeatedly wiring low-level engine systems.

## Primary outcomes
- Build open worlds quickly from existing assets.
- Turn any imported model into a meaningful gameplay object.
- Prototype multiple genres from reusable templates.
- Test without leaving the current world.
- Reuse created prefabs, chunks, logic, and systems across projects.
- Retain a clean path to ordinary Godot development and standalone export.
- Allow selected templates to run bounded direct-connect co-op or competitive Play sessions without turning multiplayer into a requirement for offline projects.
- Preserve a credible future path to collaborative authoring without conflating persistent editor collaboration with transient gameplay networking.

## Explicitly in scope
Runtime placement, terrain, foliage, roads, water integration hooks, asset indexing, thumbnail generation, metadata, licensing, components, archetypes, prefab inheritance, sockets, Visual Scripting, player templates, NPC foundations, vehicles, interactions, inventory, dialogue/quest scaffolding, procedural generation, AI command workflow, save/load, undo/redo, streaming, quality presets, standalone export, and bounded host-authoritative gameplay networking for opt-in templates.

## Explicitly not required for the current major-release scope
Photoreal AAA rendering, MMO-scale networking, cloud matchmaking/relay infrastructure, NAT traversal service, voice chat, anti-cheat platform integration, rollback netcode, dedicated-server fleet orchestration, fully automatic arbitrary FBX repair, production-grade real-time collaborative editing, server-hosted marketplace, or unlimited world size. Architecture may reserve extension points for them.

## Success definition
A successful major release lets a new user create a medium world, sculpt terrain, index external assets, search and place them, convert placed assets to reusable gameplay prefabs, add node-based interactions, enter Play mode instantly, save/reload the project, export a standalone runnable game, and—when using a multiplayer-capable template—host or join a bounded direct-connect Play session without compromising authored project identity or offline behavior.
