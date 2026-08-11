# Tests

The initial test harness is dependency-free and runs directly through Godot 4.7.x.

## Runtime smoke check

From the repository root:

```powershell
godot --headless --path . --script res://tests/test_runner.gd
```

If the Godot executable is installed under a versioned name, substitute that executable while keeping the remaining arguments unchanged.

The runner exits with code `0` only when the runtime smoke scene loads, the real `src/main/Main.tscn` scene loads and instantiates, and the expected Phase 0 scaffold nodes are present. Failures exit with code `1` and emit explicit error messages.

## Test directories
- `tests/unit/` — deterministic unit/contract tests.
- `tests/integration/` — module-boundary and persistence integration tests.
- `tests/runtime/` — real Godot scene/workflow tests.

Do not replace runtime behavior checks with symbol-existence tests or swallowed exceptions.
