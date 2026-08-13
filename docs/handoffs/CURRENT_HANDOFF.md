# POLYFORK PROJECT — PHASE 18 COMPLETION HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authority

Repository default and authoritative integrated branch: `master`.

Authoritative `master`:

`91b8b9c39fddda4b80ad5c6101d563245ef3e2d0`

This is the verified signed merge of **PR #22 — Phase 17 — Release Candidate and Distribution**. Phases **0 through 17 are complete and merged**. Historical `main` is obsolete starter code and must not be used.

## Phase 18

Milestone: **Stable Release and Windows Productization**.

Branch: `dev/phase18-stable-release`.

Target product: `PlayWorld Studio 0.1.0`.

Portable package: `PlayWorld-Studio-0.1.0-Windows-x64.zip`.

Installer: `PlayWorld-Studio-0.1.0-Windows-x64-Setup.exe`.

Completion PR: **#23 — Phase 18 — Stable Release and Windows Productization**.

PR #23 must remain unmerged until explicit user authorization.

## Delivered Phase 18 scope

- stable `0.1.0` identity across runtime, About, Windows metadata, package and release manifest;
- deterministic portable ZIP with independent rebuild proof;
- Inno Setup Windows installer/uninstaller and Start Menu integration;
- installed/portable mode markers and strict install/user-data separation;
- exact Phase 17 RC artifact/hash upgrade fixture;
- explicit, idempotent, non-destructive RC→stable migration state and backups;
- checkpoint-based damaged-project recovery with preservation of corrupt canonical metadata;
- malformed-preference backup plus safe defaults;
- first-class Home **Support** action and Support & Recovery UI;
- bounded diagnostic/support report with secret/private-material scanning;
- portable clean first/reopen/read-only QA;
- clean installed first run, repair/reinstall, uninstall preservation, reinstall and installed RC-profile upgrade QA;
- packaged creator→standalone Windows game export and launch;
- retained controller/accessibility/focus acceptance including gamepad A→`ui_accept`;
- inherited scale/export/multiplayer regressions;
- stable visual evidence capture;
- stable release security scanning;
- canonical Phase 18 planning/QA/install/troubleshooting/version/limitations documentation.

## Exact RC upgrade fixture

Phase 17 artifact ID: `9169222546`.

RC ZIP SHA-256: `8db8162872077d00582ab20de5361a59cae19a45a9bacb2a3a7f199d18b4d9b9`.

The stable workflow must verify both values before using the RC package as migration evidence.

## Remaining completion boundary

Do not claim Phase 18 complete until all of these are true on the exact final branch head:

1. `.github/workflows/phase18-stable-release.yml` `source-regressions` PASS.
2. `windows-stable-release` PASS.
3. Stable ZIP, setup executable, checksum files and release manifest verified.
4. Final `phase18-stable-release` artifact downloaded.
5. All eleven required stable packaged screenshots visually inspected.
6. PR #23 body updated with exact run IDs, artifact ID/digest, portable/setup SHA-256, upgrade/uninstall/export/security/visual evidence and known limitations.
7. PR #23 marked ready for review and left **unmerged**.

No Phase 19 work is authorized. Do not begin Phase 19 until Phase 18 is merged and a new handoff explicitly authorizes it.

## Security note

Historical `.polyforkAPI` credential material in Git history remains exposed. Never print, recover, test, reuse, or distribute it. External rotation/revocation remains required unless independently verified outside the repository; do not claim that external action occurred without evidence.
