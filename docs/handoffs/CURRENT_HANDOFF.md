# POLYFORK PROJECT — PHASE 18 POST-MERGE CORRECTION HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authority

Repository default and authoritative integrated branch: `master`.

Current authoritative `master`:

`9ed7abd28144f9757244f33aa33176e7074aca86`

This is the verified signed merge of **PR #23 — Phase 18 — Stable Release and Windows Productization**.

PR #23 was merged prematurely before its required manual visual closeout was valid. Do not reset, force-push, or rewrite `master`; repair forward from this commit.

Phases **0 through 17 are complete and accepted**. Phase 18 implementation is integrated, but Phase 18 final acceptance remains open.

Historical `main` is obsolete starter code and must not be used.

## Corrective branch

`fix/phase18-post-merge-closeout`

The corrective branch targets current `master`. Its pull request must remain open and unmerged until explicit user authorization.

## Why correction is required

The original Phase 18 workflow run was green, but downloaded artifact inspection found that:

`09-about-version-1280x720.png`

showed Home instead of the required About/version surface.

The old gate verified screenshot existence and a broad completion marker, but it did not prove that the real About action produced a visible, topmost, full-size overlay with exact stable identity text.

The stale About path also passed an untyped empty collection into an overlay API declared as `Array[Dictionary]`, so the corrective path now uses an explicitly typed collection and visible identity card.

## Corrective implementation

The corrective branch:

- keeps the existing release and support security scans unchanged;
- makes the Home overlay explicitly topmost and input-blocking;
- exposes bounded overlay presentation state for test assertions;
- renders a visible PlayWorld Studio `0.1.0` About identity card;
- activates the real About button during packaged visual QA;
- verifies exact title, version, channel, platform, Godot version, and source identity;
- verifies the overlay covers Home and required labels are renderable before screenshot capture;
- retains the complete portable, installer, upgrade, uninstall, export, controller, accessibility, scale, multiplayer, and support-bundle pipeline.

## Remaining Phase 18 completion boundary

Do not claim Phase 18 finally accepted until all of these are true on the exact corrective head:

1. `.github/workflows/phase18-stable-release.yml` `source-regressions` passes.
2. `windows-stable-release` passes.
3. Stable ZIP, setup executable, checksum files, and release manifest are verified.
4. The final `phase18-stable-release` artifact is downloaded.
5. All eleven required screenshots are visually inspected.
6. `09-about-version-1280x720.png` visibly shows the About/version surface and stable `0.1.0` identity.
7. The corrective PR body records exact run IDs, artifact ID/digest, portable/setup SHA-256, upgrade/uninstall/export/security/controller/visual evidence, and known limitations.
8. The corrective PR remains **unmerged** until explicit user authorization.

## Authorization boundary

No Phase 19 work is authorized. Do not begin Phase 19 until the corrective Phase 18 PR is explicitly merged and a new handoff authorizes the next milestone.

## Security boundary

Historical API credential material in Git history remains exposed. Never print, recover, test, reuse, or distribute it. External rotation/revocation remains required unless independently verified outside the repository; do not claim that external action occurred without evidence.
