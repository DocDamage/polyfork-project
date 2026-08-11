# Documentation Rules

## Canonical hierarchy
When documents conflict, resolve them in this order unless a later approved decision explicitly supersedes an earlier one:
1. `docs/DECISIONS.md`
2. `docs/PRODUCT_REQUIREMENTS.md`
3. `docs/architecture/SYSTEM_ARCHITECTURE.md`
4. System-specific documents in `docs/systems/`
5. `docs/implementation/MASTER_IMPLEMENTATION_PLAN.md`
6. `docs/handoffs/CURRENT_HANDOFF.md` for the exact task currently authorized

The handoff controls execution scope; it does not silently redefine product requirements.

## Required updates
Update documentation in the same task whenever implementation changes:
- persistent schemas or file formats;
- public module responsibilities or boundaries;
- user-visible behavior covered by requirements;
- input/control behavior;
- export behavior;
- performance budgets or quality gates;
- licensing/source metadata behavior.

## Handoff rules
At the end of every completed task, `docs/handoffs/CURRENT_HANDOFF.md` must include:
- completed task ID;
- concise implementation summary;
- changed files;
- tests/commands run;
- runtime/manual evidence;
- screenshots or visual evidence when applicable;
- unresolved risks/limitations;
- exactly one next authorized task.

Do not authorize multiple implementation tasks at once unless a documented dependency requires parallel execution.

## Decision records
Add or amend `docs/DECISIONS.md` only for durable product or architecture decisions. Do not use it as a changelog.

## Schema documentation
Every persisted structure must document:
- stable ID fields;
- schema/version field;
- ownership and write authority;
- migration expectations;
- references to other persisted records;
- whether the data is editor-only, runtime-required, or both.

## UI documentation
UI implementation and review must reference `assets/reference/CANONICAL_UI_REFERENCE.png` and `docs/design/UI_UX_CANONICAL_SPEC.md`. Significant intentional visual deviations require a written reason in the handoff or decisions document.

## Evidence language
Do not write that something is "verified", "working", "passing", or "complete" unless the cited evidence actually demonstrates it. If the current environment cannot execute a required check, document the limitation explicitly.

## Maintenance
Prefer editing the smallest canonical document that owns a rule. Avoid copying the same requirement into many files unless a short cross-reference improves discoverability.
