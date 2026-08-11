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
- Retain a clean path to ordinary Godot development and export.

## Explicitly in scope
Runtime placement, terrain, foliage, roads, water integration hooks, asset indexing, thumbnail generation, metadata, licensing, components, archetypes, prefab inheritance, sockets, visual scripting, player templates, NPC foundations, vehicles, interactions, inventory, dialogue/quest scaffolding, procedural generation, AI command workflow, save/load, undo/redo, streaming, quality presets, standalone export, future multiplayer-compatible identity model.

## Explicitly not required for V1
Photoreal AAA rendering, MMO-scale networking, fully automatic arbitrary FBX repair, production-grade collaborative editing, server-hosted marketplace, or unlimited world size. Architecture may reserve extension points for them.

## Success definition
A successful first major release lets a new user create a medium world, sculpt terrain, index external assets, search and place them, convert placed assets to reusable gameplay prefabs, add simple node-based interactions, enter Play mode instantly, save/reload the project, and export a standalone runnable game.
