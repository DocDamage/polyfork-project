# Task Backlog

Task IDs use `P##-T##` as internal implementation checkpoints. Pull requests are milestone gates, not task gates, unless a handoff explicitly says otherwise.

## Historically merged phases 0–15
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

The Phase 16 source audit established that historical merge labels were not, by themselves, proof of end-to-end product completeness. Phase 16 closes the verified inherited gaps before release packaging.

## Phase 16 — INHERITED PRODUCT COMPLETENESS AND INTEGRATION CLOSURE — BRANCH VERIFIED
Milestone branch: `dev/phase16-milestone`

Authoritative base: `b4b5e88ef11ba514b1c8755e45e1a9de5cf04613`

Verified implementation/evidence head: `bfdef3e5cb1699268cc23be5c9f4c9b4a9631f93`

- [x] P16-T00 Verify PR #20 merge and authoritative `master`; reconcile transition state
- [x] P16-T01 Audit actual source/runtime paths and define the inherited-completeness milestone
- [x] P16-T02 Repair Home creator routes and New World biome creation/application
- [x] P16-T03 Replace fake Asset Library thumbnails, deepen inspection, and add deterministic semantic ranking
- [x] P16-T04 Move the real application to a user-scoped universal Asset Library with legacy source migration
- [x] P16-T05 Complete authoring camera, marquee selection, visible gizmo, vertex/normal/socket snapping, and exact terrain-aware grounding
- [x] P16-T06 Promote implemented Phase 10 gameplay systems into RPG/Survival/Driving templates
- [x] P16-T07 Materialize Environment water hooks through real transactional providers
- [x] P16-T08 Add focused product/integration/shared-library contracts and strict Godot Smoke coverage
- [x] P16-T09 Run inherited Phase 4–15 regressions, scale/playable checks, visual evidence, and Windows/export/multiplayer evidence
- [x] P16-T10 Close source-level QA and canonical branch documentation
- [ ] P16-GATE Open one completion PR targeting authoritative `master`; review PR-triggered checks; merge only with explicit user authorization

### Phase 16 branch verification
- Phase 16 Contracts — `31653938946` — PASS
- Phase 16 Shared Asset Library — `31653938953` — PASS
- Godot Smoke — `31653938984` — PASS
- Phase 16 Visual Evidence — `31653938948` — PASS
- Phase 16 Inherited Regressions — `31653938981` — PASS
- Phase 16 Windows Export — `31653938952` — PASS

The Windows gate includes real Phase 16 clean-package launch, inherited Phase 14 Small/Medium/Large exports, inherited Phase 15 multiplayer/offline package build, and concurrent exported host/client verification.

## Next milestone boundary
Do not begin creator-application release packaging or a new implementation phase until the Phase 16 completion PR is merged and authoritative `master` is reconciled.

Historical `.polyforkAPI` credential material remains exposed in Git history and requires separate external rotation/revocation. Do not print, copy, restore, or reuse it.
