# Entity, Component, Archetype, and Prefab System

## Layer 1: Entity
A stable world object with identity, transform, hierarchy, and references.

## Layer 2: Components
Reusable behaviors/data modules. Initial library should include TransformMetadata, Collision, Interactable, Health, Damageable, PhysicsProp, InventoryContainer, Pickup, AudioEmitter, LightSource, Door, Seat, VehicleBody, CharacterController, NPCBrain, SpawnPoint, DialogueParticipant, QuestParticipant, TriggerVolume, SaveState, NetworkIdentityStub.

## Layer 3: Archetypes
Friendly presets that add expected components and defaults. Examples: Door, Loot Container, NPC, Enemy, Vehicle, Pickup, Light, Destructible Prop, Quest Giver.

## Layer 4: Prefabs
Configured reusable objects saved back into the content library. Prefabs support inheritance and per-instance overrides.

## Validation
- Component dependencies auto-offer required dependencies.
- Conflicts are explicit.
- Archetypes validate required pieces.
- Prefab inheritance stores only meaningful overrides where possible.

## Sockets
Named, typed attachment points. Support custom names and semantic categories such as Grip, Seat, Mount, DoorHandle, Light, LootSpawn, Wheel, Muzzle, Camera, InteractionPoint.
