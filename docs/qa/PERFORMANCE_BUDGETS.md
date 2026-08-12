# Performance Budgets

## Baseline hardware
Primary Balanced preset target: Windows desktop with RTX 3060 12 GB-class GPU, modern mid-range CPU, 32 GB system RAM, 1080p.

## Phase 14 performance profiles
The implemented deterministic profiles are **Low**, **Balanced**, and **High**. Balanced is the default.

Current policy values are owned by `src/scale/performance_profiles.gd`; documentation should not invent additional presets that the runtime does not expose.

- Low: 30 FPS target, 1536 MB policy budget, reduced render scale/ranges and lower UI/update frequency.
- Balanced: 60 FPS target, 2560 MB policy budget, 0.90 render scale, moderate streaming/environment/UI cadence.
- High: 60 FPS target, 4096 MB policy budget, full render scale, wider foliage range and higher update/UI cadence.

These are policy/regression targets, not a guarantee that every arbitrary user world will hit the target.

## System targets
- Editor interaction should remain responsive during background indexing.
- Thumbnail generation and asset scanning must be throttled/cancellable.
- Decorative repetitions should prefer instancing.
- Large-world streaming must enforce active-cell budgets.
- Procedural previews must honor profile limits rather than create unbounded runtime nodes.
- Multiplayer state/replication tests must remain bounded by declared player/state limits and must not become an excuse for unbounded per-frame allocation.

## Object scale target
Architect for tens of thousands of authored entities across a world and much larger visual populations through instancing/procedural systems. Do not promise hundreds of thousands of fully independent scripted nodes in V1.

## Measurement
Maintain representative benchmark worlds and record frame time, draw calls, visible instances, loaded cells, memory, streaming spikes, and relevant multiplayer/network-state counts after performance-sensitive milestones.

CI scale/stress suites are regression proxies. They do not replace clean-machine/hardware performance validation.
