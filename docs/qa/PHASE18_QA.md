# Phase 18 QA — Stable Release and Windows Productization

## Current status

PR #23 was merged into `master@9ed7abd28144f9757244f33aa33176e7074aca86` before the required manual visual closeout was valid. Phase 18 implementation is integrated, but final acceptance remains open on `fix/phase18-post-merge-closeout`.

The historical green artifact is not final evidence because `09-about-version-1280x720.png` showed Home instead of About/version.

## Automated workflow

`.github/workflows/phase18-stable-release.yml`

Required jobs:

- `source-regressions`
- `windows-stable-release`

## Source gate

Runs the main harness, Phase 18 contracts, Phase 16 product/integration/shared Asset Library closure, Phase 4–15 suites, Phase 7 playable smoke, and Phase 14 scale stress.

## Windows gate

Runs Phase 18 contracts plus inherited Phase 14/15/16 Windows export gates; verifies exported multiplayer host/client; builds and independently rebuilds the stable portable ZIP; validates hashes/manifests; downloads exact Phase 17 artifact `9169222546`; verifies RC ZIP SHA `8db8162872077d00582ab20de5361a59cae19a45a9bacb2a3a7f199d18b4d9b9`; performs real RC→stable migration; exercises portable first/reopen/read-only; builds the Inno Setup installer; exercises clean installed first/reopen/repair/uninstall/reinstall and installed RC-profile upgrade; executes packaged UI/controller/accessibility acceptance; captures stable visuals; and scans release/support artifacts.

## About/version automated assertions

Before `09-about-version-1280x720.png` can be saved, packaged QA must:

1. activate the real Home About button;
2. find the `HomeCreatorOverlay` created by that action;
3. verify the overlay is visible;
4. verify it is the topmost Home child;
5. verify it covers the Home surface;
6. verify the title is exactly `About PlayWorld Studio`;
7. verify the subtitle is exactly `0.1.0 • stable • Windows x64`;
8. verify Godot `4.7.1` and source identity are rendered;
9. verify title, subtitle, and status labels have non-zero renderable bounds.

The visual process must exit non-zero when any assertion fails. Screenshot existence alone is not acceptance.

## Manual visual gate

Download the final corrective `phase18-stable-release` artifact and inspect:

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

Reject clipping, overlap, unreadable labels, broken focus presentation, inconsistent spacing, incorrect `0.1.0` identity, missing icons/assets, compact-layout failures, generic developer-tool visual drift, or any image that does not show the surface named by its filename.

The About screenshot must visibly show:

- `About PlayWorld Studio`;
- PlayWorld Studio `0.1.0`;
- stable channel;
- Windows x64;
- Godot version and source identity.

## Security gate

Retain the existing package, installer, support-bundle, and release-material scans. The post-merge visual correction must not remove, bypass, or weaken any private-material or credential-pattern rejection.

## Corrective completion record

Exact final workflow ID, artifact ID/digest, portable ZIP SHA-256, installer SHA-256, lifecycle markers, security result, and manual review of all eleven screenshots belong in the corrective PR so they refer to the exact completion head without making repository commits self-referential.

The corrective PR remains unmerged until explicit user authorization. Phase 19 remains blocked.
