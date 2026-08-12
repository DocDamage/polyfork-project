# Master Implementation Plan

## Authoritative state
- The real project lives on `master`; repository default branch `main` is obsolete starter code and must not be used for development.
- Authoritative `master` before Phase 15 merge: `14085eb703b72d930f39121d3da18362d43cc77d`, the verified signed merge commit for PR #19.
- Phases 0 through 14 are complete and merged.
- Phase 15 — Multiplayer Foundations and Collaboration Roadmap is **implementation complete** on `dev/phase15-multiplayer-collaboration-milestone`.
- Completion PR **#20 is OPEN / NOT MERGED**.
- The branch head immediately before this pre-merge documentation refresh was `72ab4d275fc5dbfeb69b35ab1679fee8588616b6`, 60 commits ahead / 0 behind authoritative `master`, with merge base exactly authoritative `master`.
- This documentation refresh intentionally moves the PR head again. The live PR head and all required checks must be fetched again immediately before merge; do not treat `72ab4d...` as the final merge SHA.
- Phase 16 remains blocked until PR #20 is explicitly merged and the resulting authoritative `master` SHA is verified.

## Phases 0–14 — COMPLETE / MERGED
The repository contains the completed application shell, world/save foundation, runtime placement editor, Asset Library, terrain/streaming, components/archetypes/prefabs/sockets, Instant Play/templates, Visual Scripting, foliage/procedural/splines, gameplay framework breadth, Environment, AI Creation, Export Pipeline, and Scale/Polish milestones. See phase-specific implementation documents and merged PR history for detailed evidence.

Historical `.polyforkAPI` credential material remains exposed in Git history and must be rotated/revoked separately.

## Phase 15 — Multiplayer Foundations and Collaboration Roadmap — COMPLETE / PR #20 OPEN
Branch: `dev/phase15-multiplayer-collaboration-milestone`

Base: `14085eb703b72d930f39121d3da18362d43cc77d`

Verified implementation head before documentation closeout: `93b67eb5e50ffe5b2b686027d6a400ee9ccff1f0`

Pre-merge documentation refresh started from: `72ab4d275fc5dbfeb69b35ab1679fee8588616b6`

Completion PR: `#20 — Phase 15 — Multiplayer Foundations and Collaboration Roadmap`

### Delivered
- versioned runtime-only session/peer/network identity layered over authored stable IDs;
- Offline/Host/Client roles and project-owned Godot 4.7.1 ENet transport;
- compatibility handshake, peer lifecycle, reconnect/host-disconnect/repeated-session cleanup;
- existing first/third-person controllers extended for local-input ownership and remote player replication;
- host-authoritative health/damage/heal and door/interaction replication with client spoof/direct-authority rejection;
- opt-in multiplayer template capability, bounded player limits, teams, spawn strategy/offsets, score/objective match state;
- bounded Visual Scripting integration through the existing gameplay event/action route;
- accessible adaptive canonical Multiplayer panel with Offline / Host & Play / Join & Play;
- host-only runtime save authority;
- optional export dependency closure so offline builds omit networking and multiplayer builds package required network dependencies/capability metadata;
- export-aware standalone Host/Client startup and real concurrent Windows two-process verification;
- Small/Medium/Large bounded multiplayer state coverage;
- inherited Phase 6–14 regressions and corrected rendered full/compact evidence;
- design-complete collaborative-authoring roadmap explicitly separating durable collaboration from transient gameplay replication.

### Verified implementation gates
- Phase 15 Contracts — `31635239746` — PASS — all eight suites
- Phase 15 Inherited Regressions — `31634218734` — PASS
- Godot Smoke — `31635582701` — PASS on final implementation head
- Phase 15 Visual Evidence — `31634842058` — PASS; corrected full/compact evidence inspected
- Phase 15 Windows Multiplayer Export — `31635582699` — PASS; offline package and real concurrent exported host/client

### Pre-documentation-refresh PR CI audit
At head `72ab4d...`, several PR workflows initially failed before tests because GitHub runners could not download Godot 4.7.1. Failed jobs were rerun without product-code changes; the executable GitHub Actions workflows subsequently completed successfully, including Phase 15 Contracts, Phase 15 inherited regressions, Godot Smoke, Phase 6/7 historical contracts, and the other triggered regression workflows.

The PR aggregate still reported `mergeable_state: unstable` because third-party GitHub App suites from Cursor, Graphite App, and Netlify were stuck queued with zero check runs. These are tracked as external integration state, not Phase 15 product-test failures. See `docs/qa/PHASE15_QA.md`.

### Scope guard retained
Phase 15 does not claim production matchmaking, cloud relay/account infrastructure, NAT traversal service, voice chat, anti-cheat platform integration, rollback netcode, dedicated-server fleet orchestration, or real-time collaborative editor mutation.

## Pre-merge gate
1. Push/commit this documentation refresh to the existing Phase 15 branch.
2. Fetch the new PR #20 head SHA.
3. Verify branch remains ahead of and not behind authoritative `master`, with merge base still `14085eb...` unless `master` intentionally advanced.
4. Inspect newly triggered GitHub Actions checks; separate executed product failures from infrastructure/setup failures.
5. Inspect external GitHub App suites separately and determine whether any are actually required.
6. Do **not** merge without explicit user authorization.
7. After authorized merge, verify the resulting signed/authoritative `master` SHA and only then open Phase 16.

## Phase 16 — BLOCKED
Do not begin Phase 16 until PR #20 is explicitly merged and the resulting authoritative `master` SHA is verified.
