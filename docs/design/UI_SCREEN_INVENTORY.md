# UI Screen Inventory

## Tier 1 screens
- Home / Project Hub
- Create New World
- Main Build Workspace
- Play Mode HUD
- Asset Library
- Template Browser
- Settings

## Tier 2 workspaces / contextual surfaces
- Visual Script Editor / Logic
- Prefab / Archetype composition surfaces
- Terrain Workspace
- Biome / Environment controls
- Road/Spline Editor
- Foliage Rules Editor
- AI Command/History
- Project Export
- Asset Inspector
- Multiplayer Play surface — Offline / Host & Play / Join & Play with player/endpoint/capability/session state

## Overlays and sheets
- Command palette
- Context radial menu
- Quick add component
- Placement settings
- Snap settings
- Save prefab
- Save reusable chunk
- License/source details
- Duplicate asset warning
- Import issue report
- Performance warning / settings
- Undo history
- Controller cheat sheet

## Multiplayer surface requirements
- Must remain contextual rather than permanently taking viewport space.
- Must expose player name, host/join address, port, declared capability summary, peer/session status, and explicit Offline/Host/Join actions.
- Must support keyboard/mouse and deterministic gamepad focus.
- Compact layout must stay fully on-screen at narrower supported captures such as 1024×640.
- Closing or switching away must not imply that authored project state changed.

## Screen acceptance rule
Every screen/contextual surface must define: primary goal, single primary action or clearly ranked action group, escape/back behavior, controller focus path, touch fallback/readiness, empty state, loading/connecting state where applicable, error state, and advanced-details path.
