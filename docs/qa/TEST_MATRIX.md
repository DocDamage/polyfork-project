# Test Matrix

| Area | Unit | Integration | Runtime | Persistence | Undo | Gamepad | Performance/Scale | Visual | Export/Package |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| App shell | ✓ | ✓ | ✓ |  |  | ✓ |  | ✓ | ✓ packaged creator |
| World save | ✓ | ✓ | ✓ | ✓ packaged restart | ✓ |  |  |  | ✓ |
| Placement | ✓ | ✓ | ✓ packaged authoring | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Asset registry | ✓ | ✓ | ✓ packaged real GLTF source | ✓ shared user catalog |  |  | ✓ | ✓ | ✓ dependency closure |
| Terrain/streaming | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Components/prefabs | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Visual graphs | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Foliage/procedural/splines | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Gameplay framework | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Environment | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| AI execution | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ where UI-relevant | ✓ | ✓ | ✓ failure/config docs |
| Authored-game export | ✓ | ✓ | ✓ | ✓ |  | ✓ | ✓ | ✓ where UI-relevant | ✓ packaged creator → game → launch |
| Creator distribution | ✓ release contracts | ✓ | ✓ packaged EXE | ✓ restart/relocation/read-only install | n/a | ✓ inherited synthetic input/focus | ✓ inherited | ✓ packaged 1600×900 / 1280×720 / compact | ✓ deterministic ZIP + SHA-256 + manifest + scan |
| Scale/polish | ✓ | ✓ | ✓ | ✓ settings restart/malformed file | ✓ where authored | ✓ | ✓ | ✓ | ✓ |
| Multiplayer Play | ✓ | ✓ | ✓ host/client lifecycle | host-only runtime save authority | n/a for transient packets; authored state isolation required | ✓ multiplayer surface + semantic Play input | ✓ bounded Small/Medium/Large state | ✓ full/compact panel | ✓ concurrent exported host/client |

Rows are minimum evidence expectations, not maximums. "n/a" does not waive authored-state isolation or cleanup tests.
