# Test Matrix

| Area | Unit | Integration | Runtime | Persistence | Undo | Gamepad | Performance/Scale | Visual | Export/Package |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| App shell | ✓ | ✓ | ✓ |  |  | ✓ |  | ✓ |  |
| World save | ✓ | ✓ | ✓ | ✓ | ✓ |  |  |  | ✓ |
| Placement | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Asset registry | ✓ | ✓ | ✓ | ✓ |  |  | ✓ | ✓ | ✓ |
| Terrain/streaming | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Components/prefabs | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Visual graphs | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Foliage/procedural/splines | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Gameplay framework | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Environment | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| AI execution | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ where UI-relevant | ✓ | ✓ | ✓ |
| Export | ✓ | ✓ | ✓ | ✓ |  | ✓ | ✓ | ✓ where UI-relevant | ✓ |
| Scale/polish | ✓ | ✓ | ✓ | ✓ where state changes | ✓ where authored | ✓ | ✓ | ✓ | ✓ |
| Multiplayer Play | ✓ | ✓ | ✓ host/client lifecycle | host-only runtime save authority | n/a for transient packets; authored state isolation required | ✓ multiplayer surface + semantic Play input | ✓ bounded Small/Medium/Large state | ✓ full/compact panel | ✓ concurrent exported host/client |

Rows are minimum evidence expectations, not maximums. "n/a" does not waive authored-state isolation or cleanup tests.
