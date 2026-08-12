# Master Implementation Plan

## Authoritative state
- The real project lives on `master`; repository default branch `main` is obsolete starter code and must not be used for development.
- Authoritative `master`: `b4b5e88ef11ba514b1c8755e45e1a9de5cf04613`, the verified signed GitHub merge commit for PR #20.
- Phases 0 through 15 are complete and merged.
- PR #20 — Phase 15 — Multiplayer Foundations and Collaboration Roadmap is **MERGED** as of `2026-08-12T21:16:19Z`.
- Phase 16 is **UNBLOCKED**. Its implementation scope must be derived from the remaining authoritative requirements and deferred limitations before implementation begins.
- Phase 16 milestone work uses `dev/phase16-milestone`, created directly from authoritative `master` `b4b5e88ef11ba514b1c8755e45e1a9de5cf04613`.

Historical `.polyforkAPI` credential material remains exposed in Git history and must be rotated/revoked separately. Never print, restore, copy, or reuse that credential material.

## Phases 0–15 — COMPLETE / MERGED
The repository contains the completed application shell, world/save foundation, runtime placement editor, Asset Library, terrain/streaming, components/archetypes/prefabs/sockets, Instant Play/templates, Visual Scripting, foliage/procedural/splines, gameplay framework breadth, Environment, AI Creation, Export Pipeline, Scale/Polish, and Multiplayer Foundations/Collaboration Roadmap milestones. See phase-specific implementation documents and merged PR history for detailed evidence.

## Phase 15 — Multiplayer Foundations and Collaboration Roadmap — COMPLETE / MERGED
Milestone branch: `dev/phase15-multiplayer-collaboration-milestone`

Merged completion PR: `#20 — Phase 15 — Multiplayer Foundations and Collaboration Roadmap`

Verified merge commit on authoritative `master`: `b4b5e88ef11ba514b1c8755e45e1a9de5cf04613`

Merged at: `2026-08-12T21:16:19Z`

Phase 15 branch head included in the merge: `5f981a75f7c77ae1d144d1abb30831c57f7abfba`

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

### Verified Phase 15 implementation gates
- Phase 15 Contracts — `31635239746` — PASS — all eight suites
- Phase 15 Inherited Regressions — `31634218734` — PASS
- Godot Smoke — `31635582701` — PASS on final implementation head
- Phase 15 Visual Evidence — `31634842058` — PASS; corrected full/compact evidence inspected
- Phase 15 Windows Multiplayer Export — `31635582699` — PASS; offline package and real concurrent exported host/client

The final documentation-refresh head also passed repository-owned GitHub Actions after transient Godot-download setup failures were retried. Those failures occurred before tests executed and were infrastructure/setup failures rather than product failures. Third-party Cursor, Graphite, and Netlify checks remain distinct from Polyfork-owned verification.

### Scope guard retained
Phase 15 does not claim production matchmaking, cloud relay/account infrastructure, NAT traversal service, voice chat, anti-cheat platform integration, rollback netcode, dedicated-server fleet orchestration, or real-time collaborative editor mutation.

## Phase 16 — UNBLOCKED / SCOPE DISCOVERY IN PROGRESS
Phase 16 must not be defined by assumption or by simply promoting a Phase 15 deferral. Before implementation:

1. inspect the current Product Requirements, Product Decisions, Product Charter, Risk Register, Security/Privacy/Licensing, System Architecture, implementation plans, backlog, QA documents, system documentation, and known deferred limitations;
2. identify the highest-value remaining coherent milestone that advances the authoritative product intent without duplicating existing architecture;
3. define Phase 16 explicitly in the authoritative implementation documentation, including scope, non-goals, architecture reuse, verification gates, and completion evidence;
4. execute the full milestone continuously on `dev/phase16-milestone`;
5. run milestone contracts, inherited regressions, visual evidence, and Windows/export evidence where applicable;
6. perform documentation closeout and open one Phase 16 completion PR targeting `master`.

### Architectural constraints carried into Phase 16
- reuse the existing `PlaySession` architecture;
- keep authored mutation behind existing command / Undo / Redo ownership boundaries;
- reuse stable authored IDs, the gameplay event bus, Visual Scripting architecture, Asset Library contracts, and save/export contracts;
- preserve offline-first behavior and keep multiplayer opt-in;
- keep gameplay replication and collaborative authoring as separate concepts;
- do not create duplicate or placeholder systems solely to satisfy milestone wording.
