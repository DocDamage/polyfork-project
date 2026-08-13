# Test Matrix

Final Phase 17 release evidence baseline: workflow `31668662576` — PASS on implementation/evidence head `8f46b4cddd62efc5502033b3a9c0259bb740ec26`; artifact `9169011730`; RC ZIP SHA-256 `0911cc136b3deaf689b7959359ec9c45bee2f10255c7af573c9855ea0bbcdfa3`.

| Area | Unit | Integration | Runtime | Persistence | Undo | Gamepad | Performance/Scale | Visual | Export/Package |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| App shell | ✓ | ✓ | ✓ packaged creator |  |  | ✓ semantic UI actions |  | ✓ final packaged evidence | ✓ creator package |
| World save | ✓ | ✓ | ✓ | ✓ first/reopen/upgrade/read-only | ✓ |  |  |  | ✓ |
| Placement | ✓ | ✓ | ✓ packaged authoring | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Asset registry | ✓ | ✓ | ✓ real GLTF source | ✓ shared user catalog |  |  | ✓ | ✓ Asset Library | ✓ dependency closure |
| Terrain/streaming | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ Small/Medium/Large | ✓ | ✓ |
| Components/prefabs | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Visual graphs | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Foliage/procedural/splines | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Gameplay framework | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Environment | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| AI execution | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ where UI-relevant | ✓ | ✓ | ✓ explicit provider/config failure docs |
| Authored-game export | ✓ | ✓ | ✓ | ✓ |  | ✓ | ✓ | ✓ Export surface | ✓ packaged creator → Windows game → launch |
| Creator distribution | ✓ release contracts | ✓ inherited closure | ✓ packaged EXE | ✓ restart/reopen/upgrade/read-only install | n/a | ✓ A→`ui_accept`, D-pad navigation, focus/accessibility | ✓ inherited scale gates | ✓ Home full/compact, Asset Library, New World, workspace, Play, Export visually reviewed | ✓ deterministic ZIP + independent rebuild + SHA-256 + manifest + scan |
| Scale/polish | ✓ | ✓ | ✓ | ✓ settings restart/malformed file | ✓ where authored | ✓ | ✓ | ✓ | ✓ |
| Multiplayer Play | ✓ | ✓ | ✓ host/client lifecycle | host-only runtime save authority | n/a for transient packets; authored state isolation required | ✓ multiplayer surface + semantic Play input | ✓ bounded state | ✓ full/compact panel | ✓ concurrent exported host/client |

## Phase 17 packaged release assertions

- `source-regressions` — PASS.
- `windows-release` — PASS.
- Packaged UI/controller/accessibility marker present: `PASS: Phase 17 packaged creator UI, controller, accessibility, and major-screen acceptance completed.`
- Package integrity/credential scan marker present: `PASS: Phase 17 creator package integrity and credential scan completed.`
- Clean packaged creator first-run creator→game export marker present.
- Restart/reopen and read-only-style install markers present.
- Independent replacement ZIP is byte-for-byte identical for identical release inputs.
- Final evidence screenshots were downloaded and visually inspected rather than accepted by existence alone.
- Prior synthetic GLTF default-scene warning is absent from final logs.
- GitHub-hosted Windows visual runs use the expected ANGLE fallback to Microsoft Basic Render Driver; this is runner-specific infrastructure.

Rows are minimum evidence expectations, not maximums. `n/a` does not waive authored-state isolation or cleanup tests.
