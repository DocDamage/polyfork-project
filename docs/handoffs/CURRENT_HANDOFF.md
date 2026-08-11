# Current Handoff

## Status
OPEN

## Project state
P00-T01 and P00-T02 are complete. The repository has the required modular Godot scaffold plus explicit coding and documentation standards. No gameplay/editor systems beyond the neutral starter shell are implemented yet.

## Canonical UI
`assets/reference/CANONICAL_UI_REFERENCE.png`

## Completed task
`P00-T02 — Add coding/documentation rules`

## P00-T02 implementation evidence
- Added `docs/implementation/CODING_STANDARDS.md` with Godot/GDScript conventions, module boundaries, mutation rules, UI constraints, error handling, testing expectations, and completion standards.
- Added `docs/implementation/DOCUMENTATION_RULES.md` with canonical-document precedence, required documentation updates, handoff requirements, schema documentation expectations, UI evidence rules, and strict evidence language.
- Preserved the existing modular repository structure and neutral main scene.
- No production gameplay/editor code changed during P00-T02.

## Known limitations
- Godot runtime execution remains unavailable in the current agent environment; no runtime behavior was claimed for this documentation-only task.

## Next authorized task
`P00-T03 — Define persistent ID and schema-version conventions`

## P00-T03 boundary
Implement only persistent identity and schema/version contracts. Do not implement the command system, runtime test harness, UI, persistence engine, or migrations beyond contract-level examples/conventions.

## New-thread start prompt
Read `README.md`, `docs/PRODUCT_REQUIREMENTS.md`, `docs/architecture/SYSTEM_ARCHITECTURE.md`, `docs/architecture/DATA_MODEL.md`, `docs/architecture/FILE_FORMATS_VERSIONING.md`, `docs/implementation/CODING_STANDARDS.md`, `docs/implementation/DOCUMENTATION_RULES.md`, `docs/implementation/TASK_BACKLOG.md`, and this file. Implement only P00-T03. Verify stable-ID and schema-version conventions are internally consistent, update examples/docs, then update this handoff and authorize only P00-T04.
