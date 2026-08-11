# Visual Scripting System

## Purpose
Enable non-code gameplay assembly without closing the door to GDScript extensions.

## Node families
Events, Flow, Conditions, Variables, Math, Transform, Entity, Component, Interaction, Audio, Animation, Inventory, Combat, Dialogue, Quest, Spawn, Timer, Environment, Save, AI/Navigation, Debug.

## Example
On Interact -> Check Key -> Branch -> Open Door -> Play Sound -> Set Saved State.

## Requirements
- Full-screen editor.
- Searchable add-node palette.
- Typed pins where useful.
- Reusable functions/macros.
- Collapsible groups/comments.
- Graph validation before play/export.
- Runtime debug highlighting.
- Breakpoint/logging hooks.
- Custom node registration from GDScript.
- Serialization independent of UI node positions where practical.

## Runtime strategy
Graphs compile into an efficient executable representation rather than interpreting UI controls directly. Keep the graph file authoring-friendly and the runtime representation cacheable.
