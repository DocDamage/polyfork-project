# Current Handoff

## Status
OPEN

## Project state
P00-T01 through P00-T03 are complete. The repository now has the modular scaffold, coding/documentation standards, and explicit persistent identity/schema-version contracts. No command/persistence engine or user-facing editor systems are implemented yet.

## Canonical UI
`assets/reference/CANONICAL_UI_REFERENCE.png`

## Completed task
`P00-T03 — Define persistent ID and schema-version conventions`

## P00-T03 implementation evidence
- Added `docs/architecture/PERSISTENT_ID_SCHEMA_CONVENTIONS.md` defining lowercase canonical UUID identities, UUID v4 initial generation, ID lifecycle, stable-reference rules, schema-version increments, migration behavior, document typing, ownership, editor/runtime boundaries, and validation expectations.
- Updated `docs/architecture/FILE_FORMATS_VERSIONING.md` to reference and enforce the identity/schema contract.
- Updated `docs/architecture/DATA_MODEL.md` with version/ID ownership and stable-reference expectations for core persisted records.
- Updated `schemas/world_project.example.json` and `schemas/asset_record.example.json` to use concrete UUIDs, `document_type`, positive `schema_version`, explicit ID reference fields, and `null` optional references.
- No runtime persistence or migration implementation was introduced; this task remains contract-only as required.

## Known limitations
- Runtime validation of the contracts will be added with later persistence/test tasks.
- Godot executable remains unavailable in the current agent environment.

## Next authorized task
`P00-T04 — Implement test harness and runtime smoke-test scene`

## P00-T04 boundary
Implement a minimal real Godot-native test harness and runtime smoke scene sufficient to exercise project launch/scene loading without pulling future gameplay/editor features forward. Do not implement Phase 1 UI features yet.

## New-thread start prompt
Read `docs/implementation/CODING_STANDARDS.md`, `docs/qa/TEST_MATRIX.md`, `docs/qa/QUALITY_GATES.md`, `project.godot`, `src/main/Main.tscn`, and this file. Implement only P00-T04 with a minimal deterministic Godot test runner and runtime smoke scene. Document the exact command to run it; if Godot CLI is unavailable, verify structure statically and record that limitation. Then update the handoff and authorize only P00-T05.
