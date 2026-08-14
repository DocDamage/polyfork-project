# Phase 19 QA — Candidate Evidence Ledger

## Status

**Implementation candidate; acceptance evidence pending GitHub exact-head workflows.**

This file must not be changed to “complete” merely because source files exist or local static checks pass.

## Authority

- Base: `master@ebeb35e28f53738c63d35429eba1ea40b5c8cdb1`
- Corrective branch: `dev/phase19-completion-correction`
- Corrective PR: pending creation
- Public release/tag: forbidden until separately authorized

## Local pre-push validation

Record the bundle/local results here when applied:

- [ ] Python release tools compile.
- [ ] JSON fixtures parse.
- [ ] GitHub workflow YAML parses.
- [ ] accepted signed manifest fixture verifies.
- [ ] altered/invalid manifest fixtures reject.
- [ ] Phase 19 security/privacy scan passes.
- [ ] Godot 4.7.1 import and contract runner pass locally, or are explicitly deferred to GitHub runners.
- [ ] .NET updater helper builds locally, or is explicitly deferred to the Windows runner.

## Exact-head GitHub evidence

Fill only from the final corrective PR head:

| Evidence | Run / artifact | Result | Notes |
|---|---|---|---|
| Phase 19 source contracts | Pending | Pending | Must include Godot import, signed fixtures, migration/recovery, inherited regressions |
| Phase 19 Windows lifecycle | Pending | Pending | Must include helper, deterministic ZIP, installer, exact 0.1.0 upgrades, repair/rollback, offline/export |
| Publication dry run | Pending | Pending | Must not create a release or tag |
| Phase 18 required-check compatibility | Pending | Pending | Preserves existing required job names while testing current source |
| Portable artifact | Pending | Pending | Record artifact ID, filename, digest, SHA-256 |
| Installer artifact | Pending | Pending | Record artifact ID, filename, digest, SHA-256 |
| Updater helper | Pending | Pending | Record artifact identity/hash |
| Visual evidence | Pending | Pending | Record inventory and manual review |

## Real 0.1.0 source evidence

Accepted source artifacts to verify in CI:

- Phase 18 workflow: `31699466148`
- Phase 18 stable artifact ID: `9180943528`
- `PlayWorld-Studio-0.1.0-Windows-x64.zip`
- portable SHA-256: `f635811f0c9738ba622b91f0a5c890c24ab491ff63ed4f85cdcb12e8ca7a160a`
- `PlayWorld-Studio-0.1.0-Windows-x64-Setup.exe`
- installer SHA-256: `9f639274e4bb7df3e492a8ab9720c7c0b6c6ca12c7f644f8dd1cba4c68ba6a02`

## Visual evidence inventory

Expected active states:

1. Updates idle
2. channel selection
3. update available
4. release notes
5. downloading
6. verifying
7. ready to install
8. update failure
9. repair
10. rollback
11. diagnostics
12. support bundle
13. abnormal-shutdown recovery
14. safe mode
15. compact update layout
16. normal update layout

For each image, record clipping, overlap, hidden controls, focus, readability, product/version/channel identity, developer-facing language, and canonical visual consistency. Screenshot existence is not acceptance.

## Security and privacy review

- [ ] No private key or credential in source/history added by this milestone.
- [ ] Signed envelope tampering rejects.
- [ ] Wrong/expired/revoked/channel-mismatched keys reject.
- [ ] Unsafe URL, filename, archive path, absolute path, drive path, junction, symlink, duplicate inventory, unexpected file, size mismatch, and hash mismatch reject.
- [ ] Application replacement inventory cannot include user projects or persistent user-data roots.
- [ ] Support bundle excludes project content and secrets by default.
- [ ] Production workflow requires explicit authority and exact source/artifact verification.

## Final acceptance decision

Pending. Add the exact final branch SHA, merge candidate, run IDs, artifact IDs, hashes, manual findings, known limitations, and explicit statement that no public release was created before requesting merge authorization.
