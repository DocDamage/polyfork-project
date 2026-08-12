# Task Backlog

Task IDs use `P##-T##` as internal implementation checkpoints. Pull requests are milestone gates, not task gates, unless a handoff explicitly says otherwise.

## Completed phases 0–11
All Phase 0 through Phase 11 checkpoints are complete and merged on authoritative `master`. Historical task detail remains represented by the merged repository history and corresponding phase handoffs/PRs.

- [x] Phase 0 — Repository and contracts
- [x] Phase 1 — App shell and canonical UI foundation
- [x] Phase 2 — World project + save foundation
- [x] Phase 3 — Runtime Placement Editor
- [x] Phase 4 — Universal Asset Library — PR #9
- [x] Phase 5 — Terrain + Streaming — PR #10
- [x] Phase 6 — Components, Archetypes, Prefabs — PR #11
- [x] Phase 7 — Instant Play + Templates — PR #12
- [x] Phase 8 — Visual Scripting — PR #13
- [x] Phase 9 — Foliage / Procedural / Splines — PR #14
- [x] Phase 10 — Gameplay Framework Breadth — PR #15
- [x] Phase 11 — Environment — PR #16

## Phase 12 — AI Creation — COMPLETE
Phase 12 is complete and merged on authoritative `master` by PR #17 at `b2a97a6cea52c6620f2b826a390a1d2d531ad81e`.

- [x] P12-T01 Implement schema-v1 AI request/proposal/action/history contracts, provider descriptors, privacy policy, limits, and user-scoped provider configuration that never persists credentials in project data
- [x] P12-T02 Implement provider registry plus real OpenAI-compatible local/cloud HTTP adapter with environment-scoped credentials, structured responses/tool calls, timeout/cancel/error handling, and cloud/local disclosure metadata
- [x] P12-T03 Implement bounded read-only AI query tools over the actual project and Phase 4 Asset Library, including entities, gameplay, terrain/biomes, Visual Scripting, procedural systems, Environment state, asset licenses, and exact stable IDs
- [x] P12-T04 Implement strict proposal/action validation, deterministic normalization, action limits, stable-reference checking, and explicit rejection of unavailable/missing assets or unsupported provider output
- [x] P12-T05 Implement Suggest mode as read-only provider orchestration with bounded query/tool loops, project-aware recommendations, and zero authored mutation
- [x] P12-T06 Implement Preview mode with deterministic action impact summaries/diffs, source-asset lineage, validation findings, and zero authored mutation
- [x] P12-T07 Implement Execute mode by composing existing subsystem commands into one atomic universal transaction with rollback, one-step Undo/Redo, dirty-state integration, and project-managed AI execution history
- [x] P12-T08 Implement representative cross-system AI actions for existing-asset placement/transforms, gameplay composition, Visual Scripting graph creation, procedural settings/creation, and Environment authoring without parallel state systems
- [x] P12-T09 Implement native AI workspace behind the existing AI dock entry with provider/mode/prompt/context/result controls, explicit local/cloud disclosure, keyboard/mouse and gamepad authoring, Preview-before-Execute UX, and cancellation/status handling
- [x] P12-T10 Complete privacy/credential, project/catalog query, missing-asset, invalid-provider-output, Suggest/Preview/Execute isolation, atomic rollback/Undo, save/reopen/history, cross-system, gamepad, scale/performance, strict-log, inherited regression, Godot Smoke, rendered visual evidence, documentation closeout, and one Phase 12 completion PR

## Phase 13 — Export Pipeline — ACTIVE
Phase 13 is active on `dev/phase13-export-pipeline-milestone`, created from exactly authoritative `master` `b2a97a6cea52c6620f2b826a390a1d2d531ad81e`. The pre-write comparison was verified at 0 ahead / 0 behind with that exact merge base.

- [ ] P13-T01 Define schema-v1 export/build manifest, deterministic package layout, runtime/editor classification contracts, validation limits, and export result/report contracts
- [ ] P13-T02 Implement deterministic dependency discovery across authored world entities, Phase 6 gameplay/prefab sources, Phase 7 template/runtime modules, Phase 8 Visual Scripting, Phase 9 procedural sources, Phase 11 Environment hooks, and project-managed runtime data
- [ ] P13-T03 Integrate Phase 4 Asset Library dependency resolution, deterministic copy/import staging, source lineage, missing/unavailable dependency hard failures, and safe external-source read behavior
- [ ] P13-T04 Implement license/attribution aggregation and deterministic export reporting for every shipped external dependency, including unknown/missing-license findings without inventing license grants
- [ ] P13-T05 Implement deterministic project assembly/staging that strips editor shell/workspaces/authoring-only code and non-runtime project data while preserving all runtime-required authored data and dependencies
- [ ] P13-T06 Implement standalone runtime bootstrap that reuses the Phase 7 Play/runtime foundation, template/runtime-module resolution, semantic input, terrain/streaming, gameplay, Visual Scripting, procedural, and Environment runtime paths without a parallel runtime architecture
- [ ] P13-T07 Implement Windows standalone export orchestration/preset generation, deterministic output/package structure, safe output-path handling, repeat-export replacement/idempotency behavior, and actionable Godot export failures
- [ ] P13-T08 Implement Build → Export integration/status surface with keyboard/mouse and gamepad reachability while preventing export during invalid/transient project states
- [ ] P13-T09 Add Phase 13 contract/integration tests for manifests, classification, dependency/license resolution, stripping/preservation, missing dependencies, idempotency, Small/Medium/Large representative projects, and inherited Phase 6–12 behavior
- [ ] P13-T10 Complete real Windows Build → Export → standalone launch smoke, clean-machine-style package verification, keyboard/mouse and gamepad runtime checks, strict Godot log gates, inherited regressions, rendered/exported runtime evidence, documentation closeout, and one Phase 13 completion PR

## Later phases
Before beginning a later phase, decompose it into implementation-sized internal checkpoints. Use intermediate commits and CI runs inside the milestone, then open one PR at the milestone boundary.

Do not begin Phase 14 until the Phase 13 completion PR is explicitly merged into authoritative `master` and the resulting `master` SHA is verified.
