# Visual Scripting System

Phase 8 adds project-managed visual scripting without forking the editor or replacing GDScript. Visual graphs are authored project data that compile to deterministic execution plans and run through a bounded interpreter during Play.

## Canonical storage and identity
Project storage uses `visual_scripting/graphs.json` with the owning schema/validation and crash-safe promotion path. Persistent graph/node/connection/variable identity uses stable UUID data and never scene paths/runtime control names.

## Command-backed authoring
Graph create/delete/configure, node mutation, connections, variables, and graph-registry synchronization participate in the universal authored command/Undo system. Failed persistence rolls back rather than silently advancing history.

## Compiler / runtime
The compiler validates schema, node types, stable endpoints, ports/data compatibility, event/macro requirements, and macro dependency cycles. The interpreter executes bounded plans with step/recursion guards and structured errors.

## Logic workspace / debugger
The Logic workspace uses native Godot graph controls with searchable node creation, graph/node editing, validation/run controls, breakpoints/resume, and debug trace. Keyboard/mouse and gamepad authoring paths remain supported.

## Build / Play integration
Visual graphs execute against the disposable Play runtime and target runtime entities through stable authored IDs. Compile/runtime failure follows the existing Play rollback path. Play-only graph effects do not mutate Build data.

## Phase 10 gameplay service integration
Domain behavior is exposed through reusable gameplay actions/events/services rather than by creating a second game engine inside Visual Scripting.

## Phase 15 multiplayer integration
Phase 15 deliberately extends that same gameplay boundary instead of inventing a separate networking graph runtime.

Implemented integration includes:
- namespaced `multiplayer.score.add` action routing to host-authoritative match replication;
- namespaced `multiplayer.objective.set` action routing to host-authoritative match replication;
- runtime gameplay events for `multiplayer.session.ready`, `multiplayer.peer.joined`, and `multiplayer.peer.left`;
- client attempts to perform host-only score/objective mutation are rejected/no-op rather than becoming direct authoritative edits.

The current graph runtime does **not** claim dedicated join/leave event-entry node types that do not exist. New visual node/event entry families may be added later only when they are implemented in the graph compiler/interpreter contracts.

## Collaboration boundary
Future collaborative authoring of graph documents is a persistent command/operation synchronization problem and is not solved by Phase 15 gameplay packets. Shared graph editing must follow the durable collaboration roadmap and universal command/history model.

## Verification
Phase 8 historical graph verification remains authoritative for graph persistence/compiler/interpreter/debugger behavior. Phase 15 contract coverage verifies the bounded gameplay-event multiplayer integration without changing graph persistence schema or authored graph identity.
