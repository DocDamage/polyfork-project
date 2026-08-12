# Risk Register

## R1 — Scope explosion
Mitigation: phased delivery, strict handoff authorization, data-driven extensibility before adding every genre feature.

## R2 — Runtime editor performance
Mitigation: command coalescing, streamed cells, instancing, async/throttled indexing, benchmark worlds, and Low/Balanced/High performance profiles.

## R3 — Arbitrary asset quality
Mitigation: inspector metrics, warnings, import profiles, collision/LOD tooling, never assume imported assets are production-ready.

## R4 — Visual scripting becomes a second engine
Mitigation: nodes wrap normal component/service APIs; GDScript remains extension path; later systems such as multiplayer integrate through bounded existing event/service boundaries.

## R5 — Save corruption
Mitigation: schema versions, atomic writes, checkpoints, dirty-cell isolation, migrations with backups, and host-only authoritative runtime save responsibility for network Play.

## R6 — AI causes destructive/untraceable edits
Mitigation: Suggest/Preview/Execute modes, catalog grounding, top-level transactions, history, one-step undo.

## R7 — UI becomes complex
Mitigation: canonical visual reference, progressive disclosure, contextual panels, adaptive full/compact layouts, controller focus, and usability acceptance checks.

## R8 — Licensing confusion across huge libraries
Mitigation: first-class source/license metadata and export warnings.

## R9 — Gameplay networking is mistaken for production online infrastructure
Mitigation: keep Phase 15 explicitly bounded to direct-connect ENet foundations; document that matchmaking, relay/NAT traversal, account/auth, anti-cheat, voice, rollback, and dedicated-server fleets are not implemented.

## R10 — Multiplayer corrupts authored identity/state
Mitigation: runtime-only session/peer/network IDs, host-authoritative replicated mutation, client save-authority rejection, disposable Play teardown, and tests proving authored stable IDs are not rewritten by networking lifecycle.

## R11 — CI/provider flakiness is misdiagnosed as product regression
Mitigation: distinguish setup/download failures from executed test failures; rerun only failed infrastructure jobs when appropriate; preserve earlier complete green evidence; do not weaken product tests to accommodate runner/network failures.

## R12 — Third-party GitHub App checks remain queued or stale
Mitigation: treat external app suites separately from Polyfork GitHub Actions, do not push dummy code solely to clear them, and verify whether any external suite is actually required before merge.
