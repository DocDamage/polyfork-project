# Current Handoff

## Status
OPEN

## Project state
Phase 0, Phase 1, and P02-T01 are complete. Stable UUID generation/validation and Small/Medium/Large world-profile contracts are implemented and covered by the real Godot test harness.

## Completed task
`P02-T01 — Implement stable ID utility and Small/Medium/Large world-profile contracts`

## Evidence
- `src/world/stable_id.gd` generates and validates lowercase UUID v4 identities and rejects nil IDs.
- `src/world/world_profile.gd` defines Small 1–2 km², Medium 4–16 km² recommended, and Large 16+ km² streamed profiles.
- `tests/unit/world_foundation_contracts.gd` verifies UUID and profile contracts.
- `tests/test_runner.gd` now runs unit contracts before runtime smoke checks.
- GitHub Actions run `31493738127`, runtime-smoke job `93786192135`: SUCCESS on Godot `4.7.1.stable.official.a13da4feb`.
- Test output: `PASS: PlayWorld Studio test harness completed.`

## Known limitations
Project manifests, entity records, command history, and recovery saves do not exist yet.

## Next authorized task
`P02-T02 — Implement world-project model and atomic create/open/save repository`

## Task boundary
Implement only a versioned WorldProject model and repository for creating, reading, validating, and safely replacing project manifest files. Do not connect the New World UI yet. Do not implement entities, commands, or recovery saves.

## New-thread start prompt
Read the persistent-ID conventions, core data model, world-project example schema, stable-ID utility, world-profile contracts, and this file. Implement only P02-T02 with real integration coverage, then authorize only P02-T03.
