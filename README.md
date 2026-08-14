# PlayWorld Studio / Polyfork Project

PlayWorld Studio is a Windows-first Godot 4.7.x creator application for building, playing, and exporting interactive 3D worlds through a runtime-first workflow.

## Current authoritative state

- Repository authority: protected `master`
- Historical `main`: obsolete starter code; never develop from it
- Authoritative integrated commit: `ebeb35e28f53738c63d35429eba1ea40b5c8cdb1`
- Accepted milestones: Phases 0 through 18
- Accepted public product: PlayWorld Studio `0.1.0` stable for Windows x86_64
- Premature integration: PR #27 merged only the initial Phase 19 semantic-version and update-manifest foundations
- Active corrective branch: `dev/phase19-completion-correction`
- Active milestone: Phase 19 corrective completion for the `0.2.0` update and release infrastructure
- Phase 20: unauthorized

The `0.2.0` source identity in the corrective branch is a release candidate identity for testing. It is not proof that Phase 19 is accepted and does not authorize a public release or tag.

## Phase 19 corrective scope

The corrective milestone adds and verifies:

- nonblocking, offline-safe update checks;
- Stable, Beta, and explicitly enabled Development channels;
- strict RSA/SHA-256 signed update manifests and key policy;
- verified download, staging, progress, cancellation, and helper handoff;
- distinct portable and installed Windows update lifecycles;
- durable update journals, application-only backup, repair, interruption recovery, and binary rollback;
- sequential project/preference migration with backups and journals;
- abnormal-shutdown recovery, safe mode, and non-destructive preference reset;
- bounded local diagnostics and privacy-scanned support bundles;
- production Update Center UI with keyboard, mouse, and controller paths;
- manual-authority publication workflow that validates uploaded artifacts before publication;
- real accepted `0.1.0 → 0.2.0` portable and installed upgrade gates;
- deterministic portable packaging, installer validation, security scans, and visual evidence.

## Release boundary

Do not create `v0.2.0`, publish a GitHub Release, merge the corrective PR, or begin Phase 20 merely because the corrective source exists. Phase 19 completes only after the exact final PR head passes the full Linux/source and Windows lifecycle workflows, artifacts and hashes are recorded, screenshots are manually reviewed, and the owner explicitly authorizes merge.

## Start here

- `docs/handoffs/CURRENT_HANDOFF.md`
- `docs/implementation/PHASE19_UPDATE_RELEASE_INFRASTRUCTURE_PLAN.md`
- `docs/qa/PHASE19_QA.md`
- `docs/release/UPDATE_CHANNELS.md`
- `docs/release/MIGRATION_ROLLBACK_RECOVERY.md`
- `docs/release/SECURITY_PRIVACY.md`
- `docs/release/PUBLICATION_AND_INCIDENTS.md`
- `docs/implementation/PLAYWORLD_STUDIO_1_0_IMPLEMENTATION_PLAN.md`

## Development rules

- Start from current protected `master`, never obsolete `main`.
- Use one dedicated milestone branch and one milestone PR.
- Preserve projects, preferences, Asset Library state, checkpoints, recovery data, and support data outside installation directories.
- Never weaken security, migration, packaging, controller, accessibility, export, or visual gates to obtain a green workflow.
- Never commit a private signing key or credential.
- Keep the corrective PR open and unmerged until explicit authorization.
