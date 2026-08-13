# Phase 17 — Release Candidate and Distribution

Authoritative base: `master@37d311b90f0684668a49e7f3b8ab197e6abcbe3a`

Milestone branch: `dev/phase17-milestone`

Single PR boundary: one completed Phase 17 PR to `master`; do not merge without explicit user authorization.

## Product boundary

Phase 17 packages **PlayWorld Studio itself**. The existing `PlayWorldExportPipeline` remains the authored-game exporter and is extended only where required so a distributed creator can invoke the required Godot tooling independently of a development checkout.

## Implementation checkpoints

- P17-T01 product/version identity, icon, Windows metadata, About/version surface;
- P17-T02 dedicated creator Windows export preset;
- P17-T03 deterministic ZIP package with only shipped creator/tooling/docs;
- P17-T04 packaged clean-user create/author/save/restart/reopen/Instant Play/Asset Library/export/launch gate;
- P17-T05 packaged creator carries required Godot exporter/template and explicit tooling/template failure handling;
- P17-T06 per-user project/library/preferences paths, malformed preferences, relocation/upgrade-style and read-only-style package verification;
- P17-T07 production-facing explicit failure handling/no fake success;
- P17-T08 packaged visual and inherited controller/focus acceptance;
- P17-T09 release manifest, SHA-256, Godot/source/package identity, included-file validation, third-party notices, forbidden-material scan;
- P17-T10 dedicated release CI with bounded package/evidence artifacts;
- P17-T11 release/user/troubleshooting docs plus canonical plan/backlog/handoff reconciliation;
- P17-T12 full inherited release-candidate regression before the completion PR.

No release-candidate completion claim is valid until the dedicated packaged-app workflow is green and its package/evidence artifact is present.
