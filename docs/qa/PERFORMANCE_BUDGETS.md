# Performance Budgets

## Baseline hardware
Primary standard preset target: Windows desktop with RTX 3060 12 GB-class GPU, modern mid-range CPU, 32 GB system RAM, 1080p.

## Initial targets
- Standard preset: aim for 60 FPS in representative medium-world authoring/play scenarios.
- Editor interaction should remain responsive during background indexing.
- Thumbnail generation and asset scanning must be throttled and cancellable.
- Decorative repetitions should prefer instancing.
- Large-world streaming must enforce active-cell budgets.

## Object scale target
Architect for tens of thousands of authored entities across a world and much larger visual populations through instancing/procedural systems. Do not promise hundreds of thousands of fully independent scripted nodes in V1.

## Quality presets
Low, Medium, Standard (3060 baseline), High, Ultra. Presets control shadows, SSAO/SSIL-like effects, volumetrics, LOD distances, foliage density, streaming range, water quality, and editor preview effects.

## Measurement
Maintain a representative benchmark world and record frame time, draw calls, visible instances, loaded cells, memory, and streaming spikes after performance-sensitive milestones.
