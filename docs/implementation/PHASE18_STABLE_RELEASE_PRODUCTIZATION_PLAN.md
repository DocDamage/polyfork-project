# Phase 18 — Stable Release and Windows Productization Plan

## Objective

Convert the verified Phase 17 `0.1.0-rc.1` creator into **PlayWorld Studio 0.1.0** without replacing working editor/runtime/export architecture, then close the stable Windows release with valid package, installer, lifecycle, security, controller, and visual evidence.

## Authority

- Original Phase 18 base: `master@91b8b9c39fddda4b80ad5c6101d563245ef3e2d0`.
- Current integrated `master`: `9ed7abd28144f9757244f33aa33176e7074aca86`, the signed merge of PR #23.
- PR #23 was merged prematurely before the required manual visual gate was valid.
- Corrective branch: `fix/phase18-post-merge-closeout`.
- The corrective PR targets `master` and must remain unmerged until explicit user authorization.
- Repository history must be repaired forward; do not reset or rewrite `master`.

## Delivered implementation

1. Stable identity and deterministic portable ZIP.
2. Real Windows installer/uninstaller.
3. User-data/install separation.
4. Exact RC→stable migration validation using Phase 17 artifact `9169222546` and RC ZIP SHA `8db8162872077d00582ab20de5361a59cae19a45a9bacb2a3a7f199d18b4d9b9`.
5. Checkpoint-based project recovery and malformed-preference recovery backups.
6. Support & Recovery UI plus bounded diagnostics.
7. Portable and installed lifecycle QA, including clean first run, restart/reopen, repair/reinstall, uninstall preservation, alternate/read-only application location, export, and exported-game launch.
8. Inherited controller/accessibility/scale/export/multiplayer regressions.
9. Stable visual evidence capture.
10. Package/installer/support private-material scanning.
11. Stable release documentation and PR evidence.

## Post-merge visual correction

The original Phase 18 artifact contained an invalid `09-about-version-1280x720.png`: Home was captured instead of the About/version surface. The initial workflow checked for a file and completion marker but did not prove that the real About action rendered a visible, topmost, full-size overlay with the expected labels.

The corrective work must:

1. activate the actual Home About button;
2. use a correctly typed overlay item collection;
3. render a visible PlayWorld Studio `0.1.0` identity card;
4. verify the overlay title is `About PlayWorld Studio`;
5. verify the exact `0.1.0 • stable • Windows x64` identity;
6. verify Godot and source identity text;
7. verify title, subtitle, and status labels are renderable;
8. verify the overlay covers Home and is the topmost Home surface;
9. capture the screenshot only after those assertions pass.

## Architecture rule

Reuse Phase 17 packaging/export, Phase 2 atomic-save/checkpoint infrastructure, the universal Asset Library, current `PlaySession`, current authored-game export pipeline, and existing UI shell. Phase 18 adds productization around them; it does not create parallel versions.

## Corrective completion boundary

The exact corrective branch head must pass `.github/workflows/phase18-stable-release.yml`. Its final artifact must contain the stable portable ZIP, checksums/manifest, installer and checksum, logs, and all eleven visual-evidence images. The artifact must be downloaded, all screenshots manually inspected, and the corrective PR updated with exact run, artifact, checksum, upgrade, uninstall, export, security, and visual evidence.

The corrective PR remains open and unmerged until explicit user authorization. Phase 19 remains unauthorized.
