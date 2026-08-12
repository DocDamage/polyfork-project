# Visual Scripting System

Phase 8 adds project-managed visual scripting without forking the editor or replacing GDScript. Visual graphs are authored project data that compile to deterministic execution plans and run through a bounded interpreter during Play.

## Canonical storage and identity

Project storage:

```text
<project>/visual_scripting/
  graphs.json
```

`graphs.json` uses schema version 1 and the existing crash-safe `SafeJsonWriter` promotion path. Corrupt JSON, unsupported future schemas, duplicate persistent IDs, invalid node types, and unresolved persistent references fail closed.

Persistent identity always uses stable UUID data. Graphs do not depend on scene paths, runtime node names, array positions, or GraphEdit control names as authored identity.

`WorldProject.registries.visual_graph_ids` mirrors project-owned graph IDs. `graphs.json` remains the canonical graph-content document.

## Graph model

Each graph stores:
- `graph_id`
- display name
- `kind`: `event` or `macro`
- optional stable `owner_entity_id`
- enabled state
- nodes
- connections
- graph variables
- macro interface inputs/outputs
- editor metadata

Each node has a stable `node_id`, `type_key`, two-dimensional editor position, and property dictionary. Each connection has a stable `connection_id`, stable source/target node IDs, source/target port names, and `exec` or `data` kind. Variables use stable `variable_id` values.

## Built-in node families

Phase 8 ships a deliberately reusable base library:
- Event: Start
- Flow: Branch, Sequence
- Value: Literal
- Math: Add, Subtract, Multiply, Divide
- Logic: Equal
- Variables: Get Variable, Set Variable
- Entity: Get Position, Set Position
- Macro: Macro Entry, Macro Return, Call Macro
- Debug: Print

Later gameplay phases may add domain-specific nodes without changing graph identity, storage, compiler, or interpreter contracts.

## Command-backed authoring

Graph authoring uses the same universal `CommandHistory` as world placement and Phase 6 gameplay authoring. Command-backed mutations include graph create/delete/configure; node create/delete/move/configure; connections; variables; and graph registry synchronization.

Graph persistence happens inside command execution. A failed graph write rolls the graph state and world-project registry back to the previous snapshot. Successful edits signal the existing project dirty-state path and participate in universal Undo/Redo.

## Compiler

The compiler validates before execution:
- graph and node schemas
- supported node type keys
- stable endpoint identity
- exec/data port existence
- data type compatibility
- one incoming connection per data input
- required event Start entry
- exactly one Macro Entry for macro graphs
- macro target existence and kind
- macro dependency cycles

Connections and graph IDs are normalized into deterministic execution maps. The compiler produces executable plans keyed by stable graph/node IDs.

## Runtime interpreter

The interpreter executes compiled plans with a hard step budget. It supports nested data dependency evaluation, graph variables, flow control, math/logic, entity-position access, debug trace, and macro calls.

Failure conditions return structured errors instead of hanging Play. This includes division by zero, missing variables/entities, unconnected required inputs, data dependency cycles, unsupported executable nodes, step-budget exhaustion, missing macro plans, and recursion.

## Macros and functions

Macro graphs use one Macro Entry node and Macro Return nodes with typed interface ports. `macro.call` ports are derived from the referenced macro interface. Macro parameters are evaluated in the caller, passed into a child interpreter, and output values are propagated back to the caller.

The compiler rejects macro dependency cycles across the project registry. The runtime also maintains an independent recursion guard, so recursive execution is rejected even if a malformed plan bypasses registry-level validation.

## Logic workspace

The former unused bottom-dock `More` slot is presented to users as **Logic** while preserving its internal tool key for compatibility with existing focus/navigation code.

Logic opens a compact contextual visual-scripting tool using native Godot `GraphEdit` and `GraphNode` controls. It provides:
- project graph selector
- New Event and New Macro
- searchable categorized node palette
- native node movement
- native connection/disconnection requests
- node deletion
- JSON node-property editing
- graph rendering from stable authored IDs
- gamepad X to add the selected node
- gamepad Y to create an event graph
- Back/Cancel to close Logic before leaving the workspace

Opening another contextual workspace tool closes Logic instead of stacking unrelated authoring panels.

## Debugger

The Logic workspace includes a compact debugger toolbar with:
- stable node selector
- Validate
- Run
- Breakpoint toggle
- Resume
- live idle/running/paused/completed/error status
- debug trace display

Breakpoints pause before the selected node executes. Resume continues the existing interpreter queue rather than restarting the graph. Debugger validation uses the production compiler.

## Build and Play integration

Phase 8 is integrated into the Phase 7 Play lifecycle. The real Main scene binds the active project's graph service as the PlaySession graph provider. On Play entry:
1. authored graph records are read from the project-managed graph state;
2. the full graph registry is compiled;
3. enabled event graphs execute in deterministic graph-ID order;
4. entity operations target the disposable Phase 7 runtime project copy through stable entity IDs.

A graph compile/runtime failure rejects Play startup and follows the existing Play rollback path. Play graph mutations never modify authored Build project data. Returning to Build discards runtime-only graph effects with the rest of the disposable Play state.

## Template graph references

Phase 7 template `example_graph_references` may refer to real project-owned Phase 8 graphs. Reference validation requires stable UUIDs that resolve in the active project graph registry. Missing or malformed references fail closed; templates do not embed scene-tree paths or hidden editor forks.

## Verification

Phase 8 contract coverage includes persistence/reopen, corruption/future-schema rejection, command history, Undo/Redo, deterministic compiler behavior, type/cardinality failures, bounded runtime execution, macro cycles/recursion, debugger pause/resume/trace, template graph references, native Main-scene Logic authoring, gamepad shortcuts, real Phase 7 PlaySession graph execution, and authored-state isolation.

Representative CI regression workload: 120 graphs compiled and executed in 17 ms against a deliberately broad 12,000 ms CI budget. This is a regression proxy, not a hardware FPS claim.

Rendered evidence is produced from the real Main scene and shows both a connected Start/Literal/Add/Print graph and the same graph paused at a real `debug.print` breakpoint with the debugger toolbar visible.
