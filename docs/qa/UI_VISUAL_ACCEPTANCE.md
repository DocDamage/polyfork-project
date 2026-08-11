# UI Visual Acceptance

## Canonical reference
`assets/reference/CANONICAL_UI_REFERENCE.png`

This image is the visual source of truth. The written UI spec clarifies behavior, but implementation should not drift into generic Godot/editor styling when the reference already answers a visual question.

## Capture protocol
For each Phase 1 visual review:
1. Run the actual Godot application, not an isolated mockup.
2. Capture at the same approximate 16:9 aspect ratio as the canonical reference; use 1600x900 viewport when practical.
3. Capture the specific state being reviewed with no debug overlays unless the reference includes them.
4. Compare the app and canonical image side-by-side at equal displayed size.
5. Record intentional deviations and their requirement/constraint in the task handoff.

## Scored comparison checklist
Mark each item Pass, Needs Work, Not Yet Applicable, or Intentional Deviation.

### Overall composition
- [ ] Central viewport/content area visually dominates rather than permanent chrome.
- [ ] Visual weight feels approximately 70% playful/Nintendo-like and 30% restrained/Apple-like.
- [ ] The interface reads as a creation tool that feels game-like, not an enterprise dashboard.
- [ ] Rounded surfaces, spacing, and depth are consistent across the screen.

### Surface and depth
- [ ] Dark surfaces use distinct hierarchy levels rather than one flat gray.
- [ ] Cards/panels use soft boundaries and depth instead of heavy separator lines.
- [ ] Corner radii are visibly generous and internally consistent.
- [ ] Focus/selection states remain bright and readable against dark surfaces.

### Typography
- [ ] Display/title hierarchy resembles the scale and friendliness of the reference.
- [ ] Body/caption text remains readable without looking dense.
- [ ] No proprietary Nintendo/Apple font is required to achieve the intended character.

### Home/cards
- [ ] Primary home actions use large friendly cards.
- [ ] Card icon/title/subtext hierarchy remains clear at a glance.
- [ ] Card density is intentionally spacious by default.

### Workspace shell
- [ ] Build | Play is prominent near the top-center workspace area.
- [ ] Transform/tool controls remain compact rather than permanently dominating.
- [ ] Bottom contextual dock proportions resemble the canonical layout.
- [ ] Asset browser opens as a bottom drawer/sheet and defaults to large cards.
- [ ] Inspector appears from the right and prioritizes Basic before Advanced.
- [ ] Status/performance information remains compact.

### Semantic tool identity
- [ ] Terrain, Assets, Foliage, Roads, Water, Gameplay, and AI use distinct semantic accents.
- [ ] State is not communicated by color alone.
- [ ] Destructive/error states are clearly distinct from tool accents.

### Interaction polish
- [ ] Hover/focus/pressed states have coherent motion and depth.
- [ ] Gamepad focus is always visible when controller navigation is active.
- [ ] Advanced controls remain hidden until requested.
- [ ] Hit targets are large enough for controller and future touch use.

## Automatic defect triggers
Treat these as defects unless an explicit requirement is documented:
- generic gray Godot UI;
- dark-slate enterprise dashboard styling;
- flat rectangular panels with little depth;
- permanently visible advanced settings;
- tiny asset thumbnails as the default view;
- overly dense menu bars or inspector forms;
- inconsistent radii/spacing;
- mismatched tool colors;
- hidden or ambiguous Build | Play state;
- keyboard-only core workflows;
- viewport/content area materially subordinate to editor chrome;
- a layout that materially diverges from the canonical reference.

## Phase 1 exit rule
P01-T09 may not be marked complete until actual running-app screenshots are compared with the canonical image using this checklist. If the execution environment cannot produce screenshots, P01-T09 must remain blocked rather than being marked complete from static scene files alone.
