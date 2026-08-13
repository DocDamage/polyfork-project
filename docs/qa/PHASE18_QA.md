# Phase 18 QA — Stable Release and Windows Productization

## Final status

**PASS — COMPLETE AND ACCEPTED**

Phase 18 is integrated on authoritative `master@49a5b55748244097d952ab9c095dd00ed0ec9f06`, the verified signed merge of PR #24.

PR #23 originally integrated the implementation before manual visual closeout was valid. PR #24 corrected the About/version path, reran the complete stable-release pipeline, regenerated the artifacts, completed manual inspection, and repaired documentation forward without rewriting repository history.

## Exact source and workflow

- Corrective branch head: `5ee4e96318d34d466ec0b7fb477db8bf32941139`
- Tested PR merge candidate: `f859086a7ec874fe39cf1b83019925f544a92a10`
- Final signed integrated merge: `49a5b55748244097d952ab9c095dd00ed0ec9f06`
- Source tree tested and integrated: `9aa7ccb39e533b20936c7ce43d639abf057277c5`
- Workflow: `31699466148` — SUCCESS

Required jobs:

- `source-regressions` — PASS
- `windows-stable-release` — PASS

All other repository-owned pull-request workflows triggered on the corrective source completed successfully. The historical Phase 17 release workflow was intentionally skipped by its branch filter.

## Source gate coverage

The source gate ran:

- the main Godot test harness;
- Phase 18 contracts;
- Phase 16 product, integration, and shared Asset Library closure;
- inherited Phase 4–15 contract suites;
- Phase 7 playable controller smoke;
- Phase 14 scale stress.

## Windows gate coverage

The Windows gate verified:

- inherited Phase 14/15/16 Windows export behavior;
- concurrent exported multiplayer host/client connection and input ownership;
- deterministic stable portable package generation and independent rebuild;
- package manifests and checksums;
- exact Phase 17 release-candidate artifact and real RC→stable migration;
- portable first run, export, reopen, and read-only-style application location;
- installer creation and stable version metadata;
- alternate-location installation;
- installed first run and reopen;
- repair/reinstall;
- uninstall application removal with user-data preservation;
- reinstall and preserved-state reopen;
- installed RC-profile upgrade;
- packaged UI, controller, focus, and accessibility acceptance;
- stable visual capture;
- portable, installer, and generated support-material validation.

## Final artifacts and checksums

Stable release artifact:

- Artifact ID: `9180943528`
- Name: `phase18-stable-release`
- Digest: `sha256:fc5dc19a7ba37a8a02c7fdce579a3a2bb6cb0e70fb5e90661cf28d4ec76f480a`
- Size: 345,330,163 bytes

Source regression artifact:

- Artifact ID: `9180674153`
- Digest: `sha256:6522a03e145b91464066f3c5a6c1925bda9f9e95b21238a50a50450d697e32aa`

Portable ZIP:

- File: `PlayWorld-Studio-0.1.0-Windows-x64.zip`
- SHA-256: `f635811f0c9738ba622b91f0a5c890c24ab491ff63ed4f85cdcb12e8ca7a160a`
- Published sidecar matched the downloaded file.

Installer:

- File: `PlayWorld-Studio-0.1.0-Windows-x64-Setup.exe`
- SHA-256: `9f639274e4bb7df3e492a8ab9720c7c0b6c6ca12c7f644f8dd1cba4c68ba6a02`
- Published sidecar matched the downloaded file.

## About/version assertions

Before `09-about-version-1280x720.png` is saved, packaged verification now:

1. activates the real Home About button;
2. resolves the actual `HomeCreatorOverlay` created by that action;
3. verifies the overlay is visible;
4. verifies it is the topmost Home child;
5. verifies it covers the Home surface;
6. verifies the title is exactly `About PlayWorld Studio`;
7. verifies the stable `0.1.0` Windows x64 identity;
8. verifies Godot 4.7.1 and source identity are rendered;
9. verifies title, subtitle, and status labels have non-zero renderable bounds.

Any failed assertion exits the visual process non-zero. Screenshot existence alone is not acceptance.

## Manual visual review

Every final screenshot was opened and visually inspected:

1. `01-home-1600x900.png` — coherent full layout, visible focus, no clipping or overlap.
2. `02-home-1280x720.png` — coherent normal layout with all primary cards and header actions visible.
3. `03-home-compact.png` — vertical compact stack remains legible; lower content correctly continues below the viewport.
4. `04-asset-library-1280x720.png` — shared source, path, Add Folder, and Scan Library controls visible.
5. `05-new-world-1280x720.png` — world name, size, biome, template, and create action visible without collision.
6. `06-workspace-1280x720.png` — Build state, transform tools, contextual dock, project identity, and viewport render correctly.
7. `07-instant-play-1280x720.png` — Play state and disposable runtime character/world render correctly.
8. `08-export-1280x720.png` — Windows x86_64 export panel and build action render correctly.
9. `09-about-version-1280x720.png` — corrected and valid; About title, `0.1.0`, stable, Windows x64, Godot 4.7.1, and source identity are visible.
10. `10-settings-1280x720.png` — performance, scale, reduced motion, density, and effective policy render correctly.
11. `11-support-recovery-1280x720.png` — stable identity, bounded diagnostics notice, user-data location, support action, and recovery state render correctly.

No blank or substituted surface, major control collision, unreadable primary label, incorrect product identity, or compact-layout failure was found.

## Lifecycle acceptance

Accepted release behavior includes:

- real Phase 17 RC first-run authoring/export;
- real `0.1.0-rc.1 → 0.1.0` project and preference preservation;
- clean portable authoring and creator→standalone-game export/launch;
- portable restart/reopen persistence;
- read-only-style package location with user data outside the package;
- alternate-location silent install;
- installed first run and reopen;
- repair/reinstall;
- uninstall removes application files while authored state remains;
- reinstall reopens the preserved state;
- installed stable opens the exact RC-authored profile.

## Controller and accessibility acceptance

The inherited packaged acceptance marker passed. Coverage includes real joypad navigation, gamepad A → `ui_accept`, keyboard/mouse parity, persisted compact and reduced-motion preferences, focus assertions, Build/Play navigation, and major-screen coverage.

## Release validation

The primary portable package, independent rebuild, installer, and generated support material all passed the final distribution checks. No release gate was weakened for the corrective closeout.

## Completion

PR #24 contains the detailed completion discussion and is merged. Phase 18 is complete and accepted on authoritative `master`.

No Phase 19 work is authorized until a new user-approved handoff defines the next milestone.
