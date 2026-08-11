# POLYFORK PROJECT — PHASE 6 HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authoritative branch
The real project lives on:

`master`

Current authoritative `master` after merged PR #10:

`6007a68bf98996d8f4b7619249506c91a8a54f75`

The repository default branch `main` remains obsolete starter code.

**Never develop from `main`.**

## Current project state
Phases 0 through 5 are complete and merged.

Phase 5 delivered runtime terrain sculpting, stable terrain/cell persistence, Small/Medium/Large partition topology, deterministic Large-world streaming, incremental dirty-cell saves and recovery, data-driven biomes, stable cross-cell entity references, command-backed terrain undo/redo, keyboard/mouse/gamepad authoring, and rendered terrain evidence.

## Development workflow
The project uses milestone-based development, not one PR per small task.

For Phase 6:
1. Start from authoritative `master` commit `6007a68bf98996d8f4b7619249506c91a8a54f75`.
2. Use the already-created milestone branch `dev/phase6-components-prefabs-milestone`.
3. Work continuously through P06-T01 through P06-T08.
4. Use intermediate commits and CI runs as needed.
5. Fix failures without weakening tests.
6. Update architecture, backlog, and handoff docs during closeout.
7. Open exactly one Phase 6 completion PR targeting `master` after the milestone is complete and verified.
8. Do not merge that PR without explicit user authorization.

# NEXT AUTHORIZED MILESTONE

## Phase 6 — Components, Archetypes, Prefabs

Milestone branch:

`dev/phase6-components-prefabs-milestone`

Complete continuously:

- **P06-T01** — versioned component-definition, component-instance, archetype, prefab, socket, and attachment persistence contracts
- **P06-T02** — initial reusable component registry with defaults, dependencies, conflicts, and validation
- **P06-T03** — command-backed add/remove/configure component workflows for existing world entities
- **P06-T04** — data-driven archetype registry and reversible archetype conversion/application flow
- **P06-T05** — prefab save/snapshot, managed prefab repository, and stable-ID prefab instantiation through existing placement/runtime systems
- **P06-T06** — prefab inheritance, derived prefabs, meaningful per-instance overrides, and deterministic effective-value resolution
- **P06-T07** — named typed sockets, socket editing, command-backed attachments, and runtime attachment resolution without path-based identity
- **P06-T08** — workspace, persistence/restart, scale, keyboard/mouse, gamepad, failure-path, inheritance, attachment, and rendered visual verification

Use one Phase 6 branch and one completion PR. Do not stop at individual task boundaries.

## Product requirements
Phase 6 must preserve the project gameplay-object model:
- Any placed object can remain scenery or be promoted into a gameplay object.
- Components are composable reusable behavior/data modules.
- Archetypes bundle expected components and defaults without replacing stable entity identity.
- Prefabs save reusable configured objects back into project-managed content storage.
- Prefab inheritance supports base/derived relationships and meaningful per-instance overrides.
- Named typed sockets support Grip, Seat, Mount, DoorHandle, Light, LootSpawn, Wheel, Muzzle, Camera, InteractionPoint, and custom extension points.

The initial component library is defined by `docs/systems/ENTITY_COMPONENT_PREFAB_SYSTEM.md` and must include:
TransformMetadata, Collision, Interactable, Health, Damageable, PhysicsProp, InventoryContainer, Pickup, AudioEmitter, LightSource, Door, Seat, VehicleBody, CharacterController, NPCBrain, SpawnPoint, DialogueParticipant, QuestParticipant, TriggerVolume, SaveState, NetworkIdentityStub.

Phase 6 establishes valid data, editing, composition, prefab, inheritance, and attachment foundations. It must not prematurely implement the broad gameplay behavior systems reserved for Phase 10.

## Architecture constraints
- Persistent component, archetype, prefab, socket, attachment, and instance references use stable UUIDs only.
- Scene-tree paths, node names, array indexes, asset source paths, or runtime node pointers may not become persistent identity.
- Component definitions explicitly declare property schema/defaults, dependencies, conflicts, editor category, and future runtime hook metadata.
- Dependency application must be deterministic and visible; conflicts must reject or require explicit resolution rather than silently removing authored data.
- Component edits, archetype application, prefab assignment/instantiation, socket edits, and attachment edits are authored mutations and must be reversible through the existing command history.
- Archetype application may add/configure required components, but must not replace the entity UUID or silently discard unrelated components.
- Prefabs are project-managed canonical authored data, not Asset Library source mutations. Phase 4 external source folders remain read-only.
- Prefab inheritance must reject cycles and missing base references.
- Derived prefabs store their own stable identity and only authored differences where practical; effective resolution must be deterministic and independently testable.
- Prefab instances retain stable entity IDs separate from prefab IDs. Instantiating a prefab more than once allocates new entity UUIDs while preserving the prefab reference.
- Editing a prefab definition must never silently rewrite unrelated world entity identity.
- Instance overrides remain explicit data; base prefab updates must not overwrite a valid explicit override.
- Sockets are named typed stable-ID records with local transforms. Attachments persist by entity ID + socket ID, not node paths.
- Runtime attachment resolution must fail safely when parent/socket/child is unavailable and recover when references become loadable again.
- Cross-cell streaming from Phase 5 must remain valid for prefab instances and attachments.
- Preserve the Phase 3 command/undo/redo system, Phase 4 Asset Library placement/read-only guarantees, and Phase 5 terrain/streaming behavior.
- Core workflows support keyboard/mouse and gamepad.
- Preserve the canonical dark playful Nintendo-forward / Apple-clean UI direction; extend contextual editor surfaces instead of creating an enterprise dashboard.
- Keep production files around 300 LOC where practical and split by responsibility.
- Never weaken tests to make broken behavior pass.
- Continue using Godot 4.7.1 and the strict CI error-output gate.

## Verification expectations
The Phase 6 completion gate must behaviorally verify at least:
- schema validation and unsupported/future versions
- stable IDs and duplicate-ID rejection
- all initial component definitions load and validate
- property default/type/range/enum validation where declared
- deterministic dependency resolution
- explicit conflict rejection
- add/remove/configure component undo/redo and persistence
- save/reopen component instances without identity drift
- archetype application retaining entity identity and unrelated components
- archetype dependency/conflict behavior and undo/redo
- prefab save/reopen/instantiate and duplicate instance identity
- prefab inheritance resolution, override preservation, cycle/missing-base failure paths
- prefab instance save/reopen with stable prefab references
- socket add/edit/remove validation and undo/redo
- attachment creation/reparent/unattach using stable IDs and local socket transforms
- missing/unloaded socket/parent/child safe failure and recovery
- streamed cross-cell attachment/reference behavior
- Asset Library source folders remain read-only
- representative component/prefab scale tests
- real keyboard/mouse workflows
- real gamepad workflows
- rendered Phase 6 visual evidence
- strict raw Godot log inspection

## Completion gate
Phase 6 is complete only when P06-T01 through P06-T08 are implemented and verified together. Then update backlog/architecture/handoff docs and open one Phase 6 completion PR targeting authoritative `master`.

Do not begin Phase 7 until the Phase 6 completion PR is explicitly merged.
