# Input, Gamepad, and Touch

## Input abstraction
Editor navigation and gameplay input use semantic actions, but they are separate ownership domains.

- Editor/application UI continues to use Godot `ui_*` actions and contextual editor shortcuts.
- Disposable Play sessions install/use `play_*` gameplay actions and clean up only the actions they own when Play exits or startup fails.
- Existing editor/user actions are never erased or rewritten by the gameplay input installer.
- Remote network player replicas never receive local player input authority.

## Editor UI navigation baseline
- Home enters focus on the primary create/continue actions.
- Create New World has explicit Back, size/template, and Create focus relationships.
- Workspace links Build | Play, contextual tools, drawers, inspector, and modal/contextual panels without focus traps.
- `ui_cancel` closes contextual editor UI before leaving the workspace.
- Mouse input continues to use native Godot Control interaction; controller focus remains visible through shared theme focus styles.

## Semantic gameplay actions
Default semantic profile retains movement/look/jump/interact/primary/pause/exit actions across keyboard/mouse and gamepad. The same semantic movement/look actions drive both third-person and first-person foundations.

Play exit restores editor input ownership and visible pointer behavior as required by the active controller.

## Phase 15 local/remote input authority
`first_person_controller.gd` and `third_person_controller.gd` expose local-input enable/disable behavior for networking.

- local player controller: local input enabled;
- remote player replica: local input disabled and network state applied;
- network ownership changes may not erase or remap the user's semantic input configuration;
- exported multiplayer verification checks both keyboard/mouse and gamepad semantic bindings.

## Multiplayer workspace controls
The contextual Multiplayer surface must be fully operable by keyboard/mouse and gamepad:
- edit player name/address/port through native focusable controls;
- reach Offline, Host & Play, Join & Play, and Close deterministically;
- show context-aware input hints;
- keep focus visible in full and compact layouts;
- `ui_cancel` closes the contextual layer before leaving the workspace.

Networking status may update while focused, but status refresh must not steal focus from user input.

## Gamepad principles
- Left stick movement / right stick camera in Play.
- Shoulder/trigger modifiers remain available for editor tool controls outside Play.
- Radial tool menu remains an editor interaction and does not become gameplay state.
- D-pad remains available for editor navigation/snap increments where useful.
- Back/Cancel behavior must be deterministic in both editor and Play domains.
- Focus must never become trapped in a panel.

## Touch readiness
- Large hit targets.
- No hover-only features.
- Multi-touch gesture hooks reserved for orbit/pan/zoom and transform manipulation.
- Panels must tolerate narrower aspect ratios.
- Future touch gameplay bindings map onto the same semantic `play_*` layer rather than special-case controller code.
- Multiplayer endpoint fields/actions must remain usable in touch-sized layouts before touch input is claimed complete.
