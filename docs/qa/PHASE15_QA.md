# Phase 15 QA — Multiplayer Foundations and Collaboration Roadmap

## Scope
This document is the canonical Phase 15 verification summary for multiplayer runtime foundations, template/match integration, adaptive UX, optional export closure, and the explicit boundary between gameplay networking and future collaborative authoring.

## Verified implementation evidence
The following runs were completed before the pre-merge documentation refresh and remain the primary implementation evidence:

- **Phase 15 Contracts** — run `31635239746` — PASS — all eight suites
  - identity
  - loopback
  - replication
  - templates
  - lifecycle
  - match
  - export
  - scale
- **Phase 15 Inherited Regressions** — run `31634218734` — PASS
- **Godot Smoke** — run `31635582701` — PASS on final implementation head
- **Phase 15 Visual Evidence** — run `31634842058` — PASS; full and corrected compact captures were inspected
- **Phase 15 Windows Multiplayer Export** — run `31635582699` — PASS; builds offline/multiplayer packages and launches real concurrent exported host/client processes

## Runtime acceptance covered
- versioned compatibility/session contract;
- Offline/Host/Client ENet lifecycle;
- peer join/leave/reconnect/host termination cleanup;
- runtime-only network identity layered over authored stable IDs;
- local input enabled for the local player and disabled for remote player replicas;
- host-authoritative gameplay action/result convergence and spoof rejection;
- host-authoritative match membership/team/score/objective state;
- host-only runtime persistence authority;
- repeated Play start/stop isolation;
- Small/Medium/Large bounded state coverage.

## Export acceptance covered
- offline export excludes Phase 15 network runtime/profile;
- multiplayer export includes required network runtime closure;
- generated `runtime_data/multiplayer_profile.json` exists only for enabled multiplayer capability;
- repeat export clears stale package content;
- exported standalone bootstrap dynamically loads networking only when capability/role requires it;
- Windows host/client exported processes reach expected two-peer convergence;
- keyboard/mouse and gamepad semantic Play bindings remain present in exported multiplayer verification.

## Visual acceptance covered
Phase 15 captures include:
- full Multiplayer panel;
- Host armed state;
- compact Join armed state at 1024×640.

The compact-state correction keeps the right-side contextual panel fully inside the viewport.

## Pull-request CI incident on head `72ab4d...`
Opening/finalizing PR #20 caused the repository's broad historical workflow stack to run again. Several jobs initially failed at **Download Godot 4.7.1** before their product test/capture step executed.

The failures were classified as infrastructure-only because:
- checkout succeeded;
- the Godot download step failed;
- the actual test/capture step was skipped;
- companion matrix shards that downloaded Godot successfully executed and passed.

Failed jobs were rerun without product-code changes. The pull-request GitHub Actions workflows subsequently recovered, including Phase 15 Contracts, Phase 15 inherited regressions, Godot Smoke, and the previously affected historical Phase 6/7/8/9/11/12/13/14 gates.

This incident must **not** be rewritten as either a product test failure or a pass of a test that never ran. The rerun that actually executes the test is the relevant result.

## External GitHub App check suites
At pre-refresh head `72ab4d...`, GitHub still reported PR #20 as `mergeable: true` with `mergeable_state: unstable` even after repository-owned Actions workflows recovered.

The remaining known aggregate-state contributors were external suites created with zero check runs:
- Cursor — suite `85823513315` — queued, `latest_check_runs_count: 0`;
- Graphite App — suite `85823513523` — queued, `latest_check_runs_count: 0`;
- Netlify — suite `85823513725` — queued, `latest_check_runs_count: 0`.

These are third-party integration states, not Phase 15 contract/runtime failures. They may need to be re-requested/configured/disabled through their owning GitHub App settings if they are intended to participate in merge readiness.

## Pre-merge rule after documentation refresh
This QA document itself changes the PR head. Therefore prior head `72ab4d...` is no longer sufficient for merge authorization.

Before merge:
1. fetch PR #20 and record the new exact head SHA;
2. compare the new head to authoritative `master`;
3. inspect newly triggered repository-owned Actions workflows;
4. if a job is red, determine whether the actual product test executed before deciding whether code must change;
5. inspect external app suites separately;
6. merge only with explicit user authorization and an expected-head guard;
7. verify the resulting authoritative/signed `master` SHA after merge.

## Scope not claimed
Phase 15 does not verify or claim production matchmaking, relay/NAT traversal, account authentication, hostile-internet security, voice chat, anti-cheat platform integration, rollback netcode, dedicated-server fleet orchestration, or real-time collaborative editor mutation.
