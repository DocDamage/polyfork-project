# UI Visual Acceptance

## Canonical reference
`assets/reference/CANONICAL_UI_REFERENCE.png`

This image is the visual source of truth. The written UI spec clarifies behavior, but implementation should not drift into generic Godot/editor styling when the reference already answers a visual question.

## Capture protocol
For visual review:
1. Run the actual Godot application, not an isolated mockup.
2. Capture at the target state/aspect ratio; use 1600×900 where practical and add narrower captures when adaptive behavior is part of the milestone.
3. Capture the specific state being reviewed with no debug overlays unless evidence requires them.
4. Compare the app and canonical image side-by-side at equal displayed size.
5. Record intentional deviations and their requirement/constraint in the task handoff.
6. For contextual panels, verify both visual styling and that the entire actionable surface remains on-screen.

## Scored comparison checklist
Mark each item Pass, Needs Work, Not Yet Applicable, or Intentional Deviation.

### Overall composition
- [ ] Central viewport/content area visually dominates rather than permanent chrome.
- [ ] Visual weight feels approximately 70% playful/Nintendo-like and 30% restrained/Apple-like.
- [ ] The interface reads as a creation tool that feels game-like, not an enterprise dashboard.
- [ ] Rounded surfaces, spacing, and depth are consistent across the screen.

### Surface / typography / state
- [ ] Dark surfaces use distinct hierarchy levels rather than one flat gray.
- [ ] Cards/panels use soft boundaries and depth instead of heavy separator lines.
- [ ] Corner radii are visibly generous and internally consistent.
- [ ] Focus/selection states remain bright and readable against dark surfaces.
- [ ] Title/body/caption hierarchy remains friendly and readable without dense forms.

### Workspace shell
- [ ] Build | Play is prominent near the top-center workspace area.
- [ ] Transform/tool controls remain compact rather than permanently dominating.
- [ ] Bottom contextual dock proportions remain consistent with the canonical layout.
- [ ] Asset browser defaults to large cards.
- [ ] Inspector prioritizes Basic before Advanced.
- [ ] Status/performance/session information remains compact.

### Multiplayer contextual surface
- [ ] Offline / Host & Play / Join & Play actions are visually ranked and readable.
- [ ] Player/address/port configuration is clear without exposing unnecessary advanced network detail.
- [ ] Capability summary and peer/session status are visible but do not dominate the viewport.
- [ ] Keyboard/gamepad focus is visible and deterministic.
- [ ] Compact capture remains fully on-screen; no right-edge clipping.
- [ ] Connecting/error state uses plain language and does not imply authored project mutation.

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
- contextual panels clipped outside the viewport;
- a layout that materially diverges from the canonical reference.

## Evidence rule
A phase-specific visual milestone may only claim visual acceptance after actual running-app evidence is captured and inspected for the relevant state(s). Historical Phase 1/8/9 and later phase-specific evidence remains valid for its own milestone; later UI changes require their own captures rather than silently replacing old evidence.
