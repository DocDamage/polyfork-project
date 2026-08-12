# Task Backlog

Task IDs use `P##-T##` as internal implementation checkpoints. Pull requests are milestone gates, not task gates, unless a handoff explicitly says otherwise.

## Completed phases 0–15
Phases 0 through 15 are complete and merged on authoritative `master`.

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
- [x] Phase 12 — AI Creation — PR #17
- [x] Phase 13 — Export Pipeline — PR #18
- [x] Phase 14 — Scale and Polish — PR #19
- [x] Phase 15 — Multiplayer Foundations and Collaboration Roadmap — PR #20

Authoritative `master`: `b4b5e88ef11ba514b1c8755e45e1a9de5cf04613`

## Phase 15 — COMPLETE / MERGED
Milestone branch: `dev/phase15-multiplayer-collaboration-milestone`

Merged completion PR: `#20 — Phase 15 — Multiplayer Foundations and Collaboration Roadmap`

Merged at: `2026-08-12T21:16:19Z`

Phase 15 branch head included in the merge: `5f981a75f7c77ae1d144d1abb30831c57f7abfba`

- [x] P15-T01 Network identity/session contracts
- [x] P15-T02 ENet host/client transport and lifecycle
- [x] P15-T03 Multiplayer spawn/ownership/movement replication
- [x] P15-T04 Host-authoritative gameplay replication
- [x] P15-T05 Template/match/Visual Scripting multiplayer hooks
- [x] P15-T06 Accessible adaptive Offline/Host/Join UX
- [x] P15-T07 Save authority/reconnect/failure hardening
- [x] P15-T08 Optional export closure and exported two-process Windows verification
- [x] P15-T09 Collaborative-authoring architecture roadmap
- [x] P15-T10 Full verification/evidence/docs/completion PR
- [x] P15-T11 Pre-merge canonical documentation audit/refresh
- [x] P15-GATE PR #20 merge verification and authoritative `master` reconciliation

### Phase 15 completion verification
- Phase 15 Contracts — `31635239746` — PASS — all eight suites
- Phase 15 Inherited Regressions — `31634218734` — PASS
- Godot Smoke — `31635582701` — PASS
- Phase 15 Visual Evidence — `31634842058` — PASS
- Phase 15 Windows Multiplayer Export — `31635582699` — PASS

Later pre-merge GitHub Actions setup/download failures were retried and repository-owned executable checks completed successfully without product-code changes. Third-party Cursor/Graphite/Netlify suite state is tracked separately from Polyfork-owned verification.

## Phase 16 — UNBLOCKED / SCOPE DISCOVERY
Milestone branch: `dev/phase16-milestone`

Authoritative base: `b4b5e88ef11ba514b1c8755e45e1a9de5cf04613`

The Phase 16 implementation scope is intentionally not assigned until the remaining authoritative requirements and deferred limitations have been audited.

- [x] P16-T00 Verify PR #20 merge and authoritative `master`; reconcile stale post-merge status documentation
- [ ] P16-T01 Audit Product Requirements, Decisions, Charter, Risks, Security, System Architecture, implementation/backlog/QA/system documentation, and deferred limitations
- [ ] P16-T02 Select the highest-value coherent remaining milestone and define explicit scope/non-goals/architecture/acceptance gates
- [ ] P16-T03+ Implement the complete defined milestone continuously; detailed checkpoints are added only after scope is evidence-backed
- [ ] P16-QA Run milestone contracts, inherited regressions, visual evidence, and Windows/export evidence where applicable
- [ ] P16-DOC Close canonical documentation and prepare the Phase 16 handoff
- [ ] P16-GATE Open one completion PR targeting authoritative `master`

Historical `.polyforkAPI` credential material remains exposed in Git history and requires separate external rotation/revocation. Do not print, copy, restore, or reuse it.
