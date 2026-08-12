# Visual Scripting System

Phase 8 adds project-managed visual scripting without forking the editor or replacing GDScript. Visual graphs are authored data that compile to deterministic execution plans and run through a bounded interpreter during Play.

## Identity and persistence
Persistent identity is always stable UUID data, never scene paths, runtime node names, array positions, or GraphEdit control IDs.

Canonical project storage:

```text
<project>/visual_scripting/
  graphs.json
```

`graphs.json` is schema-v1 and is written through the existing crash-safe `SafeJsonWriter`. Corrupt JSON, unsupported future schemas, duplicate IDs, and unresolved persistent references fail closed.

`WorldProject.registries.visual_graph_ids` mirrors the project-owned graph IDs. The graph registry document remains the canonical graph content.

## Graph contract
Each graph declares:
- `graph_id`
- `display_name`
- `kind`: `event` or `macro`
- optional stable `owner_entity_id`
- `enabled`
- `nodes[]`
- `connections[]`
- `variables[]`
- macro `interface` inputs/outputs
- editor metadata such as zoom/scroll state

Each node has a stable `node_id`, `type_key`, two-dimensional editor position, and property dictionary. Each connection has its own stable `connection_id`, stable source/target node IDs, source/target port names, and `kind` (`exec` or `data`). Variables use stable `variable_id` values.

## Execution model
The compiler validates node types, ports, value types, connection cardinality, entry points, macro references, and dependency cycles. It produces a deterministic plan keyed by stable node IDs.

The interpreter executes with a hard step budget. Infinite loops, recursive macros, missing entities, invalid values, and node-runtime failures return structured diagnostics rather than hanging Play.

## Initial node families
- Event: Start
- Flow: Branch, Sequence
- Value: Literal
- Math: Add, Subtract, Multiply, Divide
- Logic: Equal
- Variables: Get, Set
- Entity: Get Position, Set Position
- Macro: Call
- Debug: Print

Later phases may add domain-specific gameplay nodes without changing the graph identity or compiler contracts.

## Authoring and Undo/Redo
Graph creation/deletion, node creation/deletion/move/configuration, connection edits, variables, and macro interfaces are command-backed through the existing authoring history. Failed persistence rolls back the authored graph mutation.

## Workspace
The graph editor uses Godot `GraphEdit`/`GraphNode` inside the existing workspace shell. It must remain visually consistent with the canonical dark playful Nintendo/Apple design and remain usable with keyboard/mouse and gamepad.

## Templates
Phase 7 template `example_graph_references` may point to real project-owned Phase 8 graphs once materialized. Templates do not embed hidden editor forks or hard-code scene-tree paths.
