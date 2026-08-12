# Prototype Template System

Templates are data-driven project starters, not forks of the editor. A template configures existing reusable systems and may declare available capabilities/modules, but it must not fabricate unavailable runtime behavior.

## Initial templates
- `blank_sandbox`
- `third_person_adventure`
- `fps`
- `survival`
- `rpg`
- `driving`
- `walking_simulator`

The registry loads manifests from `templates/manifests/` and rejects missing, malformed, duplicate-ID, future-schema, or unavailable-required-module inputs.

## Manifest contract
Schema-v1 template manifests retain their Phase 7 fields such as template identity/display data, required runtime modules, deterministic starter entities, semantic input mapping, player/camera defaults, graph/HUD references, export settings, tutorial steps, and planned modules.

Phase 15 additionally allows a normalized `multiplayer` capability:
- `enabled`
- `mode`: `coop` or `competitive`
- `min_players` / `max_players` (bounded; implementation maximum 16)
- `spawn_strategy`: `offset` or `spawn_points`
- `spawn_spacing`
- `teams[]`
- `score_mode`: `none`, `player`, `team`, `objective`
- `rejoin_allowed`

Disabled/missing capability normalizes to single-player behavior.

## Phase 15 multiplayer-enabled templates
Current template integration enables multiplayer capability for:
- Third-Person Adventure — co-op, 1–4, objective-oriented configuration;
- FPS — competitive, 2–8, team-oriented score configuration;
- Survival — co-op.

Other templates remain offline unless their manifest intentionally opts in later.

## Runtime module contract
Template application resolves only currently available runtime modules. Required modules that do not exist fail before partial application. Phase 15 registers its multiplayer runtime capability without replacing the common template/project architecture.

Projects may enable/disable available runtime modules after creation according to owning contracts. Genre choice must never permanently trap the project in one editor fork.

## Starter materialization / identity
Starter entities use stable starter keys and deterministic authored world-entity IDs. Runtime networking may map transient session/player identity to playable runtime entities, but it never replaces the authored starter/entity IDs.

Template materialization remains idempotent and project-managed. External Asset Library source folders remain read-only.

## Export interaction
Export staging reads normalized project runtime multiplayer capability. Offline templates/projects omit network closure; enabled multiplayer projects package the capability profile and required runtime network dependencies.

## Genre-lock rule
Choosing a template provides deterministic starting composition. The resulting project remains editable through the common world, component, prefab, runtime module, Visual Scripting, gameplay, environment, AI, export, and multiplayer-capability systems.
