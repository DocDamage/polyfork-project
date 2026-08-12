# Input, Gamepad, and Touch

## Input abstraction
Editor navigation and gameplay input use semantic actions, but they are separate ownership domains.

- Editor/application UI continues to use Godot `ui_*` actions and contextual editor shortcuts.
- Disposable Play sessions install `play_*` gameplay actions, own only actions they created, and remove those owned actions when Play exits or startup fails.
- Existing editor/user actions are never erased or rewritten by the gameplay input installer.

## Phase 1 editor UI navigation baseline
- Home enters focus on Create New World and has explicit directional/card focus neighbors.
- Create New World enters focus on the world-name field and has explicit Back, size-card, template, and Create focus relationships.
- Workspace enters focus on the Build | Play control and links top controls to the bottom tool dock.
- Bottom dock supports deterministic horizontal traversal across Terrain, Assets, Foliage, Roads, Water, Gameplay, AI, and More.
- Opening the Asset drawer moves focus into Search; Search and density controls are mutually reachable.
- Opening the inspector moves focus into its close/Advanced controls.
- `ui_cancel` closes contextual editor UI before leaving the workspace.
- Mouse input continues to use native Godot Control interaction; controller focus remains visible through shared theme focus styles.

## Phase 7 semantic gameplay actions
Default profile: `semantic_default`.

- `play_move_left` / `play_move_right` — A/D + left-stick X
- `play_move_forward` / `play_move_back` — W/S + left-stick Y
- `play_look_left` / `play_look_right` — right-stick X
- `play_look_up` / `play_look_down` — right-stick Y
- mouse motion — controller look while the active Play controller owns pointer look
- `play_jump` — Space + gamepad A
- `play_interact` — E + gamepad X
- `play_primary` — left mouse + right shoulder
- `play_pause` — P + Start
- `play_exit` — Escape + Back + gamepad B

The same semantic movement/look actions drive both third-person and first-person foundations. Play exit restores visible mouse mode and returns control to the Build/editor input domain.

## Gamepad principles
- Left stick movement / right stick camera in Play.
- Shoulder/trigger modifiers remain available for editor tool controls outside Play.
- Radial tool menu remains an editor interaction and does not become gameplay state.
- D-pad remains available for editor snap/tool increments where useful.
- Back/Cancel behavior must be deterministic in both domains.
- Focus must never become trapped in a panel.

## Touch readiness
- Large hit targets.
- No hover-only features.
- Multi-touch gesture hooks reserved for orbit/pan/zoom and transform manipulation.
- Panels must tolerate narrower aspect ratios.
- Future touch gameplay bindings must map onto the same semantic `play_*` layer rather than special-case controller code.