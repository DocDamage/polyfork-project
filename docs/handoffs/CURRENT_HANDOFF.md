# POLYFORK PROJECT — PHASE 17 COMPLETION PR HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## AUTHORITATIVE BRANCH

The repository default branch and authoritative integrated line is:

`master`

Current authoritative `master`:

`37d311b90f0684668a49e7f3b8ab197e6abcbe3a`

This is the verified signed GitHub merge commit for **PR #21 — Phase 16 — Inherited Product Completeness and Integration Closure**.

The historical `main` branch contains obsolete starter code. Never develop from `main`.

Phases **0 through 16 are complete and merged**.

## PHASE 17 — RELEASE CANDIDATE AND DISTRIBUTION

Milestone branch:

`dev/phase17-milestone`

Authoritative base:

`37d311b90f0684668a49e7f3b8ab197e6abcbe3a`

Verified implementation/release-evidence head:

`8f46b4cddd62efc5502033b3a9c0259bb740ec26`

Product version:

`PlayWorld Studio 0.1.0-rc.1`

Windows package:

`PlayWorld-Studio-0.1.0-rc.1-Windows-x64.zip`

## VERIFIED FINAL RELEASE EVIDENCE

Full Phase 17 release workflow:

`31668662576` — **PASS**

Both required jobs passed:

- `source-regressions` — PASS
- `windows-release` — PASS

The Windows release job proved:

- Phase 17 release contracts;
- inherited Phase 16 Windows export closure;
- inherited Phase 14 Small/Medium/Large Windows exports;
- inherited Phase 15 offline/multiplayer Windows exports;
- concurrent exported multiplayer host/client runtime;
- deterministic PlayWorld Studio creator-package construction;
- independent second package build with byte-for-byte identical ZIP output;
- package integrity, SHA-256, manifest, included-file, forbidden-development-material, and credential-like-material scanning;
- clean packaged creator first launch;
- real project create/open/edit/save workflow;
- Instant Play and return to Build;
- real shared Asset Library GLTF source/indexing behavior;
- packaged creator → standalone Windows game export → exported game launch;
- restart/reopen persistence;
- independent replacement-build upgrade persistence;
- read-only-style installation with writable per-user data separation;
- packaged visual evidence generation;
- packaged UI/controller/accessibility/major-screen acceptance.

Required packaged acceptance marker is present in the final evidence log:

`PASS: Phase 17 packaged creator UI, controller, accessibility, and major-screen acceptance completed.`

The physical gamepad A button is explicitly mapped to semantic `ui_accept` in the packaged creator InputMap; the acceptance assertion was retained unchanged.

Final release artifact:

- artifact ID: `9169011730`
- artifact name: `phase17-release-candidate`
- artifact SHA-256 digest: `18b36d3d43288c322ae35fc215ce6a3a7cada2226192ecaaf46d880a5d2d588b`

RC ZIP SHA-256:

`0911cc136b3deaf689b7959359ec9c45bee2f10255c7af573c9855ea0bbcdfa3`

The release manifest identifies source commit `8f46b4cddd62efc5502033b3a9c0259bb740ec26`, authoritative base `37d311b90f0684668a49e7f3b8ab197e6abcbe3a`, Windows x86_64, and Godot `4.7.1.stable.official.a13da4feb`.

## VISUAL EVIDENCE REVIEW

The final artifact's packaged acceptance screenshots were downloaded and visually inspected, not merely checked for existence:

- Home — 1600×900: coherent large-card layout, visible Continue/My Worlds/Templates/Asset Library routes;
- Home — 1280×720: coherent full layout with focus state visible;
- compact Home: responsive vertical stacking with lower cards continuing below the viewport and no control overlap;
- Asset Library: source card, path, Add Folder/Scan controls, and indexed-source status render cleanly;
- New World: Small/Medium/Large, biome, template, and Create World controls render cleanly;
- Build workspace: toolbar, Build/Play switch, tool palette, viewport, and bottom creation categories render cleanly;
- Instant Play: Play state and playable runtime viewport render correctly;
- Export: Windows x86_64 export panel renders cleanly over the Build workspace.

No GLTF default-scene fixture warning remains in the final release logs.

The hosted Windows runner emits the expected OpenGL 3.3/ANGLE fallback warning and reports Microsoft's Basic Render Driver. This is runner-specific rendering infrastructure and is not classified as a PlayWorld Studio product defect.

## PHASE 17 DELIVERED

- formal product/version identity and About/version UI;
- dedicated Windows x64 creator export preset and branded executable metadata/icon;
- deterministic Windows ZIP packaging;
- release manifest, SHA-256 checksums, third-party notices, release/user documentation;
- creator-package credential/private-development-material scan;
- bundled Godot executable and Windows export templates;
- bundled standalone-game runtime source closure;
- packaged creator support for standalone Windows game export;
- explicit missing-exporter/template failure handling;
- malformed preference recovery and per-user data/install separation;
- first-run, restart/reopen, upgrade/replacement-package, and read-only-style install verification;
- packaged visual evidence and controller/accessibility acceptance;
- dedicated Phase 17 release CI plus inherited export/scale/multiplayer regressions;
- generated `artifacts/` isolation via `.gdignore`;
- explicit gamepad A → `ui_accept` mapping;
- valid default scene in the Phase 17 GLTF fixture.

## SECURITY NOTE

Historical `.polyforkAPI` credential material in Git history must be considered exposed. Never print, recover, test, reuse, or distribute it.

The final package scan proves the RC package does not contain the legacy marker, OpenAI-style credential pattern, `.env` files, tests, `.github`, downloads, or `.git` development material.

External revocation/rotation of any historically exposed credential remains required unless it has already been completed outside the repository. There is no repository evidence proving that external action occurred, so do not claim it has.

## COMPLETION BOUNDARY

Phase 17 implementation and release verification are complete on `dev/phase17-milestone`.

Open exactly one completion PR:

**`Phase 17 — Release Candidate and Distribution`**

Base: `master`

Head: `dev/phase17-milestone`

Leave the PR **unmerged** until the user explicitly authorizes merge.

No Phase 18 development is authorized. After Phase 17 is merged, a new handoff must explicitly define the next milestone before implementation continues.
