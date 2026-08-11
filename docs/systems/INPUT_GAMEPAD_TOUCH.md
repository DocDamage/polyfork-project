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

## Touch readiness
- Large hit targets.
- No hover-only features.
- Multi-touch gesture hooks reserved for orbit/pan/zoom and transform manipulation.
- Panels must tolerate narrower aspect ratios.
