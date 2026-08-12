# UI/UX Canonical Specification

## Canonical reference
`assets/reference/CANONICAL_UI_REFERENCE.png` is the canonical visual target. Any implementation should be evaluated against it side-by-side.

## Visual direction
- Dark, playful, polished.
- Approximately 70% Nintendo-like friendliness / 30% Apple-like restraint.
- Rounded surfaces, clear depth, large readable hit targets, minimal permanent chrome.
- Context-sensitive accent colors by tool category.
- Avoid enterprise-dashboard density and Unreal/Blender-style permanent complexity.

## Primary shell
### Home
Large, friendly cards:
- Create New World
- Continue
- My Worlds
- Templates
- Asset Library

### Main world workspace
- Central viewport dominates the screen.
- Top-center **Build | Play** segmented control.
- Compact transform/tool controls when appropriate.
- Bottom contextual category dock: Terrain, Assets, Foliage, Roads, Water, Gameplay, AI, and contextual extension entry points.
- Asset browser appears as a bottom sheet/dock with large cards by default and density toggle.
- Inspector slides from the right when an object is selected.
- Inspector exposes Basic first, Advanced second.
- Status/performance strip remains compact.

### Selection behavior
Selected objects use a clean, bright outline and readable gizmo. Placement uses a translucent ghost preview attached to the cursor/aim point. Invalid placement must be visibly distinct.

### Advanced controls
Advanced controls remain hidden unless explicitly requested. The default panel must never present the entire internal parameter model.

### Gamepad
Every core authoring action and user-facing Phase 15 multiplayer action must be reachable by controller. Show context-aware controller hints only when needed. Radial/tool-wheel interaction is preferred for dense editor command sets.

### Touch
Use touch-friendly spacing and avoid hover-only interaction. Touch support can arrive later, but layout and hit targets must not make it impossible.

### Node editor
Visual scripting opens as a dedicated workspace and must not clutter normal world-building view. Domain systems integrate through shared node/service/event boundaries rather than duplicating the graph UX.

### AI
A single persistent Create with AI entry point opens a Spotlight-like command bar. AI may show suggestions, create a ghost preview, or execute depending on selected mode.

### Multiplayer Play
Multiplayer is a contextual Play surface, not permanent editor chrome.

- Show a concise capability summary such as co-op/competitive and supported player range.
- Primary actions are **Offline**, **Host & Play**, and **Join & Play**.
- Host/join configuration exposes only the required player name, address, and port by default.
- Session/peer status is visible but compact.
- Keyboard and controller focus/hints must remain explicit.
- Full and compact layouts must stay inside the viewport; right-side contextual placement may not clip off-screen.
- Networking errors should be readable and actionable without exposing raw engine jargon as the only explanation.
- Opening multiplayer controls must not imply that the project is already online or that authored data is being shared.
- Future collaborative editing UI must be designed separately because it represents durable project sharing/permissions/history, not gameplay hosting.

## Tool accents
Recommended semantic mapping, with exact values defined by theme resources:
- Terrain: green
- Assets: amber/gold
- Foliage: fresh green
- Roads: violet
- Water: cyan/blue
- Gameplay: warm orange
- AI: purple/magenta
- Multiplayer/session: reuse gameplay-family semantics with clear state labels rather than inventing an unrelated enterprise-network palette
- Errors/destructive: red

## UX principles
1. Smart defaults before configuration.
2. One obvious action per state.
3. Prefer direct manipulation.
4. Progressive disclosure.
5. Every authored destructive/generative action is undoable.
6. The viewport is the product; UI exists to support it.
7. Do not force users into editor terminology when a clearer user-facing phrase exists.
8. Runtime/disposable state must be visually distinguishable from authored/persistent project changes.
