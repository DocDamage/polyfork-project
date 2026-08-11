# Terrain and World Streaming

## World profiles
- Small: 1–2 km²; minimal streaming.
- Medium: 4–16 km²; partitioned and streamed.
- Large: 16+ km² starting profile; mandatory streaming and stricter budgets.

## Terrain tools
Raise, Lower, Smooth, Flatten, Terrace/Slope, Noise, Stamp, Paint, Biome Paint, Erosion-style postprocess later, and region lock/protect.

## Cells
World partition cell size must be configurable by world profile. Terrain, foliage, entities, navigation data, and procedural ownership records align with cells where practical.

## Floating origin
Reserve architecture for origin rebasing. Implement when world scale/precision tests prove it necessary; do not prematurely complicate V1.

## Streaming rules
- Stable IDs survive unload/reload.
- Cross-cell references resolve lazily.
- Save changes without requiring all cells loaded.
- Stream distance can differ by entity class.
- Heavy decorative assets can use proxy/LOD policy.
