# Prototype Template System

Templates are data-driven project starters, not forks of the editor. A template configures existing reusable systems and may declare later-phase capabilities as planned modules, but it must not fabricate unavailable runtime behavior.

## Initial Phase 7 templates
- `blank_sandbox`
- `third_person_adventure`
- `fps`
- `survival`
- `rpg`
- `driving`
- `walking_simulator`

The registry loads these manifests from `templates/manifests/` and rejects missing, malformed, duplicate-ID, future-schema, or unavailable-required-module inputs.

## Manifest contract
Schema-v1 manifests declare:
- `template_id` and display metadata
- `required_runtime_modules`
- deterministic `starter_entities`
- semantic `input_mapping`
- optional `default_player_archetype`
- `camera_configuration`
- `example_graph_references`
- `ui_hud_packages`
- `export_settings`
- `tutorial_steps`
- `planned_modules`

Starter entities use a stable `starter_key`, display name, semantic role, optional archetype key, and transform. Their world-entity IDs are derived deterministically from project ID + template ID + starter key, then persist normally with the project.

## Runtime module contract
Phase 7 resolves only currently available modules. Required modules that do not exist fail before partial application. Later gameplay systems such as combat, survival loops, RPG progression, inventory, quests, dialogue, or vehicle driving remain `planned_modules` until their owning phases implement them.

Projects may enable/disable available runtime modules after creation. Disabling the active controller module fails safe to `controller = none`; enabling another available controller module allows the project to change play style without rewriting the project's original template identity.

## Reusable Player archetype
Phase 7 extends the Phase 6 archetype registry with one stable `player` preset while preserving the original nine Phase 6 presets.

Playable templates use that reusable Player archetype for their authored player-start marker. The marker remains authored Build data with stable identity, but its proxy/collision is excluded from the disposable Play runtime while the transient `CharacterBody3D` controller owns gameplay.

Driving also materializes a real Phase 6 Vehicle archetype prototype. Actual vehicle control is deliberately deferred rather than simulated.

## Materialization and persistence
Template application writes project-managed runtime configuration and resolved dependencies. Starter materialization is idempotent: repeating it does not duplicate authored entities or create user Undo/Redo history.

Template runtime configuration, starter IDs, entity ownership, transforms, and component-instance references are verified across save/reopen.

External Asset Library source folders remain read-only; template application creates only project-managed data.

## Genre-lock rule
Choosing a template must never permanently trap the project in one genre. Templates provide deterministic starting composition; the resulting project remains editable through the common world, component, prefab, module, and later visual-scripting systems.