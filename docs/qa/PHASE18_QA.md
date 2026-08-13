# Phase 18 QA — Stable Release and Windows Productization

## Automated workflow

`.github/workflows/phase18-stable-release.yml`

Required jobs:

- `source-regressions`
- `windows-stable-release`

## Source gate

Runs the main harness, Phase 18 contracts, Phase 16 product/integration/shared Asset Library closure, Phase 4–15 suites, Phase 7 playable smoke, and Phase 14 scale stress.

## Windows gate

Runs Phase 18 contracts plus inherited Phase 14/15/16 Windows export gates; verifies exported multiplayer host/client; builds and independently rebuilds the stable portable ZIP; validates hashes/manifests; downloads exact Phase 17 artifact `9169222546`; verifies RC ZIP SHA `8db8162872077d00582ab20de5361a59cae19a45a9bacb2a3a7f199d18b4d9b9`; performs real RC→stable migration; exercises portable first/reopen/read-only; builds the Inno Setup installer; exercises clean installed first/reopen/repair/uninstall/reinstall and installed RC-profile upgrade; executes packaged UI/controller/accessibility acceptance; captures stable visuals; scans release/support artifacts.

## Manual visual gate

Download final `phase18-stable-release` evidence and inspect:

1. `01-home-1600x900.png`
2. `02-home-1280x720.png`
3. `03-home-compact.png`
4. `04-asset-library-1280x720.png`
5. `05-new-world-1280x720.png`
6. `06-workspace-1280x720.png`
7. `07-instant-play-1280x720.png`
8. `08-export-1280x720.png`
9. `09-about-version-1280x720.png`
10. `10-settings-1280x720.png`
11. `11-support-recovery-1280x720.png`

Reject clipping, overlap, unreadable labels, broken focus presentation, inconsistent spacing, incorrect `0.1.0` identity, missing icons/assets, compact-layout failures, or generic developer-tool visual drift.

## Security gate

Reject `.env`, `.git`, tests/dev-only material in release payloads; legacy `.polyforkAPI` markers; OpenAI-style credential patterns; support bundles containing API-key material or arbitrary private project content.

## Completion record

Exact final workflow ID, artifact ID/digest, portable ZIP SHA-256, installer SHA-256, and manual screenshot review belong in PR #23 so they can refer to the exact completion head without making the repository commit self-referential.
