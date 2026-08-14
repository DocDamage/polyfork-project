# Phase 19 — PlayWorld Studio 0.2.0 Update and Release Infrastructure

## Purpose

This is the canonical corrective implementation plan after PR #27 integrated only the initial semantic-version and update-manifest foundations. Work proceeds forward from signed `master@ebeb35e28f53738c63d35429eba1ea40b5c8cdb1` on `dev/phase19-completion-correction`.

## Product outcome

A normal user can continue using PlayWorld Studio offline, choose an allowed release channel, inspect a signed update, download and verify it, hand it to a Windows updater, restart into the new version, recover from interruption, repair or roll back application binaries, migrate supported data safely, recover from abnormal shutdown, and create bounded diagnostics without losing authored content.

## Invariants

- Projects and user preferences remain outside the installation directory.
- Updates replace application-owned inventory only.
- External Asset Library source folders remain read-only.
- Startup and ordinary editing never require a network connection.
- Stable never consumes Beta or Development metadata without explicit channel selection.
- Signed metadata is verified before artifact identity is trusted.
- Artifact size and SHA-256 are revalidated before handoff.
- Migration writes a recoverable backup before destructive-format changes.
- A private signing key never enters source, packages, logs, diagnostics, or support bundles.
- No normal PR or merge publishes a release.

## Implementation workstreams

### P19-T01/T02 — Update service and channels

- Background checks are deferred and bounded.
- Manual checks remain available.
- Network errors become an offline update state, not an application startup failure.
- Stable is default; Beta is explicit; Development requires an internal opt-in setting.
- Preferences persist outside project data, with backoff and cached state.
- Manifest and artifact URLs are checked against per-channel HTTPS host allowlists.

### P19-T03 — Signed manifests

- Strict envelope, payload, trust-registry, and artifact shapes.
- RSA PKCS#1 v1.5 with SHA-256 verification over canonical payload bytes.
- Key activation, expiration, revocation, channel authorization, and rotation-ready key IDs.
- Exact product, version, channel, source, platform, architecture, filename, URL, byte size, and SHA-256.
- Stable prerelease rejection, downgrade rejection, future-time bounds, duplicate inventory rejection, and unknown-field rejection.

### P19-T04/T05 — Download, staging, and lifecycle handoff

- One active update job at a time.
- `.part` staging outside live binaries, progress, cancellation, abandoned-partial cleanup, exact length/hash verification, and atomic promotion to ready state.
- External self-contained Windows helper receives a short-lived bounded request.
- Portable replacement extracts into a bounded staging directory and replaces application-owned inventory only.
- Installed replacement launches the approved installer silently at the existing location.
- Restart executable is constrained to the application root.

### P19-T06 — Journal, repair, interruption recovery, and rollback

- Durable operation ID, stage, artifact, application root, backup root, inventories, completed paths, errors, and outcome.
- Active or failed recovery journal cannot be silently overwritten.
- Choosing repair archives the interrupted journal before beginning a new repair operation.
- Helper verifies requests, artifacts, archive paths, package identity, and backup inventory.
- Failure after backup attempts verified restoration.
- Rollback restores the previous verified application inventory without deleting unrelated files.

### P19-T07 — Sequential migration

- Application migration registry and persisted migration journal.
- Ordered, idempotent project and preference steps.
- Backup before mutation, failure restoration, interrupted-step recovery, and unsupported-future-schema refusal.
- Application version remains distinct from project/data schema version.

### P19-T08/T09 — Session recovery and diagnostics

- Startup session marker and clean-shutdown marker.
- Recovery overlay after abnormal shutdown.
- Safe mode disables optional update networking, cloud AI, and multiplayer for the session without touching project files.
- Preference reset preserves the prior file as a backup.
- Diagnostics use redacted logical locations and bounded state.
- Support bundles are local, user initiated, privacy scanned, and exclude project content and credentials by default.

### P19-T10/T11 — Production UX and accessibility

- Update Center embedded in Settings.
- Current/available version, channel, release notes, progress, verification, ready/install, failure, repair, rollback, safe mode, diagnostics, and support actions.
- Visible deterministic focus, `ui_accept`, `ui_cancel`, focus restoration, controller-only navigation, compact density, UI scaling, and reduced-motion compatibility.

### P19-T12/T13 — Publication and security

- Production workflow is `workflow_dispatch` only, protected by an environment and explicit phrase.
- Exact approved source and successful artifact run are verified.
- Artifacts are validated before draft creation, re-downloaded after upload, and hash/signature checked again.
- Public publication happens only when the explicit boolean authorization is true.
- Source/package/log/support scans cover private keys, credentials, unsafe paths, archive traversal, reparse points, size bounds, duplicates, hashes, and user-data boundary errors.

### P19-T14/T15/T16 — End-to-end evidence

- Offline startup, open/create/edit/save/reopen, Instant Play, diagnostics, and Windows export.
- Exact accepted Phase 18 `0.1.0` artifacts and recorded hashes.
- Real portable and installed `0.1.0 → 0.2.0` paths.
- Repair, injected interruption, rollback, uninstall/reinstall, and preserved user data.
- Sixteen or more active-state screenshots across normal and compact layouts.
- Automation verifies active screen state; humans still inspect every screenshot.

## Required workflows

- `Phase 19 Contracts and Security / source-contracts`
- `Phase 19 Windows Update Lifecycle / windows-update-lifecycle`
- `Phase 19 Publication Dry Run / publication-dry-run`
- inherited required-check compatibility jobs under `Phase 18 Stable Release`

The production `Publish PlayWorld Studio Release` workflow is not a completion test and must not be run without explicit publication authorization.

## Completion gate

Phase 19 is complete only after all exact-head evidence is green and reconciled in `docs/qa/PHASE19_QA.md`, all screenshots are manually inspected, no Priority 0 or unresolved Priority 1 Phase 19 blocker remains, the corrective PR remains unmerged for owner review, and no unauthorized release or tag exists.
