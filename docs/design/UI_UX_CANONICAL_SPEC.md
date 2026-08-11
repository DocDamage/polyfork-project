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
- Compact vertical transform toolbar when appropriate.
- Bottom contextual category dock: Terrain, Assets, Foliage, Roads, Water, Gameplay, AI, More.
- Asset browser appears as a bottom sheet/dock with large cards by default and density toggle.
- Inspector slides from the right when an object is selected.
- Inspector exposes Basic first, Advanced second.
- Status/performance strip remains compact.

### Selection behavior
Selected objects use a clean, bright outline and readable gizmo. Placement uses a translucent ghost preview attached to the cursor/aim point. Invalid placement must be visibly distinct.

### Advanced controls
Advanced controls remain hidden unless explicitly requested. The default panel must never present the entire internal parameter model.

### Gamepad
Every core authoring action must be reachable by controller. Show context-aware controller hints only when needed. Radial/tool-wheel interaction is preferred for dense command sets.

### Touch
Use touch-friendly spacing and avoid hover-only interaction. Touch support can arrive later, but layout and hit targets must not make it impossible.

### Node editor
Visual scripting opens as a dedicated full-screen workspace. It should not clutter the normal world-building view.

### AI
A single persistent Create with AI entry point opens a Spotlight-like command bar. AI may show suggestions, create a ghost preview, or execute depending on selected mode.

## Tool accents
Recommended semantic mapping, with exact values defined later in theme resources:
- Terrain: green
- Assets: amber/gold
- Foliage: fresh green
- Roads: violet
- Water: cyan/blue
- Gameplay: warm orange
- AI: purple/magenta
- Errors/destructive: red

## UX principles
1. Smart defaults before configuration.
2. One obvious action per state.
3. Prefer direct manipulation.
4. Progressive disclosure.
5. Every destructive or generative action is undoable.
6. The viewport is the product; UI exists to support it.
7. Do not force users into editor terminology when a clearer user-facing phrase exists.
