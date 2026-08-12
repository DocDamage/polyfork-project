# End-to-End Acceptance Scenarios

## Scenario A — New creator flow
Launch -> Create New World -> choose Medium -> choose biome -> world opens -> sculpt hill -> save -> relaunch -> world restores.

## Scenario B — Asset flow
Register external folder -> scan -> thumbnail appears -> search -> select asset -> ghost preview -> surface snap -> place -> undo -> redo -> favorite asset.

## Scenario C — Gameplay conversion
Place plain model -> Add Archetype: Loot Container -> configure inventory -> save prefab -> place second instance -> enter Play -> interact -> state persists as designed -> return Build.

## Scenario D — Visual logic
Select door -> open visual script -> author an interaction flow with available nodes -> validate -> Play -> behavior works -> debug trace visible.

## Scenario E — Procedural
Paint a foliage rule set -> thousands of visuals render via instancing -> change density -> regenerate -> one undo restores previous authored procedural state.

## Scenario F — AI
Prompt AI to build a small abandoned gas station beside selected road -> AI searches actual catalog -> preview -> approve -> transaction creates result -> single undo removes complete AI operation.

## Scenario G — Export
Export offline prototype -> editor UI absent -> standalone game launches -> player can interact with authored objects -> save/load works -> network runtime/profile is absent when multiplayer is disabled.

## Scenario H — Multiplayer Play
Open a multiplayer-capable template -> Host & Play -> second process Join & Play to host endpoint -> compatibility handshake succeeds -> host/client membership converges -> each process keeps local input on its local player and disables local input for the remote player -> host-authoritative gameplay/match state converges -> client cannot persist authoritative runtime save state -> disconnect/stop Play cleans up transient network state without changing authored Build data.

## Scenario I — Multiplayer export
Export a multiplayer-capable prototype -> package includes the generated multiplayer capability profile and required network runtime closure -> launch host and client exported executables concurrently -> both reach the expected two-peer session and preserve keyboard/mouse + gamepad semantic bindings.
