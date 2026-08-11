# Design Tokens

This file defines semantic tokens, not final pixel-perfect constants. Final values should be tuned against the canonical reference.

## Shape
- Card radius: large.
- Button radius: medium-large.
- Chips/tags: pill.
- Modal/sheet radius: large.

## Spacing
Use an 8 px logical base scale with 4 px half-step where needed. Prefer generous grouping over separator lines.

## Typography
Use a highly legible rounded sans-serif family available for redistribution/use in the project. Avoid relying on proprietary Nintendo/Apple fonts. Define roles: Display, Title, Heading, Body, Caption, Mono/Data.

## Motion
- Fast hover/focus: ~100–160 ms.
- Panel slide: ~180–260 ms.
- Mode switch: ~200–300 ms.
- Avoid gratuitous bounce; reserve playful motion for successful placement, creation, and mode transitions.

## Semantic colors
Implement as theme variables: surface_0..3, text_primary, text_secondary, border_soft, focus, success, warning, danger, terrain, assets, foliage, roads, water, gameplay, ai.

## Accessibility
- Never communicate tool state by color alone.
- Minimum target sizes should support controller/touch use.
- Text/background contrast must meet reasonable WCAG targets.
- Reduced-motion option required.
- UI scale control required.
