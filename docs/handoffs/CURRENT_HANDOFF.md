# POLYFORK PROJECT — PHASE 18 COMPLETION HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authority

Repository default and authoritative integrated branch: `master`.

Authoritative `master`:

`49a5b55748244097d952ab9c095dd00ed0ec9f06`

This is the verified signed merge commit for:

**PR #24 — Phase 18 — Post-merge closeout correction**

PR #24 completed the forward repair after PR #23 was merged prematurely. Repository history was preserved; no reset, force-push, or history rewrite was used.

Phases **0 through 18 are complete and accepted**.

Historical `main` is obsolete starter code. The retained `archive/obsolete-main-phase14` branch is historical only and must not be used as a development base.

`master` is protected by active repository rules. Future changes must be developed from current `master` on a dedicated branch and integrated through a pull request.

## Phase 18 final source state

- Original Phase 18 implementation PR: #23
- Corrective completion PR: #24
- Corrective branch head: `5ee4e96318d34d466ec0b7fb477db8bf32941139`
- Verified PR merge candidate: `f859086a7ec874fe39cf1b83019925f544a92a10`
- Final signed integrated merge: `49a5b55748244097d952ab9c095dd00ed0ec9f06`
- Branch-head tree and tested merge-candidate tree: `9aa7ccb39e533b20936c7ce43d639abf057277c5`

The exact corrective source was tested against the then-current `master`, and the same source tree was integrated by PR #24.

## Final Phase 18 verification

Workflow `31699466148` completed successfully:

- `source-regressions` — PASS
- `windows-stable-release` — PASS

Repository-owned inherited checks also passed, including Godot Smoke, Phase 6–16 contracts and visual gates, inherited regressions, Phase 13/14/16 Windows export, Phase 14 scale stress, and Phase 15 exported multiplayer host/client verification.

## Final artifacts

Stable release artifact:

- Artifact ID: `9180943528`
- Name: `phase18-stable-release`
- Digest: `sha256:fc5dc19a7ba37a8a02c7fdce579a3a2bb6cb0e70fb5e90661cf28d4ec76f480a`

Source regression artifact:

- Artifact ID: `9180674153`
- Digest: `sha256:6522a03e145b91464066f3c5a6c1925bda9f9e95b21238a50a50450d697e32aa`

Portable release:

- `PlayWorld-Studio-0.1.0-Windows-x64.zip`
- SHA-256: `f635811f0c9738ba622b91f0a5c890c24ab491ff63ed4f85cdcb12e8ca7a160a`

Installer:

- `PlayWorld-Studio-0.1.0-Windows-x64-Setup.exe`
- SHA-256: `9f639274e4bb7df3e492a8ab9720c7c0b6c6ca12c7f644f8dd1cba4c68ba6a02`

## Accepted release behavior

Phase 18 acceptance includes:

- stable PlayWorld Studio `0.1.0` identity;
- deterministic portable ZIP with independent byte-for-byte rebuild proof;
- portable clean first run, save, reopen, and read-only-style location verification;
- alternate-location Windows installation;
- installed first run, reopen, repair, uninstall, reinstall, and preserved user data;
- exact Phase 17 `0.1.0-rc.1 → 0.1.0` project and preference migration;
- creator → standalone Windows game export and launch;
- exported multiplayer host/client ownership and input verification;
- controller, keyboard/mouse, focus, compact-layout, and accessibility acceptance;
- package, installer, and support-bundle release scanning;
- manual inspection of all eleven final packaged screenshots.

The corrected About/version screenshot visibly contains `About PlayWorld Studio`, `0.1.0`, stable channel, Windows x64, Godot 4.7.1, and source identity.

## Current development boundary

There is no active implementation milestone branch.

**No Phase 19 work is authorized.**

Do not begin Phase 19 until the user explicitly defines and authorizes its scope in a new handoff. Any future work must start from current authoritative `master@49a5b55748244097d952ab9c095dd00ed0ec9f06`.

## Repository history note

Previously committed sensitive data remains an external remediation concern. Do not restore or distribute it from repository history.
