# POLYFORK PROJECT — PHASE 12 ACTIVE HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authoritative branch

The real project lives on `master`.

Current authoritative `master`:

`d7245cad68b512fc5cbf9b897bce506ecbb9837d`

This is the verified merge commit for PR #16 — Phase 11 — Environment.

The repository default branch `main` remains obsolete starter code.

**Never develop from `main`.**

## Completed state

PR #16 is merged.

Phases 0 through 11 are complete on authoritative `master`.

## Phase 12 milestone branch

Phase 12 — AI Creation — is active on:

`dev/phase12-ai-creation-milestone`

The branch was created from exactly:

`d7245cad68b512fc5cbf9b897bce506ecbb9837d`

The branch/base comparison was verified identical before Phase 12 writes: zero commits ahead and zero commits behind.

No obsolete `main` ancestry is being used.

Phase 12 must be developed as one continuous milestone without task-by-task pull requests.

## Phase 12 objective

Deliver reusable AI-assisted authoring that can inspect the real project and real local asset catalog, return bounded structured suggestions/proposals, preview deterministic changes without mutation, and execute approved changes through the existing universal command/transaction architecture.

AI providers never receive direct write access to project files. Authored Build data remains authoritative. Provider output is untrusted input and must be schema-validated before Preview or Execute. Existing subsystem services/commands remain the implementation path; Phase 12 must not create parallel world, gameplay, graph, procedural, or environment state.

## Phase 12 checkpoints

- [ ] P12-T01 — schema-v1 request/proposal/action/history contracts, provider descriptors, privacy/limits, user-scoped provider configuration, no persisted credentials
- [ ] P12-T02 — provider registry and real OpenAI-compatible local/cloud HTTP adapter with structured responses/tool calls, timeouts/cancel/errors, environment credentials, disclosure metadata
- [ ] P12-T03 — bounded read-only project/catalog query tools over real entities/assets/gameplay/terrain/graphs/procedural/environment state with exact stable IDs and licensing metadata
- [ ] P12-T04 — strict proposal/action validation, deterministic normalization, stable-reference checks, action limits, missing/unavailable asset rejection
- [ ] P12-T05 — Suggest mode with bounded provider/tool orchestration and zero authored mutation
- [ ] P12-T06 — Preview mode with deterministic impact summaries/diffs, source-asset lineage, findings, zero authored mutation
- [ ] P12-T07 — Execute mode as one atomic universal transaction with rollback, one-step Undo/Redo, dirty state, and crash-safe AI history
- [ ] P12-T08 — cross-system actions for existing-asset placement/transforms, gameplay composition, Visual Scripting graph creation, procedural authoring, and Environment authoring
- [ ] P12-T09 — native AI workspace behind existing AI dock entry with provider/mode/prompt/context/results, local/cloud disclosure, Preview-before-Execute, keyboard/mouse/gamepad, cancellation/status
- [ ] P12-T10 — privacy/query/missing-asset/provider-output/Suggest/Preview/Execute/atomic rollback/Undo/save-reopen/history/cross-system/gamepad/scale/strict-log/inherited regression/Godot Smoke/rendered evidence closeout

## Architecture inspection findings before implementation

- `src/ai` is intentionally reserved and contains only `.gitkeep`, making it the correct Phase 12 module boundary.
- Phase 2 already owns stable IDs, command transactions, rollback, universal Undo/Redo, crash-safe project persistence, and dirty-state signaling; AI Execute must use those instead of adding a second history system.
- Phase 3 already owns world entity placement/transforms/runtime bridging; AI world actions must compile to existing world commands and stable entity/asset IDs.
- Phase 4 already exposes a real read-only Asset Library query surface and stable asset records; AI asset-based proposals must resolve against this catalog and may not invent unavailable assets.
- Phase 5, Phase 6/10, Phase 8, Phase 9, and Phase 11 already own terrain/biomes, gameplay, Visual Scripting, procedural content, and environment authored state with snapshot commands/repositories; AI cross-system execution should compose those commands into one transaction.
- The existing bottom dock already contains an `AI` category and semantic color token, so Phase 12 can add an AI workspace layer without changing the canonical dock structure.
- Security documentation requires API keys to remain environment/user scoped and cloud sharing to be explicit. Provider/project metadata may be persisted, but credentials must not be written into project repositories or AI history.
- A token-shaped repository file named `.polyforkAPI` exists from earlier project state. Phase 12 must not read, expose, or reuse it as an AI credential; provider credential lookup is isolated to environment/user-scoped configuration.

## Verification required before completion PR

- user-scoped provider profile persistence without credential persistence;
- local-only and cloud-consent enforcement;
- provider timeout, cancellation, malformed JSON, unsupported output, missing credential, and remote-error paths;
- real Asset Library/project queries and bounded/sanitized cloud context;
- missing/unavailable asset rejection;
- strict proposal/action/reference validation and action-count limits;
- Suggest and Preview zero-mutation guarantees;
- Execute one-transaction / one-Undo semantics and rollback on subcommand failure;
- save/reopen AI execution history with exact source asset IDs and no credentials;
- world/gameplay/graph/procedural/environment cross-system actions through existing systems;
- Build → Play → Build isolation and no provider writes during Play;
- keyboard/mouse and gamepad AI workspace authoring;
- representative catalog/project/action scale/performance checks;
- strict Godot log gates;
- inherited Phase 6–11 regression gates;
- rendered Phase 12 visual evidence;
- Godot Smoke.

## Completion gate

After all P12 checkpoints and verification are complete, open exactly one Phase 12 completion PR from `dev/phase12-ai-creation-milestone` to authoritative `master`.

Do not merge that PR without explicit user authorization.

Do not begin Phase 13 until the Phase 12 completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.
