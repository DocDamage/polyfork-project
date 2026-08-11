# Environment, Water, and Biomes

## Principle
The platform supplies systems and integration contracts; it does not force a built-in art library. The user's Polyfork/FAB/other owned assets can populate those systems.

## Day/night
World time service controls sun/moon direction, environment transitions, lights tagged for time response, and optional schedules.

## Weather
Weather profiles hold visual/audio/environment parameters and may reference user-owned particle, sky, sound, decal, mesh, or shader assets. Blend profiles over time rather than hard-switching.

## Water
Provide water-body entities and adapters that can wrap imported water solutions/assets. Initial types: ocean, lake/pond, spline river. Avoid locking the project to one water implementation.

## Biomes
A biome is a rule/data bundle: terrain material references, foliage queries, scatter constraints, environment/weather preferences, audio ambience, and procedural rules. Art assets remain replaceable references.
