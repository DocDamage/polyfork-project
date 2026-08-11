# Input, Gamepad, and Touch

## Input abstraction
Every editor action maps to semantic actions rather than raw keys. Keyboard/mouse, gamepad, and future touch implementations bind to the same action layer.

## Gamepad principles
- Left stick movement / right stick camera.
- Shoulder/trigger modifiers for tool controls.
- Radial tool menu for dense actions.
- D-pad for snap/tool increments where useful.
- Clear Back/Cancel behavior everywhere.
- Focus never becomes trapped in a panel.

## Phase 1 UI navigation baseline
Phase 1 uses Godot's semantic `ui_*` focus/navigation actions rather than raw key or joypad codes.

- Home enters focus on Create New World and has explicit directional/card focus neighbors.
- Create New World enters focus on the world-name field and has explicit Back, size-card, template, and Create focus relationships.
- Workspace enters focus on the Build | Play control and links top controls to the bottom tool dock.
- Bottom dock supports deterministic horizontal traversal across Terrain, Assets, Foliage, Roads, Water, Gameplay, AI, and More.
- Opening the Asset drawer moves focus into Search; Search and density controls are mutually reachable.
- Opening the inspector moves focus into its close/Advanced controls.
- `ui_cancel` priority in the workspace is: close Asset drawer, close inspector, then leave the workspace for Home.
- `ui_cancel` on Create New World returns Home.
- Mouse input continues to use native Godot Control interaction; controller focus remains visible through the shared theme focus styles.

Future gameplay/editor action mappings must remain separate from this UI navigation layer.

## Touch readiness
- Large hit targets.
- No hover-only features.
- Multi-touch gesture hooks reserved for orbit/pan/zoom and transform manipulation.
- Panels must tolerate narrower aspect ratios.
